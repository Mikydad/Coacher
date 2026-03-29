import '../../planning/domain/models/routine_mode.dart';

class ReminderCadence {
  const ReminderCadence({
    required this.initialSnoozeMinutes,
    required this.minSnoozeMinutes,
    required this.maxEscalationLevel,
    required this.allowHardGate,
  });

  final int initialSnoozeMinutes;
  final int minSnoozeMinutes;
  final int maxEscalationLevel;
  final bool allowHardGate;
}

class EscalationDecision {
  const EscalationDecision({
    required this.nextEscalationLevel,
    required this.snoozeMinutes,
    required this.requireAppOpenNudge,
    required this.enableNonEssentialActionGate,
  });

  final int nextEscalationLevel;
  final int snoozeMinutes;
  final bool requireAppOpenNudge;
  final bool enableNonEssentialActionGate;
}

abstract final class AdaptiveReminderPolicy {
  static ReminderCadence cadenceFor({
    required String? modeRefId,
    required int blockUrgencyScore,
  }) {
    final mode = _modeFromRef(modeRefId);
    final urgency = blockUrgencyScore.clamp(0, 100);
    switch (mode) {
      case RoutineMode.extreme:
        if (urgency >= 80) {
          return const ReminderCadence(
            initialSnoozeMinutes: 3,
            minSnoozeMinutes: 1,
            maxEscalationLevel: 4,
            allowHardGate: true,
          );
        }
        return const ReminderCadence(
          initialSnoozeMinutes: 5,
          minSnoozeMinutes: 2,
          maxEscalationLevel: 4,
          allowHardGate: true,
        );
      case RoutineMode.disciplined:
        if (urgency >= 80) {
          return const ReminderCadence(
            initialSnoozeMinutes: 5,
            minSnoozeMinutes: 2,
            maxEscalationLevel: 3,
            allowHardGate: false,
          );
        }
        return const ReminderCadence(
          initialSnoozeMinutes: 8,
          minSnoozeMinutes: 3,
          maxEscalationLevel: 3,
          allowHardGate: false,
        );
      case RoutineMode.flexible:
        if (urgency >= 80) {
          return const ReminderCadence(
            initialSnoozeMinutes: 8,
            minSnoozeMinutes: 4,
            maxEscalationLevel: 2,
            allowHardGate: false,
          );
        }
        return const ReminderCadence(
          initialSnoozeMinutes: 12,
          minSnoozeMinutes: 5,
          maxEscalationLevel: 2,
          allowHardGate: false,
        );
    }
  }

  static EscalationDecision nextStep({
    required ReminderCadence cadence,
    required int currentEscalationLevel,
    required bool emergencyBypass,
  }) {
    final nextLevel = (currentEscalationLevel + 1).clamp(1, cadence.maxEscalationLevel);
    final decayedSnooze = cadence.initialSnoozeMinutes - (nextLevel - 1) * 2;
    final snoozeMinutes = decayedSnooze < cadence.minSnoozeMinutes
        ? cadence.minSnoozeMinutes
        : decayedSnooze;
    final requireAppOpenNudge = nextLevel >= 2;
    final gateEligible = cadence.allowHardGate && nextLevel >= 3;
    return EscalationDecision(
      nextEscalationLevel: nextLevel,
      snoozeMinutes: snoozeMinutes,
      requireAppOpenNudge: requireAppOpenNudge,
      enableNonEssentialActionGate: gateEligible && !emergencyBypass,
    );
  }

  static RoutineMode _modeFromRef(String? modeRefId) {
    final raw = modeRefId?.trim().toLowerCase();
    if (raw == 'disciplined') return RoutineMode.disciplined;
    if (raw == 'extreme') return RoutineMode.extreme;
    return RoutineMode.flexible;
  }
}
