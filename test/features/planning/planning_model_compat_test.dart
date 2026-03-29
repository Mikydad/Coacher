import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Routine.fromMap falls back for legacy/minimal documents', () {
    final routine = Routine.fromMap({
      'id': 'r1',
      'title': 'Daily plan',
      'dateKey': '2026-03-24',
      'orderIndex': 0,
      'createdAtMs': 1,
      'updatedAtMs': 2,
    });

    expect(routine.modeId, 'flexible');
    expect(routine.mode, RoutineMode.flexible);
  });

  test('TaskBlock.fromMap falls back for legacy/minimal documents', () {
    final block = TaskBlock.fromMap({
      'id': 'b1',
      'routineId': 'r1',
      'title': 'Main',
      'orderIndex': 0,
      'createdAtMs': 1,
      'updatedAtMs': 2,
    });

    expect(block.urgencyScore, 0);
    expect(block.startMinutesFromMidnight, isNull);
    expect(block.modeRefId, isNull);
  });

  test('PlannedTask.fromMap does not throw on unknown status', () {
    final task = PlannedTask.fromMap({
      'id': 't1',
      'routineId': 'r1',
      'blockId': 'b1',
      'title': 'Legacy task',
      'durationMinutes': 20,
      'priority': 3,
      'orderIndex': 0,
      'reminderEnabled': false,
      'status': 'legacyStatusThatNoLongerExists',
      'createdAtMs': 1,
      'updatedAtMs': 2,
    });

    expect(task.status, TaskStatus.notStarted);
    expect(task.strictModeRequired, isFalse);
    expect(task.modeRefId, isNull);
  });
}
