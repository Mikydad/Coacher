/// One teachable feature — the single source of truth for the Getting
/// Started onboarding, first-time feature cards, and Coach AI teaching.
/// The (future) Learning Center renders these same objects.
///
/// Content rules:
/// - Plain user language; no internal identifiers. Every string is checked
///   against [AiInformationalOutputGuard] by the registry test — a guide
///   containing a forbidden substring (e.g. "Firestore") would make the AI
///   swallow its own answer.
/// - Keywords are lowercase; the longest keyword wins topic matching.
class FeatureGuide {
  const FeatureGuide({
    required this.id,
    required this.title,
    required this.emoji,
    required this.oneLiner,
    required this.what,
    required this.why,
    required this.howSteps,
    this.tips = const [],
    required this.keywords,
    this.suggestedPrompts = const [],
    this.tryItRoute,
    this.tryItTabIndex,
  });

  final String id;
  final String title;
  final String emoji;

  /// Card headline, aim for <= ~60 chars.
  final String oneLiner;
  final String what;
  final String why;
  final List<String> howSteps;
  final List<String> tips;

  /// Lowercase phrases that identify this topic in a user's question.
  final List<String> keywords;

  /// Chips offered after the AI teaches this topic.
  final List<String> suggestedPrompts;

  /// Named route for the card's "Try it" button…
  final String? tryItRoute;

  /// …or a [MainTabIndex] when the feature lives on a shell tab.
  final int? tryItTabIndex;

  bool get hasTryIt => tryItRoute != null || tryItTabIndex != null;

  /// Compact plain-text block injected into the AI prompt when the user
  /// asks about this feature (~150-220 words).
  String toPromptBlock() {
    final b = StringBuffer()
      ..writeln('$title — $oneLiner')
      ..writeln('What: $what')
      ..writeln('Why: $why');
    if (howSteps.isNotEmpty) {
      b.writeln('How:');
      for (var i = 0; i < howSteps.length; i++) {
        b.writeln('  ${i + 1}. ${howSteps[i]}');
      }
    }
    if (tips.isNotEmpty) b.writeln('Tips: ${tips.join(' ')}');
    return b.toString();
  }
}
