import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_pattern.dart';
import 'pattern_scoring.dart';

class PatternDetectionContext {
  const PatternDetectionContext({
    this.scheduledTimeBlock,
    this.dataCompleteness = 1.0,
    this.sampleQuality = 1.0,
    this.detectedAtMs,
  });

  final String? scheduledTimeBlock;
  final double dataCompleteness;
  final double sampleQuality;
  final int? detectedAtMs;
}

class _PatternCandidate {
  const _PatternCandidate({
    required this.code,
    required this.group,
    required this.severity,
    required this.confidence,
    required this.metadata,
  });

  final PatternCode code;
  final PatternGroup group;
  final double severity;
  final double confidence;
  final Map<String, dynamic> metadata;
}

List<DetectedPattern> detectPatternsForFeature({
  required BehaviorFeatureObject feature,
  PatternDetectionContext context = const PatternDetectionContext(),
  Layer2PatternConfig config = kLayer2PatternConfig,
}) {
  final candidates = <_PatternCandidate>[
    ..._detectStreakConsistency(feature, context, config),
    ..._detectTimeBehavior(feature, context, config),
    ..._detectEffortDifficulty(feature, context, config),
    ..._detectGoalAlignment(feature, context, config),
    ..._detectBehavioralStability(feature, context, config),
  ];

  // Deterministic tie/merge policy:
  // if same pattern code appears multiple times for one entity, keep highest
  // severity, then highest confidence.
  final byCode = <PatternCode, _PatternCandidate>{};
  for (final candidate in candidates) {
    final existing = byCode[candidate.code];
    if (existing == null) {
      byCode[candidate.code] = candidate;
      continue;
    }
    if (candidate.severity > existing.severity) {
      byCode[candidate.code] = candidate;
      continue;
    }
    if (candidate.severity == existing.severity &&
        candidate.confidence > existing.confidence) {
      byCode[candidate.code] = candidate;
    }
  }

  final ordered = byCode.values.toList()
    ..sort((a, b) {
      final gc = a.group.index.compareTo(b.group.index);
      if (gc != 0) return gc;
      return a.code.name.compareTo(b.code.name);
    });

  final detectedAtMs =
      context.detectedAtMs ?? DateTime.now().millisecondsSinceEpoch;
  return ordered
      .map(
        (entry) => DetectedPattern(
          entityId: feature.entityId,
          entityKind: feature.entityKind,
          patternCode: entry.code,
          patternGroup: entry.group,
          severity: clampUnit(entry.severity),
          confidence: clampUnit(entry.confidence),
          detectedAtMs: detectedAtMs,
          sourceWindowStartDateKey: feature.windowStartDateKey ?? '',
          sourceWindowEndDateKey: feature.windowEndDateKey ?? '',
          metadata: entry.metadata,
        ),
      )
      .toList();
}

List<_PatternCandidate> _detectStreakConsistency(
  BehaviorFeatureObject feature,
  PatternDetectionContext context,
  Layer2PatternConfig config,
) {
  final out = <_PatternCandidate>[];
  final streak = feature.streakMetrics;
  final time = feature.timeMetrics;
  final signal7d = layer1CompletionSignal7d(time);

  if (streak.missedLast2Days) {
    final signal = ((streak.missedCount7d / 7.0) + (1.0 - signal7d)) / 2.0;
    final severity = computeHybridSeverity(
      patternCode: PatternCode.streakRisk,
      thresholdDistance: 1.0,
      signalStrength: signal,
      config: config,
    );
    out.add(
      _PatternCandidate(
        code: PatternCode.streakRisk,
        group: PatternGroup.streakConsistency,
        severity: severity,
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{
          'missedLast2Days': true,
          'missedCount7d': streak.missedCount7d,
        },
      ),
    );
  }

  if (streak.currentStreak >= config.thresholds.currentStreakStrong) {
    final distance = normalizedDistance(
      value: streak.currentStreak.toDouble(),
      threshold: config.thresholds.currentStreakStrong.toDouble(),
      higherIsWorse: true,
      maxSpan: config.thresholds.currentStreakStrong.toDouble(),
    );
    final signal = clampUnit(streak.currentStreak / 14.0);
    out.add(
      _PatternCandidate(
        code: PatternCode.strongStreak,
        group: PatternGroup.streakConsistency,
        severity: computeHybridSeverity(
          patternCode: PatternCode.strongStreak,
          thresholdDistance: distance,
          signalStrength: signal,
          config: config,
        ),
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{'currentStreak': streak.currentStreak},
      ),
    );
  }

  if (signal7d < config.thresholds.completionRate7dLow) {
    final distance = normalizedDistance(
      value: signal7d,
      threshold: config.thresholds.completionRate7dLow,
      higherIsWorse: false,
      maxSpan: config.thresholds.completionRate7dLow,
    );
    final signal = clampUnit(1.0 - signal7d);
    out.add(
      _PatternCandidate(
        code: PatternCode.inconsistentBehavior,
        group: PatternGroup.streakConsistency,
        severity: computeHybridSeverity(
          patternCode: PatternCode.inconsistentBehavior,
          thresholdDistance: distance,
          signalStrength: signal,
          config: config,
        ),
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{
          'completionSignal7d': signal7d,
          'completionRate7d': time.completionRate7d,
          'scheduledOccurrences7d': time.scheduledOccurrences7d,
          'flexCompletionFrequency7d': time.flexCompletionFrequency7d,
          'threshold': config.thresholds.completionRate7dLow,
        },
      ),
    );
  }

  return out;
}

