import 'ai_action.dart';

/// The parsed, validated plan returned by the intent pipeline.
///
/// Three states:
///   1. [requiresFollowUp] == true  → pipeline paused; show [followUpQuestion].
///   2. [hasConflicts] == true      → plan ready but has warnings; show conflicts.
///   3. Normal                      → plan ready, no warnings.
class AiPlannedChanges {
  const AiPlannedChanges({
    required this.sessionId,
    this.actions = const [],
    this.conflicts = const [],
    this.followUpQuestion,
  });

  final String sessionId;
  final List<AiAction> actions;

  /// Human-readable conflict strings (e.g. "Workout overlaps with Commute").
  final List<String> conflicts;

  /// Set when a required field is missing and the AI needs more info.
  final String? followUpQuestion;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get requiresFollowUp => followUpQuestion != null;

  bool get hasHighRiskActions =>
      actions.any((a) => a.riskLevel == AiActionRiskLevel.high);

  int get highRiskCount =>
      actions.where((a) => a.riskLevel == AiActionRiskLevel.high).length;

  AiPlannedChanges copyWith({
    String? sessionId,
    List<AiAction>? actions,
    List<String>? conflicts,
    String? followUpQuestion,
  }) {
    return AiPlannedChanges(
      sessionId: sessionId ?? this.sessionId,
      actions: actions ?? this.actions,
      conflicts: conflicts ?? this.conflicts,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
    );
  }

  @override
  String toString() =>
      'AiPlannedChanges(session: $sessionId, actions: ${actions.length}, '
      'conflicts: ${conflicts.length}, followUp: $followUpQuestion)';
}
