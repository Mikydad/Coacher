import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/detected_pattern.dart';
import '../domain/models/pattern_taxonomy.dart';
import 'pattern_detection_engine.dart';
import 'pattern_layer2_compatibility.dart';
import 'pattern_scoring.dart';

/// Serialized Layer 1 (or declared detection-context) value for [path], or null if unknown.
String? valueForLayer1MetricPath(
  BehaviorFeatureObject f,
  String path, {
  PatternDetectionContext? ctx,
}) {
  final t = f.timeMetrics;
  final streak = f.streakMetrics;
  final effort = f.effortMetrics;
  final goal = f.goalMetrics;
  final context = f.contextFeatures;
  switch (path) {
    case 'streakMetrics.missedLast2Days':
      return streak.missedLast2Days.toString();
    case 'streakMetrics.missedCount7d':
      return streak.missedCount7d.toString();
    case 'streakMetrics.currentStreak':
      return streak.currentStreak.toString();
    case 'layer1.completionSignal7d':
      return layer1CompletionSignal7d(t).toString();
    case 'timeMetrics.scheduledOccurrences7d':
      return t.scheduledOccurrences7d.toString();
    case 'timeMetrics.flexCompletionFrequency7d':
      return t.flexCompletionFrequency7d.toString();
    case 'timeMetrics.lateCompletionRate7d':
      return t.lateCompletionRate7d.toString();
    case 'timeMetrics.avgCompletionDelayMinutes':
      return t.avgCompletionDelayMinutes.toString();
    case 'timeMetrics.missedScheduledCount7d':
      return t.missedScheduledCount7d.toString();
    case 'contextFeatures.bestTimeBlock':
      return context.bestTimeBlock;
    case 'patternDetectionContext.scheduledTimeBlock':
      return ctx?.scheduledTimeBlock;
    case 'effortMetrics.avgSnoozeCount':
      return effort.avgSnoozeCount.toString();
    case 'goalMetrics.progress':
      return goal.progress.toString();
    case 'goalMetrics.expectedProgress':
      return goal.expectedProgress.toString();
    case 'goalMetrics.gap':
      return goal.gap.toString();
    default:
      return null;
  }
}

List<PatternMetricEvidence> buildPatternMetricEvidence(
  BehaviorFeatureObject feature,
  PatternCode code,
  PatternDetectionContext context,
) {
  final spec = kPatternTaxonomyByCode[code];
  if (spec == null) return const [];
  return spec.requiredLayer1MetricPaths
      .map(
        (p) => PatternMetricEvidence(
          metricPath: p,
          valueSerialized:
              valueForLayer1MetricPath(feature, p, ctx: context) ?? 'null',
        ),
      )
      .toList(growable: false);
}

/// Wraps engine [DetectedPattern] rows with taxonomy + metric evidence (single detection pass).
List<DetectedBehaviorPattern> wrapDetectedPatternsWithEvidence({
  required BehaviorFeatureObject feature,
  required List<DetectedPattern> detected,
  required PatternDetectionContext context,
}) {
  return detected
      .map(
        (p) => DetectedBehaviorPattern(
          entityId: p.entityId,
          entityKind: p.entityKind,
          patternCode: p.patternCode,
          patternGroup: p.patternGroup,
          taxonomyFamily: patternTaxonomyFamilyForGroup(p.patternGroup),
          severity: p.severity,
          confidence: p.confidence,
          detectedAtMs: p.detectedAtMs,
          sourceWindowStartDateKey: p.sourceWindowStartDateKey,
          sourceWindowEndDateKey: p.sourceWindowEndDateKey,
          evidence: buildPatternMetricEvidence(feature, p.patternCode, context),
        ),
      )
      .toList(growable: false);
}

/// Layer 2 Phase 2: engine detection + taxonomy-aligned metric evidence.
List<DetectedBehaviorPattern> detectBehaviorPatternsForFeature({
  required BehaviorFeatureObject feature,
  PatternDetectionContext context = const PatternDetectionContext(),
  Layer2PatternConfig config = kLayer2PatternConfig,
}) {
  final detected = detectPatternsForFeature(
    feature: feature,
    context: context,
    config: config,
  );
  return wrapDetectedPatternsWithEvidence(
    feature: feature,
    detected: detected,
    context: context,
  );
}

/// Legacy [DetectedPattern] list from one detection pass (canonical → compat).
List<DetectedPattern> detectLegacyPatternsForFeature({
  required BehaviorFeatureObject feature,
  PatternDetectionContext context = const PatternDetectionContext(),
  Layer2PatternConfig config = kLayer2PatternConfig,
}) {
  final detected = detectPatternsForFeature(
    feature: feature,
    context: context,
    config: config,
  );
  final canonical = wrapDetectedPatternsWithEvidence(
    feature: feature,
    detected: detected,
    context: context,
  );
  return legacyPatternsFromCanonical(canonical);
}