List<_PatternCandidate> _detectTimeBehavior(
  BehaviorFeatureObject feature,
  PatternDetectionContext context,
  Layer2PatternConfig config,
) {
  final out = <_PatternCandidate>[];
  final time = feature.timeMetrics;

  if (time.lateCompletionRate7d > config.thresholds.lateRateHigh) {
    final distance = normalizedDistance(
      value: time.lateCompletionRate7d,
      threshold: config.thresholds.lateRateHigh,
      higherIsWorse: true,
      maxSpan: 1.0 - config.thresholds.lateRateHigh,
    );
    final signal = clampUnit(time.lateCompletionRate7d);
    out.add(
      _PatternCandidate(
        code: PatternCode.lateBehavior,
        group: PatternGroup.timeBehavior,
        severity: computeHybridSeverity(
          patternCode: PatternCode.lateBehavior,
          thresholdDistance: distance,
          signalStrength: signal,
          config: config,
        ),
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{
          'lateCompletionRate7d': time.lateCompletionRate7d,
          'threshold': config.thresholds.lateRateHigh,
        },
      ),
    );
  }

  final scheduledBlock = _sanitizeTimeBlock(context.scheduledTimeBlock);
  if (scheduledBlock != null &&
      scheduledBlock != feature.contextFeatures.bestTimeBlock) {
    final signal = 1.0;
    out.add(
      _PatternCandidate(
        code: PatternCode.timeMisalignment,
        group: PatternGroup.timeBehavior,
        severity: computeHybridSeverity(
          patternCode: PatternCode.timeMisalignment,
          thresholdDistance: 1.0,
          signalStrength: signal,
          config: config,
        ),
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{
          'scheduledTimeBlock': scheduledBlock,
          'bestTimeBlock': feature.contextFeatures.bestTimeBlock,
        },
      ),
    );
  }

  return out;
}

List<_PatternCandidate> _detectEffortDifficulty(
  BehaviorFeatureObject feature,
  PatternDetectionContext context,
  Layer2PatternConfig config,
) {
  final out = <_PatternCandidate>[];
  final time = feature.timeMetrics;
  final effort = feature.effortMetrics;
  final signal7d = layer1CompletionSignal7d(time);

  final tooHardTriggered =
      signal7d < config.thresholds.completionRate7dVeryLow &&
      effort.avgSnoozeCount > config.thresholds.avgSnoozeHigh;
  if (tooHardTriggered) {
    final completionDistance = normalizedDistance(
      value: signal7d,
      threshold: config.thresholds.completionRate7dVeryLow,
      higherIsWorse: false,
      maxSpan: config.thresholds.completionRate7dVeryLow,
    );
    final snoozeDistance = normalizedDistance(
      value: effort.avgSnoozeCount,
      threshold: config.thresholds.avgSnoozeHigh,
      higherIsWorse: true,
      maxSpan: config.thresholds.avgSnoozeHigh,
    );
    final distance = clampUnit((completionDistance + snoozeDistance) / 2.0);
    final signal = clampUnit(
      ((1.0 - signal7d) + (effort.avgSnoozeCount / 4.0)) / 2.0,
    );
    out.add(
      _PatternCandidate(
        code: PatternCode.tooHard,
        group: PatternGroup.effortDifficulty,
        severity: computeHybridSeverity(
          patternCode: PatternCode.tooHard,
          thresholdDistance: distance,
          signalStrength: signal,
          config: config,
        ),
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{
          'completionRate7d': time.completionRate7d,
          'avgSnoozeCount': effort.avgSnoozeCount,
        },
      ),
    );
  }

  final lowEngagementTriggered =
      effort.avgSnoozeCount > config.thresholds.avgSnoozeHigh && signal7d < 0.5;
  if (lowEngagementTriggered) {
    final completionDistance = normalizedDistance(
      value: signal7d,
      threshold: 0.5,
      higherIsWorse: false,
      maxSpan: 0.5,
    );
    final snoozeDistance = normalizedDistance(
      value: effort.avgSnoozeCount,
      threshold: config.thresholds.avgSnoozeHigh,
      higherIsWorse: true,
      maxSpan: config.thresholds.avgSnoozeHigh,
    );
    final distance = clampUnit((completionDistance + snoozeDistance) / 2.0);
    final signal = clampUnit(
      ((1.0 - signal7d) + (effort.avgSnoozeCount / 4.0)) / 2.0,
    );
    out.add(
      _PatternCandidate(
        code: PatternCode.lowEngagement,
        group: PatternGroup.effortDifficulty,
        severity: computeHybridSeverity(
          patternCode: PatternCode.lowEngagement,
          thresholdDistance: distance,
          signalStrength: signal,
          config: config,
        ),
        confidence: computeHybridConfidence(
          dataCompleteness: context.dataCompleteness,
          sampleQuality: context.sampleQuality,
          signalStrength: signal,
          config: config,
        ),
        metadata: <String, dynamic>{
          'completionRate7d': time.completionRate7d,
          'avgSnoozeCount': effort.avgSnoozeCount,
        },
      ),
    );
  }

  return out;
}

