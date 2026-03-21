import 'package:cloud_firestore/cloud_firestore.dart';

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
///
/// [firestoreGetOptions]: pass [GetOptions(source: Source.server)] so Focus/Home
/// match the server and avoid stale offline cache mixing days.
Future<List<PlannedTaskRow>> collectTasksForDateKey(
  PlanningRepository repo,
  String dateKey, {
  bool enforceTaskPlanDate = false,
  GetOptions? firestoreGetOptions,
}) async {
  final rows = <PlannedTaskRow>[];
  final routines = await repo.getRoutinesForDate(
    dateKey,
    getOptions: firestoreGetOptions,
  );
  for (final routine in routines) {
    if (routine.dateKey != dateKey) continue;
    final blocks = await repo.getBlocks(
      routine.id,
      getOptions: firestoreGetOptions,
    );
    for (final block in blocks) {
      final tasks = await repo.getTasks(
        routineId: routine.id,
        blockId: block.id,
        getOptions: firestoreGetOptions,
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

/// Tries a server read first (fresh truth), then falls back to default cache behavior if offline.
Future<List<PlannedTaskRow>> collectTasksForDateKeyPreferServer(
  PlanningRepository repo,
  String dateKey, {
  bool enforceTaskPlanDate = false,
}) async {
  const server = GetOptions(source: Source.server);
  try {
    return await collectTasksForDateKey(
      repo,
      dateKey,
      enforceTaskPlanDate: enforceTaskPlanDate,
      firestoreGetOptions: server,
    );
  } catch (_) {
    return await collectTasksForDateKey(
      repo,
      dateKey,
      enforceTaskPlanDate: enforceTaskPlanDate,
    );
  }
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
