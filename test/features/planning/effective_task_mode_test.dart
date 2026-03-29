import 'package:coach_for_life/features/planning/application/effective_task_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedTask _task({String? modeRefId}) {
  return PlannedTask(
    id: 't1',
    routineId: 'r1',
    blockId: 'b1',
    title: 'T',
    durationMinutes: 10,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: 1,
    modeRefId: modeRefId,
  );
}

Routine _routine({
  String modeId = 'flexible',
  RoutineMode mode = RoutineMode.flexible,
}) {
  return Routine(
    id: 'r1',
    title: 'Day',
    dateKey: '2026-01-01',
    orderIndex: 0,
    modeId: modeId,
    mode: mode,
    createdAtMs: 1,
    updatedAtMs: 2,
  );
}

void main() {
  group('EffectiveTaskMode.effectiveModeRefId', () {
    test('uses known task mode over routine', () {
      final out = EffectiveTaskMode.effectiveModeRefId(
        task: _task(modeRefId: 'disciplined'),
        routine: _routine(modeId: 'extreme', mode: RoutineMode.extreme),
      );
      expect(out, 'disciplined');
    });

    test('ignores unknown task ref and falls back to routine', () {
      final out = EffectiveTaskMode.effectiveModeRefId(
        task: _task(modeRefId: 'legacy_custom'),
        routine: _routine(modeId: 'extreme', mode: RoutineMode.extreme),
      );
      expect(out, 'extreme');
    });

    test('uses routine when task mode missing', () {
      final out = EffectiveTaskMode.effectiveModeRefId(
        task: _task(modeRefId: null),
        routine: _routine(modeId: 'disciplined', mode: RoutineMode.disciplined),
      );
      expect(out, 'disciplined');
    });

    test('uses routine.mode when modeId unknown but enum set', () {
      final out = EffectiveTaskMode.effectiveModeRefId(
        task: _task(modeRefId: null),
        routine: _routine(modeId: 'custom_algo_label', mode: RoutineMode.disciplined),
      );
      expect(out, 'disciplined');
    });

    test('defaults flexible without routine', () {
      expect(
        EffectiveTaskMode.effectiveModeRefId(task: _task(modeRefId: null), routine: null),
        'flexible',
      );
    });

    test('normalizes casing on task ref', () {
      expect(
        EffectiveTaskMode.effectiveModeRefId(task: _task(modeRefId: ' EXTREME '), routine: null),
        'extreme',
      );
    });
  });

  group('EffectiveTaskMode.routineModeFromRefId', () {
    test('maps to enum', () {
      expect(
        EffectiveTaskMode.routineModeFromRefId('disciplined'),
        RoutineMode.disciplined,
      );
      expect(EffectiveTaskMode.routineModeFromRefId('nope'), RoutineMode.flexible);
    });
  });
}
