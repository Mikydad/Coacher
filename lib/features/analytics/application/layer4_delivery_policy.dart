import '../domain/models/generated_insight.dart';

const int kLayer4DeliveryPolicyConfigVersion = 1;

enum DeliveryTimingProfile {
  morning,
  afternoon,
  evening,
  night,
  postCompletion,
}

class DeliveryThresholds {
  const DeliveryThresholds({
    required this.lowConfidenceSuppression,
    required this.notifyConfidenceHigh,
    required this.notifyConfidenceMedium,
  });

  final double lowConfidenceSuppression;
  final double notifyConfidenceHigh;
  final double notifyConfidenceMedium;
}

class AdaptiveCooldownPolicy {
  const AdaptiveCooldownPolicy({
    required this.highPriorityHours,
    required this.mediumPriorityHours,
    required this.lowPriorityHours,
  });

  final int highPriorityHours;
  final int mediumPriorityHours;
  final int lowPriorityHours;
}

class SelectionPolicy {
  const SelectionPolicy({required this.maxPrimary, required this.maxSecondary});

  final int maxPrimary;
  final int maxSecondary;
}

class TimingRuleWeights {
  const TimingRuleWeights({
    this.morningDoNowBonus = 0.08,
    this.eveningReinforcementBonus = 0.08,
    this.postCompletionReinforcementBonus = 0.12,
  });

  final double morningDoNowBonus;
  final double eveningReinforcementBonus;
  final double postCompletionReinforcementBonus;
}

class Layer4DeliveryPolicyConfig {
  const Layer4DeliveryPolicyConfig({
    required this.version,
    required this.selection,
    required this.cooldowns,
    required this.thresholds,
    required this.timingWeights,
  });

  final int version;
  final SelectionPolicy selection;
  final AdaptiveCooldownPolicy cooldowns;
  final DeliveryThresholds thresholds;
  final TimingRuleWeights timingWeights;
}

const kLayer4DeliveryPolicyConfig = Layer4DeliveryPolicyConfig(
  version: kLayer4DeliveryPolicyConfigVersion,
  selection: SelectionPolicy(maxPrimary: 1, maxSecondary: 1),
  cooldowns: AdaptiveCooldownPolicy(
    highPriorityHours: 8,
    mediumPriorityHours: 16,
    lowPriorityHours: 24,
  ),
  thresholds: DeliveryThresholds(
    lowConfidenceSuppression: 0.45,
    notifyConfidenceHigh: 0.55,
    notifyConfidenceMedium: 0.70,
  ),
  timingWeights: TimingRuleWeights(),
);

DeliveryTimingProfile resolveTimingProfile({
  required DateTime now,
  required bool justCompletedTask,
}) {
  if (justCompletedTask) return DeliveryTimingProfile.postCompletion;
  final hour = now.hour;
  if (hour >= 5 && hour <= 11) return DeliveryTimingProfile.morning;
  if (hour >= 12 && hour <= 16) return DeliveryTimingProfile.afternoon;
  if (hour >= 17 && hour <= 22) return DeliveryTimingProfile.evening;
  return DeliveryTimingProfile.night;
}

int cooldownHoursForPriority(
  InsightPriority priority, {
  Layer4DeliveryPolicyConfig config = kLayer4DeliveryPolicyConfig,
}) {
  switch (priority) {
    case InsightPriority.high:
      return config.cooldowns.highPriorityHours;
    case InsightPriority.medium:
      return config.cooldowns.mediumPriorityHours;
    case InsightPriority.low:
      return config.cooldowns.lowPriorityHours;
  }
}

bool passesNotificationGate(
  GeneratedInsight insight, {
  Layer4DeliveryPolicyConfig config = kLayer4DeliveryPolicyConfig,
}) {
  switch (insight.priority) {
    case InsightPriority.high:
      return insight.confidence >= config.thresholds.notifyConfidenceHigh;
    case InsightPriority.medium:
      return insight.confidence >= config.thresholds.notifyConfidenceMedium;
    case InsightPriority.low:
      return false;
  }
}

bool isLowConfidence(
  GeneratedInsight insight, {
  Layer4DeliveryPolicyConfig config = kLayer4DeliveryPolicyConfig,
}) {
  return insight.confidence < config.thresholds.lowConfidenceSuppression;
}

double basePriorityScore(InsightPriority priority) {
  switch (priority) {
    case InsightPriority.high:
      return 1.0;
    case InsightPriority.medium:
      return 0.6;
    case InsightPriority.low:
      return 0.3;
  }
}

double scoreDeliveryCandidate(
  GeneratedInsight insight, {
  required DeliveryTimingProfile profile,
  Layer4DeliveryPolicyConfig config = kLayer4DeliveryPolicyConfig,
}) {
  var score = basePriorityScore(insight.priority) + (insight.confidence * 0.5);

  if (profile == DeliveryTimingProfile.morning &&
      insight.action == InsightAction.doNow) {
    score += config.timingWeights.morningDoNowBonus;
  }
  if (profile == DeliveryTimingProfile.evening &&
      insight.insightBucket == InsightBucket.reinforcement) {
    score += config.timingWeights.eveningReinforcementBonus;
  }
  if (profile == DeliveryTimingProfile.postCompletion &&
      insight.insightBucket == InsightBucket.reinforcement) {
    score += config.timingWeights.postCompletionReinforcementBonus;
  }
  return score;
}

int compareDeliveryCandidates(
  GeneratedInsight a,
  GeneratedInsight b, {
  required DeliveryTimingProfile profile,
}) {
  final scoreCmp = scoreDeliveryCandidate(
    b,
    profile: profile,
  ).compareTo(scoreDeliveryCandidate(a, profile: profile));
  if (scoreCmp != 0) return scoreCmp;
  final priorityCmp = basePriorityScore(
    b.priority,
  ).compareTo(basePriorityScore(a.priority));
  if (priorityCmp != 0) return priorityCmp;
  final confidenceCmp = b.confidence.compareTo(a.confidence);
  if (confidenceCmp != 0) return confidenceCmp;
  final typeCmp = a.insightType.name.compareTo(b.insightType.name);
  if (typeCmp != 0) return typeCmp;
  return a.insightId.compareTo(b.insightId);
}
