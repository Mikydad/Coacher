import '../domain/models/ai_action.dart';

// ─── Result ───────────────────────────────────────────────────────────────────

class MissingFieldResult {
  const MissingFieldResult({
    required this.isComplete,
    this.missingFields = const [],
    this.questionToAsk,
  });

  final bool isComplete;
  final List<String> missingFields;

  /// A single, friendly question to ask the user (first missing field only).
  final String? questionToAsk;

  static const complete = MissingFieldResult(isComplete: true);
}

// ─── Detector ─────────────────────────────────────────────────────────────────

/// Validates that every [AiAction] has all required fields before a plan
/// is shown to the user.
///
/// Rules (from PRD §4.6):
/// - Ask ONE question at a time (first missing field only).
/// - Never block read-only / informational actions (suggestFreeTimeBlock).
class AiMissingFieldDetector {
  const AiMissingFieldDetector._();

  /// Check a single action for missing required parameters.
  static MissingFieldResult check(AiAction action) {
    final p = action.parameters;

    switch (action.actionType) {
      case ActionType.createTask:
      case ActionType.editTask:
        return _checkFields(p, [
          _Field('title', 'What should I call this task?'),
          _Field('time', 'What time should I schedule it?'),
          _Field('duration', 'How long will it take (in minutes)?'),
        ]);

      case ActionType.moveTask:
        return _checkFields(p, [
          _Field('taskTitle', 'Which task would you like to move?'),
          _Field(
            'destinationDate',
            'Move it to when? (e.g. "tomorrow" or a specific date)',
          ),
        ]);

      case ActionType.deleteTask:
        return _checkFields(p, [
          _Field('taskTitle', 'Which task should I delete?'),
        ]);

      case ActionType.createGoal:
        return _checkFields(p, [
          _Field('title', 'What is the name of your goal?'),
          _Field('target', 'What is the target? (e.g. "run 5km")'),
          _Field('deadline', 'What is the deadline for this goal?'),
        ]);

      case ActionType.modifyGoal:
        return _checkFields(p, [
          _Field('goalTitle', 'Which goal would you like to update?'),
          _Field('field', 'What would you like to change about it?'),
          _Field('newValue', 'What should the new value be?'),
        ]);

      case ActionType.deleteGoal:
        return _checkFields(p, [
          _Field('goalTitle', 'Which goal should I remove?'),
        ]);

      case ActionType.addReminder:
      case ActionType.rescheduleReminder:
        return _checkFields(p, [
          _Field('taskTitle', 'Which task should I add a reminder for?'),
          _Field('reminderTime', 'What time should the reminder fire?'),
        ]);

      case ActionType.removeReminder:
        return _checkFields(p, [
          _Field('taskTitle', 'Which task should I remove the reminder from?'),
        ]);

      case ActionType.activateContextOverride:
        return _checkFields(p, [
          _Field(
            'overrideType',
            'Which mode should I activate? (focus, meeting, sleep, or do not disturb)',
          ),
        ]);

      // These actions have no required fields — they are read-only or self-sufficient.
      case ActionType.endContextOverride:
      case ActionType.suggestFreeTimeBlock:
      case ActionType.moveConflictingTasks:
        return MissingFieldResult.complete;
    }
  }

  /// Iterates [actions] and returns the first incomplete result.
  /// Returns [MissingFieldResult.complete] if all actions are complete.
  static MissingFieldResult checkAll(List<AiAction> actions) {
    for (final action in actions) {
      final result = check(action);
      if (!result.isComplete) return result;
    }
    return MissingFieldResult.complete;
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  static MissingFieldResult _checkFields(
    Map<String, dynamic> params,
    List<_Field> required,
  ) {
    final missing = <String>[];
    String? firstQuestion;

    for (final field in required) {
      final value = params[field.key];
      final isEmpty = value == null ||
          (value is String && value.trim().isEmpty);
      if (isEmpty) {
        missing.add(field.key);
        firstQuestion ??= field.question;
      }
    }

    if (missing.isEmpty) return MissingFieldResult.complete;

    return MissingFieldResult(
      isComplete: false,
      missingFields: missing,
      questionToAsk: firstQuestion,
    );
  }
}

// ─── Internal field descriptor ────────────────────────────────────────────────

class _Field {
  const _Field(this.key, this.question);

  final String key;
  final String question;
}
