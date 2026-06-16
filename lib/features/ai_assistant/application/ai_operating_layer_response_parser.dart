import '../domain/models/ai_action.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_response_type.dart';

/// Parses the inner JSON object returned by the AI model into [AiPlannedChanges].
AiPlannedChanges parseOperatingLayerJsonMap(
  Map<String, dynamic> inner,
  String sessionId,
) {
  final responseType = aiResponseTypeFromJson(inner['responseType'] as String?);

  final followUp = inner['followUpQuestion'] as String?;
  if (followUp != null && followUp.isNotEmpty) {
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: AiResponseType.followUp,
      followUpQuestion: followUp,
    );
  }

  final message = (inner['message'] as String?)?.trim();

  if (responseType == AiResponseType.informational) {
    final promptsRaw = inner['suggestedPrompts'] as List? ?? const [];
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: AiResponseType.informational,
      informationalMessage: message?.isNotEmpty == true
          ? message
          : 'I could not find schedule details to answer that.',
      suggestedPrompts: promptsRaw.map((e) => e.toString()).toList(),
    );
  }

  if (responseType == AiResponseType.unsupported) {
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: AiResponseType.unsupported,
      informationalMessage: message?.isNotEmpty == true
          ? message
          : "I can't help with that yet — this feature is coming later.",
    );
  }

  final actionsRaw = inner['actions'] as List? ?? [];
  final actions = actionsRaw
      .map((a) => AiAction.fromJson(Map<String, dynamic>.from(a as Map)))
      .toList();

  final conflictsRaw = inner['conflicts'] as List? ?? [];
  final conflicts = conflictsRaw.map((c) => c.toString()).toList();
  final promptsRaw = inner['suggestedPrompts'] as List? ?? const [];

  if (responseType == AiResponseType.suggest) {
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: AiResponseType.suggest,
      informationalMessage: message?.isNotEmpty == true
          ? message
          : 'Here\'s what I\'d suggest based on your schedule:',
      actions: actions,
      conflicts: conflicts,
      suggestedPrompts: promptsRaw.map((e) => e.toString()).toList(),
    );
  }

  if (actions.isEmpty && message != null && message.isNotEmpty) {
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: AiResponseType.informational,
      informationalMessage: message,
      suggestedPrompts: (inner['suggestedPrompts'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  return AiPlannedChanges(
    sessionId: sessionId,
    responseType: AiResponseType.mutate,
    actions: actions,
    conflicts: conflicts,
  );
}
