import '../../../../core/validation/model_validators.dart';

class AnalyticsStatsCache {
  const AnalyticsStatsCache({
    required this.id,
    required this.scopeType,
    required this.scopeId,
    required this.dateKey,
    required this.payload,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.schemaVersion = 1,
  });

  final String id;
  final String scopeType;
  final String scopeId;
  final String dateKey;
  final Map<String, dynamic> payload;
  final int createdAtMs;
  final int updatedAtMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(id, 'analyticsStats.id');
    ModelValidators.requireNotBlank(scopeType, 'analyticsStats.scopeType');
    ModelValidators.requireNotBlank(scopeId, 'analyticsStats.scopeId');
    ModelValidators.requireNotBlank(dateKey, 'analyticsStats.dateKey');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'analyticsStats.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'scopeType': scopeType,
    'scopeId': scopeId,
    'dateKey': dateKey,
    'payload': payload,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static AnalyticsStatsCache fromMap(Map<String, dynamic> map) => AnalyticsStatsCache(
    id: map['id'] as String? ?? '',
    scopeType: map['scopeType'] as String? ?? '',
    scopeId: map['scopeId'] as String? ?? '',
    dateKey: map['dateKey'] as String? ?? '',
    payload: (map['payload'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
    createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
  );
}
