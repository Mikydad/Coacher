/// Validates informational assistant text stays human-readable (PRD §4.12).
abstract final class AiInformationalOutputGuard {
  static const _forbiddenTokens = [
    'periodStartMs',
    'periodEndMs',
    'parsedActionsJson',
    'isarId',
    'sessionId',
    'responseType',
    'actionType',
    'Firestore',
    'documentId',
    'timestampMs',
    'reminderTimeIso',
  ];

  static final _uuidPattern = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );

  /// Returns true when [text] appears to leak internal schema or IDs.
  static bool looksLikeInternalLeak(String text) {
    if (text.trim().isEmpty) return false;
    if (_uuidPattern.hasMatch(text)) return true;
    final lower = text.toLowerCase();
    return _forbiddenTokens.any(
      (token) => lower.contains(token.toLowerCase()),
    );
  }

  /// Returns [text] unchanged, or a safe fallback when internal details leak.
  static String sanitize(String text) {
    if (!looksLikeInternalLeak(text)) return text;
    return 'I pulled that from your schedule, but hid internal details. '
        'Try asking about a specific day or task by name.';
  }
}
