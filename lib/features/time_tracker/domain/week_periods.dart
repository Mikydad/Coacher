import '../../../core/utils/date_keys.dart';

/// ISO weeks (Monday–Sunday), local calendar, for the Time page's Week view.
class WeekPeriod {
  const WeekPeriod({
    required this.key,
    required this.startMs,
    required this.endMs,
    required this.dayKeys,
  });

  /// `'2026-W37'` (ISO), see [DateKeys.isoWeekKey].
  final String key;

  /// Local midnight Monday.
  final int startMs;

  /// Local midnight of the NEXT Monday (exclusive).
  final int endMs;

  /// The seven `yyyy-MM-dd` keys, Monday first.
  final List<String> dayKeys;

  DateTime get start => DateTime.fromMillisecondsSinceEpoch(startMs);
  DateTime get lastDay => DateTime.fromMillisecondsSinceEpoch(endMs)
      .subtract(const Duration(days: 1));

  bool contains(DateTime t) {
    final ms = t.millisecondsSinceEpoch;
    return ms >= startMs && ms < endMs;
  }
}

abstract final class WeekPeriods {
  static WeekPeriod of(DateTime t) {
    final day = DateTime(t.year, t.month, t.day);
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    final next = DateTime(monday.year, monday.month, monday.day + 7);
    return WeekPeriod(
      key: DateKeys.isoWeekKey(monday),
      startMs: monday.millisecondsSinceEpoch,
      endMs: next.millisecondsSinceEpoch,
      dayKeys: [
        for (var i = 0; i < 7; i++)
          DateKeys.yyyymmdd(DateTime(monday.year, monday.month, monday.day + i)),
      ],
    );
  }

  static WeekPeriod previous(WeekPeriod w) =>
      of(DateTime.fromMillisecondsSinceEpoch(w.startMs - 1));

  static WeekPeriod next(WeekPeriod w) =>
      of(DateTime.fromMillisecondsSinceEpoch(w.endMs));

  /// The local calendar month containing [t] as `[startMs, endMs)`.
  static ({int startMs, int endMs, String key, String label}) monthOf(DateTime t) {
    final start = DateTime(t.year, t.month, 1);
    final end = DateTime(t.year, t.month + 1, 1);
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return (
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
      key: '${t.year}-${t.month.toString().padLeft(2, '0')}',
      label: names[t.month - 1],
    );
  }
}
