// ─── Action type enum ─────────────────────────────────────────────────────────

enum ActionType {
  // Tasks
  createTask,
  editTask,
  moveTask,
  deleteTask,

  // Goals
  createGoal,
  modifyGoal,
  deleteGoal,

  // Reminders
  addReminder,
  removeReminder,
  rescheduleReminder,

  // Context overrides
  activateContextOverride,
  endContextOverride,

  // Scheduling helpers
  suggestFreeTimeBlock,
  moveConflictingTasks,

  // Intentions (humanizing Phase 1) — AUTO-COMMITS with undo, the one
  // deliberate relaxation of the confirm-gate (decision log 2026-07-23).
  createIntention,
}

// ─── Risk level enum ─────────────────────────────────────────────────────────

enum AiActionRiskLevel { low, medium, high }

// ─── AiAction model ──────────────────────────────────────────────────────────

class AiAction {
  const AiAction({
    required this.actionType,
    required this.parameters,
    this.confidence = 1.0,
    this.reasonLabel,
  });

  final ActionType actionType;
  final Map<String, dynamic> parameters;

  /// 0.0–1.0 confidence from the intent parser.
  final double confidence;

  /// Optional label set by the Assumption Engine (Phase 2).
  /// Shown as a sub-line in the PlannedChangesCard.
  final String? reasonLabel;

  // ─── Risk level ───────────────────────────────────────────────────────────

  AiActionRiskLevel get riskLevel {
    switch (actionType) {
      case ActionType.deleteTask:
      case ActionType.deleteGoal:
      case ActionType.removeReminder:
      case ActionType.moveConflictingTasks:
        return AiActionRiskLevel.high;

      case ActionType.moveTask:
      case ActionType.editTask:
      case ActionType.modifyGoal:
      case ActionType.rescheduleReminder:
        return AiActionRiskLevel.medium;

      case ActionType.createTask:
      case ActionType.createGoal:
      case ActionType.addReminder:
      case ActionType.activateContextOverride:
      case ActionType.endContextOverride:
      case ActionType.suggestFreeTimeBlock:
      case ActionType.createIntention:
        return AiActionRiskLevel.low;
    }
  }

  // ─── Serialisation ────────────────────────────────────────────────────────

  factory AiAction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['actionType'] as String? ?? '';
    final type = ActionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ActionType.createTask,
    );
    return AiAction(
      actionType: type,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      reasonLabel: json['reasonLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'actionType': actionType.name,
    'parameters': parameters,
    'confidence': confidence,
    if (reasonLabel != null) 'reasonLabel': reasonLabel,
  };

  AiAction copyWith({
    ActionType? actionType,
    Map<String, dynamic>? parameters,
    double? confidence,
    String? reasonLabel,
  }) {
    return AiAction(
      actionType: actionType ?? this.actionType,
      parameters: parameters ?? this.parameters,
      confidence: confidence ?? this.confidence,
      reasonLabel: reasonLabel ?? this.reasonLabel,
    );
  }

  @override
  String toString() =>
      'AiAction(${actionType.name}, confidence: $confidence, params: $parameters)';
}
