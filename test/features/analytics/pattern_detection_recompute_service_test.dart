import 'package:coach_for_life/features/analytics/application/behavior_pattern_phase2.dart';
import 'package:coach_for_life/features/analytics/application/pattern_aggregate_builder.dart';
import 'package:coach_for_life/features/analytics/application/pattern_detection_orchestrator.dart';
import 'package:coach_for_life/features/analytics/application/pattern_detection_debug.dart';
import 'package:coach_for_life/features/analytics/application/pattern_detection_recompute_service.dart';
import 'package:coach_for_life/features/analytics/application/pattern_detection_pipeline.dart';
import 'package:coach_for_life/features/analytics/data/feature_cache_repository.dart';
import 'package:coach_for_life/features/analytics/data/pattern_detection_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_behavior_pattern.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePatternOrchestrator extends PatternDetectionOrchestrator {
  _FakePatternOrchestrator()
    : super(
        featureCacheRepository: _NoOpFeatureCacheRepository(),
        patternRepository: _NoOpPatternDetectionRepository(),
        debugStore: PatternDetectionDebugStore(),
      );

  int runForEntityCalls = 0;
  int runBatchCalls = 0;

  @override
  Future<EntityPatternDetectionResult?> runForEntity({
    required String entityId,
    DateTime? now,
    bool persist = true,
  }) async {
    runForEntityCalls++;
    return EntityPatternDetectionResult(
      entityId: entityId,
      patterns: const <DetectedPattern>[],
      behaviorPatterns: const <DetectedBehaviorPattern>[],
      diagnostics: const [],
      hasFatalError: false,
    );
  }

  @override
  Future<PatternDetectionBatchResult> runBatch({
    DateTime? now,
    bool persist = true,
  }) async {
    runBatchCalls++;
    return PatternDetectionBatchResult(
      entityResults: const [],
      snapshot: const GlobalPatternSnapshot(
        dateKey: '2026-05-07',
        entries: [],
        totalEntitiesProcessed: 0,
        totalPatternsEmitted: 0,
        weightedAverageSeverity: 0,
        detectedAtMs: 0,
      ),
      canonicalSnapshot: const GlobalBehaviorPatternSnapshot(
        dateKey: '2026-05-07',
        entries: [],
        totalEntitiesProcessed: 0,
        totalPatternsEmitted: 0,
        weightedAverageSeverity: 0,
        detectedAtMs: 0,
      ),
      metadata: PatternAggregateRunMetadata(
        entitiesProcessed: 0,
        patternsEmitted: 0,
        elapsedMs: 0,
        schemaVersion: 1,
      ),
      canonicalMetadata: BehaviorPatternPhase2AggregateRunMetadata(
        entitiesProcessed: 0,
        patternsEmitted: 0,
        elapsedMs: 0,
        schemaVersion: kGlobalBehaviorPatternSnapshotSchemaVersion,
      ),
    );
  }
}

class _NoOpFeatureCacheRepository implements FeatureCacheRepository {
  @override
  Future<BehaviorFeatureObject?> getByEntityId(String entityId) async => null;
  @override
  Future<List<BehaviorFeatureObject>> listAll() async => const [];
  @override
  Future<List<BehaviorFeatureObject>> listByEntityKind(
    BehaviorEntityKind kind,
  ) async => const [];
  @override
  Future<List<BehaviorFeatureObject>> listByKindAndDateWindow({
    required BehaviorEntityKind kind,
    String? startDateKey,
    String? endDateKey,
  }) async => const [];
  @override
  Future<void> upsertFeature(BehaviorFeatureObject feature) async {}
  @override
  Future<void> upsertFeatures(List<BehaviorFeatureObject> features) async {}
  @override
  Future<void> deleteByEntityId(String entityId) async {}
}

class _NoOpPatternDetectionRepository implements PatternDetectionRepository {
  @override
  Future<List<DetectedPattern>> readEntityPatterns({
    required String entityId,
    required String dateKey,
  }) async => const [];
  @override
  Future<GlobalPatternSnapshot?> readGlobalSnapshot({
    required String dateKey,
  }) async => null;
  @override
  Future<void> upsertEntityPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedPattern> patterns,
    required int updatedAtMs,
  }) async {}
  @override
  Future<void> upsertGlobalSnapshot(GlobalPatternSnapshot snapshot) async {}
  @override
  Future<void> upsertEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedBehaviorPattern> patterns,
    required int updatedAtMs,
  }) async {}
  @override
  Future<List<DetectedBehaviorPattern>> readEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
  }) async => const [];
  @override
  Future<void> upsertGlobalBehaviorSnapshot(
    GlobalBehaviorPatternSnapshot snapshot,
  ) async {}
  @override
  Future<GlobalBehaviorPatternSnapshot?> readGlobalBehaviorSnapshot({
    required String dateKey,
  }) async => null;
}

void main() {
  test('recompute service debounces entity and daily runs', () async {
    final orchestrator = _FakePatternOrchestrator();
    final service = PatternDetectionRecomputeService(
      orchestrator: orchestrator,
      debounce: const Duration(seconds: 5),
    );

    final a = await service.recomputeTouchedEntity(
      entityId: 'entity-1',
      now: DateTime(2026, 5, 7, 10, 0, 0),
    );
    final b = await service.recomputeTouchedEntity(
      entityId: 'entity-1',
      now: DateTime(2026, 5, 7, 10, 0, 1),
    );
    expect(a, true);
    expect(b, false);
    expect(orchestrator.runForEntityCalls, 1);

    final d1 = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 7, 9, 0, 0),
    );
    final d2 = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 7, 16, 0, 0),
    );
    final d3 = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 8, 9, 0, 0),
    );
    expect(d1, true);
    expect(d2, false);
    expect(d3, true);
    expect(orchestrator.runBatchCalls, 2);
  });

  test('invokes Layer3 callback for entity and batch recompute', () async {
    final orchestrator = _FakePatternOrchestrator();
    var entityCallbackCalls = 0;
    var batchCallbackCalls = 0;
    String? lastEntityId;
    String? lastDateKey;
    final service = PatternDetectionRecomputeService(
      orchestrator: orchestrator,
      onPatternsComputed: ({
        required String dateKey,
        required DateTime now,
        required bool fullRefresh,
        required String entityId,
        required EntityPatternDetectionResult? entityResult,
        required PatternDetectionBatchResult? batchResult,
      }) async {
        if (fullRefresh) {
          batchCallbackCalls++;
          lastDateKey = dateKey;
          expect(batchResult, isNotNull);
          return;
        }
        entityCallbackCalls++;
        lastEntityId = entityId;
        expect(entityResult, isNotNull);
      },
    );

    final entityRun = await service.recomputeTouchedEntity(
      entityId: 'entity-42',
      now: DateTime(2026, 5, 7, 10, 0, 0),
    );
    final dailyRun = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 7, 11, 0, 0),
    );

    expect(entityRun, true);
    expect(dailyRun, true);
    expect(entityCallbackCalls, 1);
    expect(batchCallbackCalls, 1);
    expect(lastEntityId, 'entity-42');
    expect(lastDateKey, '2026-05-07');
  });
}
