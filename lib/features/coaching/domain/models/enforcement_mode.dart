/// Per-entity enforcement intensity.
///
/// Controls escalation speed, streak sensitivity, recovery tolerance, and
/// urgency weighting in [FocusScoringEngine].
///
/// Stored as a plain string in [ReminderConfig.modeRefId] — the storage
/// format matches the existing `"flexible"` / `"disciplined"` / `"extreme"`
/// values, so no migration is needed.
///
/// Global coaching philosophy is controlled separately by [CoachingStyle].
enum EnforcementMode {
  flexible,
  disciplined,
  extreme;

  // ── Serialization ─────────────────────────────────────────────────────────

  /// Parses the stored string value from [ReminderConfig.modeRefId].
  /// Falls back to [disciplined] for unknown or null values.
  static EnforcementMode fromStorage(String? value) =>
      fromModeRefId(value);

  /// Alias for [fromStorage] — accepts the modeRefId string used on
  /// [ReminderConfig] and task/habit records.
  static EnforcementMode fromModeRefId(String? modeRefId) {
    switch (modeRefId?.trim().toLowerCase()) {
      case 'flexible':
        return EnforcementMode.flexible;
      case 'extreme':
        return EnforcementMode.extreme;
      default:
        return EnforcementMode.disciplined;
    }
  }

  String toStorage() => name;

  // ── Display helpers ───────────────────────────────────────────────────────

  /// User-facing label for the per-entity edit screen.
  String get displayName {
    switch (this) {
      case EnforcementMode.flexible:
        return 'Flexible';
      case EnforcementMode.disciplined:
        return 'Disciplined';
      case EnforcementMode.extreme:
        return 'Extreme';
    }
  }

  /// Short UI label for segmented control.
  String get uiLabel => displayName;

  /// One-sentence description shown on the per-entity mode selector.
  String get description {
    switch (this) {
      case EnforcementMode.flexible:
        return 'Reminders are gentle. Missing a day is okay.';
      case EnforcementMode.disciplined:
        return 'Hold me accountable. Streaks matter.';
      case EnforcementMode.extreme:
        return 'No excuses. Follow up until I act.';
    }
  }
}
