import '../domain/models/enforcement_mode.dart';

/// Pure static helper that translates [EnforcementMode] into numeric
/// multipliers and policy flags consumed by the scoring, streak, and
/// reminder systems.
///
/// All functions are pure / static — no I/O, fully unit-testable.
///
/// **Urgency weight (FR-D-17 / FR-D-18):**
/// | Mode         | urgencyScore multiplier |
/// |--------------|------------------------|
/// | flexible     | × 0.8                  |
/// | disciplined  | × 1.0 (baseline)       |
/// | extreme      | × 1.3                  |
///
/// **Streak sensitivity (FR-D-19):**
/// | Mode         | Grace period behavior                                     |
/// |--------------|----------------------------------------------------------|
/// | flexible     | 1 missed-day grace before streak breaks                  |
/// | disciplined  | No grace — streak breaks on first miss (current)         |
/// | extreme      | No grace + no partial credit for late completions         |
abstract final class EnforcementModePolicy {
  // ── Urgency multiplier ────────────────────────────────────────────────────

  /// Returns the multiplier to apply to a `FocusCandidate`'s `urgencyScore`.
  ///
  /// Usage:
  /// ```dart
  /// final adjusted = urgencyScore * EnforcementModePolicy.urgencyMultiplier(mode);
  /// ```
  static double urgencyMultiplier(EnforcementMode mode) {
    return switch (mode) {
      EnforcementMode.flexible => 0.8,
      EnforcementMode.disciplined => 1.0,
      EnforcementMode.extreme => 1.3,
    };
  }

  // ── Streak grace period ───────────────────────────────────────────────────

  /// Number of consecutive missed days allowed before a streak is broken.
  ///
  /// - `flexible` → 1 day of grace
  /// - `disciplined` → 0 (streak breaks immediately)
  /// - `extreme`  → 0 (streak breaks immediately; late completions also excluded)
  static int missedDayGracePeriod(EnforcementMode mode) {
    return switch (mode) {
      EnforcementMode.flexible => 1,
      EnforcementMode.disciplined => 0,
      EnforcementMode.extreme => 0,
    };
  }

  /// Whether only on-time completions count toward a streak.
  ///
  /// When `true` (only for `extreme`), a completion logged after the
  /// entity's scheduled deadline is treated as a miss for streak purposes.
  static bool onlyOnTimeCompletionsCountForStreak(EnforcementMode mode) {
    return switch (mode) {
      EnforcementMode.flexible => false,
      EnforcementMode.disciplined => false,
      EnforcementMode.extreme => true,
    };
  }

  // ── Recovery tolerance ────────────────────────────────────────────────────

  /// Minimum minutes to wait before re-escalating after the user recovers
  /// (e.g. completes a missed task). Lower = less tolerance for slipping back.
  static int recoveryGapMinutes(EnforcementMode mode) {
    return switch (mode) {
      EnforcementMode.flexible => 120, // 2 h cool-down
      EnforcementMode.disciplined => 30,
      EnforcementMode.extreme => 0, // follow up immediately
    };
  }
}
