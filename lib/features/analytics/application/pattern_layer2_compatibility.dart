import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/detected_pattern.dart';

/// Temporary adapter: canonical Layer 2 → legacy [DetectedPattern] for Layer 3 / delivery.
///
/// Evidence is preserved under `metadata` for observability; Layer 3 rules should not
/// depend on these keys until migration completes.
DetectedPattern detectedPatternFromCanonical(DetectedBehaviorPattern p) {
  return DetectedPattern(
    entityId: p.entityId,
    entityKind: p.entityKind,
    patternCode: p.patternCode,
    patternGroup: p.patternGroup,
    severity: p.severity,
    confidence: p.confidence,
    detectedAtMs: p.detectedAtMs,
    sourceWindowStartDateKey: p.sourceWindowStartDateKey,
    sourceWindowEndDateKey: p.sourceWindowEndDateKey,
    metadata: <String, dynamic>{
      'layer2Canonical': true,
      'taxonomyFamily': p.taxonomyFamily.name,
      'evidence': p.evidence.map((e) => e.toMap()).toList(growable: false),
    },
    schemaVersion: kDetectedPatternSchemaVersion,
  );
}

List<DetectedPattern> legacyPatternsFromCanonical(
  Iterable<DetectedBehaviorPattern> canonical,
) {
  return canonical.map(detectedPatternFromCanonical).toList(growable: false);
}
