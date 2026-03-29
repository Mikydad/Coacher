import '../domain/models/routine.dart';
import '../domain/models/routine_mode.dart';
import '../domain/models/task_item.dart';

/// Single place for “which execution mode applies to this task right now?”.
///
/// Goal intensity uses the same mode concept via `GoalIntensityMode` in
/// `lib/features/goals/application/goal_intensity_mode.dart`.
///
/// Precedence:
/// 1. [PlannedTask.modeRefId] when it is a known built-in id (`flexible`, `disciplined`, `extreme`).
/// 2. [Routine.modeId] when it matches a known id; else [Routine.mode].
/// 3. `flexible`.
///
/// Unknown / legacy `modeRefId` values on the task are ignored so we fall back to the routine
/// or default (avoids typos locking the user into the wrong policy).
abstract final class EffectiveTaskMode {
  static const _known = {'flexible', 'disciplined', 'extreme'};

  static String effectiveModeRefId({
    required PlannedTask task,
    Routine? routine,
  }) {
    final tRaw = task.modeRefId?.trim().toLowerCase();
    if (tRaw != null && tRaw.isNotEmpty && _known.contains(tRaw)) {
      return tRaw;
    }

    if (routine != null) {
      final idRaw = routine.modeId.trim().toLowerCase();
      if (idRaw.isNotEmpty && _known.contains(idRaw)) {
        return idRaw;
      }
      final m = routine.mode.name;
      if (_known.contains(m)) {
        return m;
      }
    }

    return 'flexible';
  }

  static RoutineMode routineModeForTask({
    required PlannedTask task,
    Routine? routine,
  }) {
    return routineModeFromRefId(effectiveModeRefId(task: task, routine: routine));
  }

  static RoutineMode routineModeFromRefId(String refId) {
    final raw = refId.trim().toLowerCase();
    return switch (raw) {
      'disciplined' => RoutineMode.disciplined,
      'extreme' => RoutineMode.extreme,
      _ => RoutineMode.flexible,
    };
  }
}
