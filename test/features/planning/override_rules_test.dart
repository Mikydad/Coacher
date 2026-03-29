import 'package:coach_for_life/features/planning/application/override_rules.dart';
import 'package:coach_for_life/features/execution/domain/models/timer_session.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTask _task({
  int priority = 3,
  bool strictModeRequired = false,
  String? modeRefId,
}) {
  return PlannedTask(
    id: 't1',
    routineId: 'r1',
    blockId: 'b1',
    title: 'Task',
    durationMinutes: 25,
    priority: priority,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: 1,
    strictModeRequired: strictModeRequired,
    modeRefId: modeRefId,
  );
}

void main() {
  group('OverrideRules.requiresStrictOverrideConfirm', () {
    test('true for high priority', () {
      expect(OverrideRules.requiresStrictOverrideConfirm(_task(priority: 1)), isTrue);
    });

    test('true for strict-mode-required task', () {
      expect(
        OverrideRules.requiresStrictOverrideConfirm(_task(strictModeRequired: true)),
        isTrue,
      );
    });

    test('true for disciplined/extreme mode refs', () {
      expect(
        OverrideRules.requiresStrictOverrideConfirm(_task(modeRefId: 'disciplined')),
        isTrue,
      );
      expect(
        OverrideRules.requiresStrictOverrideConfirm(_task(modeRefId: 'EXTREME')),
        isTrue,
      );
    });

    test('false for normal priority and non-strict mode', () {
      expect(
        OverrideRules.requiresStrictOverrideConfirm(_task(priority: 4, modeRefId: 'flexible')),
        isFalse,
      );
    });
  });

  group('OverrideRules.isStrictConfirmInputValid', () {
    test('accepts confirm with spacing/case differences', () {
      expect(OverrideRules.isStrictConfirmInputValid('CONFIRM'), isTrue);
      expect(OverrideRules.isStrictConfirmInputValid(' confirm '), isTrue);
    });

    test('rejects other strings', () {
      expect(OverrideRules.isStrictConfirmInputValid('CONFIRM!'), isFalse);
      expect(OverrideRules.isStrictConfirmInputValid('OK'), isFalse);
      expect(OverrideRules.isStrictConfirmInputValid(''), isFalse);
    });
  });

  group('OverrideRules.requiresMandatoryTimer', () {
    test('true for strict mode task', () {
      expect(OverrideRules.requiresMandatoryTimer(_task(strictModeRequired: true)), isTrue);
      expect(OverrideRules.requiresMandatoryTimer(_task(modeRefId: 'disciplined')), isTrue);
      expect(OverrideRules.requiresMandatoryTimer(_task(modeRefId: 'extreme')), isTrue);
    });

    test('false for flexible task without strict flag', () {
      expect(OverrideRules.requiresMandatoryTimer(_task(modeRefId: 'flexible')), isFalse);
    });

    test('uses routine mode when task modeRefId missing', () {
      final routine = Routine(
        id: 'r1',
        title: 'Day',
        dateKey: '2026-01-01',
        orderIndex: 0,
        modeId: 'disciplined',
        mode: RoutineMode.disciplined,
        createdAtMs: 1,
        updatedAtMs: 2,
      );
      expect(
        OverrideRules.requiresMandatoryTimer(_task(modeRefId: null), routine: routine),
        isTrue,
      );
      expect(
        OverrideRules.requiresStrictOverrideConfirm(
          _task(priority: 4, modeRefId: null),
          routine: routine,
        ),
        isTrue,
      );
    });
  });

  group('OverrideRules.hasSatisfiedMandatoryTimer', () {
    test('true when ended task session exists with elapsed > 0', () {
      final sessions = [
        TimerSession(
          id: 's1',
          targetType: TimerSessionTargetType.task,
          taskId: 't1',
          startedAtMs: 1,
          endedAtMs: 2,
          elapsedSeconds: 20,
          createdAtMs: 1,
          updatedAtMs: 2,
        ),
      ];
      expect(OverrideRules.hasSatisfiedMandatoryTimer(sessions), isTrue);
    });

    test('false for running-only or block-only sessions', () {
      final sessions = [
        TimerSession(
          id: 's2',
          targetType: TimerSessionTargetType.task,
          taskId: 't1',
          startedAtMs: 1,
          endedAtMs: null,
          elapsedSeconds: 20,
          createdAtMs: 1,
          updatedAtMs: 2,
        ),
        TimerSession(
          id: 's3',
          targetType: TimerSessionTargetType.block,
          blockId: 'b1',
          startedAtMs: 1,
          endedAtMs: 2,
          elapsedSeconds: 20,
          createdAtMs: 1,
          updatedAtMs: 2,
        ),
      ];
      expect(OverrideRules.hasSatisfiedMandatoryTimer(sessions), isFalse);
    });
  });
}
