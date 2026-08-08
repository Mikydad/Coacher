import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/models/task_item.dart';

/// Where a saved task lands: routine/block, its order within the block, and
/// its identity (existing id + createdAt in edit mode, fresh otherwise).
class AddTaskSaveTarget {
  const AddTaskSaveTarget({
    required this.routineId,
    required this.blockId,
    required this.orderIndex,
    required this.taskId,
    required this.createdAtMs,
  });

  final String routineId;
  final String blockId;
  final int orderIndex;
  final String taskId;
  final int createdAtMs;
}

/// Resolves the save destination:
/// - edit on the same day → in place, keeping the task's order;
/// - edit moved to another day → delete from the old slot, land in that day's
///   default plan;
/// - create from a preset slot (Plan Tomorrow) → directly into the slot,
///   no `ensureDefaultDayPlan`;
/// - plain create → the plan day's default routine/block.
Future<AddTaskSaveTarget> resolveAddTaskSaveTarget(
  WidgetRef ref, {
  required String planDateKey,
  required int nowMs,
  PlannedTask? loadedTask,
  String? editRoutineId,
  String? editBlockId,
  String? editDateKey,
  String? slotRoutineId,
  String? slotBlockId,
}) async {
  final planning = ref.read(planningRepositoryProvider);

  if (loadedTask != null) {
    final taskId = loadedTask.id;
    final createdAtMs = loadedTask.createdAtMs;
    if (planDateKey != editDateKey) {
      await planning.deleteTask(
        routineId: editRoutineId!,
        blockId: editBlockId!,
        taskId: taskId,
      );
      final day = await planning.ensureDefaultDayPlan(planDateKey);
      return AddTaskSaveTarget(
        routineId: day.routineId,
        blockId: day.blockId,
        orderIndex: await _nextOrderIndex(planning, day.routineId, day.blockId),
        taskId: taskId,
        createdAtMs: createdAtMs,
      );
    }
    return AddTaskSaveTarget(
      routineId: editRoutineId!,
      blockId: editBlockId!,
      orderIndex: loadedTask.orderIndex,
      taskId: taskId,
      createdAtMs: createdAtMs,
    );
  }

  final taskId = StableId.generate('task');
  if (slotRoutineId != null && slotBlockId != null) {
    // Save directly into the preset slot — no ensureDefaultDayPlan needed.
    return AddTaskSaveTarget(
      routineId: slotRoutineId,
      blockId: slotBlockId,
      orderIndex: await _nextOrderIndex(planning, slotRoutineId, slotBlockId),
      taskId: taskId,
      createdAtMs: nowMs,
    );
  }
  final day = await planning.ensureDefaultDayPlan(planDateKey);
  return AddTaskSaveTarget(
    routineId: day.routineId,
    blockId: day.blockId,
    orderIndex: await _nextOrderIndex(planning, day.routineId, day.blockId),
    taskId: taskId,
    createdAtMs: nowMs,
  );
}

Future<int> _nextOrderIndex(
  PlanningRepository planning,
  String routineId,
  String blockId,
) async {
  final existing = await planning.getTasks(
    routineId: routineId,
    blockId: blockId,
  );
  return existing.isEmpty
      ? 0
      : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
}
