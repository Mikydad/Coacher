import '../../../../core/validation/model_validators.dart';

class ReminderConfig {
  const ReminderConfig({
    required this.id,
    required this.taskId,
    required this.enabled,
    required this.scheduledAtIso,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String taskId;
  final bool enabled;
  final String? scheduledAtIso;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'reminder.id');
    ModelValidators.requireNotBlank(taskId, 'reminder.taskId');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'enabled': enabled,
    'scheduledAtIso': scheduledAtIso,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static ReminderConfig fromMap(Map<String, dynamic> map) => ReminderConfig(
    id: map['id'] as String,
    taskId: map['taskId'] as String,
    enabled: map['enabled'] as bool,
    scheduledAtIso: map['scheduledAtIso'] as String?,
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
  );
}
