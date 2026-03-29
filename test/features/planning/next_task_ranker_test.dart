import 'package:coach_for_life/features/planning/application/next_task_ranker.dart';
import 'package:coach_for_life/features/planning/application/planned_task_collect.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTaskRow _row({
  required String id,
  required String blockId,
  int priority = 3,
  int orderIndex = 0,
  int? sequenceIndex,
  TaskStatus status = TaskStatus.notStarted,
}) {
  return PlannedTaskRow(
    dateKey: '2026-03-24',
    routineId: 'r1',
    blockId: blockId,
    task: PlannedTask(
      id: id,
      routineId: 'r1',
      blockId: blockId,
      title: id,
      durationMinutes: 25,
      priority: priority,
      orderIndex: orderIndex,
      reminderEnabled: false,
      reminderTimeIso: null,
      status: status,
      createdAtMs: 1,
      updatedAtMs: 1,
      sequenceIndex: sequenceIndex,
    ),
  );
}

void main() {
  test('chooseNext picks higher priority first', () {
    final rows = [
      _row(id: 'a', blockId: 'b1', priority: 3),
      _row(id: 'b', blockId: 'b1', priority: 1),
    ];
    final next = NextTaskRanker.chooseNext(rows);
    expect(next?.task.id, 'b');
  });

  test('completed task is excluded from candidates', () {
    final rows = [
      _row(id: 'a', blockId: 'b1', priority: 1, status: TaskStatus.completed),
      _row(id: 'b', blockId: 'b1', priority: 2),
    ];
    final next = NextTaskRanker.chooseNext(rows);
    expect(next?.task.id, 'b');
  });

  test('urgency breaks ties on same priority', () {
    final rows = [
      _row(id: 'a', blockId: 'morning', priority: 2),
      _row(id: 'b', blockId: 'night', priority: 2),
    ];
    final next = NextTaskRanker.chooseNext(
      rows,
      blockUrgencyById: const {'morning': 40, 'night': 90},
    );
    expect(next?.task.id, 'b');
  });

  test('preferUserSequence puts sequenced items first', () {
    final rows = [
      _row(id: 'a', blockId: 'b1', priority: 1, sequenceIndex: 3),
      _row(id: 'b', blockId: 'b1', priority: 1, sequenceIndex: 1),
      _row(id: 'c', blockId: 'b1', priority: 1),
    ];
    final ranked = NextTaskRanker.rank(rows, preferUserSequence: true);
    expect(ranked.map((r) => r.task.id).toList(), ['b', 'a', 'c']);
  });

  test('critical urgency can override user sequence when enabled', () {
    final rows = [
      _row(id: 'a', blockId: 'normal', priority: 2, sequenceIndex: 1),
      _row(id: 'b', blockId: 'critical', priority: 2, sequenceIndex: 5),
    ];

    final ranked = NextTaskRanker.rank(
      rows,
      preferUserSequence: true,
      allowUrgencyOverride: true,
      blockUrgencyById: const {'normal': 30, 'critical': 95},
      urgencyOverrideThreshold: 80,
    );

    expect(ranked.first.task.id, 'b');
  });

  test('equal priority and urgency fall back to orderIndex then id', () {
    final rows = [
      _row(id: 'b', blockId: 'same', priority: 2, orderIndex: 5),
      _row(id: 'a', blockId: 'same', priority: 2, orderIndex: 5),
      _row(id: 'c', blockId: 'same', priority: 2, orderIndex: 1),
    ];

    final ranked = NextTaskRanker.rank(
      rows,
      blockUrgencyById: const {'same': 20},
    );

    expect(ranked.map((r) => r.task.id).toList(), ['c', 'a', 'b']);
  });

  test('urgency override threshold is respected', () {
    final rows = [
      _row(id: 'a', blockId: 'normal', priority: 2, sequenceIndex: 1),
      _row(id: 'b', blockId: 'near', priority: 2, sequenceIndex: 2),
    ];

    final rankedNoOverride = NextTaskRanker.rank(
      rows,
      preferUserSequence: true,
      allowUrgencyOverride: true,
      blockUrgencyById: const {'normal': 60, 'near': 79},
      urgencyOverrideThreshold: 80,
    );
    expect(rankedNoOverride.first.task.id, 'a');

    final rankedWithOverride = NextTaskRanker.rank(
      rows,
      preferUserSequence: true,
      allowUrgencyOverride: true,
      blockUrgencyById: const {'normal': 60, 'near': 80},
      urgencyOverrideThreshold: 80,
    );
    expect(rankedWithOverride.first.task.id, 'b');
  });

  test('sequence ordering remains when urgency override disabled', () {
    final rows = [
      _row(id: 'a', blockId: 'normal', priority: 2, sequenceIndex: 1),
      _row(id: 'b', blockId: 'critical', priority: 2, sequenceIndex: 4),
    ];

    final ranked = NextTaskRanker.rank(
      rows,
      preferUserSequence: true,
      allowUrgencyOverride: false,
      blockUrgencyById: const {'normal': 20, 'critical': 99},
      urgencyOverrideThreshold: 80,
    );

    expect(ranked.first.task.id, 'a');
  });
}
