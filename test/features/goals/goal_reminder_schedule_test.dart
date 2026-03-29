import 'package:coach_for_life/features/goals/application/goal_reminder_schedule.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:flutter_test/flutter_test.dart';

UserGoal _goal({
  required int startMs,
  required int endMs,
  bool reminderEnabled = true,
  GoalReminderStyle style = GoalReminderStyle.dailyOnce,
  GoalStatus status = GoalStatus.active,
}) {
  return UserGoal(
    id: 'g1',
    title: 'T',
    categoryId: 'study',
    horizon: GoalHorizon.daily,
    status: status,
    measurementKind: MeasurementKind.minutes,
    targetValue: 1,
    intensity: 3,
    periodStartMs: startMs,
    periodEndMs: endMs,
    reminderEnabled: reminderEnabled,
    reminderMinutesFromMidnight: reminderEnabled ? 120 : null,
    reminderStyle: style,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

void main() {
  test('nextGoalDailyReminderLocal returns first 2:00 after 1:00 same day', () {
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2025, 3, 1, 23, 59, 59, 999);
    final g = _goal(startMs: start.millisecondsSinceEpoch, endMs: end.millisecondsSinceEpoch);
    final now = DateTime(2025, 3, 1, 1, 0);
    final next = nextGoalDailyReminderLocal(goal: g, minutesFromMidnight: 2 * 60, now: now);
    expect(next, DateTime(2025, 3, 1, 2, 0));
  });

  test('nextGoalDailyReminderLocal rolls to next in-period day after todays time passed', () {
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2025, 3, 3, 23, 59, 59, 999);
    final g = _goal(startMs: start.millisecondsSinceEpoch, endMs: end.millisecondsSinceEpoch);
    final now = DateTime(2025, 3, 1, 3, 0);
    final next = nextGoalDailyReminderLocal(goal: g, minutesFromMidnight: 2 * 60, now: now);
    expect(next, DateTime(2025, 3, 2, 2, 0));
  });

  test('goalShouldScheduleDailyReminder false when style not dailyOnce', () {
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2025, 3, 10, 23, 59, 59, 999);
    final g = _goal(
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      style: GoalReminderStyle.tripleNudge,
    );
    expect(goalShouldScheduleDailyReminder(g, DateTime(2025, 3, 2)), isFalse);
  });
}
