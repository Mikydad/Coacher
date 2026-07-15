import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/data/goals_repository.dart';
import '../data/feature_cache_repository.dart';
import '../data/insight_cache_repository.dart';
import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_pattern.dart';
import '../domain/models/generated_insight.dart';
import 'data_maturity.dart';
import 'insight_display_title.dart';
import 'insight_generation_orchestrator.dart';

/// Insight types allowed through while an entity is still `calibrating`:
/// concrete, high-evidence risk signals only. Praise and leverage insights
/// need a full observation window or they read as guessing.
const Set<InsightType> kCalibratingAllowedInsightTypes = {
  InsightType.streakRiskWarning,
  InsightType.fragileStreakAlert,
  InsightType.goalAtRisk,
};

class InsightGenerationRecomputeService {
  InsightGenerationRecomputeService({
    required InsightGenerationOrchestrator orchestrator,
    required InsightCacheRepository cacheRepository,
    required FeatureCacheRepository featureCacheRepository,
    GoalsRepository? goalsRepository,
    DataMaturityEvaluator? dataMaturityEvaluator,
  }) : _orchestrator = orchestrator,
       _cacheRepository = cacheRepository,
       _featureCacheRepository = featureCacheRepository,
       _goalsRepository = goalsRepository,
       _dataMaturityEvaluator = dataMaturityEvaluator;

  final InsightGenerationOrchestrator _orchestrator;
  final InsightCacheRepository _cacheRepository;
  final FeatureCacheRepository _featureCacheRepository;
  final GoalsRepository? _goalsRepository;

  /// Cold-start gate; null (tests) means ungated.
  final DataMaturityEvaluator? _dataMaturityEvaluator;

  Future<void> recomputeEntity({
    required String entityId,
    required List<DetectedPattern> patterns,
    required DateTime now,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return;
    final maturity = await _dataMaturityEvaluator?.evaluate();
    final feature = await _featureCacheRepository.getByEntityId(key);
    final out = _orchestrator.runForEntity(
      entityId: key,
      patterns: patterns,
      featureContext: _toLayer3FeatureContext(feature),
      now: now,
    );
    if (out.hasFatalError) return;
    final gated = gateInsightsByMaturity(
      insights: out.insights,
      maturity: maturity?.forEntity(key),
    );
    final insights = await _maybeWithDisplayTitles(gated);
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
    final maturity = await _dataMaturityEvaluator?.evaluate();
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
      final gated = gateInsightsByMaturity(
        insights: entity.insights,
        maturity: maturity?.forEntity(entity.entityId),
      );
      final insights = await _maybeWithDisplayTitles(gated);
      await _cacheRepository.replaceScopeInsights(
        scopeType: InsightScopeType.entity,
        scopeId: entity.entityId,
        insights: insights,
      );
    }
    if (!out.globalResult.hasFatalError) {
      // Global (cross-entity trend) insights need an established account-wide
      // observation window; before that they are aggregate guesses.
      final globalEstablished =
          maturity == null || maturity.global.isEstablished;
      await _cacheRepository.replaceScopeInsights(
        scopeType: InsightScopeType.global,
        scopeId: out.globalResult.dateKey,
        insights: globalEstablished
            ? out.globalResult.insights
            : const <GeneratedInsight>[],
      );
    }
  }

  Layer3FeatureContext? _toLayer3FeatureContext(
    BehaviorFeatureObject? feature,
  ) {
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

/// Applies the cold-start gate to one entity's freshly generated insights.
///
/// - `observing` (< 3 active days or < 5 events): nothing user-facing.
/// - `calibrating`: only [kCalibratingAllowedInsightTypes] with confidence
///   ≥ [kCalibratingConfidenceFloor].
/// - `established` (or [maturity] null = ungated): everything.
///
/// Every surviving insight is stamped with `supportingMetrics.dataMaturity`
/// so downstream consumers (AI phrasing, debugging) know how much data backs
/// it.
List<GeneratedInsight> gateInsightsByMaturity({
  required List<GeneratedInsight> insights,
  required EntityDataMaturity? maturity,
}) {
  if (maturity == null) return insights;
  switch (maturity.stage) {
    case DataMaturityStage.observing:
      return const <GeneratedInsight>[];
    case DataMaturityStage.calibrating:
      return insights
          .where(
            (insight) =>
                kCalibratingAllowedInsightTypes.contains(insight.insightType) &&
                insight.confidence >= kCalibratingConfidenceFloor,
          )
          .map((insight) => _withMaturityStamp(insight, maturity.stage))
          .toList(growable: false);
    case DataMaturityStage.established:
      return insights
          .map((insight) => _withMaturityStamp(insight, maturity.stage))
          .toList(growable: false);
  }
}

GeneratedInsight _withMaturityStamp(
  GeneratedInsight insight,
  DataMaturityStage stage,
) {
  return GeneratedInsight.fromMap({
    ...insight.toMap(),
    'supportingMetrics': <String, dynamic>{
      ...insight.supportingMetrics,
      'dataMaturity': stage.name,
    },
  });
}

final insightGenerationOrchestratorProvider =
    Provider<InsightGenerationOrchestrator>((ref) {
      return const InsightGenerationOrchestrator();
    });

final insightGenerationRecomputeServiceProvider =
    Provider<InsightGenerationRecomputeService>((ref) {
      return InsightGenerationRecomputeService(
        orchestrator: ref.read(insightGenerationOrchestratorProvider),
        cacheRepository: ref.read(insightCacheRepositoryProvider),
        featureCacheRepository: ref.read(featureCacheRepositoryProvider),
        goalsRepository: ref.read(goalsRepositoryProvider),
        dataMaturityEvaluator: ref.read(dataMaturityEvaluatorProvider),
      );
    });
