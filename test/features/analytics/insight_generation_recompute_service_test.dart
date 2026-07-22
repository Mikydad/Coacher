import 'package:sidepal/features/analytics/application/insight_generation_orchestrator.dart';
import 'package:sidepal/features/analytics/application/insight_generation_recompute_service.dart';
import 'package:sidepal/features/analytics/data/feature_cache_repository.dart';
import 'package:sidepal/features/analytics/data/insight_cache_repository.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';

class _MemoryFeatureCacheRepository implements FeatureCacheRepository {
  final Map<String, BehaviorFeatureObject> _items = <String, BehaviorFeatureObject>{};

  @override
  Future<BehaviorFeatureObject?> getByEntityId(String entityId) async => _items[entityId];

  @override
  Future<List<BehaviorFeatureObject>> listAll() async => _items.values.toList(growable: false);

  @override
  Future<List<BehaviorFeatureObject>> listByEntityKind(BehaviorEntityKind kind) async {
    return _items.values.where((item) => item.entityKind == kind).toList(growable: false);
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
    _items[feature.entityId] = feature;
  }

  @override
  Future<void> upsertFeatures(List<BehaviorFeatureObject> features) async {
    for (final feature in features) {
      _items[feature.entityId] = feature;
    }
  }

  @override
  Future<void> deleteByEntityId(String entityId) async {
    _items.remove(entityId.trim());
  }
}

class _MemoryInsightCacheRepository implements InsightCacheRepository {
  final Map<String, List<GeneratedInsight>> _byScope = <String, List<GeneratedInsight>>{};
  final Set<String> replacedScopeKeys = <String>{};

  String _scopeKey(InsightScopeType type, String scopeId) => '${type.name}::$scopeId';

  @override
  Future<void> replaceScopeInsights({
    required InsightScopeType scopeType,
    required String scopeId,
    required List<GeneratedInsight> insights,
  }) async {
    final key = _scopeKey(scopeType, scopeId);
    replacedScopeKeys.add(key);
    _byScope[key] = List<GeneratedInsight>.from(insights);
  }

  @override
  Future<List<GeneratedInsight>> listAll() async {
    return _byScope.values.expand((items) => items).toList(growable: false);
  }

  @override
  Future<List<GeneratedInsight>> listByScope({
    required InsightScopeType scopeType,
    required String scopeId,
  }) async {
    return _byScope[_scopeKey(scopeType, scopeId)] ?? const <GeneratedInsight>[];
  }

  @override
  Future<List<GeneratedInsight>> listByScopeAndDateWindow({
    required InsightScopeType scopeType,
    required String scopeId,
    String? startDateKey,
    String? endDateKey,
  }) async {
    return listByScope(scopeType: scopeType, scopeId: scopeId);
  }

  @override
  Future<void> upsertInsight(GeneratedInsight insight) async {
    await replaceScopeInsights(
      scopeType: insight.scopeType,
      scopeId: insight.scopeId,
      insights: <GeneratedInsight>[insight],
    );
  }

  @override
  Future<void> upsertInsights(List<GeneratedInsight> insights) async {
    for (final insight in insights) {
      await upsertInsight(insight);
    }
  }
}

