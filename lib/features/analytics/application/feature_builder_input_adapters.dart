import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../data/analytics_repository.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/analytics_stats_cache.dart';
import 'behavior_feature_entity_kind.dart';

class FeatureBuilderDateWindow {
  const FeatureBuilderDateWindow({
    required this.startDateKey,
    required this.endDateKey,
    required this.dateKeys,
  });

  final String startDateKey;
  final String endDateKey;
  final List<String> dateKeys;
}

class FeatureBuilderDateNormalizer {
  const FeatureBuilderDateNormalizer._();

  static DateTime localDayStart(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String dateKeyFromDateTime(DateTime value) {
    return DateKeys.yyyymmdd(localDayStart(value));
  }

  static String dateKeyFromEpochMs(int epochMs) {
    return dateKeyFromDateTime(
      DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: false),
    );
  }

  static String? dateKeyFromIsoLocal(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return dateKeyFromDateTime(parsed);
  }

  static FeatureBuilderDateWindow rollingWindow({
    required DateTime now,
    int trailingDays = 30,
  }) {
    final end = localDayStart(now);
    final safeDays = trailingDays < 1 ? 1 : trailingDays;
    final start = end.subtract(Duration(days: safeDays - 1));
    final keys = <String>[];
    for (
      var cursor = start;
      !cursor.isAfter(end);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      keys.add(DateKeys.yyyymmdd(cursor));
    }
    return FeatureBuilderDateWindow(
      startDateKey: DateKeys.yyyymmdd(start),
      endDateKey: DateKeys.yyyymmdd(end),
      dateKeys: keys,
    );
  }
}

class FeatureEventHistory {
  const FeatureEventHistory({required this.entityId, required this.events});

  final String entityId;
  final List<AnalyticsEvent> events;

  List<AnalyticsEvent> get completionEvents => events
      .where(
        (e) =>
            e.type == AnalyticsEventType.taskCompleted ||
            e.type == AnalyticsEventType.habitCompleted,
      )
      .toList();

  List<AnalyticsEvent> get deferredEvents =>
      events.where((e) => e.type == AnalyticsEventType.taskDeferred).toList();
}

class TaskFeatureSeed {
  const TaskFeatureSeed({
    required this.row,
    required this.entityKind,
    required this.scheduledDateKey,
    required this.scheduledDateKeysInWindow,
    this.rowPlannedForToday,
  });

  /// Reference row (latest plan day in the loaded window by date key).
  final PlannedTaskRow row;
  final String entityKind;
  /// Latest plan date key in window (lexicographic max among occurrences).
  final String scheduledDateKey;
  /// All `yyyy-MM-dd` days this task appears in the plan within the feature window.
  final Set<String> scheduledDateKeysInWindow;
  /// Row for **today** (local), when the task is on today's plan — used for overdue.
  final PlannedTaskRow? rowPlannedForToday;
}

class GoalFeatureSeed {
  const GoalFeatureSeed({
    required this.goal,
    required this.entityKind,
    required this.checkIns,
    required this.completedMilestones,
    required this.totalMilestones,
  });

  final UserGoal goal;
  final String entityKind;
  final List<GoalCheckIn> checkIns;
  final int completedMilestones;
  final int totalMilestones;
}

class FeatureBuilderInputBundle {
  const FeatureBuilderInputBundle({
    required this.window,
    required this.eventHistoryByEntityId,
    required this.taskSeedsById,
    required this.goalSeedsById,
    required this.statsCache,
  });

  final FeatureBuilderDateWindow window;
  final Map<String, FeatureEventHistory> eventHistoryByEntityId;
  final Map<String, TaskFeatureSeed> taskSeedsById;
  final Map<String, GoalFeatureSeed> goalSeedsById;
  final List<AnalyticsStatsCache> statsCache;
}

class FeatureBuilderInputAdapters {
  const FeatureBuilderInputAdapters({
    required AnalyticsRepository analyticsRepository,
    required PlanningRepository planningRepository,
    required GoalsRepository goalsRepository,
  }) : _analyticsRepository = analyticsRepository,
       _planningRepository = planningRepository,
       _goalsRepository = goalsRepository;

  final AnalyticsRepository _analyticsRepository;
  final PlanningRepository _planningRepository;
  final GoalsRepository _goalsRepository;

