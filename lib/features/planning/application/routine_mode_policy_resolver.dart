import '../domain/models/routine_mode.dart';

/// Derives effective execution policy from base mode + context.
///
/// Context knobs are intentionally simple in V2. They can be expanded later
/// (e.g. AI confidence, task history, user fatigue index) without changing
/// call sites that just ask for the effective policy.
class RoutineModePolicyResolver {
  const RoutineModePolicyResolver();

  RoutineModePolicy resolve({
    required RoutineModeConfig config,
    required int taskPriority,
    required int urgencyScore,
    bool strictTaskRequired = false,
  }) {
    final clampedPriority = taskPriority.clamp(1, 5);
    final clampedUrgency = urgencyScore.clamp(0, 100);
    var effective = config.policy;

    // Tighten policy for explicit strict tasks.
    if (strictTaskRequired) {
      effective = _tightenStrictTask(effective);
    }

    // High-priority tasks (1-2) get stricter handling.
    if (clampedPriority <= 2) {
      effective = _tightenHighPriority(effective);
    }

    // Urgent tasks near block boundary get shorter snoozes and less extension.
    if (clampedUrgency >= 80) {
      effective = _tightenUrgent(effective);
    } else if (clampedUrgency >= 60) {
      effective = _tightenModeratelyUrgent(effective);
    }

    return effective;
  }

  RoutineModePolicy _tightenStrictTask(RoutineModePolicy p) {
    return p.copyWith(
      requireTimerForCompletion: true,
      allowHardGate: p.allowHardGate || p.mode == RoutineMode.extreme,
      baseSnoozeMinutes: p.baseSnoozeMinutes > 5 ? p.baseSnoozeMinutes - 5 : 5,
      maxExtensionMinutes: p.maxExtensionMinutes > 30 ? 30 : p.maxExtensionMinutes,
      requireReasonForDeferral: true,
    );
  }

  RoutineModePolicy _tightenHighPriority(RoutineModePolicy p) {
    return p.copyWith(
      requireTimerForCompletion: true,
      allowHardGate: p.allowHardGate || p.mode == RoutineMode.extreme,
      baseSnoozeMinutes: p.baseSnoozeMinutes > 5 ? p.baseSnoozeMinutes - 5 : 5,
      maxExtensionMinutes: p.maxExtensionMinutes > 45 ? 45 : p.maxExtensionMinutes,
      requireReasonForDeferral: true,
    );
  }

  RoutineModePolicy _tightenModeratelyUrgent(RoutineModePolicy p) {
    return p.copyWith(
      baseSnoozeMinutes: p.baseSnoozeMinutes > 5 ? p.baseSnoozeMinutes - 5 : 5,
      maxExtensionMinutes: p.maxExtensionMinutes > 45 ? 45 : p.maxExtensionMinutes,
    );
  }

  RoutineModePolicy _tightenUrgent(RoutineModePolicy p) {
    return p.copyWith(
      requireTimerForCompletion: true,
      allowHardGate: p.allowHardGate || p.mode == RoutineMode.extreme,
      baseSnoozeMinutes: 5,
      maxExtensionMinutes: p.maxExtensionMinutes > 30 ? 30 : p.maxExtensionMinutes,
      requireReasonForDeferral: true,
    );
  }
}
