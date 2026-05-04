import 'package:coach_for_life/features/analytics/application/daily_analytics_engine.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_check_in.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
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
        goals: [
          _goal(id: 'g1', intensity: 1),
          _goal(id: 'g2', intensity: 3),
        ],
        checkIns: [
          const GoalCheckIn(
            goalId: 'g1',
            dateKey: '2026-05-04',
            metCommitment: true,
            updatedAtMs: 1,
          ),
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

UserGoal _goal({required String id, required int intensity}) {
  return UserGoal(
    id: id,
    title: id,
    categoryId: 'habits',
    horizon: GoalHorizon.daily,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.sessions,
    targetValue: 1,
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
