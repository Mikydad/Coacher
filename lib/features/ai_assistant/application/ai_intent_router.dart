import '../domain/models/ai_intent_kind.dart';

/// Hybrid intent router — fast keyword rules before the LLM call.
abstract final class AiIntentRouter {
  static const _queryKeywords = [
    'what',
    'show',
    'tell me',
    'list',
    'how many',
    'when ',
    'how am i',
    "what's",
    'whats',
  ];

  static const _suggestKeywords = [
    'help me plan',
    'help me with',
    'help plan',
    'suggest',
    'recommend',
    'optimize',
    'fill my',
    'plan my',
    'plan out',
  ];

  /// Questions ABOUT the app or a feature. Checked before mutate verbs:
  /// "explain how to set a reminder" contains ' set ' but must route query.
  static const _educationKeywords = [
    'what is',
    'what are',
    'how do i',
    'how do you',
    'how does',
    'how to use',
    'explain',
    'teach me',
    'tell me about',
    'which mode',
    'what does',
  ];

  static AiIntentRoute classify(String userInput) {
    final lower = userInput.toLowerCase().trim();
    final focusDate = _detectFocusDate(lower);

    if (_educationKeywords.any(lower.contains)) {
      return AiIntentRoute(kind: AiIntentKind.query, focusDate: focusDate);
    }

    if (_hasMutateKeyword(lower)) {
      return AiIntentRoute(kind: AiIntentKind.mutate, focusDate: focusDate);
    }

    if (_isQuery(lower)) {
      return AiIntentRoute(kind: AiIntentKind.query, focusDate: focusDate);
    }

    if (_isSuggest(lower)) {
      return AiIntentRoute(kind: AiIntentKind.suggest, focusDate: focusDate);
    }

    // Imperative "plan tomorrow" without a question word → suggest.
    if (_isImperativePlan(lower)) {
      return AiIntentRoute(kind: AiIntentKind.suggest, focusDate: focusDate);
    }

    return AiIntentRoute(kind: AiIntentKind.mutate, focusDate: focusDate);
  }

  static AiFocusDate? _detectFocusDate(String lower) {
    if (lower.contains('tomorrow')) return AiFocusDate.tomorrow;
    if (lower.contains('today')) return AiFocusDate.today;
    if (lower.contains('this week') ||
        lower.contains('next week') ||
        lower.contains(' week')) {
      return AiFocusDate.week;
    }
    return null;
  }

  static bool _hasMutateKeyword(String lower) {
    const prefixVerbs = [
      'add ',
      'create ',
      'delete ',
      'remove ',
      'move ',
      'schedule ',
      'enable ',
      'set ',
      'cancel ',
    ];
    if (prefixVerbs.any(lower.startsWith)) return true;

    const embeddedVerbs = [
      ' add ',
      ' create ',
      ' delete ',
      ' remove ',
      ' move ',
      ' enable ',
      ' set ',
      ' cancel ',
    ];
    return embeddedVerbs.any(lower.contains);
  }

  static bool _isQuery(String lower) {
    final hasQueryWord = _queryKeywords.any(lower.contains);
    if (!hasQueryWord) return false;

    const scheduleWords = [
      'plan',
      'schedule',
      'tomorrow',
      'today',
      'goal',
      'on my',
      'doing on',
    ];
    final hasScheduleContext =
        scheduleWords.any(lower.contains) || lower.endsWith('?');
    return hasScheduleContext;
  }

  static bool _isSuggest(String lower) {
    if (_suggestKeywords.any(lower.contains)) return true;
    return _isImperativePlan(lower);
  }

  /// "Plan tomorrow" / "plan my day" without question words.
  static bool _isImperativePlan(String lower) {
    if (lower.contains('what') || lower.contains('show')) return false;
    if (!lower.contains('plan')) return false;
    return lower.contains('help') ||
        lower.contains('my ') ||
        lower.contains('tomorrow') ||
        lower.contains('today') ||
        lower.startsWith('plan ');
  }
}
