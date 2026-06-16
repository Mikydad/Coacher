/// How Coach AI should present a parsed turn to the user.
enum AiResponseType {
  /// Preview card → confirm → execute (default write path).
  mutate,

  /// Read-only answer from schedule/goal data — no confirm card.
  informational,

  /// Request needs a feature or dataset that is not available yet.
  unsupported,

  /// Clarifying question before planning (legacy follow-up path).
  followUp,
}

AiResponseType aiResponseTypeFromJson(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'informational':
      return AiResponseType.informational;
    case 'unsupported':
      return AiResponseType.unsupported;
    case 'followup':
    case 'follow_up':
    case 'follow-up':
      return AiResponseType.followUp;
    case 'mutate':
    default:
      return AiResponseType.mutate;
  }
}