class BehaviorPatternPhase2AggregateRunMetadata {
  const BehaviorPatternPhase2AggregateRunMetadata({
    required this.entitiesProcessed,
    required this.patternsEmitted,
    required this.elapsedMs,
    required this.schemaVersion,
  });

  final int entitiesProcessed;
  final int patternsEmitted;
  final int elapsedMs;
  final int schemaVersion;
}

class BehaviorPatternPhase2AggregateBuildResult {
  const BehaviorPatternPhase2AggregateBuildResult({
    required this.snapshot,
    required this.metadata,
  });

  final GlobalBehaviorPatternSnapshot snapshot;
  final BehaviorPatternPhase2AggregateRunMetadata metadata;
}

/// Day-level aggregate over [DetectedBehaviorPattern] (same merge/sort semantics as Layer 2 V1 global snapshot).
BehaviorPatternPhase2AggregateBuildResult buildGlobalBehaviorPatternSnapshot({
  required String dateKey,
  required Iterable<DetectedBehaviorPattern> patterns,
  required int entitiesProcessed,
  int elapsedMs = 0,
  int? detectedAtMs,
}) {
  final started = detectedAtMs ?? DateTime.now().millisecondsSinceEpoch;
  final all = patterns.toList();

  final byEntityAndCode = <String, DetectedBehaviorPattern>{};
  for (final p in all) {
    final key = '${p.entityId}::${p.patternCode.name}';
    final existing = byEntityAndCode[key];
    if (existing == null) {
      byEntityAndCode[key] = p;
      continue;
    }
    if (p.severity > existing.severity) {
      byEntityAndCode[key] = p;
      continue;
    }
    if (p.severity == existing.severity && p.confidence > existing.confidence) {
      byEntityAndCode[key] = p;
    }
  }
  final merged = byEntityAndCode.values.toList();

  final grouped = <PatternCode, List<DetectedBehaviorPattern>>{};
  for (final p in merged) {
    grouped.putIfAbsent(p.patternCode, () => <DetectedBehaviorPattern>[]).add(p);
  }

  final entries = <GlobalBehaviorPatternAggregateEntry>[];
  grouped.forEach((code, items) {
    if (items.isEmpty) return;
    final entityIds = <String>{for (final item in items) item.entityId};
    var severitySum = 0.0;
    var confidenceSum = 0.0;
    var maxSeverity = 0.0;
    for (final item in items) {
      severitySum += item.severity;
      confidenceSum += item.confidence;
      if (item.severity > maxSeverity) {
        maxSeverity = item.severity;
      }
    }
    final avgSeverity = items.isEmpty ? 0.0 : (severitySum / items.length);
    final avgConfidence = items.isEmpty ? 0.0 : (confidenceSum / items.length);
    entries.add(
      GlobalBehaviorPatternAggregateEntry(
        patternCode: code,
        patternGroup: items.first.patternGroup,
        entityCount: entityIds.length,
        occurrenceCount: items.length,
        averageSeverity: avgSeverity,
        maxSeverity: maxSeverity,
        averageConfidence: avgConfidence,
      ),
    );
  });

  entries.sort((a, b) {
    final gc = a.patternGroup.index.compareTo(b.patternGroup.index);
    if (gc != 0) return gc;
    return a.patternCode.name.compareTo(b.patternCode.name);
  });

  var weightedSeverityNumerator = 0.0;
  var weightedSeverityDenominator = 0.0;
  for (final entry in entries) {
    weightedSeverityNumerator += entry.averageSeverity * entry.occurrenceCount;
    weightedSeverityDenominator += entry.occurrenceCount;
  }
  final weightedAverageSeverity = weightedSeverityDenominator <= 0
      ? 0.0
      : (weightedSeverityNumerator / weightedSeverityDenominator);

  final snapshot = GlobalBehaviorPatternSnapshot(
    dateKey: dateKey,
    entries: entries,
    totalEntitiesProcessed: entitiesProcessed < 0 ? 0 : entitiesProcessed,
    totalPatternsEmitted: merged.length,
    weightedAverageSeverity: weightedAverageSeverity,
    detectedAtMs: started,
  );
  snapshot.validate();

  return BehaviorPatternPhase2AggregateBuildResult(
    snapshot: snapshot,
    metadata: BehaviorPatternPhase2AggregateRunMetadata(
      entitiesProcessed: entitiesProcessed < 0 ? 0 : entitiesProcessed,
      patternsEmitted: merged.length,
      elapsedMs: elapsedMs < 0 ? 0 : elapsedMs,
      schemaVersion: snapshot.schemaVersion,
    ),
  );
}
