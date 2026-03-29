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

bool goalShouldScheduleDailyReminder(UserGoal goal, DateTime now) {
  if (goal.status != GoalStatus.active) return false;
  if (!goal.reminderEnabled || goal.reminderMinutesFromMidnight == null) return false;
  if (goal.reminderStyle != GoalReminderStyle.dailyOnce) return false;
  final end = DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs);
  if (now.isAfter(end)) return false;
  return true;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
