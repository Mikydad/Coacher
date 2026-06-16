import '../data/dismissed_suggestion_repository.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/proactive_suggestion.dart';
import 'proactive_suggestion_source.dart';

/// Attaches proactive-engine prompts to informational answers when gaps exist.
class AiChatSuggestionEnricher {
  const AiChatSuggestionEnricher({
    required ProactiveSuggestionSource proactiveEngine,
    required this.dismissedRepo,
  }) : _proactiveEngine = proactiveEngine;

  final ProactiveSuggestionSource _proactiveEngine;
  final DismissedSuggestionRepository dismissedRepo;

  /// Returns up to 2 [preDraftedInput] strings for empty schedule gaps.
  Future<List<String>> promptsForInformationalGaps(
    AiOperatingLayerPayload payload,
  ) async {
    if (!hasRelevantGap(payload)) return const [];

    final suggestions = await _proactiveEngine.generateForToday();
    final suppressed = await dismissedRepo.suppressedTypes();

    return suggestions
        .where((s) => !suppressed.contains(s.type))
        .take(2)
        .map((s) => s.preDraftedInput)
        .toList();
  }

  /// True when the user's query targets a day/period that looks empty in payload.
  static bool hasRelevantGap(AiOperatingLayerPayload payload) {
    final lower = payload.userInput.toLowerCase();

    if (lower.contains('tomorrow')) {
      return payload.tomorrowTasks.isEmpty && payload.tomorrowSchedule.isEmpty;
    }

    if (lower.contains('today')) {
      return payload.activeTasks.isEmpty && payload.todaySchedule.isEmpty;
    }

    if (lower.contains('week')) {
      if (payload.weekOverview.isEmpty) return false;
      return payload.weekOverview.every(
        (day) => (day['taskCount'] as int? ?? 0) == 0,
      );
    }

    return false;
  }
}
