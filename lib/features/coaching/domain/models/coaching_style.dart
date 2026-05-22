/// Global, user-level coaching philosophy.
///
/// Controls AI tone, accountability framing, and persistence philosophy
/// across the entire app. There is exactly one [CoachingStyle] per user.
///
/// Per-entity enforcement intensity is controlled separately by [EnforcementMode].
enum CoachingStyle {
  supportive,
  balanced,
  disciplined,
  intense;

  // ── Serialization ─────────────────────────────────────────────────────────

  static CoachingStyle fromStorage(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'supportive':
        return CoachingStyle.supportive;
      case 'disciplined':
        return CoachingStyle.disciplined;
      case 'intense':
        return CoachingStyle.intense;
      default:
        return CoachingStyle.balanced;
    }
  }

  String toStorage() => name;

  // ── Display helpers ───────────────────────────────────────────────────────

  /// User-facing label shown in selection UI.
  String get displayName {
    switch (this) {
      case CoachingStyle.supportive:
        return 'Supportive';
      case CoachingStyle.balanced:
        return 'Balanced';
      case CoachingStyle.disciplined:
        return 'Disciplined';
      case CoachingStyle.intense:
        return 'Intense';
    }
  }

  /// One-sentence description for the coaching style selection screen.
  String get description {
    switch (this) {
      case CoachingStyle.supportive:
        return 'Warm encouragement, no guilt. The app cheers you on and backs off gently.';
      case CoachingStyle.balanced:
        return 'Clear and friendly. Facts, suggestions, and steady accountability.';
      case CoachingStyle.disciplined:
        return 'Direct and accountable. You committed to this — the app holds you to it.';
      case CoachingStyle.intense:
        return 'High standards, no excuses. The app pushes hard until you act.';
    }
  }

  /// Example of how each style frames a missed workout — shown on selection screen.
  String get exampleMissedWorkout {
    switch (this) {
      case CoachingStyle.supportive:
        return '"Hey, you missed your workout — that\'s okay. Want to fit in something shorter today?"';
      case CoachingStyle.balanced:
        return '"You missed your workout. You\'re 2 days into your streak — here\'s how to get back on track."';
      case CoachingStyle.disciplined:
        return '"You committed to this workout and skipped it. Streaks matter. Act now to recover."';
      case CoachingStyle.intense:
        return '"No workout. No excuses. You said this matters — prove it. Go now."';
    }
  }

  /// AI system prompt instruction for this style (used in AI summarization).
  String get aiSystemInstruction {
    switch (this) {
      case CoachingStyle.supportive:
        return 'Be warm and encouraging. Avoid guilt framing. Focus on small wins.';
      case CoachingStyle.balanced:
        return 'Be clear and friendly. Present facts and suggest action without pressure.';
      case CoachingStyle.disciplined:
        return 'Be direct. The user values accountability. State what\'s expected clearly.';
      case CoachingStyle.intense:
        return 'Be assertive. The user has high standards for themselves. Don\'t soften the message.';
    }
  }
}
