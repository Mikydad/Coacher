import '../../../../core/validation/model_validators.dart';

class TaskScore {
  const TaskScore({
    required this.id,
    required this.taskId,
    required this.completionPercent,
    required this.reason,
    required this.timerSessionId,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String taskId;
  final int completionPercent;
  final String? reason;
  final String? timerSessionId;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'taskScore.id');
    ModelValidators.requireNotBlank(taskId, 'taskScore.taskId');
    ModelValidators.validateScore(
      completionPercent: completionPercent,
      reason: reason,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'completionPercent': completionPercent,
    'reason': reason,
    'timerSessionId': timerSessionId,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static TaskScore fromMap(Map<String, dynamic> map) => TaskScore(
    id: map['id'] as String,
    taskId: map['taskId'] as String,
    completionPercent: map['completionPercent'] as int,
    reason: map['reason'] as String?,
    timerSessionId: map['timerSessionId'] as String?,
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
  );
}
