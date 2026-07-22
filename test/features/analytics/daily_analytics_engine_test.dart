import 'package:sidepal/features/analytics/application/daily_analytics_engine.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('daily_analytics_engine', () {
    test('task daily uses linear priority weights', () {
      final out = computeTaskDailyAnalytics(
        dateKey: '2026-05-04',
        tasks: [
          _task(id: 'a', priority: 1, done: true),
          _task(id: 'b', priority: 5, done: false),
        ],
      );
      expect(out.createdCount, 2);
      expect(out.completedCount, 1);
      expect(out.weightedCreated, 6); // P1=5 + P5=1
      expect(out.weightedCompleted, 5);
      expect(out.weightedCompletionRate, closeTo(5 / 6, 0.0001));
    });

    test('goal/habit daily counts goal checkins and habit tasks', () {
      final out = computeGoalHabitDailyAnalytics(
        dateKey: '2026-05-04',
        goalContributions: const [
          GoalDayContribution(weight: 5, fraction: 1.0), // intensity 1, done
          GoalDayContribution(weight: 3, fraction: 0.0), // intensity 3, not
        ],
        habitTasks: [
          _task(id: 'h1', priority: 2, done: true, habitAnchor: true),
          _task(id: 'h2', priority: 5, done: false, habitAnchor: true),
        ],
      );
      expect(out.createdCount, 4);
      expect(out.completedCount, 2);
      expect(out.weightedCreated, 13); // 5 + 3 + 4 + 1
      expect(out.weightedCompleted, 9); // g1 + h1
      expect(out.completionRate, 0.5);
      expect(out.weightedCompletionRate, closeTo(9 / 13, 0.0001));
      expect(out.schemaVersion, 3);
    });

    test('fractional contributions weight the day partially', () {
      final out = computeGoalHabitDailyAnalytics(
        dateKey: '2026-05-04',
        goalContributions: const [
          GoalDayContribution(weight: 4, fraction: 0.75), // 45/60 min
        ],
        habitTasks: const [],
      );
      expect(out.completedCount, 0); // partial is not "completed"
      expect(out.weightedCompletionRate, closeTo(0.75, 0.0001));
    });

    group('computeGoalDayContribution', () {
      test('daily goal is proportional to today (45/60 → 0.75)', () {
        final c = computeGoalDayContribution(
          goal: _goal(id: 'g', intensity: 3, targetValue: 60),
          dateKey: '2026-05-04',
          checkIns: const [
            GoalCheckIn(
              goalId: 'g',
              dateKey: '2026-05-04',
              metCommitment: false,
              value: 45,
              updatedAtMs: 1,
            ),
          ],
        );
        expect(c, isNotNull);
        expect(c!.fraction, closeTo(0.75, 0.0001));
        expect(c.weight, 3);
      });

      test('legacy boolean check-in (null value, met) counts as full', () {
        final c = computeGoalDayContribution(
          goal: _goal(id: 'g', intensity: 1, targetValue: 60),
          dateKey: '2026-05-04',
          checkIns: const [
            GoalCheckIn(
              goalId: 'g',
              dateKey: '2026-05-04',
              metCommitment: true,
              updatedAtMs: 1,
            ),
          ],
        );
        expect(c!.fraction, 1.0);
      });

      test('weekly goal on an action day: did-anything-today is binary', () {
        // 2026-05-04 is a Monday.
        final goal = _goal(
          id: 'g',
          intensity: 2,
          targetValue: 5,
          cadence: GoalRepeatCadence.weekly,
          scheduledWeekdays: const [DateTime.monday],
        );
        final logged = computeGoalDayContribution(
          goal: goal,
          dateKey: '2026-05-04',
          checkIns: const [
            GoalCheckIn(
              goalId: 'g',
              dateKey: '2026-05-04',
              metCommitment: false,
              value: 1, // 1 of 5 — but showed up today
              updatedAtMs: 1,
            ),
          ],
        );
        expect(logged!.fraction, 1.0);

        final silent = computeGoalDayContribution(
          goal: goal,
          dateKey: '2026-05-04',
          checkIns: const [],
        );
        expect(silent!.fraction, 0.0);
      });

      test('weekly goal off its action day is excluded (null)', () {
        final goal = _goal(
          id: 'g',
          intensity: 2,
          targetValue: 5,
          cadence: GoalRepeatCadence.weekly,
          scheduledWeekdays: const [DateTime.tuesday],
        );
        final c = computeGoalDayContribution(
          goal: goal,
          dateKey: '2026-05-04', // a Monday
          checkIns: const [],
        );
        expect(c, isNull);
      });

      test('passive (repeat-off) goal contributes overall period progress',
          () {
        final goal = _goal(
          id: 'g',
          intensity: 3,
          targetValue: 20,
          cadence: GoalRepeatCadence.off,
        );
        final c = computeGoalDayContribution(
          goal: goal,
          dateKey: '2026-05-04',
          checkIns: const [
            GoalCheckIn(
              goalId: 'g',
              dateKey: '2026-05-02',
              metCommitment: false,
              value: 6,
              updatedAtMs: 1,
            ),
            GoalCheckIn(
              goalId: 'g',
              dateKey: '2026-05-04',
              metCommitment: false,
              value: 4,
              updatedAtMs: 1,
            ),
          ],
        );
        expect(c!.fraction, closeTo(0.5, 0.0001)); // 10 of 20
      });

      test('fraction clamps at 1.0 when over target', () {
        final c = computeGoalDayContribution(
          goal: _goal(id: 'g', intensity: 1, targetValue: 30),
          dateKey: '2026-05-04',
          checkIns: const [
            GoalCheckIn(
              goalId: 'g',
              dateKey: '2026-05-04',
              metCommitment: true,
              value: 90,
              updatedAtMs: 1,
            ),
          ],
        );
        expect(c!.fraction, 1.0);
      });
    });

    test('rollup computes streak from full-completion days', () {
      final now = DateTime(2026, 5, 4);
      final out = rollupDailyAnalytics(
        snapshots: const [
          DailyAnalyticsSnapshot(
            dateKey: '2026-05-01',
            createdCount: 1,
            completedCount: 1,
            weightedCreated: 1,
            weightedCompleted: 1,
            completionRate: 1,
            weightedCompletionRate: 1,
            schemaVersion: 2,
          ),
          DailyAnalyticsSnapshot(
            dateKey: '2026-05-02',
            createdCount: 1,
            completedCount: 1,
            weightedCreated: 1,
            weightedCompleted: 1,
            completionRate: 1,
            weightedCompletionRate: 1,
            schemaVersion: 2,
          ),
          DailyAnalyticsSnapshot(
            dateKey: '2026-05-03',
            createdCount: 1,
            completedCount: 0,
            weightedCreated: 1,
            weightedCompleted: 0,
            completionRate: 0,
            weightedCompletionRate: 0,
            schemaVersion: 2,
          ),
          DailyAnalyticsSnapshot(
            dateKey: '2026-05-04',
            createdCount: 1,
            completedCount: 1,
            weightedCreated: 1,
            weightedCompleted: 1,
            completionRate: 1,
            weightedCompletionRate: 1,
            schemaVersion: 2,
          ),
        ],
        now: now,
      );
      expect(out.bestStreakDays, 2);
      expect(out.currentStreakDays, 1);
    });
  });
}

UserGoal _goal({
  required String id,
  required int intensity,
  double targetValue = 1,
  GoalRepeatCadence cadence = GoalRepeatCadence.daily,
  List<int>? scheduledWeekdays,
}) {
  return UserGoal(
    id: id,
    title: id,
    categoryId: 'habits',
    repeatCadence: cadence,
    scheduledWeekdays: scheduledWeekdays,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.sessions,
    targetValue: targetValue,
    intensity: intensity,
    periodStartMs: DateTime(2026, 5, 1).millisecondsSinceEpoch,
    periodEndMs: DateTime(2026, 5, 31).millisecondsSinceEpoch,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

PlannedTask _task({
  required String id,
  required int priority,
  required bool done,
  bool habitAnchor = false,
}) {
  return PlannedTask(
    id: id,
    routineId: 'r',
    blockId: 'b',
    title: id,
    durationMinutes: 25,
    priority: priority,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: done ? TaskStatus.completed : TaskStatus.notStarted,
    createdAtMs: 0,
    updatedAtMs: 0,
    isHabitAnchor: habitAnchor,
  );
}
