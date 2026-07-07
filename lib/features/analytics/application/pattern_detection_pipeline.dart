import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/detected_pattern.dart';
import 'behavior_pattern_phase2.dart';
import 'pattern_detection_engine.dart';
import 'pattern_layer2_compatibility.dart';

enum RuleEvaluationStatus { triggered, skipped, error }

class RuleEvaluationDiagnostic {
  const RuleEvaluationDiagnostic({
    required this.ruleCode,
    required this.status,
    required this.reason,
  });

  final PatternCode ruleCode;
  final RuleEvaluationStatus status;
  final String reason;
}

class EntityPatternDetectionResult {
  const EntityPatternDetectionResult({
    required this.entityId,
    required this.patterns,
    required this.behaviorPatterns,
    required this.diagnostics,
    required this.hasFatalError,
  });

  final String entityId;

  /// Legacy compatibility projection for Layer 3 / delivery.
  final List<DetectedPattern> patterns;

  /// Canonical Layer 2 interpretation + metric evidence.
  final List<DetectedBehaviorPattern> behaviorPatterns;
  final List<RuleEvaluationDiagnostic> diagnostics;
  final bool hasFatalError;
}

EntityPatternDetectionResult runPatternDetectionForEntity({
  required BehaviorFeatureObject feature,
  PatternDetectionContext context = const PatternDetectionContext(),
}) {
  final diagnostics = <RuleEvaluationDiagnostic>[];
  final entityId = feature.entityId.trim();

  if (entityId.isEmpty) {
    return EntityPatternDetectionResult(
      entityId: entityId,
      patterns: const <DetectedPattern>[],
      behaviorPatterns: const <DetectedBehaviorPattern>[],
      diagnostics: const <RuleEvaluationDiagnostic>[
        RuleEvaluationDiagnostic(
          ruleCode: PatternCode.streakRisk,
          status: RuleEvaluationStatus.error,
          reason: 'entity_id_missing',
        ),
      ],
      hasFatalError: true,
    );
  }

  if ((feature.windowStartDateKey ?? '').trim().isEmpty ||
      (feature.windowEndDateKey ?? '').trim().isEmpty) {
    diagnostics.add(
      const RuleEvaluationDiagnostic(
        ruleCode: PatternCode.streakRisk,
        status: RuleEvaluationStatus.skipped,
        reason: 'source_window_missing',
      ),
    );
  }

  try {
    final raw = detectPatternsForFeature(feature: feature, context: context);
    final behaviorPatterns = wrapDetectedPatternsWithEvidence(
      feature: feature,
      detected: raw,
      context: context,
    );
    final patterns = legacyPatternsFromCanonical(behaviorPatterns);
    final triggered = raw.map((p) => p.patternCode).toSet();

    final knownCodes = kLayer2V1PatternCodes.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final code in knownCodes) {
      diagnostics.add(
        RuleEvaluationDiagnostic(
          ruleCode: code,
          status: triggered.contains(code)
              ? RuleEvaluationStatus.triggered
              : RuleEvaluationStatus.skipped,
          reason: triggered.contains(code)
              ? 'rule_triggered'
              : 'condition_not_met',
        ),
      );
    }

    return EntityPatternDetectionResult(
      entityId: entityId,
      patterns: patterns,
      behaviorPatterns: behaviorPatterns,
      diagnostics: diagnostics,
      hasFatalError: false,
    );
  } catch (_) {
    return EntityPatternDetectionResult(
      entityId: entityId,
      patterns: const <DetectedPattern>[],
      behaviorPatterns: const <DetectedBehaviorPattern>[],
      diagnostics: const <RuleEvaluationDiagnostic>[
        RuleEvaluationDiagnostic(
          ruleCode: PatternCode.streakRisk,
          status: RuleEvaluationStatus.error,
          reason: 'pattern_detection_failed',
        ),
      ],
      hasFatalError: true,
    );
  }
}
