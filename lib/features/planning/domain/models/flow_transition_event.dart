import '../../../../core/validation/model_validators.dart';

enum FlowTransitionType {
  startNow,
  extraTime,
  moveWithReason,
}

enum OverrideReasonCategory {
  dependencyBlocked,
  urgentInterruption,
  energyFocusMismatch,
  scheduleConflict,
}

enum PlanChangeIntent {
  feeling,
  logical,
}

extension PlanChangeIntentStorage on PlanChangeIntent {
  String get storageValue => name;

  static PlanChangeIntent fromStorage(String? raw) {
    return PlanChangeIntent.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => PlanChangeIntent.logical,
    );
  }
}

extension OverrideReasonCategoryStorage on OverrideReasonCategory {
  String get storageValue => name;

  String get label {
    switch (this) {
      case OverrideReasonCategory.dependencyBlocked:
        return 'Dependency blocked';
      case OverrideReasonCategory.urgentInterruption:
        return 'Urgent interruption';
      case OverrideReasonCategory.energyFocusMismatch:
        return 'Energy/focus mismatch';
      case OverrideReasonCategory.scheduleConflict:
        return 'Schedule conflict';
    }
  }

  static OverrideReasonCategory fromStorage(String? raw) {
    return OverrideReasonCategory.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => OverrideReasonCategory.scheduleConflict,
    );
  }
}

extension FlowTransitionTypeStorage on FlowTransitionType {
  String get storageValue => name;

  static FlowTransitionType fromStorage(String? raw) {
    return FlowTransitionType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => FlowTransitionType.startNow,
    );
  }
}

class FlowTransitionEvent {
  const FlowTransitionEvent({
    required this.id,
    required this.taskId,
    required this.type,
    this.planChangeIntent,
    this.reasonCategory,
    this.reasonNote,
    required this.createdAtMs,
  });

  final String id;
  final String taskId;
  final FlowTransitionType type;
  final PlanChangeIntent? planChangeIntent;
  final OverrideReasonCategory? reasonCategory;
  final String? reasonNote;
  final int createdAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'flowTransition.id');
    ModelValidators.requireNotBlank(taskId, 'flowTransition.taskId');
    if (type == FlowTransitionType.moveWithReason) {
      if (reasonCategory == null) {
        throw ArgumentError('flowTransition.reasonCategory is required');
      }
      validateReasonNote(reasonNote ?? '');
    }
  }

  static void validateReasonNote(String value) {
    final trimmed = value.trim();
    ModelValidators.requireNotBlank(trimmed, 'flowTransition.reasonNote');
    final sentences = _countSentences(trimmed);
    if (sentences < 1 || sentences > 2) {
      throw ArgumentError(
        'flowTransition.reasonNote must be 1-2 sentences',
      );
    }
  }

  static int _countSentences(String text) {
    final matches = RegExp(r'[.!?]+').allMatches(text).length;
    if (matches > 0) return matches;
    // Fallback for users who do not include punctuation.
    return 1;
  }

  PlanChangeIntent? get _effectiveIntent {
    return planChangeIntent ?? (reasonCategory == null ? null : PlanChangeIntent.logical);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'type': type.storageValue,
    if (_effectiveIntent != null) 'planChangeIntent': _effectiveIntent!.storageValue,
    if (reasonCategory != null) 'reasonCategory': reasonCategory!.storageValue,
    if (reasonNote != null) 'reasonNote': reasonNote,
    'createdAtMs': createdAtMs,
  };
}
