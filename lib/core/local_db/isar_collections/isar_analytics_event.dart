import 'package:isar/isar.dart';

import '../../../features/analytics/domain/models/analytics_event.dart';

part 'isar_analytics_event.g.dart';

@collection
class IsarAnalyticsEvent {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  @Index(unique: true)
  late String idempotencyKey;

  @Index()
  late int updatedAtMs;

  @Index()
  late String dateKey;

  @Index()
  late String entityId;

  late String typeName;
  late String entityKind;
  late String timestampLocalIso;
  late String sourceSurface;
  String? modeRefId;
  String? reason;
  late int createdAtMs;
  late int schemaVersion;

  static IsarAnalyticsEvent fromDomain(AnalyticsEvent e) {
    return IsarAnalyticsEvent()
      ..eventId = e.id
      ..idempotencyKey = e.idempotencyKey
      ..updatedAtMs = e.updatedAtMs
      ..dateKey = e.dateKey
      ..entityId = e.entityId
      ..typeName = e.type.name
      ..entityKind = e.entityKind
      ..timestampLocalIso = e.timestampLocalIso
      ..sourceSurface = e.sourceSurface
      ..modeRefId = e.modeRefId
      ..reason = e.reason
      ..createdAtMs = e.createdAtMs
      ..schemaVersion = e.schemaVersion;
  }

  AnalyticsEvent toDomain() {
    return AnalyticsEvent(
      id: eventId,
      type: _eventTypeFromStorage(typeName),
      entityId: entityId,
      entityKind: entityKind,
      dateKey: dateKey,
      timestampLocalIso: timestampLocalIso,
      sourceSurface: sourceSurface,
      idempotencyKey: idempotencyKey,
      modeRefId: modeRefId,
      reason: reason,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      schemaVersion: schemaVersion,
    );
  }
}

AnalyticsEventType _eventTypeFromStorage(String? raw) {
  for (final v in AnalyticsEventType.values) {
    if (v.name == raw) return v;
  }
  return AnalyticsEventType.taskStarted;
}
