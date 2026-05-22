import 'package:isar/isar.dart';

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

  /// JSON-encoded List<AiAction.toJson()>
  late String parsedActionsJson;

  late bool confirmed;
  late bool executed;

  /// Milliseconds since epoch — used for TTL purge queries.
  @Index()
  late int timestampMs;
}
