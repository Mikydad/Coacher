import '../domain/models/detected_pattern.dart';

class PatternAggregateRunMetadata {
  const PatternAggregateRunMetadata({
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

class PatternAggregateBuildResult {
  const PatternAggregateBuildResult({
    required this.snapshot,
    required this.metadata,
  });

  final GlobalPatternSnapshot snapshot;
  final PatternAggregateRunMetadata metadata;
}

PatternAggregateBuildResult buildGlobalPatternSnapshot({
  required String dateKey,
  required Iterable<DetectedPattern> patterns,
  required int entitiesProcessed,
  int elapsedMs = 0,
  int? detectedAtMs,
}) {
  final started = detectedAtMs ?? DateTime.now().millisecondsSinceEpoch;
  final all = patterns.toList();

  // Deterministic duplicate merge semantics:
  // (entityId + patternCode) duplicates collapse to one pattern with highest
  // severity, then highest confidence.
  final byEntityAndCode = <String, DetectedPattern>{};
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

  final grouped = <PatternCode, List<DetectedPattern>>{};
  for (final p in merged) {
    grouped.putIfAbsent(p.patternCode, () => <DetectedPattern>[]).add(p);
  }

  final entries = <GlobalPatternAggregateEntry>[];
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
      GlobalPatternAggregateEntry(
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

  final snapshot = GlobalPatternSnapshot(
    dateKey: dateKey,
    entries: entries,
    totalEntitiesProcessed: entitiesProcessed < 0 ? 0 : entitiesProcessed,
    totalPatternsEmitted: merged.length,
    weightedAverageSeverity: weightedAverageSeverity,
    detectedAtMs: started,
  );
  snapshot.validate();

  return PatternAggregateBuildResult(
    snapshot: snapshot,
    metadata: PatternAggregateRunMetadata(
      entitiesProcessed: entitiesProcessed < 0 ? 0 : entitiesProcessed,
      patternsEmitted: merged.length,
      elapsedMs: elapsedMs < 0 ? 0 : elapsedMs,
      schemaVersion: snapshot.schemaVersion,
    ),
  );
}
