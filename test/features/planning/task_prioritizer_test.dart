import 'package:coach_for_life/features/planning/application/planned_task_collect.dart';
import 'package:coach_for_life/features/planning/application/task_prioritizer.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTaskRow _row({
  required String id,
  required String title,
  required int duration,
  required int priority,
  required int orderIndex,
  String? reminderTimeIso,
  int? sequenceIndex,
  bool isHabitAnchor = false,
  TaskStatus status = TaskStatus.notStarted,
}) {
  return PlannedTaskRow(
    dateKey: '2026-04-30',
    routineId: 'r1',
    blockId: 'b1',
    task: PlannedTask(
      id: id,
      routineId: 'r1',
      blockId: 'b1',
      title: title,
      durationMinutes: duration,
      priority: priority,
      orderIndex: orderIndex,
      reminderEnabled: reminderTimeIso != null,
      reminderTimeIso: reminderTimeIso,
      status: status,
      createdAtMs: 1,
      updatedAtMs: 1,
      sequenceIndex: sequenceIndex,
      isHabitAnchor: isHabitAnchor,
    ),
  );
}

void main() {
  test('orders overdue then upcoming then doNow then flexible', () {
    final now = DateTime(2026, 4, 30, 14, 0);
    final rows = [
      _row(
        id: 'overdue1',
        title: 'Overdue',
        duration: 20,
        priority: 2,
        orderIndex: 0,
        reminderTimeIso: DateTime(2026, 4, 30, 13, 30).toIso8601String(),
      ),
      _row(
        id: 'upcoming1',
        title: 'Upcoming',
        duration: 20,
        priority: 2,
        orderIndex: 1,
        reminderTimeIso: DateTime(2026, 4, 30, 14, 30).toIso8601String(),
      ),
      _row(id: 'flex1', title: 'Flex1', duration: 10, priority: 2, orderIndex: 2),
      _row(id: 'flex2', title: 'Flex2', duration: 15, priority: 3, orderIndex: 3),
      _row(id: 'flex3', title: 'Flex3', duration: 25, priority: 1, orderIndex: 4),
      _row(id: 'flex4', title: 'Flex4', duration: 40, priority: 4, orderIndex: 5),
    ];

    final prioritized = prioritizePlannedTasks(rows, now: now);
    expect(prioritized.first.layer, TaskPriorityLayer.overdueScheduled);
    expect(prioritized[1].layer, TaskPriorityLayer.upcomingScheduled);
    expect(prioritized[2].layer, TaskPriorityLayer.doNow);
    expect(prioritized[3].layer, TaskPriorityLayer.doNow);
    expect(prioritized[4].layer, TaskPriorityLayer.doNow);
    expect(prioritized[5].layer, TaskPriorityLayer.flexible);
  });

  test('treats invalid reminderTimeIso as flexible', () {
    final now = DateTime(2026, 4, 30, 14, 0);
    final prioritized = prioritizePlannedTasks([
      _row(
        id: 't1',
        title: 'Invalid time',
        duration: 10,
        priority: 2,
        orderIndex: 0,
        reminderTimeIso: 'not-a-date',
      ),
    ], now: now);
    expect(prioritized.single.layer, TaskPriorityLayer.doNow);
  });

  test('classifies past as overdue and future as upcoming', () {
    final now = DateTime(2026, 4, 30, 14, 0);
    final prioritized = prioritizePlannedTasks([
      _row(
        id: 'past',
        title: 'Past',
        duration: 10,
        priority: 2,
        orderIndex: 0,
        reminderTimeIso: DateTime(2026, 4, 30, 13, 0).toIso8601String(),
      ),
      _row(
        id: 'future',
        title: 'Future',
        duration: 10,
        priority: 2,
        orderIndex: 1,
        reminderTimeIso: DateTime(2026, 4, 30, 15, 0).toIso8601String(),
      ),
    ], now: now);

    expect(prioritized[0].row.task.id, 'past');
    expect(prioritized[0].layer, TaskPriorityLayer.overdueScheduled);
    expect(prioritized[1].row.task.id, 'future');
    expect(prioritized[1].layer, TaskPriorityLayer.upcomingScheduled);
  });

  test('caps doNow to 3 and excludes duplicates from flexible', () {
    final now = DateTime(2026, 4, 30, 14, 0);
    final prioritized = prioritizePlannedTasks([
      _row(id: 'a', title: 'A', duration: 5, priority: 2, orderIndex: 0),
      _row(id: 'b', title: 'B', duration: 6, priority: 2, orderIndex: 1),
      _row(id: 'c', title: 'C', duration: 7, priority: 2, orderIndex: 2),
      _row(id: 'd', title: 'D', duration: 8, priority: 2, orderIndex: 3),
      _row(id: 'e', title: 'E', duration: 9, priority: 2, orderIndex: 4),
    ], now: now, doNowLimit: 3);

    final doNowIds = prioritized
        .where((p) => p.layer == TaskPriorityLayer.doNow)
        .map((p) => p.row.task.id)
        .toList();
    final flexibleIds = prioritized
        .where((p) => p.layer == TaskPriorityLayer.flexible)
        .map((p) => p.row.task.id)
        .toList();

    expect(doNowIds.length, 3);
    expect(flexibleIds.any(doNowIds.contains), isFalse);
  });

  test('respects sequenceIndex for tie ordering', () {
    final prioritized = prioritizePlannedTasks([
      _row(id: 't1', title: 'A', duration: 20, priority: 2, orderIndex: 2, sequenceIndex: 2),
      _row(id: 't2', title: 'B', duration: 20, priority: 2, orderIndex: 1, sequenceIndex: 1),
    ], now: DateTime(2026, 4, 30, 10, 0), doNowLimit: 0);

    expect(prioritized[0].row.task.id, 't2');
    expect(prioritized[1].row.task.id, 't1');
  });

  test('habit anchor tasks are always ordered first', () {
    final now = DateTime(2026, 4, 30, 14, 0);
    final prioritized = prioritizePlannedTasks([
      _row(
        id: 'overdue',
        title: 'Overdue',
        duration: 10,
        priority: 2,
        orderIndex: 0,
        reminderTimeIso: DateTime(2026, 4, 30, 13, 0).toIso8601String(),
      ),
      _row(
        id: 'habit',
        title: 'Habit',
        duration: 20,
        priority: 3,
        orderIndex: 1,
        reminderTimeIso: DateTime(2026, 4, 30, 16, 0).toIso8601String(),
        isHabitAnchor: true,
      ),
      _row(id: 'flex', title: 'Flex', duration: 5, priority: 1, orderIndex: 2),
    ], now: now);

    expect(prioritized[0].row.task.id, 'habit');
    expect(prioritized[0].layer, TaskPriorityLayer.habitAnchor);
    expect(prioritized[1].layer, TaskPriorityLayer.overdueScheduled);
  });
}
