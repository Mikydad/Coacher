import 'package:sidepal/features/goals/application/goal_reminder_schedule.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:flutter_test/flutter_test.dart';

UserGoal _goal({
  required int startMs,
  required int endMs,
  bool reminderEnabled = true,
  GoalReminderStyle style = GoalReminderStyle.dailyOnce,
  GoalStatus status = GoalStatus.active,
  GoalRepeatCadence? repeatCadence,
  int repeatInterval = 1,
  List<int>? scheduledWeekdays,
}) {
  return UserGoal(
    id: 'g1',
    title: 'T',
    categoryId: 'study',
    status: status,
    measurementKind: MeasurementKind.minutes,
    targetValue: 1,
    intensity: 3,
    periodStartMs: startMs,
    periodEndMs: endMs,
    repeatCadence:
        repeatCadence ??
        (scheduledWeekdays != null
            ? GoalRepeatCadence.weekly
            : GoalRepeatCadence.daily),
    repeatInterval: repeatInterval,
    scheduledWeekdays: scheduledWeekdays,
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

  test('nextGoalActionDayReminderLocal skips non-action days', () {
    // 2025-03-01 is a Saturday; goal repeats weekly on Mon/Wed/Fri.
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2025, 3, 31, 23, 59, 59, 999);
    final g = _goal(
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      scheduledWeekdays: const [
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ],
    );
    final now = DateTime(2025, 3, 1, 1, 0);
    final next = nextGoalActionDayReminderLocal(
      goal: g,
      minutesFromMidnight: 2 * 60,
      now: now,
    );
    // First Monday in period is 2025-03-03.
    expect(next, DateTime(2025, 3, 3, 2, 0));
  });

  test('nextGoalActionDayReminderLocal honors every-2-days interval', () {
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2025, 3, 31, 23, 59, 59, 999);
    final g = _goal(
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      repeatCadence: GoalRepeatCadence.daily,
      repeatInterval: 2,
    );
    // Action days: Mar 1, 3, 5... After Mar 1's slot passed → Mar 3.
    final next = nextGoalActionDayReminderLocal(
      goal: g,
      minutesFromMidnight: 2 * 60,
      now: DateTime(2025, 3, 1, 3, 0),
    );
    expect(next, DateTime(2025, 3, 3, 2, 0));
  });

  test('goalShouldScheduleDailyReminder false when repeat is off', () {
    final start = DateTime(2025, 3, 1);
    final end = DateTime(2025, 3, 10, 23, 59, 59, 999);
    final g = _goal(
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      repeatCadence: GoalRepeatCadence.off,
    );
    expect(goalShouldScheduleDailyReminder(g, DateTime(2025, 3, 2)), isFalse);
  });

  test('nextGoalWeekdayReminderLocal finds the next matching weekday', () {
    final start = DateTime(2025, 3, 1); // Saturday
    final end = DateTime(2025, 3, 31, 23, 59, 59, 999);
    final g = _goal(
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      scheduledWeekdays: const [DateTime.wednesday],
    );
    final next = nextGoalWeekdayReminderLocal(
      goal: g,
      weekday: DateTime.wednesday,
      minutesFromMidnight: 9 * 60,
      now: DateTime(2025, 3, 1, 1, 0),
    );
    expect(next, DateTime(2025, 3, 5, 9, 0));
  });

  test('nextGoalWeekdayReminderLocal null when weekday never occurs in period', () {
    final start = DateTime(2025, 3, 1); // Sat
    final end = DateTime(2025, 3, 2, 23, 59, 59, 999); // Sun
    final g = _goal(
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      scheduledWeekdays: const [DateTime.monday],
    );
    final next = nextGoalWeekdayReminderLocal(
      goal: g,
      weekday: DateTime.monday,
      minutesFromMidnight: 9 * 60,
      now: DateTime(2025, 3, 1, 1, 0),
    );
    expect(next, isNull);
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