List<_PatternCandidate> _detectGoalAlignment(
  BehaviorFeatureObject feature,
  PatternDetectionContext context,
  Layer2PatternConfig config,
) {
  final out = <_PatternCandidate>[];
  if (feature.entityKind != BehaviorEntityKind.goal) return out;
  final goal = feature.goalMetrics;
  const gapThreshold = 0.2;
  if (goal.gap <= gapThreshold) return out;

  final distance = normalizedDistance(
    value: goal.gap,
    threshold: gapThreshold,
    higherIsWorse: true,
    maxSpan: 0.8,
  );
  final signal = clampUnit(goal.gap);
  out.add(
    _PatternCandidate(
      code: PatternCode.goalProgressDrift,
      group: PatternGroup.goalAlignment,
      severity: computeHybridSeverity(
        patternCode: PatternCode.goalProgressDrift,
        thresholdDistance: distance,
        signalStrength: signal,
        config: config,
      ),
      confidence: computeHybridConfidence(
        dataCompleteness: context.dataCompleteness,
        sampleQuality: context.sampleQuality,
        signalStrength: signal,
        config: config,
      ),
      metadata: <String, dynamic>{
        'progress': goal.progress,
        'expectedProgress': goal.expectedProgress,
        'gap': goal.gap,
      },
    ),
  );
  return out;
}

List<_PatternCandidate> _detectBehavioralStability(
  BehaviorFeatureObject feature,
  PatternDetectionContext context,
  Layer2PatternConfig config,
) {
  final out = <_PatternCandidate>[];
  if (feature.entityKind == BehaviorEntityKind.goal) return out;
  final time = feature.timeMetrics;
  final scheduled = time.scheduledOccurrences7d;
  if (scheduled < 5) return out;
  final missed = time.missedScheduledCount7d;
  final ratio = missed / scheduled;
  if (ratio < 0.75) return out;

  final distance = normalizedDistance(
    value: ratio,
    threshold: 0.75,
    higherIsWorse: true,
    maxSpan: 0.25,
  );
  final signal = clampUnit(ratio);
  out.add(
    _PatternCandidate(
      code: PatternCode.scheduleRhythmVolatile,
      group: PatternGroup.behavioralStability,
      severity: computeHybridSeverity(
        patternCode: PatternCode.scheduleRhythmVolatile,
        thresholdDistance: distance,
        signalStrength: signal,
        config: config,
      ),
      confidence: computeHybridConfidence(
        dataCompleteness: context.dataCompleteness,
        sampleQuality: context.sampleQuality,
        signalStrength: signal,
        config: config,
      ),
      metadata: <String, dynamic>{
        'missedScheduledCount7d': missed,
        'scheduledOccurrences7d': scheduled,
        'missedRatio7d': ratio,
      },
    ),
  );
  return out;
}

String? _sanitizeTimeBlock(String? raw) {
  switch (raw) {
    case 'morning':
    case 'afternoon':
    case 'evening':
      return raw;
    default:
      return null;
  }
}
