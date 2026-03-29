import '../../../core/utils/date_keys.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';

/// Local-time calendar math for goal periods (`tasks-prd-goals.md` 1.6).
abstract final class GoalPeriodHelpers {
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// First instant of [year]-[month] through last ms of that calendar month (local).
  static ({int startMs, int endMs}) localCalendarMonthBounds(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return (startMs: start.millisecondsSinceEpoch, endMs: end.millisecondsSinceEpoch);
  }

  /// Inclusive local calendar days from [startDay] 00:00 to [endDay] 23:59:59.999.
  static ({int startMs, int endMs}) localDayRangeBounds(DateTime startDay, DateTime endDay) {
    final s = DateTime(startDay.year, startDay.month, startDay.day);
    final e = DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59, 999);
    return (startMs: s.millisecondsSinceEpoch, endMs: e.millisecondsSinceEpoch);
  }

  /// [dayCount] inclusive calendar days from [startDay] (e.g. 30 → start through start+29).
  static ({int startMs, int endMs}) localDurationDayCount(DateTime startDay, int dayCount) {
    if (dayCount < 1) {
      throw ArgumentError.value(dayCount, 'dayCount', 'must be >= 1');
    }
    final s = DateTime(startDay.year, startDay.month, startDay.day);
    final endCal = s.add(Duration(days: dayCount - 1));
    final e = DateTime(endCal.year, endCal.month, endCal.day, 23, 59, 59, 999);
    return (startMs: s.millisecondsSinceEpoch, endMs: e.millisecondsSinceEpoch);
  }

  static bool isDateKeyInPeriod(UserGoal goal, String dateKey) {
    final d = DateKeys.parseLocalDateKey(dateKey);
    final dd = _dateOnly(d);
    final ds = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs));
    final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    return !dd.isBefore(ds) && !dd.isAfter(de);
  }

  /// Inclusive count of calendar days from period start through period end.
  static int totalCalendarDaysInPeriod(UserGoal goal) {
    final s = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs));
    final e = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    return e.difference(s).inDays + 1;
  }

  /// Days from period start through `now` (capped by period end), inclusive.
  /// Returns `0` if [now] is before the period starts.
  static int daysElapsedInPeriodThrough(UserGoal goal, DateTime now) {
    final today = _dateOnly(now);
    final ds = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs));
    final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    if (today.isBefore(ds)) return 0;
    final effectiveEnd = today.isAfter(de) ? de : today;
    return effectiveEnd.difference(ds).inDays + 1;
  }

  static int countMetCheckIns(List<GoalCheckIn> checkIns) {
    return checkIns.where((c) => c.metCommitment).length;
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatPeriodSummary(UserGoal goal) {
    final s = DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs);
    final e = DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs);
    if (goal.periodMode == GoalPeriodMode.durationDays && goal.durationDays != null) {
      return '${goal.durationDays} days · from ${_months[s.month - 1]} ${s.day}, ${s.year}';
    }
    if (goal.horizon == GoalHorizon.monthly) {
      return '${_months[s.month - 1]} ${s.year}';
    }
    return '${_months[s.month - 1]} ${s.day}, ${s.year} – ${_months[e.month - 1]} ${e.day}, ${e.year}';
  }
}
