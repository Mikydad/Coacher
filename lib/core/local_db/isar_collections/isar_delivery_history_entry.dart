import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/analytics/domain/models/delivery_decision.dart';

part 'isar_delivery_history_entry.g.dart';

@collection
class IsarDeliveryHistoryEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String historyId;

  @Index()
  late String insightId;

  @Index(composite: [CompositeIndex('surface')])
  late String scopeId;

  @Index()
  late String surface;

  @Index()
  late int deliveredAtMs;

  late String payloadJson;
  late int createdAtMs;
  late int schemaVersion;

  static IsarDeliveryHistoryEntry fromDomain(DeliveryHistoryEntry entry) {
    return IsarDeliveryHistoryEntry()
      ..historyId = _historyId(entry)
      ..insightId = entry.insightId
      ..scopeId = entry.scopeId
      ..surface = entry.surface.name
      ..deliveredAtMs = entry.deliveredAtMs
      ..payloadJson = jsonEncode(entry.toMap())
      ..createdAtMs = entry.deliveredAtMs
      ..schemaVersion = entry.schemaVersion;
  }

  DeliveryHistoryEntry toDomain() {
    final payload = _decodePayload(payloadJson);
    final rawVersion =
        (payload['schemaVersion'] as num?)?.toInt() ?? schemaVersion;
    final compatiblePayload = rawVersion > kDeliveryHistorySchemaVersion
        ? <String, dynamic>{
            ...payload,
            'schemaVersion': kDeliveryHistorySchemaVersion,
          }
        : payload;
    return DeliveryHistoryEntry.fromMap(compatiblePayload);
  }
}

String _historyId(DeliveryHistoryEntry entry) {
  return 'delivery::history::${entry.scopeId}::${entry.insightId}::${entry.deliveredAtMs}';
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_delivery_history_entry: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
