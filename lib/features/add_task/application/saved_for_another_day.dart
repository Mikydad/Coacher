import '../../../core/utils/date_keys.dart';

/// The snackbar shown after saving a task whose plan day is not today
/// (Miko, 2026-09-24): a reminder dated tomorrow, or a Plan-Tomorrow slot,
/// files the task under that day, so it never appears in Home's Today's
/// Tasks and read as lost. Names the day and where to find it. Null when
/// the task is for today.
String? savedForAnotherDayMessage({
  required String planDateKey,
  required String todayKey,
}) {
  if (planDateKey == todayKey) return null;
  final day = DateKeys.parseLocalDateKey(planDateKey);
  final today = DateKeys.parseLocalDateKey(todayKey);
  final delta = DateTime(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  final label = switch (delta) {
    1 => 'tomorrow',
    -1 => 'yesterday',
    _ => '${_weekday(day.weekday)} ${day.day} ${_month(day.month)}',
  };
  return 'Saved for $label. Find it in Tasks under "Open on other days".';
}

String _weekday(int w) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

String _month(int m) => const [
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
][m - 1];
