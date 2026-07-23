import '../../../../core/validation/model_validators.dart';

const int kScheduledTimeBlockSchemaVersion = 1;

// ─── Flexibility type ─────────────────────────────────────────────────────────

/// Whether this time block can be moved without consequence.
/// Rigid blocks (e.g. meetings, fixed appointments) escalate conflict severity.
enum FlexibilityType { flexible, rigid }

FlexibilityType flexibilityTypeFromStorage(String? raw) {
  for (final v in FlexibilityType.values) {
    if (v.name == raw) return v;
  }
  return FlexibilityType.flexible;
}

// ─── ScheduledTimeBlock ───────────────────────────────────────────────────────

/// A concrete occupied time window derived from a scheduled task or habit.
///
/// Created automatically when an entity is saved with both a scheduled time
/// and an expected duration. Isar is the source of truth; replicated via the
/// outbox and pulled by RemoteIsarMerge (sync set completed in Phase 1).
class ScheduledTimeBlock {
  const ScheduledTimeBlock({
    required this.id,
    required this.entityId,
    required this.entityKind,
    required this.startAt,
    required this.expectedDurationMinutes,
    required this.computedEndAt,
    required this.flexibilityType,
    required this.allowOverlapOverride,
    required this.importance,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.schemaVersion = kScheduledTimeBlockSchemaVersion,
  });

  /// Stable UUID for this block.
  final String id;

  /// ID of the owning task or habit.
  final String entityId;

  /// `"task"` or `"habit"`.
  final String entityKind;

  /// Scheduled start time.
  final DateTime startAt;

  /// Planned duration in minutes.
  final int expectedDurationMinutes;

  /// Derived: `startAt + expectedDurationMinutes`. Always kept in sync.
  final DateTime computedEndAt;

  /// Whether this block can be moved without consequence.
  final FlexibilityType flexibilityType;

  /// True when the user explicitly chose to save despite a detected conflict.
  final bool allowOverlapOverride;

  /// 0–100 importance score used in conflict severity weighting.
  /// Derived from enforcement mode: extreme = 90, disciplined = 60, flexible = 30.
  final int importance;

  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;

  bool get isRigid => flexibilityType == FlexibilityType.rigid;

  void validate() {
    ModelValidators.requireNotBlank(id, 'scheduledTimeBlock.id');
    ModelValidators.requireNotBlank(entityId, 'scheduledTimeBlock.entityId');
    ModelValidators.requireNotBlank(
      entityKind,
      'scheduledTimeBlock.entityKind',
    );
    ModelValidators.requireRange(
      value: expectedDurationMinutes,
      min: 1,
      max: 1440,
      fieldName: 'scheduledTimeBlock.expectedDurationMinutes',
    );
    ModelValidators.requireRange(
      value: importance,
      min: 0,
      max: 100,
      fieldName: 'scheduledTimeBlock.importance',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'entityId': entityId,
    'entityKind': entityKind,
    'startAtMs': startAt.millisecondsSinceEpoch,
    'expectedDurationMinutes': expectedDurationMinutes,
    'computedEndAtMs': computedEndAt.millisecondsSinceEpoch,
    'flexibilityType': flexibilityType.name,
    'allowOverlapOverride': allowOverlapOverride,
    'importance': importance,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static ScheduledTimeBlock fromMap(Map<String, dynamic> map) {
    final startAtMs = (map['startAtMs'] as num?)?.toInt() ?? 0;
    final endAtMs = (map['computedEndAtMs'] as num?)?.toInt() ?? 0;
    return ScheduledTimeBlock(
      id: map['id'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      entityKind: map['entityKind'] as String? ?? '',
      startAt: DateTime.fromMillisecondsSinceEpoch(startAtMs),
      expectedDurationMinutes:
          (map['expectedDurationMinutes'] as num?)?.toInt() ?? 0,
      computedEndAt: DateTime.fromMillisecondsSinceEpoch(endAtMs),
      flexibilityType: flexibilityTypeFromStorage(
        map['flexibilityType'] as String?,
      ),
      allowOverlapOverride: map['allowOverlapOverride'] as bool? ?? false,
      importance: (map['importance'] as num?)?.toInt() ?? 30,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kScheduledTimeBlockSchemaVersion,
    );
  }

  ScheduledTimeBlock copyWith({
    String? entityKind,
    DateTime? startAt,
    int? expectedDurationMinutes,
    DateTime? computedEndAt,
    FlexibilityType? flexibilityType,
    bool? allowOverlapOverride,
    int? importance,
    int? updatedAtMs,
  }) {
    return ScheduledTimeBlock(
      id: id,
      entityId: entityId,
      entityKind: entityKind ?? this.entityKind,
      startAt: startAt ?? this.startAt,
      expectedDurationMinutes:
          expectedDurationMinutes ?? this.expectedDurationMinutes,
      computedEndAt: computedEndAt ?? this.computedEndAt,
      flexibilityType: flexibilityType ?? this.flexibilityType,
      allowOverlapOverride: allowOverlapOverride ?? this.allowOverlapOverride,
      importance: importance ?? this.importance,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion,
    );
  }
}

// ─── AvailableTimeWindow ──────────────────────────────────────────────────────

/// Represents time freed up when a task completes before its expected duration.
/// In-memory only — not persisted to Isar.
class AvailableTimeWindow {
  const AvailableTimeWindow({
    required this.entityId,
    required this.windowStartAt,
    required this.windowEndAt,
    required this.durationMinutes,
    required this.createdAtMs,
  });

  /// The task that completed early.
  final String entityId;

  /// Time of early completion.
  final DateTime windowStartAt;

  /// Originally scheduled end time.
  final DateTime windowEndAt;

  /// Reclaimed minutes (`windowEndAt - windowStartAt`).
  final int durationMinutes;

  final int createdAtMs;
}
