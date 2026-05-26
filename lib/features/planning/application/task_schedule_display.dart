import '../domain/models/task_item.dart';
import '../domain/sleep_task.dart';

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

DateTime? taskSleepEndLocal(PlannedTask task, [DateTime? now]) {
  final start = taskScheduledTimeLocalToday(task, now);
  if (start == null) return null;
  return start.add(Duration(minutes: task.durationMinutes));
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

/// For sleep tasks: `10:00 PM – 6:00 AM`. For others: start time only.
String? taskScheduledTimeLabelForDisplay(PlannedTask task, [DateTime? now]) {
  if (!isSleepTask(task)) return taskScheduledTimeLabel(task, now);
  return taskScheduledSleepRangeLabel(task, now);
}

/// e.g. `10:00 PM – 6:00 AM` when [task] has a start time today.
String? taskScheduledSleepRangeLabel(PlannedTask task, [DateTime? now]) {
  final start = taskScheduledTimeLocalToday(task, now);
  if (start == null) return null;
  final end = taskSleepEndLocal(task, now);
  if (end == null) return formatTaskTimeOfDay(start);
  return '${formatTaskTimeOfDay(start)} – ${formatTaskTimeOfDay(end)}';
}

/// Sleep range from explicit start + duration (Add Task preview).
String formatSleepRangeLabel({
  required DateTime start,
  required int durationMinutes,
}) {
  final end = start.add(Duration(minutes: durationMinutes));
  return '${formatTaskTimeOfDay(start)} – ${formatTaskTimeOfDay(end)}';
}
