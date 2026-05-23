import 'ai_action.dart';

/// The parsed, validated plan returned by the intent pipeline.
///
/// Four states:
///   1. [requiresFollowUp] == true       → pipeline paused; show [followUpQuestion].
///   2. [isBlockedByContext] == true     → hard warning; confirm disabled by default.
///   3. [hasConflicts] == true           → soft advisory warnings; confirm still available.
///   4. Normal                           → plan ready, no warnings.
class AiPlannedChanges {
  const AiPlannedChanges({
    required this.sessionId,
    this.actions = const [],
    this.conflicts = const [],
    this.blockedByContext = const [],
    this.followUpQuestion,
  });

  final String sessionId;
  final List<AiAction> actions;

  /// Soft advisory conflict strings (amber rows in the preview card).
  /// e.g. "Reminder for Morning Run fires 2 min before this."
  final List<String> conflicts;

  /// Hard context-block strings (red rows — task falls inside DND/sleep).
  /// Confirm still possible but labelled "Confirm Anyway".
  final List<String> blockedByContext;

  /// Set when a required field is missing and the AI needs more info.
  final String? followUpQuestion;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isBlockedByContext => blockedByContext.isNotEmpty;
  bool get requiresFollowUp => followUpQuestion != null;

  bool get hasHighRiskActions =>
      actions.any((a) => a.riskLevel == AiActionRiskLevel.high);

  int get highRiskCount =>
      actions.where((a) => a.riskLevel == AiActionRiskLevel.high).length;

  bool get hasAnyWarnings => hasConflicts || isBlockedByContext;

  AiPlannedChanges copyWith({
    String? sessionId,
    List<AiAction>? actions,
    List<String>? conflicts,
    List<String>? blockedByContext,
    String? followUpQuestion,
  }) {
    return AiPlannedChanges(
      sessionId: sessionId ?? this.sessionId,
      actions: actions ?? this.actions,
      conflicts: conflicts ?? this.conflicts,
      blockedByContext: blockedByContext ?? this.blockedByContext,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
    );
  }

  @override
  String toString() =>
      'AiPlannedChanges(session: $sessionId, actions: ${actions.length}, '
      'conflicts: ${conflicts.length}, blocked: ${blockedByContext.length}, '
      'followUp: $followUpQuestion)';
}
