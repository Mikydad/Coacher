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
}
