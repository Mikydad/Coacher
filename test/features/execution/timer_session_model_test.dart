import 'package:coach_for_life/features/execution/domain/models/timer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task target session validates with taskId', () {
    final session = TimerSession(
      id: 's1',
      targetType: TimerSessionTargetType.task,
      taskId: 'task_1',
      startedAtMs: 1,
      endedAtMs: null,
      elapsedSeconds: 10,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
    expect(() => session.validate(), returnsNormally);
  });

  test('block target session validates with blockId', () {
    final session = TimerSession(
      id: 's2',
      targetType: TimerSessionTargetType.block,
      blockId: 'block_1',
      startedAtMs: 1,
      endedAtMs: null,
      elapsedSeconds: 10,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
    expect(() => session.validate(), returnsNormally);
  });

  test('block target without blockId fails validation', () {
    final session = TimerSession(
      id: 's3',
      targetType: TimerSessionTargetType.block,
      startedAtMs: 1,
      endedAtMs: null,
      elapsedSeconds: 10,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
    expect(() => session.validate(), throwsArgumentError);
  });

  test('fromMap falls back to task target for legacy docs', () {
    final session = TimerSession.fromMap({
      'id': 'legacy',
      'taskId': 'task_legacy',
      'startedAtMs': 100,
      'elapsedSeconds': 25,
      'createdAtMs': 100,
      'updatedAtMs': 100,
    });
    expect(session.targetType, TimerSessionTargetType.task);
    expect(session.taskId, 'task_legacy');
  });
}
