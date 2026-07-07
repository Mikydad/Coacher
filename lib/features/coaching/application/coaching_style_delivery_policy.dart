import '../domain/models/coaching_style.dart';

/// Governs how aggressively the app persists with notification follow-ups
/// based on the user's global [CoachingStyle].
///
/// All functions are pure / static — no I/O, fully unit-testable.
///
/// **Back-off rules (FR-D-15 / FR-D-16):**
/// | Style        | Back-off trigger                        | Effect                                      |
/// |--------------|----------------------------------------|---------------------------------------------|
/// | supportive   | 2 consecutive ignored notifications    | Suppress follow-ups for 4 h                 |
/// | balanced     | Standard Phase C escalation            | No additional back-off                      |
/// | disciplined  | Full escalation reached                | Continue at tail frequency until resolved   |
/// | intense      | Only sleep/DND context override        | Never backs off voluntarily                 |
abstract final class CoachingStyleDeliveryPolicy {
  // ── Back-off ──────────────────────────────────────────────────────────────

  /// Returns `true` when the orchestrator should stop sending follow-up
  /// notifications based on the user's coaching style and how many
  /// notifications have been consecutively ignored.
  ///
  /// [consecutiveIgnoredCount] is the number of consecutive notifications
  /// for this entity that were delivered but received no interaction (no tap,
  /// snooze, or dismiss) before the [kIgnoredTimeoutMinutes] window elapsed.
  static bool shouldBackOff(CoachingStyle style, int consecutiveIgnoredCount) {
    return switch (style) {
      CoachingStyle.supportive => consecutiveIgnoredCount >= 2,
      CoachingStyle.balanced => false,
      CoachingStyle.disciplined => false,
      CoachingStyle.intense => false,
    };
  }

  /// Duration in minutes to suppress follow-ups once a back-off is triggered.
  /// Returns 0 for styles that never back off voluntarily.
  static int backOffDurationMinutes(CoachingStyle style) {
    return switch (style) {
      CoachingStyle.supportive => 240, // 4 hours
      CoachingStyle.balanced => 0,
      CoachingStyle.disciplined => 0,
      CoachingStyle.intense => 0,
    };
  }

  // ── Persistence philosophy helpers ────────────────────────────────────────

  /// Whether this style should continue escalating after reaching the tail
  /// frequency (instead of stopping after [tailRepeatCount]).
  static bool continuesAtTailAfterFullEscalation(CoachingStyle style) {
    return switch (style) {
      CoachingStyle.supportive => false,
      CoachingStyle.balanced => false,
      CoachingStyle.disciplined => true,
      CoachingStyle.intense => true,
    };
  }

  /// Returns the maximum consecutive ignored count before this style would
  /// signal that the user has clearly disengaged and no further follow-ups
  /// should be scheduled (value of `null` means "never stop automatically").
  static int? maxIgnoredBeforeGivingUp(CoachingStyle style) {
    return switch (style) {
      CoachingStyle.supportive => 2,
      CoachingStyle.balanced => null,
      CoachingStyle.disciplined => null,
      CoachingStyle.intense => null,
    };
  }
}
