import '../../../../core/validation/model_validators.dart';

enum TimerSessionTargetType {
  task,
  block,
}

extension TimerSessionTargetTypeStorage on TimerSessionTargetType {
  String get storageValue => name;

  static TimerSessionTargetType fromStorage(String? raw) {
    return TimerSessionTargetType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => TimerSessionTargetType.task,
    );
  }
}

class TimerSession {
  const TimerSession({
    required this.id,
    this.targetType = TimerSessionTargetType.task,
    this.taskId,
    this.blockId,
    required this.startedAtMs,
    required this.endedAtMs,
    required this.elapsedSeconds,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final TimerSessionTargetType targetType;
  final String? taskId;
  final String? blockId;
  final int startedAtMs;
  final int? endedAtMs;
  final int elapsedSeconds;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'timerSession.id');
    switch (targetType) {
      case TimerSessionTargetType.task:
        ModelValidators.requireNotBlank(taskId ?? '', 'timerSession.taskId');
        break;
      case TimerSessionTargetType.block:
        ModelValidators.requireNotBlank(blockId ?? '', 'timerSession.blockId');
        break;
    }
    ModelValidators.requireRange(
      value: elapsedSeconds,
      min: 0,
      max: 60 * 60 * 24,
      fieldName: 'timerSession.elapsedSeconds',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'targetType': targetType.storageValue,
    if (taskId != null) 'taskId': taskId,
    if (blockId != null) 'blockId': blockId,
    'startedAtMs': startedAtMs,
    'endedAtMs': endedAtMs,
    'elapsedSeconds': elapsedSeconds,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static TimerSession fromMap(Map<String, dynamic> map) => TimerSession(
    id: map['id'] as String? ?? '',
    targetType: TimerSessionTargetTypeStorage.fromStorage(map['targetType'] as String?),
    taskId: map['taskId'] as String?,
    blockId: map['blockId'] as String?,
    startedAtMs: (map['startedAtMs'] as num?)?.toInt() ?? 0,
    endedAtMs: (map['endedAtMs'] as num?)?.toInt(),
    elapsedSeconds: (map['elapsedSeconds'] as num?)?.toInt() ?? 0,
    createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
  );
}
