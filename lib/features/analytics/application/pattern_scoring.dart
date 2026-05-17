import '../domain/models/detected_pattern.dart';

const int kLayer2PatternConfigVersion = 1;

class PatternRuleThresholds {
  const PatternRuleThresholds({
    required this.completionRate7dLow,
    required this.completionRate7dVeryLow,
    required this.currentStreakStrong,
    required this.missedCount7dHigh,
    required this.lateRateHigh,
    required this.avgSnoozeHigh,
  });

  final double completionRate7dLow;
  final double completionRate7dVeryLow;
  final int currentStreakStrong;
  final int missedCount7dHigh;
  final double lateRateHigh;
  final double avgSnoozeHigh;
}

class PatternScoringWeights {
  const PatternScoringWeights({
    this.baseSeverityWeight = 0.65,
    this.distanceAdjustmentWeight = 0.35,
    this.signalStrengthWeight = 0.4,
    this.sampleQualityWeight = 0.35,
    this.dataCompletenessWeight = 0.25,
  });

  final double baseSeverityWeight;
  final double distanceAdjustmentWeight;
  final double signalStrengthWeight;
  final double sampleQualityWeight;
  final double dataCompletenessWeight;
}

class Layer2PatternConfig {
  const Layer2PatternConfig({
    required this.version,
    required this.thresholds,
    required this.baseSeverityByCode,
    this.weights = const PatternScoringWeights(),
  });

  final int version;
  final PatternRuleThresholds thresholds;
  final Map<PatternCode, double> baseSeverityByCode;
  final PatternScoringWeights weights;
}

const kLayer2PatternConfig = Layer2PatternConfig(
  version: kLayer2PatternConfigVersion,
  thresholds: PatternRuleThresholds(
    completionRate7dLow: 0.60,
    completionRate7dVeryLow: 0.40,
    currentStreakStrong: 7,
    missedCount7dHigh: 3,
    lateRateHigh: 0.60,
    avgSnoozeHigh: 2.0,
  ),
  baseSeverityByCode: <PatternCode, double>{
    PatternCode.streakRisk: 0.90,
    PatternCode.strongStreak: 0.15,
    PatternCode.inconsistentBehavior: 0.70,
    PatternCode.lateBehavior: 0.60,
    PatternCode.timeMisalignment: 0.55,
    PatternCode.tooHard: 0.80,
    PatternCode.lowEngagement: 0.65,
    PatternCode.goalProgressDrift: 0.72,
    PatternCode.scheduleRhythmVolatile: 0.68,
  },
);

double clampUnit(double value) => value.clamp(0.0, 1.0);

double clampNonNegative(double value) => value < 0 ? 0.0 : value;

double normalizedDistance({
  required double value,
  required double threshold,
  required bool higherIsWorse,
  required double maxSpan,
}) {
  final span = maxSpan <= 0 ? 1.0 : maxSpan;
  final raw = higherIsWorse ? (value - threshold) : (threshold - value);
  return clampUnit(raw / span);
}

double baseSeverityForPattern(
  PatternCode code, {
  Layer2PatternConfig config = kLayer2PatternConfig,
}) {
  return clampUnit(config.baseSeverityByCode[code] ?? 0.5);
}

double computeHybridSeverity({
  required PatternCode patternCode,
  required double thresholdDistance,
  required double signalStrength,
  Layer2PatternConfig config = kLayer2PatternConfig,
}) {
  final base = baseSeverityForPattern(patternCode, config: config);
  final distance = clampUnit(thresholdDistance);
  final signal = clampUnit(signalStrength);

  final weightedBase = base * config.weights.baseSeverityWeight;
  final weightedAdjustment =
      ((distance + signal) / 2.0) * config.weights.distanceAdjustmentWeight;
  return clampUnit(weightedBase + weightedAdjustment);
}

double computeHybridConfidence({
  required double dataCompleteness,
  required double sampleQuality,
  required double signalStrength,
  Layer2PatternConfig config = kLayer2PatternConfig,
}) {
  final completeness = clampUnit(dataCompleteness);
  final sample = clampUnit(sampleQuality);
  final signal = clampUnit(signalStrength);

  final value =
      (signal * config.weights.signalStrengthWeight) +
      (sample * config.weights.sampleQualityWeight) +
      (completeness * config.weights.dataCompletenessWeight);
  return clampUnit(value);
}