  Future<FeatureBuilderInputBundle> load({
    DateTime? now,
    int trailingDays = 30,
  }) async {
    final nowLocal = now ?? DateTime.now();
    final window = FeatureBuilderDateNormalizer.rollingWindow(
      now: nowLocal,
      trailingDays: trailingDays,
    );

    final events = await _analyticsRepository.listEvents();
    final eventsInWindow = events.where((event) {
      if (event.entityId.trim().isEmpty) return false;
      final key = event.dateKey.trim();
      if (key.isEmpty) return false;
      return key.compareTo(window.startDateKey) >= 0 &&
          key.compareTo(window.endDateKey) <= 0;
    }).toList();

    final eventHistoryByEntityId = <String, FeatureEventHistory>{};
    final groupedEvents = <String, List<AnalyticsEvent>>{};
    for (final event in eventsInWindow) {
      groupedEvents
          .putIfAbsent(event.entityId, () => <AnalyticsEvent>[])
          .add(event);
    }
    groupedEvents.forEach((entityId, grouped) {
      grouped.sort(
        (a, b) => a.timestampLocalIso.compareTo(b.timestampLocalIso),
      );
      eventHistoryByEntityId[entityId] = FeatureEventHistory(
        entityId: entityId,
        events: grouped,
      );
    });

    final taskSeedsById = await _loadTaskSeeds(window.dateKeys, nowLocal);
    final goalSeedsById = await _loadGoalSeeds(
      startDateKey: window.startDateKey,
      endDateKey: window.endDateKey,
    );
    final stats = await _analyticsRepository.listStatsCache();
    final statsInWindow = stats.where((s) {
      final dateKey = s.dateKey.trim();
      if (dateKey.isEmpty) return false;
      return dateKey.compareTo(window.startDateKey) >= 0 &&
          dateKey.compareTo(window.endDateKey) <= 0;
    }).toList();

    return FeatureBuilderInputBundle(
      window: window,
      eventHistoryByEntityId: eventHistoryByEntityId,
      taskSeedsById: taskSeedsById,
      goalSeedsById: goalSeedsById,
      statsCache: statsInWindow,
    );
  }

  Future<Map<String, TaskFeatureSeed>> _loadTaskSeeds(
    List<String> dateKeys,
    DateTime nowLocal,
  ) async {
    final todayKey = DateKeys.yyyymmdd(
      FeatureBuilderDateNormalizer.localDayStart(nowLocal),
    );
    final accum = <String, _TaskSeedAccum>{};

    for (final dateKey in dateKeys) {
      final rows = await collectTasksForDateKey(
        _planningRepository,
        dateKey,
        enforceTaskPlanDate: true,
      );
      for (final row in rows) {
        final task = row.task;
        if (task.id.trim().isEmpty) continue;
        final id = task.id;
        final acc = accum.putIfAbsent(id, _TaskSeedAccum.new);
        acc.keys.add(row.dateKey);
        if (acc.maxDateKey.isEmpty || row.dateKey.compareTo(acc.maxDateKey) >= 0) {
          acc.maxDateKey = row.dateKey;
          acc.referenceRow = row;
        }
        if (row.dateKey == todayKey) {
          acc.rowPlannedForToday = row;
        }
      }
    }

    return accum.map((id, a) {
      final ref = a.referenceRow;
      if (ref == null) {
        throw StateError('Task seed accum missing reference row for $id');
      }
      return MapEntry(
        id,
        TaskFeatureSeed(
          row: ref,
          entityKind: behaviorEntityKindForTask(ref.task).name,
          scheduledDateKey: a.maxDateKey,
          scheduledDateKeysInWindow: Set<String>.unmodifiable(a.keys),
          rowPlannedForToday: a.rowPlannedForToday,
        ),
      );
    });
  }

  Future<Map<String, GoalFeatureSeed>> _loadGoalSeeds({
    required String startDateKey,
    required String endDateKey,
  }) async {
    final out = <String, GoalFeatureSeed>{};
    final goals = await _goalsRepository.fetchGoalsOnce();
    for (final goal in goals) {
      if (goal.id.trim().isEmpty) continue;
      if (goal.status == GoalStatus.completed) continue;
      final checkIns = await _goalsRepository.getCheckInsForGoal(
        goal.id,
        startDateKey: startDateKey,
        endDateKey: endDateKey,
      );
      final milestones = await _goalsRepository.getMilestones(goal.id);
      final completedMilestones = milestones.where((m) => m.completed).length;
      out[goal.id] = GoalFeatureSeed(
        goal: goal,
        entityKind: behaviorEntityKindForGoal(goal).name,
        checkIns: checkIns,
        completedMilestones: completedMilestones,
        totalMilestones: milestones.length,
      );
    }
    return out;
  }
}

class _TaskSeedAccum {
  PlannedTaskRow? referenceRow;
  String maxDateKey = '';
  final Set<String> keys = <String>{};
  PlannedTaskRow? rowPlannedForToday;
}

final featureBuilderInputAdaptersProvider =
    Provider<FeatureBuilderInputAdapters>((ref) {
      return FeatureBuilderInputAdapters(
        analyticsRepository: ref.read(analyticsRepositoryProvider),
        planningRepository: ref.read(planningRepositoryProvider),
        goalsRepository: ref.read(goalsRepositoryProvider),
      );
    });

final featureBuilderInputsProvider =
    FutureProvider.family<FeatureBuilderInputBundle, int>((
      ref,
      trailingDays,
    ) async {
      final adapters = ref.read(featureBuilderInputAdaptersProvider);
      return adapters.load(trailingDays: trailingDays);
    });
