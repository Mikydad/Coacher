import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/data/goals_repository.dart';
import '../data/feature_cache_repository.dart';
import '../data/insight_cache_repository.dart';
import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_pattern.dart';
import '../domain/models/generated_insight.dart';
import 'insight_display_title.dart';
import 'insight_generation_orchestrator.dart';

class InsightGenerationRecomputeService {
  InsightGenerationRecomputeService({
    required InsightGenerationOrchestrator orchestrator,
    required InsightCacheRepository cacheRepository,
    required FeatureCacheRepository featureCacheRepository,
    GoalsRepository? goalsRepository,
  }) : _orchestrator = orchestrator,
       _cacheRepository = cacheRepository,
       _featureCacheRepository = featureCacheRepository,
       _goalsRepository = goalsRepository;

  final InsightGenerationOrchestrator _orchestrator;
  final InsightCacheRepository _cacheRepository;
  final FeatureCacheRepository _featureCacheRepository;
  final GoalsRepository? _goalsRepository;

  Future<void> recomputeEntity({
    required String entityId,
    required List<DetectedPattern> patterns,
    required DateTime now,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return;
    final feature = await _featureCacheRepository.getByEntityId(key);
    final out = _orchestrator.runForEntity(
      entityId: key,
      patterns: patterns,
      featureContext: _toLayer3FeatureContext(feature),
      now: now,
    );
    if (out.hasFatalError) return;
    final insights = await _maybeWithDisplayTitles(out.insights);
    await _cacheRepository.replaceScopeInsights(
      scopeType: InsightScopeType.entity,
      scopeId: key,
      insights: insights,
    );
  }

  Future<void> recomputeBatch({
    required String dateKey,
    required Map<String, List<DetectedPattern>> patternsByEntityId,
    required DateTime now,
  }) async {
    final contexts = <String, Layer3FeatureContext>{};
    for (final entityId in patternsByEntityId.keys) {
      final feature = await _featureCacheRepository.getByEntityId(entityId);
      final context = _toLayer3FeatureContext(feature);
      if (context != null) contexts[entityId] = context;
    }
    final globalPatterns = patternsByEntityId.values
        .expand((patterns) => patterns)
        .toList(growable: false);
    final out = _orchestrator.runBatch(
      entityPatternsById: patternsByEntityId,
      dateKey: dateKey,
      globalPatterns: globalPatterns,
      contextByEntityId: contexts,
      now: now,
    );
    for (final entity in out.entityResults) {
      if (entity.hasFatalError) continue;
      final insights = await _maybeWithDisplayTitles(entity.insights);
      await _cacheRepository.replaceScopeInsights(
        scopeType: InsightScopeType.entity,
        scopeId: entity.entityId,
        insights: insights,
      );
    }
    if (!out.globalResult.hasFatalError) {
      await _cacheRepository.replaceScopeInsights(
        scopeType: InsightScopeType.global,
        scopeId: out.globalResult.dateKey,
        insights: out.globalResult.insights,
      );
    }
  }

  Layer3FeatureContext? _toLayer3FeatureContext(BehaviorFeatureObject? feature) {
    if (feature == null) return null;
    return Layer3FeatureContext(
      currentStreak: feature.streakMetrics.currentStreak,
      completionRate7d: feature.timeMetrics.completionRate7d,
      entityLabel: feature.entityId,
    );
  }

  Future<List<GeneratedInsight>> _maybeWithDisplayTitles(
    List<GeneratedInsight> insights,
  ) async {
    final repo = _goalsRepository;
    if (repo == null) return insights;
    return enrichInsightsWithDisplayTitles(
      insights: insights,
      goalsRepository: repo,
    );
  }
}

final insightGenerationOrchestratorProvider = Provider<InsightGenerationOrchestrator>((
  ref,
) {
  return const InsightGenerationOrchestrator();
});

final insightGenerationRecomputeServiceProvider =
    Provider<InsightGenerationRecomputeService>((ref) {
      return InsightGenerationRecomputeService(
        orchestrator: ref.read(insightGenerationOrchestratorProvider),
        cacheRepository: ref.read(insightCacheRepositoryProvider),
        featureCacheRepository: ref.read(featureCacheRepositoryProvider),
        goalsRepository: ref.read(goalsRepositoryProvider),
      );
    });
