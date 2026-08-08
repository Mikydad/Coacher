/// Navigation arguments for the Add Task sheet (`showAddTaskSheet`).
library;

class AddTaskEditArgs {
  const AddTaskEditArgs({
    required this.taskId,
    required this.routineId,
    required this.blockId,
    required this.dateKey,
  });

  final String taskId;
  final String routineId;
  final String blockId;

  /// `Routine.dateKey` for this task’s current plan day.
  final String dateKey;
}

/// Passed when opening Add Task from a specific routine slot (e.g. Plan Tomorrow).
/// Saves directly under [routineId]/[blockId] without calling `ensureDefaultDayPlan`.
class AddTaskSlotArgs {
  const AddTaskSlotArgs({
    required this.routineId,
    required this.blockId,
    required this.dateKey,
  });

  final String routineId;
  final String blockId;
  final String dateKey;
}
