import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/sync/cloud_sync_providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../data/analytics_repository.dart';
import '../domain/models/analytics_stats_cache.dart';
import 'daily_analytics_engine.dart';
import 'analytics_period_bundle.dart';
import 'streak_protection.dart';

String _statsId({required String scopeType, required String dateKey}) =>
    'analytics::$scopeType::$dateKey';

Future<DailyAnalyticsSnapshot?> readCachedDailySnapshot(
  AnalyticsRepository repo, {
  required String scopeType,
  required String dateKey,
}) async {
  final existing = await repo.listStatsCache(
    scopeType: scopeType,
    scopeId: 'global',
    dateKey: dateKey,
  );
  if (existing.isEmpty || existing.first.payload.isEmpty) return null;
  return DailyAnalyticsSnapshot.fromPayload(existing.first.payload);
}

Future<void> _upsertDailySnapshot(
  AnalyticsRepository repo, {
  required String scopeType,
  required DailyAnalyticsSnapshot snapshot,
}) async {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final stats = AnalyticsStatsCache(
    id: _statsId(scopeType: scopeType, dateKey: snapshot.dateKey),
    scopeType: scopeType,
    scopeId: 'global',
    dateKey: snapshot.dateKey,
    payload: snapshot.toPayload(),
    createdAtMs: nowMs,
    updatedAtMs: nowMs,
    schemaVersion: snapshot.schemaVersion,
  );
  await repo.upsertStatsCache(stats);
}

Future<DailyAnalyticsSnapshot> _computeGoalHabitDailyForDate(
  Ref ref,
  String dateKey,
) async {
  final goalsRepo = ref.read(goalsRepositoryProvider);
  final planningRepo = ref.read(planningRepositoryProvider);
  final allGoals = await goalsRepo.fetchGoalsOnce();
  final inPeriodGoals = allGoals.where((goal) {
    if (goal.status == GoalStatus.paused) return false;
    return GoalPeriodHelpers.isDateKeyInPeriod(goal, dateKey);
  }).toList();

  final checkIns = <GoalCheckIn>[];
  for (final goal in inPeriodGoals) {
    final rows = await goalsRepo.getCheckInsForGoal(
      goal.id,
      startDateKey: dateKey,
      endDateKey: dateKey,
    );
    checkIns.addAll(rows);
  }

  final dayRows = await collectTasksForDateKey(
    planningRepo,
    dateKey,
    enforceTaskPlanDate: true,
  );
  final habitTasks = dayRows
      .where((row) => row.task.isHabitAnchor)
      .map((e) => e.task);

  return computeGoalHabitDailyAnalytics(
    dateKey: dateKey,
    goals: inPeriodGoals,
    checkIns: checkIns,
    habitTasks: habitTasks,
  );
}

Future<DailyAnalyticsSnapshot> _computeTaskDailyForDate(
  Ref ref,
  String dateKey,
) async {
  final planningRepo = ref.read(planningRepositoryProvider);
  final dayRows = await collectTasksForDateKey(
    planningRepo,
    dateKey,
    enforceTaskPlanDate: true,
  );
  // Task analytics should reflect all tasks planned for the day.
  final tasks = dayRows.map((row) => row.task).toList();
  return computeTaskDailyAnalytics(dateKey: dateKey, tasks: tasks);
}

Future<List<DailyAnalyticsSnapshot>> _readOrComputeDailyRange(
  Ref ref, {
  required String scopeType,
  required DateTime startInclusive,
  required DateTime endInclusive,
}) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final todayKey = DateKeys.todayKey();
  final results = <DailyAnalyticsSnapshot>[];
  for (
    var day = DateTime(
      startInclusive.year,
      startInclusive.month,
      startInclusive.day,
    );
    !day.isAfter(endInclusive);
    day = day.add(const Duration(days: 1))
  ) {
    final dateKey = DateKeys.yyyymmdd(day);
    final existing = await repo.listStatsCache(
      scopeType: scopeType,
      scopeId: 'global',
      dateKey: dateKey,
    );
    final shouldRecompute = dateKey == todayKey;
    if (!shouldRecompute &&
        existing.isNotEmpty &&
        existing.first.payload.isNotEmpty) {
      results.add(DailyAnalyticsSnapshot.fromPayload(existing.first.payload));
      continue;
    }
    final computed = scopeType == goalHabitDailyScope
        ? await _computeGoalHabitDailyForDate(ref, dateKey)
        : await _computeTaskDailyForDate(ref, dateKey);
    await _upsertDailySnapshot(repo, scopeType: scopeType, snapshot: computed);
    results.add(computed);
  }
  return results;
}

