import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/analytics/domain/models/behavior_feature_object.dart';

part 'isar_behavior_feature_cache.g.dart';

@collection
class IsarBehaviorFeatureCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String entityId;

  @Index()
  late String entityKind;

  @Index()
  late int updatedAtMs;

  String? windowStartDateKey;
  String? windowEndDateKey;
  late String payloadJson;
  late int createdAtMs;
  late int schemaVersion;

  static IsarBehaviorFeatureCache fromDomain(BehaviorFeatureObject feature) {
    return IsarBehaviorFeatureCache()
      ..entityId = feature.entityId
      ..entityKind = feature.entityKind.name
      ..updatedAtMs = feature.computedAtMs
      ..windowStartDateKey = feature.windowStartDateKey
      ..windowEndDateKey = feature.windowEndDateKey
      ..payloadJson = jsonEncode(feature.toMap())
      ..createdAtMs = feature.computedAtMs
      ..schemaVersion = feature.schemaVersion;
  }

  BehaviorFeatureObject toDomain() {
    final payload = _decodePayload(payloadJson);
    final rawVersion = (payload['schemaVersion'] as num?)?.toInt() ?? schemaVersion;
    final compatiblePayload = rawVersion > kBehaviorFeatureSchemaVersion
        ? <String, dynamic>{
            ...payload,
            'schemaVersion': kBehaviorFeatureSchemaVersion,
          }
        : payload;
    return BehaviorFeatureObject.fromMap(compatiblePayload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {}
  return const <String, dynamic>{};
}
