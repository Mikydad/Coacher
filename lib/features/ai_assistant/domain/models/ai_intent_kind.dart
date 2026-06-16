/// Fast-path classification for Coach AI user utterances.
enum AiIntentKind {
  /// Read-only question about schedule, goals, or progress.
  query,

  /// Explicit create/move/delete/schedule request.
  mutate,

  /// Collaborative planning — narrative + optional draft actions.
  suggest,
}

/// Optional date focus detected in the user's message.
enum AiFocusDate {
  today,
  tomorrow,
  week,
}

/// Output of [AiIntentRouter.classify].
class AiIntentRoute {
  const AiIntentRoute({
    required this.kind,
    this.focusDate,
  });

  final AiIntentKind kind;
  final AiFocusDate? focusDate;

  /// Human-readable hint injected into the LLM user prompt.
  String toPromptHint() {
    final focus = focusDate != null ? ' Focus date: ${focusDate!.name}.' : '';
    switch (kind) {
      case AiIntentKind.query:
        return 'User intent is QUERY — answer read-only from payload; do NOT return '
            'actions unless they explicitly ask to change something.$focus';
      case AiIntentKind.suggest:
        return 'User intent is SUGGEST — propose a plan in plain language with optional '
            'draft actions (Schema E). Do NOT treat as confirmed changes.$focus';
      case AiIntentKind.mutate:
        return 'User intent is MUTATE — return structured actions for preview.$focus';
    }
  }
}
