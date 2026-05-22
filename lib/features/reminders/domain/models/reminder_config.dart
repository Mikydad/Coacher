import '../../../../core/validation/model_validators.dart';

class ReminderConfig {
  const ReminderConfig({
    required this.id,
    required this.taskId,
    this.taskTitle,
    required this.enabled,
    required this.scheduledAtIso,
    this.modeRefId,
    this.blockUrgencyScore = 50,
    this.pendingAction = false,
    this.escalationLevel = 0,
    this.emergencyBypass = false,
    this.lastTriggeredAtMs,
    this.nextPromptAtIso,
    this.activeNotificationId,
    this.evaluationTrace = const [],
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String taskId;
  final String? taskTitle;
  final bool enabled;
  final String? scheduledAtIso;
  final String? modeRefId;
  final int blockUrgencyScore;
  final bool pendingAction;
  final int escalationLevel;
  final bool emergencyBypass;
  final int? lastTriggeredAtMs;
  final String? nextPromptAtIso;

  /// The OS notification ID currently scheduled for this entity.
  /// Null when no notification is active. Used by [AttentionOrchestratorService]
  /// for single-cancel across app restarts (in-memory map is primary; this is
  /// the persistence fallback added in Phase C).
  final int? activeNotificationId;

  /// Ordered human-readable trace entries from escalation decisions.
  /// Appended by [AttentionOrchestratorService] for explainability/debug.
  final List<String> evaluationTrace;

  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'reminder.id');
    ModelValidators.requireNotBlank(taskId, 'reminder.taskId');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    if (taskTitle != null) 'taskTitle': taskTitle,
    'enabled': enabled,
    'scheduledAtIso': scheduledAtIso,
    if (modeRefId != null) 'modeRefId': modeRefId,
    'blockUrgencyScore': blockUrgencyScore,
    'pendingAction': pendingAction,
    'escalationLevel': escalationLevel,
    'emergencyBypass': emergencyBypass,
    if (lastTriggeredAtMs != null) 'lastTriggeredAtMs': lastTriggeredAtMs,
    if (nextPromptAtIso != null) 'nextPromptAtIso': nextPromptAtIso,
    if (activeNotificationId != null)
      'activeNotificationId': activeNotificationId,
    if (evaluationTrace.isNotEmpty) 'evaluationTrace': evaluationTrace,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static ReminderConfig fromMap(Map<String, dynamic> map) {
    final rawTrace = map['evaluationTrace'];
    final trace = rawTrace is List
        ? rawTrace.whereType<String>().toList(growable: false)
        : const <String>[];
    return ReminderConfig(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      taskTitle: map['taskTitle'] as String?,
      enabled: map['enabled'] as bool? ?? false,
      scheduledAtIso: map['scheduledAtIso'] as String?,
      modeRefId: map['modeRefId'] as String?,
      blockUrgencyScore: (map['blockUrgencyScore'] as num?)?.toInt() ?? 50,
      pendingAction: map['pendingAction'] as bool? ?? false,
      escalationLevel: (map['escalationLevel'] as num?)?.toInt() ?? 0,
      emergencyBypass: map['emergencyBypass'] as bool? ?? false,
      lastTriggeredAtMs: (map['lastTriggeredAtMs'] as num?)?.toInt(),
      nextPromptAtIso: map['nextPromptAtIso'] as String?,
      activeNotificationId: (map['activeNotificationId'] as num?)?.toInt(),
      evaluationTrace: trace,
      createdAtMs: map['createdAtMs'] as int,
      updatedAtMs: map['updatedAtMs'] as int,
    );
  }

  ReminderConfig copyWith({
    bool? enabled,
    String? scheduledAtIso,
    String? taskTitle,
    String? modeRefId,
    int? blockUrgencyScore,
    bool? pendingAction,
    int? escalationLevel,
    bool? emergencyBypass,
    int? lastTriggeredAtMs,
    String? nextPromptAtIso,
    int? activeNotificationId,
    List<String>? evaluationTrace,
    int? updatedAtMs,
  }) {
    return ReminderConfig(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      enabled: enabled ?? this.enabled,
      scheduledAtIso: scheduledAtIso ?? this.scheduledAtIso,
      modeRefId: modeRefId ?? this.modeRefId,
      blockUrgencyScore: blockUrgencyScore ?? this.blockUrgencyScore,
      pendingAction: pendingAction ?? this.pendingAction,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      emergencyBypass: emergencyBypass ?? this.emergencyBypass,
      lastTriggeredAtMs: lastTriggeredAtMs ?? this.lastTriggeredAtMs,
      nextPromptAtIso: nextPromptAtIso ?? this.nextPromptAtIso,
      activeNotificationId: activeNotificationId ?? this.activeNotificationId,
      evaluationTrace: evaluationTrace ?? this.evaluationTrace,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
