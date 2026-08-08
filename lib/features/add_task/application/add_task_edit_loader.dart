import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../planning/domain/models/task_item.dart';

/// The task plus its stored reminder identity, fetched for edit mode.
class AddTaskEditLoad {
  const AddTaskEditLoad({
    required this.task,
    this.reminderId,
    this.reminderCreatedAtMs,
  });

  final PlannedTask task;
  final String? reminderId;
  final int? reminderCreatedAtMs;
}

/// Fetches the task and its reminder for edit mode. Returns null when the
/// task no longer exists; repository errors propagate to the caller (which
/// owns the snackbar-and-pop error story).
Future<AddTaskEditLoad?> loadAddTaskForEdit(
  WidgetRef ref, {
  required String taskId,
  required String routineId,
  required String blockId,
}) async {
  final planning = ref.read(planningRepositoryProvider);
  final tasks = await planning.getTasks(routineId: routineId, blockId: blockId);
  PlannedTask? task;
  for (final t in tasks) {
    if (t.id == taskId) {
      task = t;
      break;
    }
  }
  if (task == null) return null;

  final reminders = await ref
      .read(reminderRepositoryProvider)
      .getRemindersForTasks([task.id]);
  return AddTaskEditLoad(
    task: task,
    reminderId: reminders.isNotEmpty ? reminders.first.id : null,
    reminderCreatedAtMs: reminders.isNotEmpty
        ? reminders.first.createdAtMs
        : null,
  );
}
