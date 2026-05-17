import 'package:coach_for_life/features/analytics/application/feature_builder_assembler.dart';
import 'package:coach_for_life/features/analytics/application/feature_builder_input_adapters.dart';
import 'package:coach_for_life/features/analytics/application/feature_builder_orchestrator.dart';
import 'package:coach_for_life/features/analytics/application/feature_builder_recompute_service.dart';
import 'package:coach_for_life/features/analytics/data/analytics_repository.dart';
import 'package:coach_for_life/features/analytics/data/feature_cache_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';
import '../../support/no_op_goals_repository.dart';
import '../../support/no_op_planning_repository.dart';

class _NoOpAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {}

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {}

  @override
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  }) async => const [];

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async => const [];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {}
}

class _MemoryFeatureCacheRepository implements FeatureCacheRepository {
  final Map<String, BehaviorFeatureObject> map = {};
  int upsertSingleCalls = 0;
  int upsertBatchCalls = 0;

  @override
  Future<BehaviorFeatureObject?> getByEntityId(String entityId) async =>
      map[entityId];

  @override
  Future<List<BehaviorFeatureObject>> listAll() async => map.values.toList();

  @override
  Future<List<BehaviorFeatureObject>> listByEntityKind(
    BehaviorEntityKind kind,
  ) async {
    return map.values.where((v) => v.entityKind == kind).toList();
  }

  @override
  Future<List<BehaviorFeatureObject>> listByKindAndDateWindow({
    required BehaviorEntityKind kind,
    String? startDateKey,
    String? endDateKey,
  }) async {
    return listByEntityKind(kind);
  }

  @override
  Future<void> upsertFeature(BehaviorFeatureObject feature) async {
    upsertSingleCalls++;
    map[feature.entityId] = feature;
  }

  @override
  Future<void> upsertFeatures(List<BehaviorFeatureObject> features) async {
    upsertBatchCalls++;
    for (final feature in features) {
      map[feature.entityId] = feature;
    }
  }

  @override
  Future<void> deleteByEntityId(String entityId) async {
    map.remove(entityId.trim());
  }
}

class _FakeOrchestrator extends FeatureBuilderOrchestrator {
  _FakeOrchestrator({required this.entityFeature, required this.batchFeatures})
    : super(
        adapters: FeatureBuilderInputAdapters(
          analyticsRepository: _NoOpAnalyticsRepository(),
          planningRepository: NoOpPlanningRepository(),
          goalsRepository: NoOpGoalsRepository(),
        ),
      );

  final BehaviorFeatureObject entityFeature;
  final List<BehaviorFeatureObject> batchFeatures;
  int runForEntityCalls = 0;
  int runBatchCalls = 0;

  @override
  Future<FeatureEntityResult?> runForEntity({
    required String entityId,
    int trailingDays = 30,
    DateTime? now,
  }) async {
    runForEntityCalls++;
    if (entityId != entityFeature.entityId) return null;
    return FeatureEntityResult(
      entityId: entityId,
      feature: entityFeature,
      telemetry: const FeatureBatchTelemetry(
        startedAtMs: 1,
        elapsedMs: 1,
        totalEntities: 1,
        successCount: 1,
        failureCount: 0,
      ),
    );
  }

  @override
  Future<FeatureBatchResult> runBatch({
    int trailingDays = 30,
    DateTime? now,
  }) async {
    runBatchCalls++;
    return FeatureBatchResult(
      assembly: FeatureAssemblyResult(
        featuresByEntityId: {for (final f in batchFeatures) f.entityId: f},
        issues: const [],
      ),
      telemetry: FeatureBatchTelemetry(
        startedAtMs: now?.millisecondsSinceEpoch ?? 0,
        elapsedMs: 1,
        totalEntities: batchFeatures.length,
        successCount: batchFeatures.length,
        failureCount: 0,
      ),
    );
  }
}

void main() {
  test('debounces touched entity recompute calls', () async {
    final feature = _feature('entity-1');
    final orchestrator = _FakeOrchestrator(
      entityFeature: feature,
      batchFeatures: [feature],
    );
    final repo = _MemoryFeatureCacheRepository();
    final service = FeatureBuilderRecomputeService(
      orchestrator: orchestrator,
      cacheRepository: repo,
      debounce: const Duration(seconds: 5),
    );

    final first = await service.recomputeTouchedEntity(
      entityId: 'entity-1',
      now: DateTime(2026, 5, 6, 10, 0, 0),
    );
    final second = await service.recomputeTouchedEntity(
      entityId: 'entity-1',
      now: DateTime(2026, 5, 6, 10, 0, 2),
    );

    expect(first, true);
    expect(second, false);
    expect(orchestrator.runForEntityCalls, 1);
    expect(repo.upsertSingleCalls, 1);
  });

  test('daily refresh runs once per local day', () async {
    final feature = _feature('entity-1');
    final orchestrator = _FakeOrchestrator(
      entityFeature: feature,
      batchFeatures: [feature, _feature('entity-2')],
    );
    final repo = _MemoryFeatureCacheRepository();
    final service = FeatureBuilderRecomputeService(
      orchestrator: orchestrator,
      cacheRepository: repo,
    );

    final first = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 6, 8),
    );
    final second = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 6, 21),
    );
    final third = await service.maybeRunDailyFullRefresh(
      now: DateTime(2026, 5, 7, 8),
    );

    expect(first, true);
    expect(second, false);
    expect(third, true);
    expect(orchestrator.runBatchCalls, 2);
    expect(repo.upsertBatchCalls, 2);
    expect(repo.map.length, 2);
  });
}

BehaviorFeatureObject _feature(String entityId) {
  return BehaviorFeatureObject(
    entityId: entityId,
    entityKind: BehaviorEntityKind.task,
    timeMetrics: testBehaviorTimeMetrics(
      scheduledOccurrences7d: 7,
      scheduledOccurrences30d: 30,
      completionRate7d: 1,
      completionRate30d: 1,
    ),
    streakMetrics: const BehaviorStreakMetrics(
      currentStreak: 1,
      longestStreak: 1,
      missedLast2Days: false,
      missedCount7d: 0,
    ),
    effortMetrics: const BehaviorEffortMetrics(
      avgSnoozeCount: 0,
      avgSessionDuration: 20,
      plannedVsActualRatio: 1,
    ),
    goalMetrics: const BehaviorGoalMetrics(
      progress: 0,
      expectedProgress: 0,
      gap: 0,
    ),
    contextFeatures: const BehaviorContextFeatures(
      bestTimeBlock: 'morning',
      isHabitAnchor: false,
      priority: 3,
    ),
    computedAtMs: 1,
    windowStartDateKey: '2026-05-01',
    windowEndDateKey: '2026-05-06',
  );
}
