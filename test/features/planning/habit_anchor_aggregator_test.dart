import 'package:coach_for_life/features/planning/application/habit_anchor_aggregator.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTask _task({
  required String id,
  required String iso,
  int duration = 30,
}) {
  return PlannedTask(
    id: id,
    routineId: 'r1',
    blockId: 'b1',
    title: id,
    durationMinutes: duration,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: true,
    reminderTimeIso: iso,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}

void main() {
  test('findOverlappingHabitAnchorsForTask returns only overlapping windows', () {
    final task = _task(
      id: 'task1',
      iso: DateTime(2026, 5, 1, 10, 0).toIso8601String(),
      duration: 30,
    );
    final anchors = [
      HabitAnchor(
        id: 'goal_1',
        source: HabitAnchorSource.goal,
        label: 'Goal habit',
        dateKey: '2026-05-01',
        startLocal: DateTime(2026, 5, 1, 10, 10),
        endLocal: DateTime(2026, 5, 1, 10, 25),
      ),
      HabitAnchor(
        id: 'task_2',
        source: HabitAnchorSource.plannedTask,
        label: 'Other habit task',
        dateKey: '2026-05-01',
        startLocal: DateTime(2026, 5, 1, 11, 0),
        endLocal: DateTime(2026, 5, 1, 11, 20),
        taskId: 'task2',
      ),
    ];

    final overlaps = findOverlappingHabitAnchorsForTask(task, anchors);
    expect(overlaps.length, 1);
    expect(overlaps.single.id, 'goal_1');
  });

  test('findOverlappingHabitAnchorsForTask ignores same task anchor id', () {
    final task = _task(
      id: 'task-self',
      iso: DateTime(2026, 5, 1, 10, 0).toIso8601String(),
      duration: 30,
    );
    final anchors = [
      HabitAnchor(
        id: 'task_self',
        source: HabitAnchorSource.plannedTask,
        label: 'Self',
        dateKey: '2026-05-01',
        startLocal: DateTime(2026, 5, 1, 10, 0),
        endLocal: DateTime(2026, 5, 1, 10, 30),
        taskId: 'task-self',
      ),
    ];

    final overlaps = findOverlappingHabitAnchorsForTask(
      task,
      anchors,
      ignoredTaskId: 'task-self',
    );
    expect(overlaps, isEmpty);
  });
}
