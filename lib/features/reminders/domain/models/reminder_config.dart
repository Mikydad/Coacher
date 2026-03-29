import '../../../../core/validation/model_validators.dart';

class ReminderConfig {
  const ReminderConfig({
    required this.id,
    required this.taskId,
    required this.enabled,
    required this.scheduledAtIso,
    this.modeRefId,
    this.blockUrgencyScore = 50,
    this.pendingAction = false,
    this.escalationLevel = 0,
    this.emergencyBypass = false,
    this.lastTriggeredAtMs,
    this.nextPromptAtIso,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String taskId;
  final bool enabled;
  final String? scheduledAtIso;
  final String? modeRefId;
  final int blockUrgencyScore;
  final bool pendingAction;
  final int escalationLevel;
  final bool emergencyBypass;
  final int? lastTriggeredAtMs;
  final String? nextPromptAtIso;
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
    if (modeRefId != null) 'modeRefId': modeRefId,
    'blockUrgencyScore': blockUrgencyScore,
    'pendingAction': pendingAction,
    'escalationLevel': escalationLevel,
    'emergencyBypass': emergencyBypass,
    if (lastTriggeredAtMs != null) 'lastTriggeredAtMs': lastTriggeredAtMs,
    if (nextPromptAtIso != null) 'nextPromptAtIso': nextPromptAtIso,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static ReminderConfig fromMap(Map<String, dynamic> map) => ReminderConfig(
    id: map['id'] as String,
    taskId: map['taskId'] as String,
    enabled: map['enabled'] as bool? ?? false,
    scheduledAtIso: map['scheduledAtIso'] as String?,
    modeRefId: map['modeRefId'] as String?,
    blockUrgencyScore: (map['blockUrgencyScore'] as num?)?.toInt() ?? 50,
    pendingAction: map['pendingAction'] as bool? ?? false,
    escalationLevel: (map['escalationLevel'] as num?)?.toInt() ?? 0,
    emergencyBypass: map['emergencyBypass'] as bool? ?? false,
    lastTriggeredAtMs: (map['lastTriggeredAtMs'] as num?)?.toInt(),
    nextPromptAtIso: map['nextPromptAtIso'] as String?,
    createdAtMs: map['createdAtMs'] as int,
    updatedAtMs: map['updatedAtMs'] as int,
  );

  ReminderConfig copyWith({
    bool? enabled,
    String? scheduledAtIso,
    String? modeRefId,
    int? blockUrgencyScore,
    bool? pendingAction,
    int? escalationLevel,
    bool? emergencyBypass,
    int? lastTriggeredAtMs,
    String? nextPromptAtIso,
    int? updatedAtMs,
  }) {
    return ReminderConfig(
      id: id,
      taskId: taskId,
      enabled: enabled ?? this.enabled,
      scheduledAtIso: scheduledAtIso ?? this.scheduledAtIso,
      modeRefId: modeRefId ?? this.modeRefId,
      blockUrgencyScore: blockUrgencyScore ?? this.blockUrgencyScore,
      pendingAction: pendingAction ?? this.pendingAction,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      emergencyBypass: emergencyBypass ?? this.emergencyBypass,
      lastTriggeredAtMs: lastTriggeredAtMs ?? this.lastTriggeredAtMs,
      nextPromptAtIso: nextPromptAtIso ?? this.nextPromptAtIso,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
