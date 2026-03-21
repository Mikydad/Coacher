import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';

/// All routine slots for tomorrow, sorted by [Routine.orderIndex].
/// Creates the default Morning / Afternoon / Night slots if none exist yet.
final tomorrowRoutineSlotsProvider = FutureProvider<List<Routine>>((ref) async {
  final repo = ref.read(planningRepositoryProvider);
  final tomorrow = DateKeys.tomorrowKey();

  // Check cache first — avoids recreating defaults when invalidated right after creation.
  List<Routine> routines = await repo.getRoutinesForDate(tomorrow);

  // If cache says empty, try server to confirm.
  if (routines.isEmpty) {
    const server = GetOptions(source: Source.server);
    try {
      routines = await repo.getRoutinesForDate(tomorrow, getOptions: server);
    } catch (_) {
      // Stay offline — routines already set from cache above.
    }
  }

  if (routines.isEmpty) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = [
      ('Morning', 0),
      ('Afternoon', 1),
      ('Night', 2),
    ];
    final created = <Routine>[];
    for (final (title, idx) in defaults) {
      final routineId = StableId.generate('routine');
      final routine = Routine(
        id: routineId,
        title: title,
        dateKey: tomorrow,
        orderIndex: idx,
        createdAtMs: now,
        updatedAtMs: now,
      );
      await repo.upsertRoutine(routine);
      await repo.upsertBlock(
        TaskBlock(
          id: StableId.generate('block'),
          routineId: routineId,
          title: 'Main',
          orderIndex: 0,
          createdAtMs: now,
          updatedAtMs: now,
        ),
      );
      created.add(routine);
    }
    return created;
  }

  return routines;
});

/// Tasks for a single tomorrow routine slot, keyed by [routineId].
final tomorrowTasksForRoutineProvider =
    FutureProvider.family<List<PlannedTaskRow>, String>((ref, routineId) async {
  final repo = ref.read(planningRepositoryProvider);
  final tomorrow = DateKeys.tomorrowKey();
  const server = GetOptions(source: Source.server);

  List<TaskBlock> blocks;
  try {
    blocks = await repo.getBlocks(routineId, getOptions: server);
  } catch (_) {
    blocks = await repo.getBlocks(routineId);
  }

  final rows = <PlannedTaskRow>[];
  for (final block in blocks) {
    List<PlannedTask> tasks;
    try {
      tasks = await repo.getTasks(
        routineId: routineId,
        blockId: block.id,
        getOptions: server,
      );
    } catch (_) {
      tasks = await repo.getTasks(routineId: routineId, blockId: block.id);
    }
    for (final task in tasks) {
      rows.add(
        PlannedTaskRow(
          dateKey: tomorrow,
          routineId: routineId,
          blockId: block.id,
          task: task,
        ),
      );
    }
  }

  rows.sort((a, b) {
    final c = a.task.orderIndex.compareTo(b.task.orderIndex);
    if (c != 0) return c;
    return a.task.id.compareTo(b.task.id);
  });
  return rows;
});

void invalidateTomorrowProviders(WidgetRef ref) {
  ref.invalidate(tomorrowRoutineSlotsProvider);
  ref.invalidate(tomorrowTasksForRoutineProvider);
}
