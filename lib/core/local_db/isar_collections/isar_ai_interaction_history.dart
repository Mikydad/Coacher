import 'package:isar_community/isar.dart';

part 'isar_ai_interaction_history.g.dart';

/// Persists each Coach AI interaction for session history and debugging.
///
/// Entries are purged when they are older than 48 hours (TTL).
/// [parsedActionsJson] stores a JSON array of serialised [AiAction] objects.
@collection
class IsarAiInteractionHistory {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String sessionId;

  late String userInput;

  /// JSON-encoded list of AiAction.toJson() maps.
  late String parsedActionsJson;

  late bool confirmed;
  late bool executed;

  /// Canonical category resolved by EntityNormaliser for the primary action.
  /// Seeded by AiAssistantService on successful execution (Phase 2).
  String? resolvedCategory;

  /// Short summary of what the assistant did (e.g. "Added Morning Workout at 5AM").
  /// Stored after execution to enable full assistant turns in conversationHistory (Phase 3).
  String? assistantSummary;

  /// Response mode for analytics — informational, mutate, followUp, unsupported.
  String? responseType;

  /// Milliseconds since epoch — used for TTL purge queries.
  @Index()
  late int timestampMs;
}
