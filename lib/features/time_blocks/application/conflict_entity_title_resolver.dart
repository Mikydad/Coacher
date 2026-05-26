import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_goal.dart';
import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../goals/application/goals_providers.dart';
import '../../planning/application/planned_task_collect.dart';
import '../domain/models/scheduled_time_block.dart';

/// Builds entityId → display title for scheduling conflict UI.
///
/// Merges today's planned tasks, goals, reminder titles, then resolves any
/// [overlapping] block ids still missing via local Isar lookup.
Future<Map<String, String>> buildSchedulingConflictEntityTitles(
  WidgetRef ref, {
  Iterable<ScheduledTimeBlock>? overlapping,
}) async {
  final titles = <String, String>{};
  titles.addAll(ref.read(goalTitleMapProvider));

  final rows = await collectTodayPlannedRows(ref.read(planningRepositoryProvider));
  for (final row in rows) {
    titles[row.task.id] = row.task.title;
  }

  try {
    final reminders = await ref.read(reminderRepositoryProvider).listAllReminders();
    for (final reminder in reminders) {
      final id = reminder.taskId;
      final name = reminder.taskTitle?.trim();
      if (id.isNotEmpty && name != null && name.isNotEmpty) {
        titles.putIfAbsent(id, () => name);
      }
    }
  } catch (_) {}

  final isar = ref.read(offlineStoreProvider).isar;
  if (isar == null || overlapping == null) return titles;

  for (final block in overlapping) {
    if (titles.containsKey(block.entityId)) continue;
    try {
      if (block.entityKind == 'goal') {
        final goal = await isar.isarGoals.getByGoalId(block.entityId);
        final name = goal?.title.trim();
        if (name != null && name.isNotEmpty) {
          titles[block.entityId] = name;
        }
      } else {
        final task = await isar.isarTasks.getByTaskId(block.entityId);
        final name = task?.title.trim();
        if (name != null && name.isNotEmpty) {
          titles[block.entityId] = name;
        }
      }
    } catch (_) {}
  }

  return titles;
}
