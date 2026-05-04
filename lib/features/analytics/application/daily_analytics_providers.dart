import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../data/analytics_repository.dart';
import '../domain/models/analytics_stats_cache.dart';
import 'daily_analytics_engine.dart';

class AnalyticsPeriodBundle {
  const AnalyticsPeriodBundle({
    required this.goalHabitDay,
    required this.taskDay,
    required this.goalHabitWeek,
    required this.taskWeek,
    required this.goalHabitMonth,
    required this.taskMonth,
  });

  final DailyAnalyticsSnapshot goalHabitDay;
  final DailyAnalyticsSnapshot taskDay;
  final RollupAnalyticsSnapshot goalHabitWeek;
  final RollupAnalyticsSnapshot taskWeek;
  final RollupAnalyticsSnapshot goalHabitMonth;
  final RollupAnalyticsSnapshot taskMonth;
}

String _statsId({required String scopeType, required String dateKey}) =>
    'analytics::$scopeType::$dateKey';

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
      final snapshot = await _computeTaskDailyForDate(ref, dateKey);
      await _upsertDailySnapshot(
        repo,
        scopeType: taskDailyScope,
        snapshot: snapshot,
      );
      return snapshot;
    });

final analyticsPeriodBundleProvider = FutureProvider<AnalyticsPeriodBundle>((
  ref,
) async {
  final now = DateTime.now();
  final todayKey = DateKeys.todayKey(now);
  final todayGoalHabit = await ref.watch(
    dailyGoalHabitAnalyticsProvider(todayKey).future,
  );
  final todayTask = await ref.watch(
    dailyTaskAnalyticsProvider(todayKey).future,
  );

  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final weekGoalHabitRange = await _readOrComputeDailyRange(
    ref,
    scopeType: goalHabitDailyScope,
    startInclusive: weekStart,
    endInclusive: DateTime(now.year, now.month, now.day),
  );
  final weekTaskRange = await _readOrComputeDailyRange(
    ref,
    scopeType: taskDailyScope,
    startInclusive: weekStart,
    endInclusive: DateTime(now.year, now.month, now.day),
  );

  final monthStart = DateTime(now.year, now.month, 1);
  final monthGoalHabitRange = await _readOrComputeDailyRange(
    ref,
    scopeType: goalHabitDailyScope,
    startInclusive: monthStart,
    endInclusive: DateTime(now.year, now.month, now.day),
  );
  final monthTaskRange = await _readOrComputeDailyRange(
    ref,
    scopeType: taskDailyScope,
    startInclusive: monthStart,
    endInclusive: DateTime(now.year, now.month, now.day),
  );

  return AnalyticsPeriodBundle(
    goalHabitDay: todayGoalHabit,
    taskDay: todayTask,
    goalHabitWeek: rollupDailyAnalytics(
      snapshots: weekGoalHabitRange,
      now: now,
    ),
    taskWeek: rollupDailyAnalytics(snapshots: weekTaskRange, now: now),
    goalHabitMonth: rollupDailyAnalytics(
      snapshots: monthGoalHabitRange,
      now: now,
    ),
    taskMonth: rollupDailyAnalytics(snapshots: monthTaskRange, now: now),
  );
});
