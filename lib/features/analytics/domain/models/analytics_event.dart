import '../../../../core/validation/model_validators.dart';

enum AnalyticsEventType {
  habitCompleted,
  habitSkipped,
  habitSnoozed,
  habitMissedWindow,
  taskStarted,
  taskCompleted,
  taskDeferred,
  overlapOverride,
  autoNextStarted,
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.id,
    required this.type,
    required this.entityId,
    required this.entityKind,
    required this.dateKey,
    required this.timestampLocalIso,
    required this.sourceSurface,
    required this.idempotencyKey,
    this.modeRefId,
    this.reason,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.schemaVersion = 1,
  });

  final String id;
  final AnalyticsEventType type;
  final String entityId;
  final String entityKind;
  final String dateKey;
  final String timestampLocalIso;
  final String sourceSurface;
  final String idempotencyKey;
  final String? modeRefId;
  final String? reason;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(id, 'analyticsEvent.id');
    ModelValidators.requireNotBlank(entityId, 'analyticsEvent.entityId');
    ModelValidators.requireNotBlank(entityKind, 'analyticsEvent.entityKind');
    ModelValidators.requireNotBlank(dateKey, 'analyticsEvent.dateKey');
    ModelValidators.requireNotBlank(timestampLocalIso, 'analyticsEvent.timestampLocalIso');
    ModelValidators.requireNotBlank(sourceSurface, 'analyticsEvent.sourceSurface');
    ModelValidators.requireNotBlank(idempotencyKey, 'analyticsEvent.idempotencyKey');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'analyticsEvent.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'entityId': entityId,
    'entityKind': entityKind,
    'dateKey': dateKey,
    'timestampLocalIso': timestampLocalIso,
    'sourceSurface': sourceSurface,
    'idempotencyKey': idempotencyKey,
    if (modeRefId != null) 'modeRefId': modeRefId,
    if (reason != null) 'reason': reason,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static AnalyticsEvent fromMap(Map<String, dynamic> map) => AnalyticsEvent(
    id: map['id'] as String? ?? '',
    type: _eventTypeFromStorage(map['type'] as String?),
    entityId: map['entityId'] as String? ?? '',
    entityKind: map['entityKind'] as String? ?? '',
    dateKey: map['dateKey'] as String? ?? '',
    timestampLocalIso: map['timestampLocalIso'] as String? ?? '',
    sourceSurface: map['sourceSurface'] as String? ?? '',
    idempotencyKey: map['idempotencyKey'] as String? ?? '',
    modeRefId: map['modeRefId'] as String?,
    reason: map['reason'] as String?,
    createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
  );
}

AnalyticsEventType _eventTypeFromStorage(String? raw) {
  for (final v in AnalyticsEventType.values) {
    if (v.name == raw) return v;
  }
  return AnalyticsEventType.taskStarted;
}
