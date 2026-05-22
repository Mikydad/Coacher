class DateKeys {
  const DateKeys._();

  static String yyyymmdd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Calendar date for "today" in local time (aligned with home + add-task day plan).
  static String todayKey([DateTime? now]) {
    final base = now ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day);
    return yyyymmdd(day);
  }

  static String tomorrowKey([DateTime? now]) {
    final base = now ?? DateTime.now();
    final tmr = DateTime(base.year, base.month, base.day).add(const Duration(days: 1));
    return yyyymmdd(tmr);
  }

  /// Returns ISO week key: `'yyyy-Www'` (e.g. `'2026-W21'`).
  ///
  /// Uses the ISO 8601 week numbering: week 1 is the week containing the first
  /// Thursday of the year. Monday is the start of the week.
  static String isoWeekKey(DateTime date) {
    // Shift to nearest Thursday to find the ISO year.
    final thursday =
        date.add(Duration(days: DateTime.thursday - date.weekday));
    final year = thursday.year;
    // Week 1 starts on the Monday of the week containing Jan 4.
    final jan4 = DateTime(year, 1, 4);
    final week1Monday =
        jan4.subtract(Duration(days: jan4.weekday - DateTime.monday));
    final weekNumber =
        ((date.difference(week1Monday).inDays) ~/ 7) + 1;
    return '$year-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Parses [yyyymmdd] output (`yyyy-MM-dd`) as a **local** calendar date at midnight.
  static DateTime parseLocalDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected yyyy-MM-dd, got: $key');
    }
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d);
  }
}
