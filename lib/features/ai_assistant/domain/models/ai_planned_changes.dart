import 'ai_action.dart';
import 'ai_response_type.dart';

/// The parsed, validated plan returned by the intent pipeline.
///
/// Response paths:
///   1. [isInformational] / [isUnsupported] → text-only assistant bubble.
///   2. [requiresFollowUp] == true         → pipeline paused; show [followUpQuestion].
///   3. [isBlockedByContext] == true       → hard warning; confirm disabled by default.
///   4. [hasConflicts] == true             → soft advisory warnings; confirm still available.
///   5. [isMutate] with actions            → plan ready, preview card.
///   6. [isSuggest] with actions           → narrative + Apply this plan tap.
class AiPlannedChanges {
  const AiPlannedChanges({
    required this.sessionId,
    this.responseType = AiResponseType.mutate,
    this.actions = const [],
    this.conflicts = const [],
    this.blockedByContext = const [],
    this.followUpQuestion,
    this.informationalMessage,
    this.suggestedPrompts = const [],
  });

  final String sessionId;
  final AiResponseType responseType;
  final List<AiAction> actions;

  /// Soft advisory conflict strings (amber rows in the preview card).
  final List<String> conflicts;

  /// Hard context-block strings (red rows — task falls inside DND/sleep).
  final List<String> blockedByContext;

  /// Set when a required field is missing and the AI needs more info.
  final String? followUpQuestion;

  /// Plain-language answer for read-only queries.
  final String? informationalMessage;

  /// Optional chips shown under an informational reply (pre-fill input).
  final List<String> suggestedPrompts;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isBlockedByContext => blockedByContext.isNotEmpty;
  bool get requiresFollowUp =>
      responseType == AiResponseType.followUp ||
      (followUpQuestion != null && followUpQuestion!.isNotEmpty);
  bool get isInformational => responseType == AiResponseType.informational;
  bool get isUnsupported => responseType == AiResponseType.unsupported;
  bool get isMutate => responseType == AiResponseType.mutate;
  bool get isSuggest => responseType == AiResponseType.suggest;

  bool get hasHighRiskActions =>
      actions.any((a) => a.riskLevel == AiActionRiskLevel.high);

  int get highRiskCount =>
      actions.where((a) => a.riskLevel == AiActionRiskLevel.high).length;

  bool get hasAnyWarnings => hasConflicts || isBlockedByContext;

  /// Primary text to show in the assistant bubble for non-preview turns.
  String? get assistantDisplayMessage {
    if (requiresFollowUp) return followUpQuestion;
    if (isInformational || isUnsupported) return informationalMessage;
    if (isSuggest) return informationalMessage;
    return null;
  }

  AiPlannedChanges copyWith({
    String? sessionId,
    AiResponseType? responseType,
    List<AiAction>? actions,
    List<String>? conflicts,
    List<String>? blockedByContext,
    String? followUpQuestion,
    String? informationalMessage,
    List<String>? suggestedPrompts,
  }) {
    return AiPlannedChanges(
      sessionId: sessionId ?? this.sessionId,
      responseType: responseType ?? this.responseType,
      actions: actions ?? this.actions,
      conflicts: conflicts ?? this.conflicts,
      blockedByContext: blockedByContext ?? this.blockedByContext,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
      informationalMessage: informationalMessage ?? this.informationalMessage,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
    );
  }

  @override
  String toString() =>
      'AiPlannedChanges(session: $sessionId, type: $responseType, actions: ${actions.length}, '
      'conflicts: ${conflicts.length}, blocked: ${blockedByContext.length}, '
      'followUp: $followUpQuestion, message: ${informationalMessage?.length})';
}
