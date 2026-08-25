/// Human phrasing for calendar days (2026-08-25): people say "Sunday",
/// not "2026-08-30" — the app-wide formatter every user-facing surface
/// (AI plan cards, confirmations, voice) should reach for instead of
/// echoing a raw date key.
library;

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _shortMonths = [
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

/// - today / tomorrow / yesterday
/// - a bare weekday name for the next six days ("Sunday")
/// - "Mon, Sep 1" beyond that (with the year when it differs)
String friendlyDate(DateTime date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(ref.year, ref.month, ref.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff == -1) return 'yesterday';
  if (diff >= 2 && diff <= 6) return _weekdays[day.weekday - 1];
  final base =
      '${_shortWeekdays[day.weekday - 1]}, '
      '${_shortMonths[day.month - 1]} ${day.day}';
  return day.year == today.year ? base : '$base, ${day.year}';
}

/// [friendlyDate] over a `yyyy-MM-dd` date key; anything unparseable
/// (already-friendly words like "today", or malformed input) passes
/// through unchanged.
String friendlyDateKey(String dateKey, {DateTime? now}) {
  final parsed = DateTime.tryParse(dateKey.trim());
  if (parsed == null) return dateKey;
  return friendlyDate(parsed, now: now);
}
