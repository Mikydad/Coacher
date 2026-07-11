import '../../../core/utils/date_keys.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';

/// Local-time calendar math for goal periods (`tasks-prd-goals.md` 1.6).
abstract final class GoalPeriodHelpers {
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// First instant of [year]-[month] through last ms of that calendar month (local).
  static ({int startMs, int endMs}) localCalendarMonthBounds(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return (
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
    );
  }

  /// Inclusive local calendar days from [startDay] 00:00 to [endDay] 23:59:59.999.
  static ({int startMs, int endMs}) localDayRangeBounds(
    DateTime startDay,
    DateTime endDay,
  ) {
    final s = DateTime(startDay.year, startDay.month, startDay.day);
    final e = DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59, 999);
    return (startMs: s.millisecondsSinceEpoch, endMs: e.millisecondsSinceEpoch);
  }

  /// [dayCount] inclusive calendar days from [startDay] (e.g. 30 → start through start+29).
  static ({int startMs, int endMs}) localDurationDayCount(
    DateTime startDay,
    int dayCount,
  ) {
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
    final ds = _dateOnly(
      DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs),
    );
    final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    return !dd.isBefore(ds) && !dd.isAfter(de);
  }

  /// In period **and** a planned action day — membership test for Today's
  /// goals and other "act today" surfaces. Always false for repeat-off goals.
  static bool isGoalActiveOnDateKey(UserGoal goal, String dateKey) {
    if (!isDateKeyInPeriod(goal, dateKey)) return false;
    return goal.isActionDay(DateKeys.parseLocalDateKey(dateKey));
  }

  /// Whether progress may be logged on [dateKey]: any period day for passive
  /// (repeat-off) goals, action days only for repeating goals.
  static bool allowsLoggingOnDateKey(UserGoal goal, String dateKey) {
    if (!isDateKeyInPeriod(goal, dateKey)) return false;
    return goal.allowsLoggingOn(DateKeys.parseLocalDateKey(dateKey));
  }

  /// The current evaluation window for progress accumulation: one repeat
  /// cycle (X days / X weeks / X months, anchored at the period start's
  /// day / week / month), or the whole period when repeat is off. Clamped to
  /// the goal period; [now] outside the period clamps to the nearest edge.
  static ({DateTime start, DateTime end}) evaluationWindow(
    UserGoal goal,
    DateTime now,
  ) {
    final ps = _dateOnly(
      DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs),
    );
    final pe = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    var today = _dateOnly(now);
    if (today.isBefore(ps)) today = ps;
    if (today.isAfter(pe)) today = pe;
    final n = goal.repeatInterval < 1 ? 1 : goal.repeatInterval;
    DateTime lo;
    DateTime hi;
    switch (goal.repeatCadence) {
      case GoalRepeatCadence.off:
        lo = ps;
        hi = pe;
      case GoalRepeatCadence.daily:
        final sinceAnchor = today.difference(ps).inDays;
        lo = ps.add(Duration(days: (sinceAnchor ~/ n) * n));
        hi = lo.add(Duration(days: n - 1));
      case GoalRepeatCadence.weekly:
        final anchor = ps.subtract(Duration(days: ps.weekday - 1));
        final thisWeek = today.subtract(Duration(days: today.weekday - 1));
        final weeksSince = thisWeek.difference(anchor).inDays ~/ 7;
        lo = anchor.add(Duration(days: (weeksSince ~/ n) * n * 7));
        hi = lo.add(Duration(days: n * 7 - 1));
      case GoalRepeatCadence.monthly:
        final monthsSince =
            (today.year - ps.year) * 12 + (today.month - ps.month);
        final blockStart = (monthsSince ~/ n) * n;
        lo = DateTime(ps.year, ps.month + blockStart, 1);
        hi = DateTime(ps.year, ps.month + blockStart + n, 0);
    }
    if (lo.isBefore(ps)) lo = ps;
    if (hi.isAfter(pe)) hi = pe;
    return (start: lo, end: hi);
  }

  /// Action days from period start through period end, inclusive.
  /// Calendar days for passive (repeat-off) goals.
  static int totalScheduledDaysInPeriod(UserGoal goal) {
    if (!goal.hasRepeatSchedule) return totalCalendarDaysInPeriod(goal);
    return _countActionDays(
      goal,
      _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs)),
      _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs)),
    );
  }

  /// Action days from period start through `now` (capped by period end),
  /// inclusive. Returns `0` if [now] is before the period starts.
  static int scheduledDaysElapsedThrough(UserGoal goal, DateTime now) {
    if (!goal.hasRepeatSchedule) return daysElapsedInPeriodThrough(goal, now);
    final today = _dateOnly(now);
    final ds = _dateOnly(
      DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs),
    );
    final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    if (today.isBefore(ds)) return 0;
    return _countActionDays(goal, ds, today.isAfter(de) ? de : today);
  }

  static int _countActionDays(UserGoal goal, DateTime from, DateTime to) {
    var count = 0;
    var day = from;
    while (!day.isAfter(to)) {
      if (goal.isActionDay(day)) count++;
      day = day.add(const Duration(days: 1));
    }
    return count;
  }

  static const weekdayShortLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// "Mon · Wed · Fri" (sorted Monday-first). Empty string for no selection.
  static String formatWeekdays(List<int> weekdays) {
    final sorted = weekdays.toSet().toList()..sort();
    return sorted
        .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
        .map((d) => weekdayShortLabels[d - 1])
        .join(' · ');
  }

  /// "1st · 15th · 28th" (sorted). Empty string for no selection.
  static String formatDaysOfMonth(List<int> days) {
    final sorted = days.toSet().toList()..sort();
    return sorted.where((d) => d >= 1 && d <= 31).map(_ordinal).join(' · ');
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  /// One-line summary of the repeat schedule, e.g. "Every week on Mon · Wed",
  /// "Every 2 days", "Monthly on the 1st · 15th". Empty when repeat is off.
  static String formatRepeatSummary(UserGoal goal) {
    final n = goal.repeatInterval;
    switch (goal.repeatCadence) {
      case GoalRepeatCadence.off:
        return '';
      case GoalRepeatCadence.daily:
        return n <= 1 ? 'Every day' : 'Every $n days';
      case GoalRepeatCadence.weekly:
        final days = goal.scheduledWeekdays ?? const [];
        final dayPart = days.isEmpty ? '' : ' on ${formatWeekdays(days)}';
        return n <= 1 ? 'Every week$dayPart' : 'Every $n weeks$dayPart';
      case GoalRepeatCadence.monthly:
        final days = goal.repeatDaysOfMonth ?? const [];
        final dayPart = days.isEmpty
            ? ''
            : ' on the ${formatDaysOfMonth(days)}';
        return n <= 1 ? 'Every month$dayPart' : 'Every $n months$dayPart';
    }
  }

  /// Inclusive count of calendar days from period start through period end.
  static int totalCalendarDaysInPeriod(UserGoal goal) {
    final s = _dateOnly(
      DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs),
    );
    final e = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    return e.difference(s).inDays + 1;
  }

  /// Days from period start through `now` (capped by period end), inclusive.
  /// Returns `0` if [now] is before the period starts.
  static int daysElapsedInPeriodThrough(UserGoal goal, DateTime now) {
    final today = _dateOnly(now);
    final ds = _dateOnly(
      DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs),
    );
    final de = _dateOnly(DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs));
    if (today.isBefore(ds)) return 0;
    final effectiveEnd = today.isAfter(de) ? de : today;
    return effectiveEnd.difference(ds).inDays + 1;
  }

  static int countMetCheckIns(List<GoalCheckIn> checkIns) {
    return checkIns.where((c) => c.metCommitment).length;
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatPeriodSummary(UserGoal goal) {
    final s = DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs);
    final e = DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs);
    if (goal.periodMode == GoalPeriodMode.durationDays &&
        goal.durationDays != null) {
      return '${goal.durationDays} days · from ${_months[s.month - 1]} ${s.day}, ${s.year}';
    }
    return '${_months[s.month - 1]} ${s.day}, ${s.year} – ${_months[e.month - 1]} ${e.day}, ${e.year}';
  }
}
