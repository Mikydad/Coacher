import 'package:sidepal/features/planning/application/auto_next_task_flow.dart';
import 'package:sidepal/features/planning/application/planned_task_collect.dart';
import 'package:sidepal/features/planning/application/task_prioritizer.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

final _autoNextNow = DateTime(2026, 4, 30, 18, 0);

PlannedTaskRow _row({
  required String id,
  required int duration,
  required int priority,
  required int orderIndex,
  String? reminderTimeIso,
}) {
  return PlannedTaskRow(
    dateKey: '2026-04-30',
    routineId: 'r1',
    blockId: 'b1',
    task: PlannedTask(
      id: id,
      routineId: 'r1',
      blockId: 'b1',
      title: id,
      durationMinutes: duration,
      priority: priority,
      orderIndex: orderIndex,
      reminderEnabled: reminderTimeIso != null,
      reminderTimeIso: reminderTimeIso,
      status: TaskStatus.notStarted,
      createdAtMs: 1,
      updatedAtMs: 1,
    ),
  );
}

PrioritizedTaskRow _prioritized({
  required String id,
  required TaskPriorityLayer layer,
  required int orderIndex,
  String? reminderTimeIso,
}) {
  return PrioritizedTaskRow(
    row: _row(
      id: id,
      duration: 10,
      priority: 2,
      orderIndex: orderIndex,
      reminderTimeIso: reminderTimeIso,
    ),
    layer: layer,
  );
}

void main() {
  test('pickNextAutoTaskFromPrioritized skips completed id', () {
    final prioritized = <PrioritizedTaskRow>[
      _prioritized(
        id: 'done',
        layer: TaskPriorityLayer.overdueScheduled,
        orderIndex: 0,
        reminderTimeIso: DateTime(2026, 4, 30, 17, 0).toIso8601String(),
      ),
      _prioritized(
        id: 'next',
        layer: TaskPriorityLayer.upcomingScheduled,
        orderIndex: 1,
        reminderTimeIso: DateTime(2026, 4, 30, 22, 0).toIso8601String(),
      ),
      _prioritized(id: 'later', layer: TaskPriorityLayer.flexible, orderIndex: 2),
    ];

    final next = pickNextAutoTaskFromPrioritized(
      prioritized,
      completedTaskId: 'done',
      now: _autoNextNow,
    );
    expect(next?.task.id, 'later');
  });

  test('pickNextAutoTaskFromPrioritized skips upcoming scheduled tasks', () {
    final prioritized = <PrioritizedTaskRow>[
      _prioritized(id: 'done', layer: TaskPriorityLayer.doNow, orderIndex: 0),
      _prioritized(
        id: 'sleep',
        layer: TaskPriorityLayer.upcomingScheduled,
        orderIndex: 1,
        reminderTimeIso: DateTime(2026, 4, 30, 22, 0).toIso8601String(),
      ),
    ];

    final next = pickNextAutoTaskFromPrioritized(
      prioritized,
      completedTaskId: 'done',
      now: _autoNextNow,
    );
    expect(next, isNull);
  });

  test('pickNextAutoTaskFromPrioritized returns null when only completed exists', () {
    final prioritized = <PrioritizedTaskRow>[
      _prioritized(id: 'done', layer: TaskPriorityLayer.doNow, orderIndex: 0),
    ];

    final next = pickNextAutoTaskFromPrioritized(
      prioritized,
      completedTaskId: 'done',
      now: _autoNextNow,
    );
    expect(next, isNull);
  });
}
