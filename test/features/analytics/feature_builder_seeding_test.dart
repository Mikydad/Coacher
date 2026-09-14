import 'package:sidepal/features/analytics/application/feature_builder_input_adapters.dart';
import 'package:sidepal/features/analytics/data/analytics_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/no_op_goals_repository.dart';
import '../../support/no_op_planning_repository.dart';

/// Layer 1 seeds coaching subjects only (2026-09-15): goals inside their
/// period with at least one loggable day so far, and tasks planned within
/// the last [kTaskCoachingRecencyDays]. Everything else is history.
void main() {
  final now = DateTime(2026, 9, 13, 10); // Sunday

  group('goal seeding', () {
    test('keeps in-period goals, drops ended and future ones', () async {
      final adapters = FeatureBuilderInputAdapters(
        analyticsRepository: _NoOpAnalyticsRepository(),
        planningRepository: NoOpPlanningRepository(),
        goalsRepository: _GoalsRepo([
          _goal(
            id: 'live',
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 10, 1),
          ),
          _goal(
            id: 'ended',
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 9, 10),
          ),
          _goal(
            id: 'future',
            start: DateTime(2026, 9, 20),
            end: DateTime(2026, 10, 20),
          ),
          _goal(
            id: 'paused',
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 10, 1),
            status: GoalStatus.paused,
          ),
        ]),
      );
      final bundle = await adapters.load(now: now);
      expect(bundle.goalSeedsById.keys, ['live']);
    });

    test(
      'a repeating goal with no action day in the window yet is skipped',
      () async {
        // Sundays only, period starts today (Sunday) → one opportunity: seeded.
        // Mondays only, period starts today → no opportunity yet: skipped.
        final adapters = FeatureBuilderInputAdapters(
          analyticsRepository: _NoOpAnalyticsRepository(),
          planningRepository: NoOpPlanningRepository(),
          goalsRepository: _GoalsRepo([
            _goal(
              id: 'sundays',
              start: DateTime(2026, 9, 13),
              end: DateTime(2026, 10, 31),
              weekdays: const [DateTime.sunday],
            ),
            _goal(
              id: 'mondays',
              start: DateTime(2026, 9, 13),
              end: DateTime(2026, 10, 31),
              weekdays: const [DateTime.monday],
            ),
          ]),
        );
        final bundle = await adapters.load(now: now);
        expect(bundle.goalSeedsById.keys, ['sundays']);
      },
    );
  });

  group('task seeding', () {
    test('only tasks planned within the recency window are subjects', () async {
      final adapters = FeatureBuilderInputAdapters(
        analyticsRepository: _NoOpAnalyticsRepository(),
        planningRepository: _PlanningRepo({
          '2026-09-13': ['today'],
          '2026-09-07': ['six-days-ago'],
          '2026-09-06': ['seven-days-ago'],
          '2026-08-25': ['old', 'today'],
        }),
        goalsRepository: NoOpGoalsRepository(),
      );
      final bundle = await adapters.load(now: now);
      expect(bundle.goalSeedsById, isEmpty);
      expect(
        bundle.taskSeedsById.keys.toSet(),
        {'today', 'six-days-ago'},
        reason: 'planned ≥ $kTaskCoachingRecencyDays days ago is history',
      );
      // Recent task keeps its full in-window plan history for the metrics.
      expect(bundle.taskSeedsById['today']!.scheduledDateKeysInWindow, {
        '2026-08-25',
        '2026-09-13',
      });
      expect(bundle.taskSeedsById['today']!.rowPlannedForToday, isNotNull);
    });
  });
}

class _GoalsRepo extends NoOpGoalsRepository {
  _GoalsRepo(this.goals);
  final List<UserGoal> goals;

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => goals;
}

/// Plan days → task ids planned that day (one routine + one block per day).
class _PlanningRepo extends NoOpPlanningRepository {
  _PlanningRepo(this.byDay);
  final Map<String, List<String>> byDay;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    if (!byDay.containsKey(dateKey)) return const [];
    return [
      Routine(
        id: 'r-$dateKey',
        title: 'Day',
        dateKey: dateKey,
        orderIndex: 0,
        createdAtMs: 0,
        updatedAtMs: 0,
      ),
    ];
  }

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => [
    TaskBlock(
      id: 'b-$routineId',
      routineId: routineId,
      title: 'Block',
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  ];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async {
    final dateKey = routineId.substring(2);
    return [
      for (final id in byDay[dateKey] ?? const <String>[])
        PlannedTask(
          id: id,
          routineId: routineId,
          blockId: blockId,
          title: id,
          durationMinutes: 25,
          priority: 2,
          orderIndex: 0,
          reminderEnabled: false,
          reminderTimeIso: null,
          status: TaskStatus.notStarted,
          createdAtMs: 0,
          updatedAtMs: 0,
          planDateKey: dateKey,
        ),
    ];
  }
}

class _NoOpAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {}

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {}

  @override
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  }) async => const [];

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async => const [];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {}
}

UserGoal _goal({
  required String id,
  required DateTime start,
  required DateTime end,
  List<int>? weekdays,
  GoalStatus status = GoalStatus.active,
}) {
  return UserGoal(
    id: id,
    title: id,
    categoryId: 'study',
    repeatCadence: weekdays == null
        ? GoalRepeatCadence.daily
        : GoalRepeatCadence.weekly,
    scheduledWeekdays: weekdays,
    status: status,
    measurementKind: MeasurementKind.sessions,
    targetValue: 1,
    intensity: 3,
    periodStartMs: start.millisecondsSinceEpoch,
    periodEndMs: end.millisecondsSinceEpoch,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}
