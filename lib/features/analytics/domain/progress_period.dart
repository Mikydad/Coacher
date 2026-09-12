/// Progress periods — day / ISO week / month / quarter / year, local time.
///
/// One calendar bucket for the Progress page's period browser. Boundaries
/// are LOCAL calendar days built with the `DateTime(y, m, d ± n)` form so
/// DST never shifts a midnight; weeks are ISO (Monday → Sunday), matching
/// `WeekPeriods` (Time tracker) and `DateKeys.isoWeekKey`; quarter and year
/// buckets match `DirectionPeriods` keys (`2026-Q3`, `2026`).
///
/// Pure Dart: no Flutter, no Isar, no clock of its own (callers pass `now`).
library;

import '../../../core/utils/date_keys.dart';

enum ProgressHorizon { day, week, month, quarter, year }

const List<String> _shortMonths = [
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

const List<String> _longMonths = [
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

const List<String> _shortWeekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

class ProgressPeriod {
  const ProgressPeriod._({
    required this.horizon,
    required this.key,
    required this.start,
    required this.end,
    required this.label,
  });

  final ProgressHorizon horizon;

  /// `2026-09-12` | `2026-W37` | `2026-09` | `2026-Q3` | `2026`.
  final String key;

  /// Local midnight of the first day (inclusive).
  final DateTime start;

  /// Local midnight of the LAST day (inclusive).
  final DateTime end;

  /// Human label: `Sat, 12 Sep` | `8 – 14 Sep` | `September 2026` |
  /// `Q3 2026` | `2026`.
  final String label;

  String get startDateKey => DateKeys.yyyymmdd(start);
  String get endDateKey => DateKeys.yyyymmdd(end);

  int get dayCount => _daysBetween(start, end) + 1;

  /// Every `yyyy-MM-dd` in the period, first → last.
  List<String> get dateKeys => [
    for (var i = 0; i < dayCount; i++)
      DateKeys.yyyymmdd(DateTime(start.year, start.month, start.day + i)),
  ];

  bool contains(String dateKey) =>
      dateKey.compareTo(startDateKey) >= 0 && dateKey.compareTo(endDateKey) <= 0;

  bool isCurrent([DateTime? now]) => contains(DateKeys.todayKey(now));

  bool startsAfterToday([DateTime? now]) =>
      startDateKey.compareTo(DateKeys.todayKey(now)) > 0;

  /// Small-caps scope line for period-level cards, so a week total is
  /// never mistaken for the open day: `TODAY` | `SAT, 12 SEP` |
  /// `THIS WEEK · 7 – 13 SEP` | `WEEK · 31 AUG – 6 SEP` |
  /// `THIS MONTH · SEPTEMBER 2026` | `AUGUST 2026` | `Q3 2026` | `2026`.
  String scopeLabel([DateTime? now]) {
    final current = isCurrent(now);
    final upper = label.toUpperCase();
    return switch (horizon) {
      ProgressHorizon.day => current ? 'TODAY' : upper,
      ProgressHorizon.week => current ? 'THIS WEEK · $upper' : 'WEEK · $upper',
      ProgressHorizon.month => current ? 'THIS MONTH · $upper' : upper,
      ProgressHorizon.quarter => current ? 'THIS QUARTER · $upper' : upper,
      ProgressHorizon.year => current ? 'THIS YEAR · $upper' : upper,
    };
  }

  ProgressPeriod get previous => switch (horizon) {
    ProgressHorizon.day => forDate(
      horizon,
      DateTime(start.year, start.month, start.day - 1),
    ),
    ProgressHorizon.week => forDate(
      horizon,
      DateTime(start.year, start.month, start.day - 7),
    ),
    ProgressHorizon.month => forDate(
      horizon,
      DateTime(start.year, start.month - 1, 1),
    ),
    ProgressHorizon.quarter => forDate(
      horizon,
      DateTime(start.year, start.month - 3, 1),
    ),
    ProgressHorizon.year => forDate(horizon, DateTime(start.year - 1, 1, 1)),
  };

  ProgressPeriod get next => forDate(
    horizon,
    DateTime(end.year, end.month, end.day + 1),
  );

  static ProgressPeriod current(ProgressHorizon horizon, [DateTime? now]) =>
      forDate(horizon, now ?? DateTime.now());

  /// The period of [horizon] containing local calendar day [t].
  static ProgressPeriod forDate(ProgressHorizon horizon, DateTime t) {
    final day = DateTime(t.year, t.month, t.day);
    switch (horizon) {
      case ProgressHorizon.day:
        return ProgressPeriod._(
          horizon: horizon,
          key: DateKeys.yyyymmdd(day),
          start: day,
          end: day,
          label:
              '${_shortWeekdays[day.weekday - 1]}, ${day.day} '
              '${_shortMonths[day.month - 1]}',
        );
      case ProgressHorizon.week:
        final monday = DateTime(
          day.year,
          day.month,
          day.day - (day.weekday - 1),
        );
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        return ProgressPeriod._(
          horizon: horizon,
          key: DateKeys.isoWeekKey(monday),
          start: monday,
          end: sunday,
          label: _rangeLabel(monday, sunday),
        );
      case ProgressHorizon.month:
        final first = DateTime(day.year, day.month, 1);
        final last = DateTime(day.year, day.month + 1, 0);
        return ProgressPeriod._(
          horizon: horizon,
          key: '${day.year}-${day.month.toString().padLeft(2, '0')}',
          start: first,
          end: last,
          label: '${_longMonths[day.month - 1]} ${day.year}',
        );
      case ProgressHorizon.quarter:
        final q = ((day.month - 1) ~/ 3) + 1;
        final firstMonth = (q - 1) * 3 + 1;
        final first = DateTime(day.year, firstMonth, 1);
        final last = DateTime(day.year, firstMonth + 3, 0);
        return ProgressPeriod._(
          horizon: horizon,
          key: '${day.year}-Q$q',
          start: first,
          end: last,
          label: 'Q$q ${day.year}',
        );
      case ProgressHorizon.year:
        return ProgressPeriod._(
          horizon: horizon,
          key: '${day.year}',
          start: DateTime(day.year, 1, 1),
          end: DateTime(day.year, 12, 31),
          label: '${day.year}',
        );
    }
  }

  /// `8 – 14 Sep` | `28 Sep – 4 Oct` | `29 Dec 2025 – 4 Jan 2026`.
  static String _rangeLabel(DateTime a, DateTime b) {
    if (a.year != b.year) {
      return '${a.day} ${_shortMonths[a.month - 1]} ${a.year} – '
          '${b.day} ${_shortMonths[b.month - 1]} ${b.year}';
    }
    if (a.month != b.month) {
      return '${a.day} ${_shortMonths[a.month - 1]} – '
          '${b.day} ${_shortMonths[b.month - 1]}';
    }
    return '${a.day} – ${b.day} ${_shortMonths[a.month - 1]}';
  }

  static int _daysBetween(DateTime a, DateTime b) {
    // UTC arithmetic so a DST transition inside the range can't round the
    // day count down.
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressPeriod && other.horizon == horizon && other.key == key;

  @override
  int get hashCode => Object.hash(horizon, key);

  @override
  String toString() => 'ProgressPeriod(${horizon.name} $key)';
}
