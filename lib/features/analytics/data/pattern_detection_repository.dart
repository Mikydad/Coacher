import '../domain/models/analytics_stats_cache.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/detected_pattern.dart';
import 'analytics_repository.dart';

const String layer2EntityPatternsScope = 'layer2_entity_patterns';
const String layer2GlobalPatternsScope = 'layer2_global_patterns';
const String layer2CanonicalEntityPatternsScope =
    'layer2_canonical_entity_patterns';
const String layer2CanonicalGlobalPatternsScope =
    'layer2_canonical_global_patterns';

String _entityStatsId({required String entityId, required String dateKey}) =>
    'layer2::entity::$entityId::$dateKey';

String _globalStatsId({required String dateKey}) => 'layer2::global::$dateKey';

String _entityCanonicalStatsId({
  required String entityId,
  required String dateKey,
}) => 'layer2::canonical_entity::$entityId::$dateKey';

String _globalCanonicalStatsId({required String dateKey}) =>
    'layer2::canonical_global::$dateKey';

abstract class PatternDetectionRepository {
  Future<void> upsertEntityPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedPattern> patterns,
    required int updatedAtMs,
  });

  Future<List<DetectedPattern>> readEntityPatterns({
    required String entityId,
    required String dateKey,
  });

  Future<void> upsertGlobalSnapshot(GlobalPatternSnapshot snapshot);

  Future<GlobalPatternSnapshot?> readGlobalSnapshot({required String dateKey});

  Future<void> upsertEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedBehaviorPattern> patterns,
    required int updatedAtMs,
  });

  Future<List<DetectedBehaviorPattern>> readEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
  });

  Future<void> upsertGlobalBehaviorSnapshot(
    GlobalBehaviorPatternSnapshot snapshot,
  );

  Future<GlobalBehaviorPatternSnapshot?> readGlobalBehaviorSnapshot({
    required String dateKey,
  });
}

class StatsBackedPatternDetectionRepository
    implements PatternDetectionRepository {
  StatsBackedPatternDetectionRepository(this._analyticsRepository);

  final AnalyticsRepository _analyticsRepository;

  @override
  Future<void> upsertEntityPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedPattern> patterns,
    required int updatedAtMs,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return;
    final stats = AnalyticsStatsCache(
      id: _entityStatsId(entityId: key, dateKey: dateKey),
      scopeType: layer2EntityPatternsScope,
      scopeId: key,
      dateKey: dateKey,
      payload: <String, dynamic>{
        'entityId': key,
        'dateKey': dateKey,
        'patterns': patterns.map((p) => p.toMap()).toList(),
        'schemaVersion': kDetectedPatternSchemaVersion,
      },
      createdAtMs: updatedAtMs,
      updatedAtMs: updatedAtMs,
      schemaVersion: kDetectedPatternSchemaVersion,
    );
    await _analyticsRepository.upsertStatsCache(stats);
  }

  @override
  Future<List<DetectedPattern>> readEntityPatterns({
    required String entityId,
    required String dateKey,
  }) async {
    final rows = await _analyticsRepository.listStatsCache(
      scopeType: layer2EntityPatternsScope,
      scopeId: entityId.trim(),
      dateKey: dateKey,
    );
    if (rows.isEmpty) return const <DetectedPattern>[];
    final payload = rows.first.payload;
    final list = payload['patterns'];
    if (list is! List) return const <DetectedPattern>[];
    return list.map((item) {
      if (item is Map<String, dynamic>) return DetectedPattern.fromMap(item);
      if (item is Map) {
        return DetectedPattern.fromMap(item.cast<String, dynamic>());
      }
      return DetectedPattern.fromMap(const <String, dynamic>{});
    }).toList();
  }

  @override
  Future<void> upsertGlobalSnapshot(GlobalPatternSnapshot snapshot) async {
    final stats = AnalyticsStatsCache(
      id: _globalStatsId(dateKey: snapshot.dateKey),
      scopeType: layer2GlobalPatternsScope,
      scopeId: 'global',
      dateKey: snapshot.dateKey,
      payload: snapshot.toMap(),
      createdAtMs: snapshot.detectedAtMs,
      updatedAtMs: snapshot.detectedAtMs,
      schemaVersion: snapshot.schemaVersion,
    );
    await _analyticsRepository.upsertStatsCache(stats);
  }

  @override
  Future<GlobalPatternSnapshot?> readGlobalSnapshot({
    required String dateKey,
  }) async {
    final rows = await _analyticsRepository.listStatsCache(
      scopeType: layer2GlobalPatternsScope,
      scopeId: 'global',
      dateKey: dateKey,
    );
    if (rows.isEmpty) return null;
    return GlobalPatternSnapshot.fromMap(rows.first.payload);
  }

  @override
  Future<void> upsertEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedBehaviorPattern> patterns,
    required int updatedAtMs,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return;
    final stats = AnalyticsStatsCache(
      id: _entityCanonicalStatsId(entityId: key, dateKey: dateKey),
      scopeType: layer2CanonicalEntityPatternsScope,
      scopeId: key,
      dateKey: dateKey,
      payload: <String, dynamic>{
        'entityId': key,
        'dateKey': dateKey,
        'patterns': patterns.map((p) => p.toMap()).toList(),
        'schemaVersion': kDetectedBehaviorPatternSchemaVersion,
      },
      createdAtMs: updatedAtMs,
      updatedAtMs: updatedAtMs,
      schemaVersion: kDetectedBehaviorPatternSchemaVersion,
    );
    await _analyticsRepository.upsertStatsCache(stats);
  }

  @override
  Future<List<DetectedBehaviorPattern>> readEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
  }) async {
    final rows = await _analyticsRepository.listStatsCache(
      scopeType: layer2CanonicalEntityPatternsScope,
      scopeId: entityId.trim(),
      dateKey: dateKey,
    );
    if (rows.isEmpty) return const <DetectedBehaviorPattern>[];
    final payload = rows.first.payload;
    final list = payload['patterns'];
    if (list is! List) return const <DetectedBehaviorPattern>[];
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return DetectedBehaviorPattern.fromMap(item);
      }
      if (item is Map) {
        return DetectedBehaviorPattern.fromMap(item.cast<String, dynamic>());
      }
      return DetectedBehaviorPattern.fromMap(const <String, dynamic>{});
    }).toList();
  }

  @override
  Future<void> upsertGlobalBehaviorSnapshot(
    GlobalBehaviorPatternSnapshot snapshot,
  ) async {
    final stats = AnalyticsStatsCache(
      id: _globalCanonicalStatsId(dateKey: snapshot.dateKey),
      scopeType: layer2CanonicalGlobalPatternsScope,
      scopeId: 'global',
      dateKey: snapshot.dateKey,
      payload: snapshot.toMap(),
      createdAtMs: snapshot.detectedAtMs,
      updatedAtMs: snapshot.detectedAtMs,
      schemaVersion: snapshot.schemaVersion,
    );
    await _analyticsRepository.upsertStatsCache(stats);
  }

  @override
  Future<GlobalBehaviorPatternSnapshot?> readGlobalBehaviorSnapshot({
    required String dateKey,
  }) async {
    final rows = await _analyticsRepository.listStatsCache(
      scopeType: layer2CanonicalGlobalPatternsScope,
      scopeId: 'global',
      dateKey: dateKey,
    );
    if (rows.isEmpty) return null;
    return GlobalBehaviorPatternSnapshot.fromMap(rows.first.payload);
  }
}
