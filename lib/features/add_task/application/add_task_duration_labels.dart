import '../../planning/domain/add_task_duration.dart';
import '../../planning/domain/sleep_task.dart';

/// Pure duration-chip derivations for the Add Task form. All functions are
/// keyed off the same four form values (category, enabled flag, selected chip
/// key, custom minutes) so the screen keeps one-line delegating getters.

List<String> activeAddTaskDurationOptions(String? category) =>
    isSleepCategory(category)
    ? sleepDurationChipKeys
    : standardDurationChipKeys;

List<String> activeAddTaskDurationLabels({
  required String? category,
  required String duration,
  required int customMinutes,
}) {
  if (isSleepCategory(category)) {
    return [
      ...sleepDurationChipLabels.sublist(0, sleepDurationChipLabels.length - 1),
      isCustomDurationKey(duration)
          ? formatAddTaskDurationChipLabel(customMinutes)
          : sleepDurationChipLabels.last,
    ];
  }
  return [
    ...standardDurationChipLabels.sublist(0, 4),
    isCustomDurationKey(duration)
        ? formatAddTaskDurationChipLabel(customMinutes)
        : 'Custom',
  ];
}

int resolvedAddTaskDurationMinutes({
  required String? category,
  required bool durationEnabled,
  required String duration,
  required int customMinutes,
}) {
  if (isSleepCategory(category) || durationEnabled) {
    return addTaskDurationMinutes(duration, customMinutes: customMinutes);
  }
  return kReminderOnlyDurationMinutes;
}

String addTaskDurationDisplayLabel({
  required String? category,
  required String duration,
  required int customMinutes,
}) {
  if (isCustomDurationKey(duration)) {
    return formatAddTaskDurationChipLabel(customMinutes);
  }
  final options = activeAddTaskDurationOptions(category);
  final i = options.indexOf(duration);
  if (i >= 0) {
    return activeAddTaskDurationLabels(
      category: category,
      duration: duration,
      customMinutes: customMinutes,
    )[i];
  }
  return isSleepCategory(category) ? sleepDurationChipLabels.last : '25m';
}

/// No chip highlighted until duration is enabled (sleep always has duration).
String? addTaskDurationSegmentSelection({
  required String? category,
  required bool durationEnabled,
  required String duration,
  required int customMinutes,
}) {
  if (isSleepCategory(category) || durationEnabled) {
    return addTaskDurationDisplayLabel(
      category: category,
      duration: duration,
      customMinutes: customMinutes,
    );
  }
  return null;
}
