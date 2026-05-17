import '../domain/models/generated_insight.dart';
import 'insight_generation_policy.dart';

class InsightPostProcessDiagnostics {
  const InsightPostProcessDiagnostics({
    required this.inputCount,
    required this.outputCount,
    required this.mergedCount,
    required this.suppressedCount,
    required this.cappedOutCount,
    required this.filteredByScopeCount,
  });

  final int inputCount;
  final int outputCount;
  final int mergedCount;
  final int suppressedCount;
  final int cappedOutCount;
  final int filteredByScopeCount;
}

class InsightPostProcessResult {
  const InsightPostProcessResult({
    required this.insights,
    required this.diagnostics,
  });

  final List<GeneratedInsight> insights;
  final InsightPostProcessDiagnostics diagnostics;
}

InsightPostProcessResult postProcessInsights({
  required List<GeneratedInsight> rawInsights,
  required InsightScopeType scopeType,
  Layer3InsightPolicyConfig config = kLayer3InsightPolicyConfig,
}) {
  final scoped = rawInsights
      .where((insight) => insight.scopeType == scopeType)
      .toList(growable: false);
  final filteredByScopeCount = rawInsights.length - scoped.length;

  final ordered = List<GeneratedInsight>.from(scoped)
    ..sort(compareInsightOrdering);

  final merged = <GeneratedInsight>[];
  var mergedCount = 0;
  for (final candidate in ordered) {
    if (config.mergePolicy.combineRelatedSignals) {
      final mergeIndex = merged.indexWhere(
        (existing) => _canMerge(existing, candidate),
      );
      if (mergeIndex >= 0) {
        merged[mergeIndex] = _mergeInsights(merged[mergeIndex], candidate);
        mergedCount += 1;
        continue;
      }
    }
    merged.add(candidate);
  }

  final dedupedByType = <String, GeneratedInsight>{};
  var suppressedCount = 0;
  for (final insight in merged) {
    if (!config.mergePolicy.dedupeByTypePerScope) {
      dedupedByType['${insight.insightId}::${dedupedByType.length}'] = insight;
      continue;
    }
    final key = mergeKeyForInsight(insight);
    final existing = dedupedByType[key];
    if (existing == null) {
      dedupedByType[key] = insight;
      continue;
    }
    final pickNew = compareInsightOrdering(insight, existing) < 0;
    dedupedByType[key] = pickNew ? insight : existing;
    suppressedCount += 1;
  }

  final finalOrdered = dedupedByType.values.toList()
    ..sort(compareInsightOrdering);
  final cap = scopeType == InsightScopeType.entity
      ? config.outputCaps.maxEntityInsights
      : config.outputCaps.maxGlobalInsights;
  final safeCap = cap < 0 ? 0 : cap;
  final cappedOutCount = finalOrdered.length > safeCap
      ? finalOrdered.length - safeCap
      : 0;
  final finalInsights = finalOrdered.take(safeCap).toList(growable: false);

  return InsightPostProcessResult(
    insights: finalInsights,
    diagnostics: InsightPostProcessDiagnostics(
      inputCount: rawInsights.length,
      outputCount: finalInsights.length,
      mergedCount: mergedCount,
      suppressedCount: suppressedCount,
      cappedOutCount: cappedOutCount,
      filteredByScopeCount: filteredByScopeCount,
    ),
  );
}

bool _canMerge(GeneratedInsight a, GeneratedInsight b) {
  if (a.scopeType != b.scopeType || a.scopeId != b.scopeId) return false;
  if (a.priority != b.priority) return false;
  if (a.insightBucket != b.insightBucket) return false;
  final overlappingCodes =
      a.linkedPatternCodes.toSet().intersection(b.linkedPatternCodes.toSet());
  return overlappingCodes.isNotEmpty;
}

GeneratedInsight _mergeInsights(GeneratedInsight a, GeneratedInsight b) {
  final preferred = compareInsightOrdering(a, b) <= 0 ? a : b;
  final mergedCodes = <String>{
    ...a.linkedPatternCodes,
    ...b.linkedPatternCodes,
  }.toList()
    ..sort();
  final mergedMetrics = <String, dynamic>{
    ...a.supportingMetrics,
    ...b.supportingMetrics,
  };
  final mergedConfidence =
      (a.confidence > b.confidence ? a.confidence : b.confidence).clamp(0.0, 1.0);
  // Lifecycle: if either side is reinforced the merged result is too.
  final mergedLifecycle =
      (a.lifecycleState == InsightLifecycleState.reinforced ||
              b.lifecycleState == InsightLifecycleState.reinforced)
          ? InsightLifecycleState.reinforced
          : preferred.lifecycleState;
  return GeneratedInsight(
    insightId: preferred.insightId,
    scopeType: preferred.scopeType,
    scopeId: preferred.scopeId,
    insightType: preferred.insightType,
    insightBucket: preferred.insightBucket,
    priority: preferred.priority,
    messageKey: preferred.messageKey,
    message: preferred.message,
    action: preferred.action,
    linkedPatternCodes: mergedCodes,
    confidence: mergedConfidence,
    detectedAtMs: preferred.detectedAtMs,
    sourceWindowStartDateKey: preferred.sourceWindowStartDateKey,
    sourceWindowEndDateKey: preferred.sourceWindowEndDateKey,
    lifecycleState: mergedLifecycle,
    urgency: (a.urgency > b.urgency ? a.urgency : b.urgency).clamp(0.0, 1.0),
    coachingImportance: (a.coachingImportance > b.coachingImportance
            ? a.coachingImportance
            : b.coachingImportance)
        .clamp(0.0, 1.0),
    supportingMetrics: mergedMetrics,
    metadata: <String, dynamic>{
      ...preferred.metadata,
      'merged': true,
    },
    schemaVersion: preferred.schemaVersion,
  );
}
