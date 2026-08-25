import '../domain/models/context_override.dart';
import '../domain/models/interruption_level.dart';

/// Pure static class — no constructor, no state, no I/O.
/// Same input always produces the same output (fully deterministic).
///
/// Suppression table (from PRD FR-B-04):
///
/// | Override       | Suppresses              | Allows               |
/// |----------------|-------------------------|----------------------|
/// | none           | nothing                 | everything           |
/// | meeting        | low, medium             | high, critical       |
/// | focus          | low, medium             | high, critical       |
/// | sleep          | low, medium, high       | critical only        |
/// | vacation       | low, medium, high       | critical only        |
/// | doNotDisturb   | low, medium, high, crit | nothing              |
abstract final class OverrideAttentionPolicy {
  // ─── Core suppression check ───────────────────────────────────────────────

  /// Returns true if the notification at [level] should be suppressed
  /// while [override] is active.
  static bool shouldSuppress(
    InterruptionLevel level,
    ContextOverride override,
  ) {
    switch (override) {
      case ContextOverride.none:
        return false;

      case ContextOverride.meeting:
      case ContextOverride.focus:
        return level == InterruptionLevel.low ||
            level == InterruptionLevel.medium;

      case ContextOverride.sleep:
      case ContextOverride.vacation:
        return level == InterruptionLevel.low ||
            level == InterruptionLevel.medium ||
            level == InterruptionLevel.high;

      case ContextOverride.doNotDisturb:
        return true;
    }
  }

  // ─── Minimum allowed level ────────────────────────────────────────────────

  /// Returns the lowest [InterruptionLevel] that passes through [override].
  ///
  /// Used by UI to show "allows urgent alerts" / "critical only" summaries.
  static InterruptionLevel allowedMinimumLevel(ContextOverride override) {
    switch (override) {
      case ContextOverride.none:
        return InterruptionLevel.low;
      case ContextOverride.meeting:
      case ContextOverride.focus:
        return InterruptionLevel.high;
      case ContextOverride.sleep:
      case ContextOverride.vacation:
        return InterruptionLevel.critical;
      case ContextOverride.doNotDisturb:
        // Nothing gets through — return a level beyond critical as a sentinel.
        // Callers should treat doNotDisturb as "nothing allowed".
        return InterruptionLevel.critical;
    }
  }

  /// Returns true if [override] allows nothing through at all.
  static bool suppressesAll(ContextOverride override) =>
      override == ContextOverride.doNotDisturb;

  // ─── Suppression summary for UI ───────────────────────────────────────────

  /// Human-readable one-liner shown beneath each option in the quick-activate
  /// bottom sheet.
  // Every summary names SidePal explicitly (2026-08-25): "Do Not Disturb /
  // Holds everything" read as phone-wide DND, which no app can do — the
  // copy must never promise more than the app controls.
  static String suppressionSummary(ContextOverride override) {
    switch (override) {
      case ContextOverride.none:
        return 'All SidePal notifications active.';
      case ContextOverride.meeting:
        return 'Holds standard SidePal reminders. Urgent alerts still get '
            'through.';
      case ContextOverride.focus:
        return 'Holds low and medium SidePal reminders. Urgent alerts still '
            'get through.';
      case ContextOverride.sleep:
        return 'Holds all SidePal reminders. Only critical emergency alerts '
            'bypass.';
      case ContextOverride.vacation:
        return 'Holds all SidePal reminders and protects your streaks.';
      case ContextOverride.doNotDisturb:
        return 'Holds every SidePal notification. Your phone\'s own '
            'Do Not Disturb is untouched.';
    }
  }
}
