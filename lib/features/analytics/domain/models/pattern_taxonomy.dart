import 'detected_pattern.dart';

/// Phase 2 taxonomy families (strict superset of [PatternGroup] semantics).
enum PatternTaxonomyFamily {
  streakConsistency,
  timeBehavior,
  effortDifficulty,
  goalAlignment,
  behavioralStability,
}

PatternTaxonomyFamily patternTaxonomyFamilyFromStorage(String? raw) {
  for (final value in PatternTaxonomyFamily.values) {
    if (value.name == raw) return value;
  }
  return PatternTaxonomyFamily.streakConsistency;
}

PatternTaxonomyFamily patternTaxonomyFamilyForGroup(PatternGroup group) {
  switch (group) {
    case PatternGroup.streakConsistency:
      return PatternTaxonomyFamily.streakConsistency;
    case PatternGroup.timeBehavior:
      return PatternTaxonomyFamily.timeBehavior;
    case PatternGroup.effortDifficulty:
      return PatternTaxonomyFamily.effortDifficulty;
    case PatternGroup.goalAlignment:
      return PatternTaxonomyFamily.goalAlignment;
    case PatternGroup.behavioralStability:
      return PatternTaxonomyFamily.behavioralStability;
  }
}

/// Declarative spec: stable IDs, documentation, required Layer 1 metric paths, scoring rule ids.
///
/// **Patterns = interpretation of metrics** — no advice strings, no LLM, no randomness.
class PatternTaxonomySpec {
  const PatternTaxonomySpec({
    required this.code,
    required this.family,
    required this.description,
    required this.requiredLayer1MetricPaths,
    required this.severityRuleId,
    required this.confidenceRuleId,
  });

  final PatternCode code;
  final PatternTaxonomyFamily family;
  final String description;
  final List<String> requiredLayer1MetricPaths;
  /// Id of deterministic hybrid rule in `pattern_scoring.dart` (`computeHybridSeverity`).
  final String severityRuleId;
  /// Id of deterministic hybrid rule (`computeHybridConfidence`).
  final String confidenceRuleId;
}

/// Canonical Phase 2 taxonomy (one entry per [PatternCode]).
const Map<PatternCode, PatternTaxonomySpec> kPatternTaxonomyByCode =
    <PatternCode, PatternTaxonomySpec>{
      PatternCode.streakRisk: PatternTaxonomySpec(
        code: PatternCode.streakRisk,
        family: PatternTaxonomyFamily.streakConsistency,
        description:
            'Recent completion gaps combined with low short-window adherence signal.',
        requiredLayer1MetricPaths: <String>[
          'streakMetrics.missedLast2Days',
          'streakMetrics.missedCount7d',
          'layer1.completionSignal7d',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.strongStreak: PatternTaxonomySpec(
        code: PatternCode.strongStreak,
        family: PatternTaxonomyFamily.streakConsistency,
        description: 'Current streak exceeds configured strong threshold.',
        requiredLayer1MetricPaths: <String>['streakMetrics.currentStreak'],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.inconsistentBehavior: PatternTaxonomySpec(
        code: PatternCode.inconsistentBehavior,
        family: PatternTaxonomyFamily.streakConsistency,
        description: 'Short-window completion signal below configured low band.',
        requiredLayer1MetricPaths: <String>[
          'layer1.completionSignal7d',
          'timeMetrics.scheduledOccurrences7d',
          'timeMetrics.flexCompletionFrequency7d',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.lateBehavior: PatternTaxonomySpec(
        code: PatternCode.lateBehavior,
        family: PatternTaxonomyFamily.timeBehavior,
        description: 'Share of completions after scheduled instants exceeds threshold.',
        requiredLayer1MetricPaths: <String>[
          'timeMetrics.lateCompletionRate7d',
          'timeMetrics.avgCompletionDelayMinutes',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.timeMisalignment: PatternTaxonomySpec(
        code: PatternCode.timeMisalignment,
        family: PatternTaxonomyFamily.timeBehavior,
        description:
            'Observed completion time block differs from externally supplied scheduled block (deterministic compare).',
        requiredLayer1MetricPaths: <String>[
          'contextFeatures.bestTimeBlock',
          'patternDetectionContext.scheduledTimeBlock',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.tooHard: PatternTaxonomySpec(
        code: PatternCode.tooHard,
        family: PatternTaxonomyFamily.effortDifficulty,
        description: 'Very low completion signal with elevated snooze/defer pressure.',
        requiredLayer1MetricPaths: <String>[
          'layer1.completionSignal7d',
          'effortMetrics.avgSnoozeCount',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.lowEngagement: PatternTaxonomySpec(
        code: PatternCode.lowEngagement,
        family: PatternTaxonomyFamily.effortDifficulty,
        description: 'Elevated snooze/defer with weak completion signal.',
        requiredLayer1MetricPaths: <String>[
          'layer1.completionSignal7d',
          'effortMetrics.avgSnoozeCount',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.goalProgressDrift: PatternTaxonomySpec(
        code: PatternCode.goalProgressDrift,
        family: PatternTaxonomyFamily.goalAlignment,
        description: 'Goal progress materially lags expected trajectory (gap metric).',
        requiredLayer1MetricPaths: <String>[
          'goalMetrics.progress',
          'goalMetrics.expectedProgress',
          'goalMetrics.gap',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
      PatternCode.scheduleRhythmVolatile: PatternTaxonomySpec(
        code: PatternCode.scheduleRhythmVolatile,
        family: PatternTaxonomyFamily.behavioralStability,
        description:
            'High ratio of missed scheduled days vs scheduled opportunities in trailing 7d.',
        requiredLayer1MetricPaths: <String>[
          'timeMetrics.scheduledOccurrences7d',
          'timeMetrics.missedScheduledCount7d',
        ],
        severityRuleId: 'layer2_hybrid_v1',
        confidenceRuleId: 'layer2_hybrid_confidence_v1',
      ),
    };
