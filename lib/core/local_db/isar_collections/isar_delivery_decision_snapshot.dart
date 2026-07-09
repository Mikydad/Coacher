import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/analytics/domain/models/delivery_decision.dart';

part 'isar_delivery_decision_snapshot.g.dart';

@collection
class IsarDeliveryDecisionSnapshot {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String snapshotId;

  @Index()
  late String scopeId;

  @Index()
  late String surface;

  @Index()
  late int updatedAtMs;

  late String payloadJson;
  late int createdAtMs;
  late int schemaVersion;

  static IsarDeliveryDecisionSnapshot fromDomain({
    required String scopeId,
    required DeliverySurface surface,
    required DeliveryDecision decision,
  }) {
    final key = _snapshotId(scopeId: scopeId, surface: surface);
    return IsarDeliveryDecisionSnapshot()
      ..snapshotId = key
      ..scopeId = scopeId
      ..surface = surface.name
      ..updatedAtMs = decision.evaluatedAtMs
      ..payloadJson = jsonEncode(decision.toMap())
      ..createdAtMs = decision.evaluatedAtMs
      ..schemaVersion = decision.schemaVersion;
  }

  DeliveryDecision toDomain() {
    final payload = _decodePayload(payloadJson);
    final rawVersion =
        (payload['schemaVersion'] as num?)?.toInt() ?? schemaVersion;
    final compatiblePayload = rawVersion > kDeliveryDecisionSchemaVersion
        ? <String, dynamic>{
            ...payload,
            'schemaVersion': kDeliveryDecisionSchemaVersion,
          }
        : payload;
    return DeliveryDecision.fromMap(compatiblePayload);
  }
}

String decisionSnapshotId({
  required String scopeId,
  required DeliverySurface surface,
}) {
  return _snapshotId(scopeId: scopeId, surface: surface);
}

String _snapshotId({
  required String scopeId,
  required DeliverySurface surface,
}) => 'delivery::decision::${surface.name}::$scopeId';

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_delivery_decision_snapshot: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
