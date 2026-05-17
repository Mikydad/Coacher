import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/analytics/domain/models/generated_insight.dart';

part 'isar_generated_insight.g.dart';

@collection
class IsarGeneratedInsight {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String insightId;

  @Index(composite: [CompositeIndex('scopeId')])
  late String scopeType;

  @Index()
  late String scopeId;

  @Index()
  late String sourceWindowEndDateKey;

  @Index()
  late int updatedAtMs;

  late String insightType;
  late String insightBucket;
  late String priority;
  late String payloadJson;
  late int createdAtMs;
  late int schemaVersion;

  static IsarGeneratedInsight fromDomain(GeneratedInsight insight) {
    return IsarGeneratedInsight()
      ..insightId = insight.insightId
      ..scopeType = insight.scopeType.name
      ..scopeId = insight.scopeId
      ..sourceWindowEndDateKey = insight.sourceWindowEndDateKey
      ..updatedAtMs = insight.detectedAtMs
      ..insightType = insight.insightType.name
      ..insightBucket = insight.insightBucket.name
      ..priority = insight.priority.name
      ..payloadJson = jsonEncode(insight.toMap())
      ..createdAtMs = insight.detectedAtMs
      ..schemaVersion = insight.schemaVersion;
  }

  GeneratedInsight toDomain() {
    final payload = _decodePayload(payloadJson);
    final rawVersion =
        (payload['schemaVersion'] as num?)?.toInt() ?? schemaVersion;
    final compatiblePayload = rawVersion > kGeneratedInsightSchemaVersion
        ? <String, dynamic>{
            ...payload,
            'schemaVersion': kGeneratedInsightSchemaVersion,
          }
        : payload;
    return GeneratedInsight.fromMap(compatiblePayload);
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
