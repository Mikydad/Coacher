import '../../../../core/validation/model_validators.dart';
import '../../../context_override/domain/models/interruption_level.dart';
import 'reminder_type.dart';

/// A request for a notification to be delivered for an entity.
/// Produced by [ReminderSyncService] and passed to [AttentionOrchestratorService]
/// for evaluation — [ReminderSyncService] never schedules OS notifications directly.
class ReminderIntent {
  const ReminderIntent({
    required this.id,
    required this.entityId,
    required this.entityKind,
    required this.entityTitle,
    required this.proposedAt,
    required this.importance,
    required this.interruptionLevel,
    required this.enforcementMode,
    this.escalationLevel = 0,
    this.reminderType = ReminderType.scheduled,
    this.sourceReason = '',
    required this.createdAtMs,
  });

  /// Stable UUID for this intent.
  final String id;

  /// Task or habit ID.
  final String entityId;

  /// `"task"` or `"habit"`.
  final String entityKind;

  /// Display title used in the notification body.
  final String entityTitle;

  /// When the reminder wants to fire. The orchestrator may adjust this.
  final DateTime proposedAt;

  /// 0–100 importance score. Higher values resist suppression and collision delay.
  final int importance;

  /// Notification interruption classification (from Phase B).
  final InterruptionLevel interruptionLevel;

  /// `"flexible"`, `"disciplined"`, or `"extreme"`.
  final String enforcementMode;

  /// Current escalation level (0 = first fire).
  final int escalationLevel;

  final ReminderType reminderType;

  /// Human-readable reason for debug/trace.
  final String sourceReason;

  final int createdAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'reminderIntent.id');
    ModelValidators.requireNotBlank(entityId, 'reminderIntent.entityId');
    ModelValidators.requireNotBlank(entityKind, 'reminderIntent.entityKind');
    ModelValidators.requireRange(
      value: importance,
      min: 0,
      max: 100,
      fieldName: 'reminderIntent.importance',
    );
    ModelValidators.requireRange(
      value: escalationLevel,
      min: 0,
      max: 999,
      fieldName: 'reminderIntent.escalationLevel',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'entityId': entityId,
    'entityKind': entityKind,
    'entityTitle': entityTitle,
    'proposedAt': proposedAt.toIso8601String(),
    'importance': importance,
    'interruptionLevel': interruptionLevel.name,
    'enforcementMode': enforcementMode,
    'escalationLevel': escalationLevel,
    'reminderType': reminderType.toStorage(),
    'sourceReason': sourceReason,
    'createdAtMs': createdAtMs,
  };

  static ReminderIntent fromMap(Map<String, dynamic> map) => ReminderIntent(
    id: map['id'] as String,
    entityId: map['entityId'] as String,
    entityKind: map['entityKind'] as String,
    entityTitle: map['entityTitle'] as String? ?? '',
    proposedAt: DateTime.parse(map['proposedAt'] as String),
    importance: (map['importance'] as num?)?.toInt() ?? 50,
    interruptionLevel: interruptionLevelFromStorage(
      map['interruptionLevel'] as String?,
    ),
    enforcementMode: map['enforcementMode'] as String? ?? 'flexible',
    escalationLevel: (map['escalationLevel'] as num?)?.toInt() ?? 0,
    reminderType: ReminderType.fromStorage(map['reminderType'] as String?),
    sourceReason: map['sourceReason'] as String? ?? '',
    createdAtMs: (map['createdAtMs'] as num).toInt(),
  );

  ReminderIntent copyWith({
    String? entityTitle,
    DateTime? proposedAt,
    int? importance,
    InterruptionLevel? interruptionLevel,
    String? enforcementMode,
    int? escalationLevel,
    ReminderType? reminderType,
    String? sourceReason,
  }) => ReminderIntent(
    id: id,
    entityId: entityId,
    entityKind: entityKind,
    entityTitle: entityTitle ?? this.entityTitle,
    proposedAt: proposedAt ?? this.proposedAt,
    importance: importance ?? this.importance,
    interruptionLevel: interruptionLevel ?? this.interruptionLevel,
    enforcementMode: enforcementMode ?? this.enforcementMode,
    escalationLevel: escalationLevel ?? this.escalationLevel,
    reminderType: reminderType ?? this.reminderType,
    sourceReason: sourceReason ?? this.sourceReason,
    createdAtMs: createdAtMs,
  );
}
