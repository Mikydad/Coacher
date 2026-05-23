import '../domain/models/proactive_suggestion.dart';

/// How many proactive cards to surface on Home before "See all in Coach".
const int kHomeProactiveSuggestionLimit = 1;

/// Maximum suggestions generated for the Coach suggestions panel.
const int kCoachProactiveSuggestionLimit = 5;

List<ProactiveSuggestion> activeProactiveSuggestions(
  List<ProactiveSuggestion> suggestions,
) {
  return suggestions.where((s) => !s.dismissed).toList();
}
