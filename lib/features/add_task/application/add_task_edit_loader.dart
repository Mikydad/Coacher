import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../../reminders/domain/models/reminder_occurrence_enums.dart';

/// The task plus its stored reminder identity, fetched for edit mode.
class AddTaskEditLoad {
  const AddTaskEditLoad({
    required this.task,
    this.reminderId,
    this.reminderCreatedAtMs,
    this.classification,
  });

  final PlannedTask task;
  final String? reminderId;
  final int? reminderCreatedAtMs;

  /// The stored classification, so editing shows what SidePal (or the user)
  /// decided last time rather than re-guessing from scratch (FR-R-21).
  /// Null when the stored source is not `user` — the heuristic's live answer
  /// is better than a stale one.
  final ({ReminderTaxonomy taxonomy, int criticality})? classification;
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
  final stored = reminders.isNotEmpty ? reminders.first : null;
  return AddTaskEditLoad(
    task: task,
    reminderId: stored?.id,
    reminderCreatedAtMs: stored?.createdAtMs,
    classification:
        stored != null && stored.classificationSource.isAuthoritative
        ? (taxonomy: stored.taxonomy, criticality: stored.criticality)
        : null,
  );
}
