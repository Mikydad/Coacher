import '../domain/models/enforcement_mode.dart';

/// Resolves the enforcement mode a **new** task should inherit when the user
/// has not picked one explicitly.
///
/// The profile-level [EnforcementMode] is treated as "how strict the app is
/// overall", scaled by how important the individual task is — so an Extreme
/// user is not nagged aggressively about low-stakes tasks (drink water),
/// while high-stakes tasks (submit the project) escalate hard.
///
/// | Importance          | Flexible    | Disciplined | Extreme     |
/// |---------------------|-------------|-------------|-------------|
/// | low  (priority ≤ 2) | flexible    | flexible    | disciplined |
/// | medium (priority 3) | flexible    | disciplined | disciplined |
/// | high (priority ≥ 4) | disciplined | disciplined | extreme     |
///
/// Importance is the stronger of two signals:
///   - task priority (1–5, clamped)
///   - parent block urgency (0–100): ≥ 80 counts as high, < 40 as low —
///     matching the ≥ 80 boost threshold in `AdaptiveReminderPolicy`.
///
/// Precedence note: this is only the *fallback*. An explicit per-task mode or
/// an inherited routine mode (see `EffectiveTaskMode`) always wins.
abstract final class DefaultModeResolver {
  /// Returns the modeRefId (`flexible` | `disciplined` | `extreme`) a new
  /// task should default to.
  static String resolveModeRefId({
    required EnforcementMode profileDefault,
    int priority = 3,
    int? blockUrgencyScore,
  }) {
    final band = _importanceBand(priority, blockUrgencyScore);
    switch (profileDefault) {
      case EnforcementMode.flexible:
        return band == _Band.high ? 'disciplined' : 'flexible';
      case EnforcementMode.disciplined:
        return band == _Band.low ? 'flexible' : 'disciplined';
      case EnforcementMode.extreme:
        return switch (band) {
          _Band.low => 'disciplined',
          _Band.medium => 'disciplined',
          _Band.high => 'extreme',
        };
    }
  }

  static _Band _importanceBand(int priority, int? blockUrgencyScore) {
    final p = priority.clamp(1, 5);
    final priorityBand = p <= 2
        ? _Band.low
        : p >= 4
            ? _Band.high
            : _Band.medium;
    if (blockUrgencyScore == null) return priorityBand;

    final u = blockUrgencyScore.clamp(0, 100);
    final urgencyBand = u >= 80
        ? _Band.high
        : u < 40
            ? _Band.low
            : _Band.medium;
    // The stronger signal wins so an urgent block lifts a default-priority
    // task, but a casual block never downgrades an explicitly important one.
    return priorityBand.index >= urgencyBand.index ? priorityBand : urgencyBand;
  }
}

enum _Band { low, medium, high }
