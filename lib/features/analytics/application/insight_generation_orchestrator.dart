import '../domain/models/detected_pattern.dart';
import '../domain/models/generated_insight.dart';
import 'insight_mapping_engine.dart';
import 'insight_post_processor.dart';

enum InsightGenerationDiagnosticStatus { info, skipped, error }

class InsightGenerationDiagnostic {
  const InsightGenerationDiagnostic({
    required this.code,
    required this.status,
    required this.reason,
  });

  final String code;
  final InsightGenerationDiagnosticStatus status;
  final String reason;
}

class Layer3FeatureContext {
  const Layer3FeatureContext({
    this.currentStreak,
    this.completionRate7d,
    this.entityLabel,
  });

  final int? currentStreak;
  final double? completionRate7d;
  final String? entityLabel;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (currentStreak != null) 'currentStreak': currentStreak,
      if (completionRate7d != null) 'completionRate7d': completionRate7d,
      if (entityLabel != null && entityLabel!.trim().isNotEmpty)
        'entityLabel': entityLabel!.trim(),
    };
  }
}

class EntityInsightGenerationResult {
  const EntityInsightGenerationResult({
    required this.entityId,
    required this.insights,
    required this.diagnostics,
    required this.hasFatalError,
    required this.postProcessDiagnostics,
  });

  final String entityId;
  final List<GeneratedInsight> insights;
  final List<InsightGenerationDiagnostic> diagnostics;
  final bool hasFatalError;
  final InsightPostProcessDiagnostics? postProcessDiagnostics;
}

class GlobalInsightGenerationResult {
  const GlobalInsightGenerationResult({
    required this.dateKey,
    required this.insights,
    required this.diagnostics,
    required this.hasFatalError,
    required this.postProcessDiagnostics,
  });

  final String dateKey;
  final List<GeneratedInsight> insights;
  final List<InsightGenerationDiagnostic> diagnostics;
  final bool hasFatalError;
  final InsightPostProcessDiagnostics? postProcessDiagnostics;
}

class InsightGenerationBatchMetadata {
  const InsightGenerationBatchMetadata({
    required this.entitiesProcessed,
    required this.entityErrors,
    required this.totalInsightsEmitted,
    required this.elapsedMs,
    required this.schemaVersion,
  });

  final int entitiesProcessed;
  final int entityErrors;
  final int totalInsightsEmitted;
  final int elapsedMs;
  final int schemaVersion;
}

class InsightGenerationBatchResult {
  const InsightGenerationBatchResult({
    required this.entityResults,
    required this.globalResult,
    required this.metadata,
  });

  final List<EntityInsightGenerationResult> entityResults;
  final GlobalInsightGenerationResult globalResult;
  final InsightGenerationBatchMetadata metadata;
}

class InsightGenerationOrchestrator {
  const InsightGenerationOrchestrator();

