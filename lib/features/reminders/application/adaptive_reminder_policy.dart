import '../../coaching/domain/models/enforcement_mode.dart';
import '../../planning/domain/models/routine_mode.dart';

class ReminderRepeatStage {
  const ReminderRepeatStage({
    required this.durationMinutes,
    required this.nudges,
  });

  final int durationMinutes;
  final int nudges;
}

class ReminderRepeatPlan {
  const ReminderRepeatPlan({
    required this.stages,
    required this.tailEveryMinutes,
    required this.tailRepeatCount,
  });

  final List<ReminderRepeatStage> stages;
  final int tailEveryMinutes;
  final int tailRepeatCount;
}

class ReminderCadence {
  const ReminderCadence({
    required this.initialSnoozeMinutes,
    required this.minSnoozeMinutes,
    required this.maxEscalationLevel,
    required this.allowHardGate,
    required this.autoRepeatEnabled,
    required this.repeatPlan,
    this.maxFutureNudges = 24,
  });

  final int initialSnoozeMinutes;
  final int minSnoozeMinutes;
  final int maxEscalationLevel;
  final bool allowHardGate;
  final bool autoRepeatEnabled;
  final ReminderRepeatPlan repeatPlan;
  final int maxFutureNudges;
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
  /// Returns a [ReminderCadence] for the given enforcement intensity.
  ///
  /// [enforcementMode] takes precedence over [modeRefId] when provided
  /// (FR-D-24). If only [modeRefId] is supplied, it is parsed as before
  /// for backward compatibility with existing callers.
  static ReminderCadence cadenceFor({
    required String? modeRefId,
    required int blockUrgencyScore,
    EnforcementMode? enforcementMode,
  }) {
    final mode = enforcementMode != null
        ? _modeFromEnforcement(enforcementMode)
        : _modeFromRef(modeRefId);
    final urgency = blockUrgencyScore.clamp(0, 100);
    switch (mode) {
      case RoutineMode.extreme:
        if (urgency >= 80) {
          return const ReminderCadence(
            initialSnoozeMinutes: 3,
            minSnoozeMinutes: 1,
            maxEscalationLevel: 4,
            allowHardGate: true,
            autoRepeatEnabled: true,
            repeatPlan: ReminderRepeatPlan(
              stages: [
                ReminderRepeatStage(durationMinutes: 10, nudges: 3),
                ReminderRepeatStage(durationMinutes: 30, nudges: 5),
              ],
              tailEveryMinutes: 60,
              tailRepeatCount: 5,
            ),
          );
        }
        return const ReminderCadence(
          initialSnoozeMinutes: 5,
          minSnoozeMinutes: 2,
          maxEscalationLevel: 4,
          allowHardGate: true,
          autoRepeatEnabled: true,
          repeatPlan: ReminderRepeatPlan(
            stages: [
              ReminderRepeatStage(durationMinutes: 10, nudges: 3),
              ReminderRepeatStage(durationMinutes: 30, nudges: 5),
            ],
            tailEveryMinutes: 60,
            tailRepeatCount: 5,
          ),
        );
      case RoutineMode.disciplined:
        if (urgency >= 80) {
          return const ReminderCadence(
            initialSnoozeMinutes: 5,
            minSnoozeMinutes: 2,
            maxEscalationLevel: 3,
            allowHardGate: false,
            autoRepeatEnabled: true,
            repeatPlan: ReminderRepeatPlan(
              stages: [
                ReminderRepeatStage(durationMinutes: 10, nudges: 3),
                ReminderRepeatStage(durationMinutes: 30, nudges: 3),
              ],
              tailEveryMinutes: 60,
              tailRepeatCount: 24,
            ),
          );
        }
        return const ReminderCadence(
          initialSnoozeMinutes: 8,
          minSnoozeMinutes: 3,
          maxEscalationLevel: 3,
          allowHardGate: false,
          autoRepeatEnabled: true,
          repeatPlan: ReminderRepeatPlan(
            stages: [
              ReminderRepeatStage(durationMinutes: 10, nudges: 3),
              ReminderRepeatStage(durationMinutes: 30, nudges: 3),
            ],
            tailEveryMinutes: 60,
            tailRepeatCount: 24,
          ),
        );
      case RoutineMode.flexible:
        if (urgency >= 80) {
          return const ReminderCadence(
            initialSnoozeMinutes: 8,
            minSnoozeMinutes: 4,
            maxEscalationLevel: 2,
            allowHardGate: false,
            autoRepeatEnabled: false,
            repeatPlan: ReminderRepeatPlan(
              stages: [],
              tailEveryMinutes: 60,
              tailRepeatCount: 0,
            ),
            maxFutureNudges: 1,
          );
        }
        return const ReminderCadence(
          initialSnoozeMinutes: 12,
          minSnoozeMinutes: 5,
          maxEscalationLevel: 2,
          allowHardGate: false,
          autoRepeatEnabled: false,
          repeatPlan: ReminderRepeatPlan(
            stages: [],
            tailEveryMinutes: 60,
            tailRepeatCount: 0,
          ),
          maxFutureNudges: 1,
        );
    }
  }

  /// Returns absolute minute offsets *after* the first reminder fire.
  /// Example: [3, 6, 10, 20, ...]
  static List<int> autoRepeatOffsets(ReminderCadence cadence) {
    if (!cadence.autoRepeatEnabled) return const [];
    final out = <int>[];
    var elapsed = 0;
    for (final stage in cadence.repeatPlan.stages) {
      final end = elapsed + stage.durationMinutes;
      if (stage.nudges > 0 && stage.durationMinutes > 0) {
        for (var i = 1; i <= stage.nudges; i++) {
          final offset = elapsed + ((stage.durationMinutes * i) ~/ stage.nudges);
          if (offset > 0 && (out.isEmpty || out.last != offset)) out.add(offset);
        }
      }
      elapsed = end;
    }
    if (cadence.repeatPlan.tailEveryMinutes > 0) {
      for (var i = 1; i <= cadence.repeatPlan.tailRepeatCount; i++) {
        out.add(elapsed + i * cadence.repeatPlan.tailEveryMinutes);
      }
    }
    return out;
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

  /// Maps [EnforcementMode] → [RoutineMode] for cadence resolution.
  // ignore: deprecated_member_use_from_same_package
  static RoutineMode _modeFromEnforcement(EnforcementMode mode) {
    return switch (mode) {
      // ignore: deprecated_member_use_from_same_package
      EnforcementMode.flexible => RoutineMode.flexible,
      // ignore: deprecated_member_use_from_same_package
      EnforcementMode.disciplined => RoutineMode.disciplined,
      // ignore: deprecated_member_use_from_same_package
      EnforcementMode.extreme => RoutineMode.extreme,
    };
  }
}
