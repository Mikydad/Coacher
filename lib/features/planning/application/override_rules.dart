import '../domain/models/routine.dart';
import '../domain/models/task_item.dart';
import '../../execution/domain/models/timer_session.dart';
import 'effective_task_mode.dart';

abstract final class OverrideRules {
  static bool requiresStrictOverrideConfirm(
    PlannedTask task, {
    Routine? routine,
  }) {
    if (task.priority <= 2) return true;
    if (task.strictModeRequired) return true;
    final mode = EffectiveTaskMode.effectiveModeRefId(
      task: task,
      routine: routine,
    );
    if (mode == 'disciplined' || mode == 'extreme') return true;
    return false;
  }

  static bool isStrictConfirmInputValid(String value) {
    return value.trim().toUpperCase() == 'CONFIRM';
  }

  static bool requiresMandatoryTimer(PlannedTask task, {Routine? routine}) {
    if (task.strictModeRequired) return true;
    final mode = EffectiveTaskMode.effectiveModeRefId(
      task: task,
      routine: routine,
    );
    if (mode == 'disciplined' || mode == 'extreme') return true;
    return false;
  }

  /// The least focus that counts as "timed" (Miko, 2026-09-27): any ended
  /// session above 0s used to pass, so a 2-second start/end satisfied
  /// "Timer required".
  static const mandatoryTimerMinSeconds = 60;

  /// One ended task session of at least [mandatoryTimerMinSeconds]. Not a
  /// sum: a resumed session's elapsed already includes the earlier part.
  static bool hasSatisfiedMandatoryTimer(List<TimerSession> sessions) {
    for (final s in sessions) {
      if (s.targetType != TimerSessionTargetType.task) continue;
      if (s.endedAtMs != null && s.elapsedSeconds >= mandatoryTimerMinSeconds) {
        return true;
      }
    }
    return false;
  }
}
