import '../domain/models/routine.dart';
import '../domain/models/routine_mode.dart';
import '../domain/models/task_item.dart';
import 'effective_task_mode.dart';
import 'routine_mode_policy_resolver.dart';

class ExtensionPolicyDecision {
  const ExtensionPolicyDecision({
    required this.allowedMaxMinutes,
    required this.requiresReason,
    required this.requiresReflectionPrompt,
  });

  final int allowedMaxMinutes;
  final bool requiresReason;
  final bool requiresReflectionPrompt;
}

abstract final class ExtensionPolicy {
  static ExtensionPolicyDecision forTask({
    required PlannedTask task,
    required RoutineModePolicyResolver resolver,
    required int blockUrgencyScore,
    Routine? routine,
  }) {
    final mode = EffectiveTaskMode.routineModeForTask(task: task, routine: routine);
    final config = RoutineModeConfig.defaults().firstWhere(
      (m) => m.baseMode == mode,
      orElse: () => RoutineModeConfig.defaults().first,
    );
    final effective = resolver.resolve(
      config: config,
      taskPriority: task.priority,
      urgencyScore: blockUrgencyScore,
      strictTaskRequired: task.strictModeRequired,
    );
    final allowedMaxMinutes = effective.maxExtensionMinutes.clamp(0, 60);
    return ExtensionPolicyDecision(
      allowedMaxMinutes: allowedMaxMinutes,
      requiresReason: effective.requireReasonForDeferral,
      // Product rule for v2: always show commitment reflection prompt.
      requiresReflectionPrompt: true,
    );
  }
}
