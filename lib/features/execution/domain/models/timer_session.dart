import '../../../../core/validation/model_validators.dart';

class TimerSession {
  const TimerSession({
    required this.id,
    required this.taskId,
    required this.startedAtMs,
    required this.endedAtMs,
    required this.elapsedSeconds,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String taskId;
  final int startedAtMs;
  final int? endedAtMs;
  final int elapsedSeconds;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'timerSession.id');
    ModelValidators.requireNotBlank(taskId, 'timerSession.taskId');
    ModelValidators.requireRange(
      value: elapsedSeconds,
      min: 0,
      max: 60 * 60 * 24,
      fieldName: 'timerSession.elapsedSeconds',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'startedAtMs': startedAtMs,
    'endedAtMs': endedAtMs,
    'elapsedSeconds': elapsedSeconds,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static TimerSession fromMap(Map<String, dynamic> map) => TimerSession(
    id: map['id'] as String,
    taskId: map['taskId'] as String,
    startedAtMs: map['startedAtMs'] as int,
    endedAtMs: map['endedAtMs'] as int?,
    elapsedSeconds: map['elapsedSeconds'] as int,
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
  );
}
