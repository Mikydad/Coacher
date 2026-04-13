import '../../../core/utils/date_keys.dart';
import '../data/planning_repository.dart';
import '../domain/models/task_item.dart';

/// One planned task with Firestore path context (routine/block/day).
class PlannedTaskRow {
  const PlannedTaskRow({
    required this.dateKey,
    required this.routineId,
    required this.blockId,
    required this.task,
  });

  final String dateKey;
  final String routineId;
  final String blockId;
  final PlannedTask task;
}

/// Loads all tasks for a single plan day (`Routine.dateKey`).
///
/// When [enforceTaskPlanDate] is true, skips tasks whose [PlannedTask.planDateKey]
/// is non-null and differs from [dateKey] (stale path / migration safety).
Future<List<PlannedTaskRow>> collectTasksForDateKey(
  PlanningRepository repo,
  String dateKey, {
  bool enforceTaskPlanDate = false,
}) async {
  final rows = <PlannedTaskRow>[];
  final routines = await repo.getRoutinesForDate(dateKey);
  for (final routine in routines) {
    if (routine.dateKey != dateKey) continue;
    final blocks = await repo.getBlocks(routine.id);
    for (final block in blocks) {
      final tasks = await repo.getTasks(
        routineId: routine.id,
        blockId: block.id,
      );
      for (final task in tasks) {
        if (enforceTaskPlanDate) {
          final pk = task.planDateKey;
          if (pk != null && pk != dateKey) continue;
        }
        rows.add(
          PlannedTaskRow(
            dateKey: dateKey,
            routineId: routine.id,
            blockId: block.id,
            task: task,
          ),
        );
      }
    }
  }
  rows.sort((a, b) {
    final c = a.task.orderIndex.compareTo(b.task.orderIndex);
    if (c != 0) return c;
    return a.task.id.compareTo(b.task.id);
  });
  return rows;
}

/// Alias for callers that previously preferred a server-first read; local-first uses the same path.
Future<List<PlannedTaskRow>> collectTasksForDateKeyPreferServer(
  PlanningRepository repo,
  String dateKey, {
  bool enforceTaskPlanDate = false,
}) {
  return collectTasksForDateKey(
    repo,
    dateKey,
    enforceTaskPlanDate: enforceTaskPlanDate,
  );
}

/// Fresh read from local store (same as stream content); use after writes instead of [StreamProvider.future].
Future<List<PlannedTaskRow>> collectTodayPlannedRows(PlanningRepository repo) {
  return collectTasksForDateKeyPreferServer(
    repo,
    DateKeys.todayKey(),
    enforceTaskPlanDate: true,
  );
}

bool taskIsOpenForHub(PlannedTask task) {
  switch (task.status) {
    case TaskStatus.notStarted:
    case TaskStatus.inProgress:
    case TaskStatus.partial:
      return true;
    case TaskStatus.completed:
      return false;
  }
}
