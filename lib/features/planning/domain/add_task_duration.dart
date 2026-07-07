import 'sleep_task.dart';

/// Chip key when duration is not a preset (15m–1h or sleep).
const String kAddTaskCustomDurationKey = 'CUSTOM';

/// Stored on [PlannedTask.durationMinutes] when the user turns duration off.
const int kReminderOnlyDurationMinutes = 0;

bool taskHasFocusDuration(int durationMinutes) => durationMinutes >= 1;

const List<String> standardDurationChipKeys = [
  '15 MIN',
  '25 MIN',
  '45 MIN',
  '1 HOUR',
  kAddTaskCustomDurationKey,
];

const List<String> standardDurationChipLabels = [
  '15m',
  '25m',
  '45m',
  '1h',
  'Custom',
];

/// Short label for duration chips (e.g. `90m`, `2h`, `1h 30m`).
String formatAddTaskDurationChipLabel(int minutes) {
  if (minutes < 1) return '1m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${minutes}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Maps minutes back to the closest Add Task chip label.
String durationLabelFromMinutes(int minutes, {String? category}) {
  if (minutes < 1) return kAddTaskCustomDurationKey;
  if (isSleepCategory(category)) {
    if (minutes == 6 * 60) return '6 HOURS';
    if (minutes == 7 * 60) return '7 HOURS';
    if (minutes == 8 * 60) return '8 HOURS';
    return kAddTaskCustomDurationKey;
  }
  if (minutes == 15) return '15 MIN';
  if (minutes == 25) return '25 MIN';
  if (minutes == 45) return '45 MIN';
  if (minutes == 60) return '1 HOUR';
  return kAddTaskCustomDurationKey;
}

/// Maps Add Task screen duration chip labels to minutes.
int addTaskDurationMinutes(
  String label, {
  int customMinutes = kAddTaskDefaultCustomMinutes,
}) {
  switch (label.trim().toUpperCase()) {
    case '6 HOURS':
      return 6 * 60;
    case '7 HOURS':
      return 7 * 60;
    case '8 HOURS':
      return 8 * 60;
    case '15 MIN':
      return 15;
    case '25 MIN':
      return 25;
    case '45 MIN':
      return 45;
    case '1 HOUR':
      return 60;
    case 'CUSTOM':
      return customMinutes.clamp(
        kAddTaskMinCustomMinutes,
        kAddTaskMaxCustomMinutes,
      );
    default:
      return 25;
  }
}

const int kAddTaskMinCustomMinutes = 1;
const int kAddTaskMaxCustomMinutes = 12 * 60;

/// Default when opening the custom duration picker (0h 30m).
const int kAddTaskDefaultCustomMinutes = 30;

bool isCustomDurationKey(String label) =>
    label.trim().toUpperCase() == kAddTaskCustomDurationKey;
