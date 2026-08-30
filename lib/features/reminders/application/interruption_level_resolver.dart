import '../../context_override/domain/models/interruption_level.dart';

/// Maps enforcement mode + escalation level → [InterruptionLevel].
///
/// PRD FR-C-03 table:
/// | Condition                          | InterruptionLevel |
/// |------------------------------------|-------------------|
/// | flexible, any escalation           | low / medium      |
/// | disciplined, escalation 0–1        | medium            |
/// | disciplined, escalation ≥ 2        | high              |
/// | extreme, escalation 0–1            | high              |
/// | extreme, escalation ≥ 2            | critical          |
/// | emergencyBypass == true            | critical          |
abstract final class InterruptionLevelResolver {
  static InterruptionLevel resolve({
    required String enforcementMode,
    required int escalationLevel,
    required bool emergencyBypass,
  }) {
    if (emergencyBypass) return InterruptionLevel.critical;

    final mode = enforcementMode.trim().toLowerCase();

    switch (mode) {
      case 'extreme':
        return escalationLevel >= 2
            ? InterruptionLevel.critical
            : InterruptionLevel.high;

      case 'disciplined':
        return escalationLevel >= 2
            ? InterruptionLevel.high
            : InterruptionLevel.medium;

      case 'flexible':
      default:
        // High urgency scores can bump flexible to medium; default to low.
        return escalationLevel >= 1
            ? InterruptionLevel.medium
            : InterruptionLevel.low;
    }
  }

  /// One step more interruptive — the focus-boost upgrade (FR-R-44).
  ///
  /// Mirrors `AttentionOrchestrator._upgradeLevel`, which computed a boosted
  /// level and then dropped it: the decision recorded `priorityBoosted` but
  /// not the level it produced, so the boost never reached the OS.
  static InterruptionLevel upgrade(InterruptionLevel level) =>
      switch (level) {
        InterruptionLevel.low => InterruptionLevel.medium,
        InterruptionLevel.medium => InterruptionLevel.high,
        InterruptionLevel.high => InterruptionLevel.critical,
        InterruptionLevel.critical => InterruptionLevel.critical,
      };
}