  EntityInsightGenerationResult runForEntity({
    required String entityId,
    required List<DetectedPattern> patterns,
    Layer3FeatureContext? featureContext,
    DateTime? now,
  }) {
    final trimmedEntityId = entityId.trim();
    if (trimmedEntityId.isEmpty) {
      return const EntityInsightGenerationResult(
        entityId: '',
        insights: <GeneratedInsight>[],
        diagnostics: <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'entity_id_missing',
            status: InsightGenerationDiagnosticStatus.error,
            reason: 'entity_id_missing',
          ),
        ],
        hasFatalError: true,
        postProcessDiagnostics: null,
      );
    }

    final contextWindow = _resolveWindow(patterns);
    if (contextWindow == null) {
      return EntityInsightGenerationResult(
        entityId: trimmedEntityId,
        insights: const <GeneratedInsight>[],
        diagnostics: const <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'source_window_missing',
            status: InsightGenerationDiagnosticStatus.skipped,
            reason: 'source_window_missing',
          ),
        ],
        hasFatalError: false,
        postProcessDiagnostics: null,
      );
    }

    try {
      final mapped = mapPatternsToInsights(
        patterns: patterns,
        context: InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: trimmedEntityId,
          sourceWindowStartDateKey: contextWindow.$1,
          sourceWindowEndDateKey: contextWindow.$2,
          detectedAtMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
        ),
      );
      final withContext = _attachFeatureContext(mapped, featureContext);
      final processed = postProcessInsights(
        rawInsights: withContext,
        scopeType: InsightScopeType.entity,
      );
      return EntityInsightGenerationResult(
        entityId: trimmedEntityId,
        insights: processed.insights,
        diagnostics: const <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'entity_processed',
            status: InsightGenerationDiagnosticStatus.info,
            reason: 'entity_processed',
          ),
        ],
        hasFatalError: false,
        postProcessDiagnostics: processed.diagnostics,
      );
    } catch (_) {
      return EntityInsightGenerationResult(
        entityId: trimmedEntityId,
        insights: const <GeneratedInsight>[],
        diagnostics: const <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'entity_generation_failed',
            status: InsightGenerationDiagnosticStatus.error,
            reason: 'entity_generation_failed',
          ),
        ],
        hasFatalError: true,
        postProcessDiagnostics: null,
      );
    }
  }

  GlobalInsightGenerationResult runForGlobalDay({
    required String dateKey,
    required List<DetectedPattern> patterns,
    DateTime? now,
  }) {
    final trimmedDateKey = dateKey.trim();
    if (trimmedDateKey.isEmpty) {
      return const GlobalInsightGenerationResult(
        dateKey: '',
        insights: <GeneratedInsight>[],
        diagnostics: <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'date_key_missing',
            status: InsightGenerationDiagnosticStatus.error,
            reason: 'date_key_missing',
          ),
        ],
        hasFatalError: true,
        postProcessDiagnostics: null,
      );
    }

    try {
      final mapped = mapPatternsToInsights(
        patterns: patterns,
        context: InsightMappingContext(
          scopeType: InsightScopeType.global,
          scopeId: trimmedDateKey,
          sourceWindowStartDateKey: trimmedDateKey,
          sourceWindowEndDateKey: trimmedDateKey,
          detectedAtMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
        ),
      );
      final processed = postProcessInsights(
        rawInsights: mapped,
        scopeType: InsightScopeType.global,
      );
      return GlobalInsightGenerationResult(
        dateKey: trimmedDateKey,
        insights: processed.insights,
        diagnostics: const <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'global_processed',
            status: InsightGenerationDiagnosticStatus.info,
            reason: 'global_processed',
          ),
        ],
        hasFatalError: false,
        postProcessDiagnostics: processed.diagnostics,
      );
    } catch (_) {
      return GlobalInsightGenerationResult(
        dateKey: trimmedDateKey,
        insights: const <GeneratedInsight>[],
        diagnostics: const <InsightGenerationDiagnostic>[
          InsightGenerationDiagnostic(
            code: 'global_generation_failed',
            status: InsightGenerationDiagnosticStatus.error,
            reason: 'global_generation_failed',
          ),
        ],
        hasFatalError: true,
        postProcessDiagnostics: null,
      );
    }
  }

  InsightGenerationBatchResult runBatch({
    required Map<String, List<DetectedPattern>> entityPatternsById,
    required String dateKey,
    List<DetectedPattern> globalPatterns = const <DetectedPattern>[],
    Map<String, Layer3FeatureContext> contextByEntityId = const {},
    DateTime? now,
  }) {
    final stopwatch = Stopwatch()..start();
    final entityResults = <EntityInsightGenerationResult>[];
    for (final entry in entityPatternsById.entries) {
      entityResults.add(
        runForEntity(
          entityId: entry.key,
          patterns: entry.value,
          featureContext: contextByEntityId[entry.key],
          now: now,
        ),
      );
    }
    final globalResult = runForGlobalDay(
      dateKey: dateKey,
      patterns: globalPatterns,
      now: now,
    );
    stopwatch.stop();

    final entityErrors = entityResults
        .where((result) => result.hasFatalError)
        .length;
    final totalInsightsEmitted =
        entityResults.fold<int>(
          0,
          (sum, result) => sum + result.insights.length,
        ) +
        globalResult.insights.length;

    return InsightGenerationBatchResult(
      entityResults: entityResults,
      globalResult: globalResult,
      metadata: InsightGenerationBatchMetadata(
        entitiesProcessed: entityResults.length,
        entityErrors: entityErrors,
        totalInsightsEmitted: totalInsightsEmitted,
        elapsedMs: stopwatch.elapsedMilliseconds,
        schemaVersion: kGeneratedInsightSchemaVersion,
      ),
    );
  }
}

List<GeneratedInsight> _attachFeatureContext(
  List<GeneratedInsight> insights,
  Layer3FeatureContext? featureContext,
) {
  if (featureContext == null) return insights;
  final contextMap = featureContext.toMap();
  if (contextMap.isEmpty) return insights;

  return insights
      .map(
        (insight) => GeneratedInsight(
          insightId: insight.insightId,
          scopeType: insight.scopeType,
          scopeId: insight.scopeId,
          insightType: insight.insightType,
          insightBucket: insight.insightBucket,
          priority: insight.priority,
          messageKey: insight.messageKey,
          message: insight.message,
          action: insight.action,
          linkedPatternCodes: insight.linkedPatternCodes,
          confidence: insight.confidence,
          detectedAtMs: insight.detectedAtMs,
          sourceWindowStartDateKey: insight.sourceWindowStartDateKey,
          sourceWindowEndDateKey: insight.sourceWindowEndDateKey,
          lifecycleState: insight.lifecycleState,
          urgency: insight.urgency,
          coachingImportance: insight.coachingImportance,
          supportingMetrics: insight.supportingMetrics,
          metadata: <String, dynamic>{
            ...insight.metadata,
            'featureContext': contextMap,
          },
          schemaVersion: insight.schemaVersion,
        ),
      )
      .toList(growable: false);
}

(String, String)? _resolveWindow(List<DetectedPattern> patterns) {
  for (final pattern in patterns) {
    final start = pattern.sourceWindowStartDateKey.trim();
    final end = pattern.sourceWindowEndDateKey.trim();
    if (start.isNotEmpty && end.isNotEmpty) {
      return (start, end);
    }
  }
  return null;
}
