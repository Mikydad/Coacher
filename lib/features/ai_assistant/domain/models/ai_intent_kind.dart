/// Fast-path classification for Coach AI user utterances.
enum AiIntentKind {
  /// Read-only question about schedule, goals, or progress.
  query,

  /// Explicit create/move/delete/schedule request.
  mutate,

  /// Collaborative planning — narrative + optional draft actions.
  suggest,

  /// No keyword rule matched (AI chat fix plan Phase 1.3, decision D1).
  /// The turn takes the agent path with both tools and NO hint — the model
  /// decides whether anything changes. This replaced the old `mutate`
  /// default, whose "return structured actions for preview" hint primed
  /// plans for greetings, questions, and STT fragments.
  unknown,
}

/// Optional date focus detected in the user's message.
enum AiFocusDate { today, tomorrow, week }

/// Output of [AiIntentRouter.classify].
class AiIntentRoute {
  const AiIntentRoute({required this.kind, this.focusDate});

  final AiIntentKind kind;
  final AiFocusDate? focusDate;

  /// True for the turn shapes that need the full planning context
  /// (tomorrow, week, patterns): anything that may end in a plan.
  bool get isPlanningTurn =>
      kind == AiIntentKind.suggest ||
      kind == AiIntentKind.mutate ||
      kind == AiIntentKind.unknown;

  /// Human-readable hint injected into the LLM user prompt; null when the
  /// router has nothing trustworthy to say (D1: never steer on a guess).
  String? toPromptHint() {
    final focus = focusDate != null ? ' Focus date: ${focusDate!.name}.' : '';
    switch (kind) {
      case AiIntentKind.query:
        return 'User intent is QUERY — answer read-only from payload; do NOT return '
            'actions unless they explicitly ask to change something.$focus';
      case AiIntentKind.suggest:
        return 'User intent is SUGGEST — propose a plan in plain language with optional '
            'draft actions (Schema E). Do NOT treat as confirmed changes.$focus';
      case AiIntentKind.mutate:
        return 'The user seems to be asking for a change — if so, propose it with '
            'propose_changes for preview; if they are only asking or chatting, '
            'just answer.$focus';
      case AiIntentKind.unknown:
        return focus.isEmpty ? null : focus.trim();
    }
  }
}
