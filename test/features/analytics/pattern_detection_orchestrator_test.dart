import 'package:sidepal/features/analytics/application/pattern_detection_orchestrator.dart';
import 'package:sidepal/features/analytics/application/pattern_detection_debug.dart';
import 'package:sidepal/features/analytics/data/analytics_repository.dart';
import 'package:sidepal/features/analytics/data/feature_cache_repository.dart';
import 'package:sidepal/features/analytics/data/pattern_detection_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';

class _MemoryAnalyticsRepository implements AnalyticsRepository {
  final Map<String, AnalyticsStatsCache> _stats = {};

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
  }) async => const <AnalyticsEvent>[];

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async {
    return _stats.values.where((s) {
      if (scopeType != null &&
          scopeType.isNotEmpty &&
          s.scopeType != scopeType) {
        return false;
      }
      if (scopeId != null && scopeId.isNotEmpty && s.scopeId != scopeId) {
        return false;
      }
      if (dateKey != null && dateKey.isNotEmpty && s.dateKey != dateKey) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {
    _stats[stats.id] = stats;
  }
}

class _MemoryFeatureCacheRepository implements FeatureCacheRepository {
  _MemoryFeatureCacheRepository(this._features);

  final Map<String, BehaviorFeatureObject> _features;

  @override
  Future<BehaviorFeatureObject?> getByEntityId(String entityId) async =>
      _features[entityId];

  @override
  Future<List<BehaviorFeatureObject>> listAll() async =>
      _features.values.toList();

  @override
  Future<List<BehaviorFeatureObject>> listByEntityKind(
    BehaviorEntityKind kind,
  ) async {
    return _features.values.where((f) => f.entityKind == kind).toList();
  }

  @override
  Future<List<BehaviorFeatureObject>> listByKindAndDateWindow({
    required BehaviorEntityKind kind,
    String? startDateKey,
    String? endDateKey,
  }) async => listByEntityKind(kind);

  @override
  Future<void> upsertFeature(BehaviorFeatureObject feature) async {
    _features[feature.entityId] = feature;
  }

  @override
  Future<void> upsertFeatures(List<BehaviorFeatureObject> features) async {
    for (final feature in features) {
      _features[feature.entityId] = feature;
    }
  }

  @override
  Future<void> deleteByEntityId(String entityId) async {
    _features.remove(entityId.trim());
  }
}

void main() {
  test(
    'orchestrator detects patterns and persists entity/global snapshots',
    () async {
      final analytics = _MemoryAnalyticsRepository();
      final patternRepo = StatsBackedPatternDetectionRepository(analytics);
      final featureRepo =
          _MemoryFeatureCacheRepository(<String, BehaviorFeatureObject>{
            'a': _feature(
              entityId: 'a',
              completionRate7d: 0.3,
              lateRate: 0.8,
              avgSnoozeCount: 3.0,
              missedLast2Days: true,
            ),
            'b': _feature(
              entityId: 'b',
              completionRate7d: 0.9,
              lateRate: 0.1,
              avgSnoozeCount: 0.1,
              missedLast2Days: false,
            ),
          });

      final orchestrator = PatternDetectionOrchestrator(
        featureCacheRepository: featureRepo,
        patternRepository: patternRepo,
        debugStore: PatternDetectionDebugStore(),
      );

      final out = await orchestrator.runBatch(
        now: DateTime(2026, 5, 7, 10),
        persist: true,
      );

      expect(out.entityResults.length, 2);
      expect(out.snapshot.totalEntitiesProcessed, 2);
      expect(out.snapshot.entries, isNotEmpty);

      final entityPatterns = await patternRepo.readEntityPatterns(
        entityId: 'a',
        dateKey: '2026-05-07',
      );
      expect(entityPatterns, isNotEmpty);

      final global = await patternRepo.readGlobalSnapshot(
        dateKey: '2026-05-07',
      );
      expect(global, isNotNull);
      expect(global!.entries, isNotEmpty);

      final canonicalEntity = await patternRepo.readEntityBehaviorPatterns(
        entityId: 'a',
        dateKey: '2026-05-07',
      );
      expect(canonicalEntity, isNotEmpty);
      final canonicalGlobal = await patternRepo.readGlobalBehaviorSnapshot(
        dateKey: '2026-05-07',
      );
      expect(canonicalGlobal, isNotNull);
      expect(canonicalGlobal!.totalPatternsEmitted, global.totalPatternsEmitted);
    },
  );

  test('orchestrator skips unchanged batch and logs telemetry event', () async {
    final analytics = _MemoryAnalyticsRepository();
    final patternRepo = StatsBackedPatternDetectionRepository(analytics);
    final debugStore = PatternDetectionDebugStore();
    final featureRepo =
        _MemoryFeatureCacheRepository(<String, BehaviorFeatureObject>{
          'a': _feature(
            entityId: 'a',
            completionRate7d: 0.3,
            lateRate: 0.8,
            avgSnoozeCount: 3.0,
            missedLast2Days: true,
          ),
        });

    final orchestrator = PatternDetectionOrchestrator(
      featureCacheRepository: featureRepo,
      patternRepository: patternRepo,
      debugStore: debugStore,
    );

    await orchestrator.runBatch(now: DateTime(2026, 5, 7, 10), persist: true);
    final second = await orchestrator.runBatch(
      now: DateTime(2026, 5, 7, 10, 1),
      persist: true,
    );

    expect(second.entityResults, hasLength(1));
    expect(second.entityResults.single.entityId, 'a');
    expect(debugStore.events, isNotEmpty);
    expect(debugStore.events.last.skippedUnchanged, true);
  });
}

BehaviorFeatureObject _feature({
  required String entityId,
  required double completionRate7d,
  required double lateRate,
  required double avgSnoozeCount,
  required bool missedLast2Days,
}) {
  return BehaviorFeatureObject(
    entityId: entityId,
    entityKind: BehaviorEntityKind.habit,
    timeMetrics: testBehaviorTimeMetrics(
      scheduledOccurrences7d: 7,
      scheduledOccurrences30d: 30,
      completionRate7d: completionRate7d,
      completionRate30d: completionRate7d,
      lateCompletionRate7d: lateRate,
      lateCompletionRate30d: lateRate,
      avgCompletionDelayMinutes: 20,
    ),
    streakMetrics: BehaviorStreakMetrics(
      currentStreak: missedLast2Days ? 0 : 8,
      longestStreak: 8,
      missedLast2Days: missedLast2Days,
      missedCount7d: missedLast2Days ? 4 : 0,
    ),
    effortMetrics: BehaviorEffortMetrics(
      avgSnoozeCount: avgSnoozeCount,
      avgSessionDuration: 25,
      plannedVsActualRatio: 1.0,
    ),
    goalMetrics: const BehaviorGoalMetrics(
      progress: 0.4,
      expectedProgress: 0.6,
      gap: 0.2,
    ),
    contextFeatures: const BehaviorContextFeatures(
      bestTimeBlock: 'evening',
      isHabitAnchor: true,
      priority: 2,
    ),
    computedAtMs: 1,
    windowStartDateKey: '2026-05-01',
    windowEndDateKey: '2026-05-07',
  );
}