void main() {
  test('recomputeEntity writes entity-scope insights', () async {
    final featureRepo = _MemoryFeatureCacheRepository();
    await featureRepo.upsertFeature(_feature('entity-1'));
    final cacheRepo = _MemoryInsightCacheRepository();
    final service = InsightGenerationRecomputeService(
      orchestrator: const InsightGenerationOrchestrator(),
      cacheRepository: cacheRepo,
      featureCacheRepository: featureRepo,
    );

    await service.recomputeEntity(
      entityId: 'entity-1',
      patterns: <DetectedPattern>[
        _pattern('entity-1', PatternCode.streakRisk, PatternGroup.streakConsistency),
      ],
      now: DateTime(2026, 5, 7, 10),
    );

    final rows = await cacheRepo.listByScope(
      scopeType: InsightScopeType.entity,
      scopeId: 'entity-1',
    );
    expect(rows, isNotEmpty);
    expect(rows.every((item) => item.scopeType == InsightScopeType.entity), isTrue);
  });

  test('recomputeBatch writes global and entity scopes', () async {
    final featureRepo = _MemoryFeatureCacheRepository();
    await featureRepo.upsertFeatures(<BehaviorFeatureObject>[
      _feature('entity-1'),
      _feature('entity-2'),
    ]);
    final cacheRepo = _MemoryInsightCacheRepository();
    final service = InsightGenerationRecomputeService(
      orchestrator: const InsightGenerationOrchestrator(),
      cacheRepository: cacheRepo,
      featureCacheRepository: featureRepo,
    );

    await service.recomputeBatch(
      dateKey: '2026-05-07',
      patternsByEntityId: <String, List<DetectedPattern>>{
        'entity-1': <DetectedPattern>[
          _pattern('entity-1', PatternCode.streakRisk, PatternGroup.streakConsistency),
        ],
        'entity-2': <DetectedPattern>[
          _pattern('entity-2', PatternCode.tooHard, PatternGroup.effortDifficulty),
        ],
      },
      now: DateTime(2026, 5, 7, 10),
    );

    final global = await cacheRepo.listByScope(
      scopeType: InsightScopeType.global,
      scopeId: '2026-05-07',
    );
    final entity1 = await cacheRepo.listByScope(
      scopeType: InsightScopeType.entity,
      scopeId: 'entity-1',
    );
    final entity2 = await cacheRepo.listByScope(
      scopeType: InsightScopeType.entity,
      scopeId: 'entity-2',
    );
    expect(
      cacheRepo.replacedScopeKeys.contains('global::2026-05-07'),
      isTrue,
    );
    expect(
      cacheRepo.replacedScopeKeys.contains('entity::entity-1'),
      isTrue,
    );
    expect(
      cacheRepo.replacedScopeKeys.contains('entity::entity-2'),
      isTrue,
    );
    expect(global, isNotNull);
    expect(entity1, isNotEmpty);
    expect(entity2, isNotEmpty);
  });
}

BehaviorFeatureObject _feature(String entityId) {
  return BehaviorFeatureObject(
    entityId: entityId,
    entityKind: BehaviorEntityKind.task,
    timeMetrics: testBehaviorTimeMetrics(
      scheduledOccurrences7d: 7,
      scheduledOccurrences30d: 30,
      completionRate7d: 0.5,
      completionRate30d: 0.5,
      lateCompletionRate7d: 0.2,
      lateCompletionRate30d: 0.2,
      avgCompletionDelayMinutes: 2,
    ),
    streakMetrics: const BehaviorStreakMetrics(
      currentStreak: 2,
      longestStreak: 3,
      missedLast2Days: false,
      missedCount7d: 1,
    ),
    effortMetrics: const BehaviorEffortMetrics(
      avgSnoozeCount: 1,
      avgSessionDuration: 18,
      plannedVsActualRatio: 0.9,
    ),
    goalMetrics: const BehaviorGoalMetrics(
      progress: 0.4,
      expectedProgress: 0.6,
      gap: -0.2,
    ),
    contextFeatures: const BehaviorContextFeatures(
      bestTimeBlock: 'morning',
      isHabitAnchor: false,
      priority: 3,
    ),
    computedAtMs: 1,
    windowStartDateKey: '2026-05-01',
    windowEndDateKey: '2026-05-07',
  );
}

DetectedPattern _pattern(
  String entityId,
  PatternCode code,
  PatternGroup group,
) {
  return DetectedPattern(
    entityId: entityId,
    entityKind: BehaviorEntityKind.task,
    patternCode: code,
    patternGroup: group,
    severity: 0.8,
    confidence: 0.8,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
