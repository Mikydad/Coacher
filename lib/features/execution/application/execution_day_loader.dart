import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/task_prioritizer.dart';
import '../../planning/domain/models/task_item.dart';

class ExecutionTaskItem {
  const ExecutionTaskItem({
    required this.id,
    required this.title,
    required this.durationMinutes,
  });

  final String id;
  final String title;
  final int durationMinutes;
}

/// Non–auto-dispose so hot reload doesn’t hit a `FutureProvider` vs
/// `AutoDisposeFutureProvider` subtype mismatch in a running isolate.
/// Refresh on resume / day change: `invalidateTaskListProviders` in `app_lifecycle_task_refresh.dart`.
final executionDayTasksProvider = FutureProvider<List<ExecutionTaskItem>>((
  ref,
) async {
  final planningRepo = ref.read(planningRepositoryProvider);
  final rows = await collectTasksForDateKeyPreferServer(
    planningRepo,
    DateKeys.todayKey(),
    enforceTaskPlanDate: true,
  );
  final blockUrgencyById = <String, int>{};
  final routinesById = <String>{};
  for (final row in rows) {
    routinesById.add(row.routineId);
  }
  for (final routineId in routinesById) {
    final blocks = await planningRepo.getBlocks(routineId);
    for (final b in blocks) {
      blockUrgencyById[b.id] = b.urgencyScore;
    }
  }
  final prioritized = prioritizePlannedTasks(
    rows,
    blockUrgencyById: blockUrgencyById,
  );

  final items = <ExecutionTaskItem>[];
  for (final prioritizedRow in prioritized) {
    final row = prioritizedRow.row;
    final task = row.task;
    if (task.status == TaskStatus.notStarted ||
        task.status == TaskStatus.inProgress ||
        task.status == TaskStatus.partial) {
      items.add(
        ExecutionTaskItem(
          id: task.id,
          title: task.title,
          durationMinutes: task.durationMinutes,
        ),
      );
    }
  }
  return items;
});
