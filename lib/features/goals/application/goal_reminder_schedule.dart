import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';

/// Next wall-clock reminder inside the goal’s inclusive local period, if any (local [DateTime]).
DateTime? nextGoalDailyReminderLocal({
  required UserGoal goal,
  required int minutesFromMidnight,
  required DateTime now,
}) {
  final h = minutesFromMidnight ~/ 60;
  final m = minutesFromMidnight % 60;
  final ds = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs));
  final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
  var day = _dateOnly(now);
  if (day.isBefore(ds)) day = ds;
  while (!day.isAfter(de)) {
    final fire = DateTime(day.year, day.month, day.day, h, m);
    if (fire.isAfter(now)) return fire;
    day = day.add(const Duration(days: 1));
  }
  return null;
}

/// Next fire on any of the goal's **action days** inside the period, or null.
/// Used for interval repeats (every 2 days/weeks/…) where the OS can't
/// auto-repeat — the app schedules one shot at a time and rolls it forward.
DateTime? nextGoalActionDayReminderLocal({
  required UserGoal goal,
  required int minutesFromMidnight,
  required DateTime now,
}) {
  final h = minutesFromMidnight ~/ 60;
  final m = minutesFromMidnight % 60;
  final ds = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs));
  final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
  var day = _dateOnly(now);
  if (day.isBefore(ds)) day = ds;
  while (!day.isAfter(de)) {
    if (goal.isActionDay(day)) {
      final fire = DateTime(day.year, day.month, day.day, h, m);
      if (fire.isAfter(now)) return fire;
    }
    day = day.add(const Duration(days: 1));
  }
  return null;
}

/// The next [count] fires on the goal's **action days** inside its period,
/// soonest first. Returns fewer than [count] (possibly none) when the period
/// ends first.
///
/// FR-R-14 keeps two armed at a time: every re-arm trigger in this app is app
/// activity, so a single armed occurrence means an untouched phone fires one
/// goal reminder and then goes quiet (AUDIT §10 C4).
List<DateTime> nextGoalActionDayReminders({
  required UserGoal goal,
  required int minutesFromMidnight,
  required DateTime now,
  int count = 2,
}) {
  final out = <DateTime>[];
  var cursor = now;
  for (var i = 0; i < count; i++) {
    final next = nextGoalActionDayReminderLocal(
      goal: goal,
      minutesFromMidnight: minutesFromMidnight,
      now: cursor,
    );
    if (next == null) break;
    out.add(next);
    cursor = next;
  }
  return out;
}

/// Next fire on [weekday] (1=Mon…7=Sun) inside the goal's period, or null if
/// that weekday never occurs again before the period ends.
DateTime? nextGoalWeekdayReminderLocal({
  required UserGoal goal,
  required int weekday,
  required int minutesFromMidnight,
  required DateTime now,
}) {
  final h = minutesFromMidnight ~/ 60;
  final m = minutesFromMidnight % 60;
  final ds = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs));
  final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
  var day = _dateOnly(now);
  if (day.isBefore(ds)) day = ds;
  while (!day.isAfter(de)) {
    if (day.weekday == weekday) {
      final fire = DateTime(day.year, day.month, day.day, h, m);
      if (fire.isAfter(now)) return fire;
    }
    day = day.add(const Duration(days: 1));
  }
  return null;
}

bool goalShouldScheduleDailyReminder(UserGoal goal, DateTime now) {
  if (goal.status != GoalStatus.active) return false;
  // Reminders are gated on the repeat schedule: passive goals stay silent.
  if (!goal.hasRepeatSchedule) return false;
  if (!goal.reminderEnabled || goal.reminderMinutesFromMidnight == null) {
    return false;
  }
  if (goal.reminderStyle != GoalReminderStyle.dailyOnce) return false;
  final end = DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs);
  if (now.isAfter(end)) return false;
  return true;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
