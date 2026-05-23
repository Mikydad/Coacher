import '../domain/models/task_item.dart';

/// Local scheduled time for [task] when [reminderTimeIso] falls on today's calendar day.
DateTime? taskScheduledTimeLocalToday(PlannedTask task, [DateTime? now]) {
  final iso = task.reminderTimeIso;
  if (iso == null || iso.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return null;
  final base = now ?? DateTime.now();
  if (parsed.year != base.year ||
      parsed.month != base.month ||
      parsed.day != base.day) {
    return null;
  }
  return parsed;
}

String formatTaskTimeOfDay(DateTime dt) {
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$hour:$m $period';
}

/// e.g. `9:30 AM`, or null when the task has no time scheduled for today.
String? taskScheduledTimeLabel(PlannedTask task, [DateTime? now]) {
  final dt = taskScheduledTimeLocalToday(task, now);
  if (dt == null) return null;
  return formatTaskTimeOfDay(dt);
}
