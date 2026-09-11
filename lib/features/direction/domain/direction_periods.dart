/// Direction periods — calendar year / quarter / month, local time.
///
/// Direction is not something SidePal asks the user to accomplish. It is
/// something SidePal remembers while helping them. Periods are plain
/// calendar buckets (decision 1, 2026-09-11): `2026`, `2026-Q3`, `2026-09` —
/// never "three months from when I wrote it".
///
/// Pure Dart: no Flutter, no Isar, no clocks of its own (callers pass `now`).
library;

enum DirectionHorizon { year, quarter, month }

DirectionHorizon? directionHorizonFromStorage(String? raw) {
  for (final v in DirectionHorizon.values) {
    if (v.name == raw) return v;
  }
  return null;
}

/// One calendar bucket for one horizon. [endMs] is exclusive (local midnight
/// of the next period's first day), so `startMs <= t < endMs` is membership.
class DirectionPeriod {
  const DirectionPeriod({
    required this.horizon,
    required this.key,
    required this.startMs,
    required this.endMs,
    required this.label,
  });

  final DirectionHorizon horizon;

  /// `'2026'` | `'2026-Q3'` | `'2026-09'`. Sorts lexicographically within a
  /// horizon (zero-padded month).
  final String key;

  /// Local midnight of the first day.
  final int startMs;

  /// Local midnight of the first day of the NEXT period (exclusive).
  final int endMs;

  /// Human label: `'2026'` | `'Q3 2026'` | `'September'`.
  final String label;

  bool contains(DateTime t) {
    final ms = t.millisecondsSinceEpoch;
    return ms >= startMs && ms < endMs;
  }

  @override
  bool operator ==(Object other) =>
      other is DirectionPeriod && other.horizon == horizon && other.key == key;

  @override
  int get hashCode => Object.hash(horizon, key);

  @override
  String toString() => 'DirectionPeriod($key)';
}

const List<String> kDirectionMonthNames = [
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

class DirectionPeriods {
  const DirectionPeriods._();

  static final RegExp _yearKey = RegExp(r'^(\d{4})$');
  static final RegExp _quarterKey = RegExp(r'^(\d{4})-Q([1-4])$');
  static final RegExp _monthKey = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$');

  /// The period containing [now] for [horizon]. All boundaries are LOCAL
  /// calendar (`DateTime(y, m, 1)`), matching `localCalendarMonthBounds` in
  /// goals — never UTC (a user at UTC−7 on Sep 30 22:00 is still in
  /// September).
  static DirectionPeriod current(DirectionHorizon horizon, DateTime now) {
    switch (horizon) {
      case DirectionHorizon.year:
        return _year(now.year);
      case DirectionHorizon.quarter:
        return _quarter(now.year, ((now.month - 1) ~/ 3) + 1);
      case DirectionHorizon.month:
        return _month(now.year, now.month);
    }
  }

  static String keyFor(DirectionHorizon horizon, DateTime now) =>
      current(horizon, now).key;

  /// The period immediately before [period]; crosses year boundaries
  /// (`2026-01` → `2025-12`, `2026-Q1` → `2025-Q4`, `2026` → `2025`).
  static DirectionPeriod previous(DirectionPeriod period) {
    // The last instant of the previous period is one ms before this one
    // starts; resolving its calendar bucket is the boundary-safe way.
    final beforeStart = DateTime.fromMillisecondsSinceEpoch(
      period.startMs - 1,
    );
    return current(period.horizon, beforeStart);
  }

  /// Inverse of [DirectionPeriod.key]; null for anything malformed.
  static DirectionPeriod? parseKey(String key) {
    final y = _yearKey.firstMatch(key);
    if (y != null) return _year(int.parse(y.group(1)!));
    final q = _quarterKey.firstMatch(key);
    if (q != null) {
      return _quarter(int.parse(q.group(1)!), int.parse(q.group(2)!));
    }
    final m = _monthKey.firstMatch(key);
    if (m != null) {
      return _month(int.parse(m.group(1)!), int.parse(m.group(2)!));
    }
    return null;
  }

  static DirectionPeriod _year(int year) => DirectionPeriod(
    horizon: DirectionHorizon.year,
    key: '$year',
    startMs: DateTime(year, 1, 1).millisecondsSinceEpoch,
    endMs: DateTime(year + 1, 1, 1).millisecondsSinceEpoch,
    label: '$year',
  );

  static DirectionPeriod _quarter(int year, int quarter) {
    final firstMonth = (quarter - 1) * 3 + 1;
    return DirectionPeriod(
      horizon: DirectionHorizon.quarter,
      key: '$year-Q$quarter',
      startMs: DateTime(year, firstMonth, 1).millisecondsSinceEpoch,
      // DateTime normalises month 13+ into the next year.
      endMs: DateTime(year, firstMonth + 3, 1).millisecondsSinceEpoch,
      label: 'Q$quarter $year',
    );
  }

  static DirectionPeriod _month(int year, int month) => DirectionPeriod(
    horizon: DirectionHorizon.month,
    key: '$year-${month.toString().padLeft(2, '0')}',
    startMs: DateTime(year, month, 1).millisecondsSinceEpoch,
    endMs: DateTime(year, month + 1, 1).millisecondsSinceEpoch,
    label: kDirectionMonthNames[month - 1],
  );
}
