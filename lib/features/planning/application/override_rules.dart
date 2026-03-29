import '../domain/models/routine.dart';
import '../domain/models/task_item.dart';
import '../../execution/domain/models/timer_session.dart';
import 'effective_task_mode.dart';

abstract final class OverrideRules {
  static bool requiresStrictOverrideConfirm(PlannedTask task, {Routine? routine}) {
    if (task.priority <= 2) return true;
    if (task.strictModeRequired) return true;
    final mode = EffectiveTaskMode.effectiveModeRefId(task: task, routine: routine);
    if (mode == 'disciplined' || mode == 'extreme') return true;
    return false;
  }

  static bool isStrictConfirmInputValid(String value) {
    return value.trim().toUpperCase() == 'CONFIRM';
  }

  static bool requiresMandatoryTimer(PlannedTask task, {Routine? routine}) {
    if (task.strictModeRequired) return true;
    final mode = EffectiveTaskMode.effectiveModeRefId(task: task, routine: routine);
    if (mode == 'disciplined' || mode == 'extreme') return true;
    return false;
  }

  static bool hasSatisfiedMandatoryTimer(List<TimerSession> sessions) {
    for (final s in sessions) {
      if (s.targetType != TimerSessionTargetType.task) continue;
      if ((s.elapsedSeconds) > 0 && s.endedAtMs != null) return true;
    }
    return false;
  }
}