final dailyGoalHabitAnalyticsProvider =
    FutureProvider.family<DailyAnalyticsSnapshot, String>((ref, dateKey) async {
      // Recompute when goals change; for today also react to task-stream updates
      // because habit-task completion is a hybrid source.
      ref.watch(goalsStreamProvider);
      if (dateKey == DateKeys.todayKey()) {
        ref.watch(todayAllTasksRowsProvider);
      }
      final repo = ref.read(analyticsRepositoryProvider);
      if (ref.read(cloudSyncInProgressProvider)) {
        final cached = await readCachedDailySnapshot(
          repo,
          scopeType: goalHabitDailyScope,
          dateKey: dateKey,
        );
        if (cached != null) return cached;
      }
      final snapshot = await _computeGoalHabitDailyForDate(ref, dateKey);
      await _upsertDailySnapshot(
        repo,
        scopeType: goalHabitDailyScope,
        snapshot: snapshot,
      );
      return snapshot;
    });

final dailyTaskAnalyticsProvider =
    FutureProvider.family<DailyAnalyticsSnapshot, String>((ref, dateKey) async {
      // Recompute task daily analytics immediately as today's tasks stream changes.
      if (dateKey == DateKeys.todayKey()) {
        ref.watch(todayAllTasksRowsProvider);
      }
      final repo = ref.read(analyticsRepositoryProvider);
      if (ref.read(cloudSyncInProgressProvider)) {
        final cached = await readCachedDailySnapshot(
          repo,
          scopeType: taskDailyScope,
          dateKey: dateKey,
        );
        if (cached != null) return cached;
      }
      final snapshot = await _computeTaskDailyForDate(ref, dateKey);
      await _upsertDailySnapshot(
        repo,
        scopeType: taskDailyScope,
        snapshot: snapshot,
      );
      return snapshot;
    });

/// Full recompute from live goals/tasks (persists daily caches as a side effect).
Future<AnalyticsPeriodBundle> computeAnalyticsPeriodBundle(Ref ref) async {
  final now = DateTime.now();
  final todayKey = DateKeys.todayKey(now);
  final todayGoalHabit = await _computeGoalHabitDailyForDate(ref, todayKey);
  final todayTask = await _computeTaskDailyForDate(ref, todayKey);
  final repo = ref.read(analyticsRepositoryProvider);
  await _upsertDailySnapshot(
    repo,
    scopeType: goalHabitDailyScope,
    snapshot: todayGoalHabit,
  );
  await _upsertDailySnapshot(
    repo,
    scopeType: taskDailyScope,
    snapshot: todayTask,
  );

  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final endDay = DateTime(now.year, now.month, now.day);
  final weekGoalHabitRange = await _readOrComputeDailyRange(
    ref,
    scopeType: goalHabitDailyScope,
    startInclusive: weekStart,
    endInclusive: endDay,
  );
  final weekTaskRange = await _readOrComputeDailyRange(
    ref,
    scopeType: taskDailyScope,
    startInclusive: weekStart,
    endInclusive: endDay,
  );

  final monthStart = DateTime(now.year, now.month, 1);
  final monthGoalHabitRange = await _readOrComputeDailyRange(
    ref,
    scopeType: goalHabitDailyScope,
    startInclusive: monthStart,
    endInclusive: endDay,
  );
  final monthTaskRange = await _readOrComputeDailyRange(
    ref,
    scopeType: taskDailyScope,
    startInclusive: monthStart,
    endInclusive: endDay,
  );

  final enforcementMode = ref.read(defaultEnforcementModeProvider);
  final attention = ref.read(attentionStateProvider).valueOrNull;
  final protectedWeek = buildStreakProtectedDateKeys(
    attention: attention,
    rangeStartInclusive: weekStart,
    rangeEndInclusive: endDay,
  );
  final protectedMonth = buildStreakProtectedDateKeys(
    attention: attention,
    rangeStartInclusive: monthStart,
    rangeEndInclusive: endDay,
  );

  return AnalyticsPeriodBundle(
    goalHabitDay: todayGoalHabit,
    taskDay: todayTask,
    goalHabitWeek: rollupDailyAnalytics(
      snapshots: weekGoalHabitRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedWeek,
    ),
    taskWeek: rollupDailyAnalytics(
      snapshots: weekTaskRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedWeek,
    ),
    goalHabitMonth: rollupDailyAnalytics(
      snapshots: monthGoalHabitRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedMonth,
    ),
    taskMonth: rollupDailyAnalytics(
      snapshots: monthTaskRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedMonth,
    ),
    goalHabitWeekSeries: weekGoalHabitRange
        .map((d) => d.weightedCompletionRate.clamp(0.0, 1.0))
        .toList(),
    taskWeekSeries: weekTaskRange
        .map((d) => d.weightedCompletionRate.clamp(0.0, 1.0))
        .toList(),
  );
}
