import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/analytics/domain/models/analytics_stats_cache.dart';

part 'isar_analytics_stats.g.dart';

@collection
class IsarAnalyticsStats {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String statsId;

  @Index()
  late String scopeType;

  @Index()
  late String scopeId;

  @Index()
  late String dateKey;

  @Index()
  late int updatedAtMs;

  late String payloadJson;
  late int createdAtMs;
  late int schemaVersion;

  static IsarAnalyticsStats fromDomain(AnalyticsStatsCache s) {
    return IsarAnalyticsStats()
      ..statsId = s.id
      ..scopeType = s.scopeType
      ..scopeId = s.scopeId
      ..dateKey = s.dateKey
      ..updatedAtMs = s.updatedAtMs
      ..payloadJson = jsonEncode(s.payload)
      ..createdAtMs = s.createdAtMs
      ..schemaVersion = s.schemaVersion;
  }

  AnalyticsStatsCache toDomain() {
    return AnalyticsStatsCache(
      id: statsId,
      scopeType: scopeType,
      scopeId: scopeId,
      dateKey: dateKey,
      payload: _decodePayload(payloadJson),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
      schemaVersion: schemaVersion,
    );
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
