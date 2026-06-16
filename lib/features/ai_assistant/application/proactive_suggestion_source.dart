import '../domain/models/proactive_suggestion.dart';

/// Minimal surface for chat-side proactive prompt enrichment.
abstract interface class ProactiveSuggestionSource {
  Future<List<ProactiveSuggestion>> generateForToday();
}
