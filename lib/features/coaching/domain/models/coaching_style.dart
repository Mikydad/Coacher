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

  /// User-facing label shown in selection UI. Storage ids are unchanged;
  /// `disciplined` reads as Direct and `intense` as Tough (2026-09-25).
  String get displayName {
    switch (this) {
      case CoachingStyle.supportive:
        return 'Supportive';
      case CoachingStyle.balanced:
        return 'Balanced';
      case CoachingStyle.disciplined:
        return 'Direct';
      case CoachingStyle.intense:
        return 'Tough';
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
        return 'Straight to the point. Less encouragement, more action.';
      case CoachingStyle.intense:
        return 'Very direct. Challenges excuses and tells you what you may not want to hear.';
    }
  }

  /// Example of how each style frames a missed workout — shown on selection screen.
  String get exampleMissedWorkout {
    switch (this) {
      case CoachingStyle.supportive:
        return '"Hey, you missed your workout — that\'s okay. Want to fit in something shorter today?"';
      case CoachingStyle.balanced:
        return '"You missed your workout. Here\'s how to get back on track today."';
      case CoachingStyle.disciplined:
        return '"You skipped the workout you committed to. Do it now — a shorter one still counts."';
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
