import '../domain/models/proactive_suggestion.dart';

/// How many proactive cards to show on Home when collapsed.
const int kHomeProactiveSuggestionLimit = 1;

/// Maximum suggestions generated for the Coach suggestions panel.
const int kCoachProactiveSuggestionLimit = 5;

/// Auto-collapse expanded Home suggestions after this idle period.
const Duration kHomeSuggestionsAutoCollapseDuration = Duration(seconds: 10);

/// Expand/collapse animation on Home.
const Duration kHomeSuggestionsExpandDuration = Duration(milliseconds: 280);

List<ProactiveSuggestion> activeProactiveSuggestions(
  List<ProactiveSuggestion> suggestions,
) {
  return suggestions.where((s) => !s.dismissed).toList();
}
