import '../domain/models/proactive_suggestion.dart';

/// Maximum suggestions generated for the Coach suggestions panel.
const int kCoachProactiveSuggestionLimit = 5;

List<ProactiveSuggestion> activeProactiveSuggestions(
  List<ProactiveSuggestion> suggestions,
) {
  return suggestions.where((s) => !s.dismissed).toList();
}
