import '../../../features/coaching/application/enforcement_mode_policy.dart';
import '../../../features/coaching/domain/models/enforcement_mode.dart';
import '../domain/models/current_coaching_focus.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/generated_insight.dart';
import 'focus_candidate.dart';
import 'layer4_delivery_policy.dart';

// ─── Scoring policy ───────────────────────────────────────────────────────────

class FocusScoringWeights {
  const FocusScoringWeights({
    this.urgency = 0.30,
    this.momentum = 0.20,
    this.feasibility = 0.20,
    this.risk = 0.20,
    this.recovery = 0.10,
  });

  final double urgency;
  final double momentum;
  final double feasibility;
  final double risk;
  final double recovery;
}

const kFocusScoringWeights = FocusScoringWeights();

// ─── Sub-score helpers ───────────────────────────────────────────────────────

/// 0–1 how time-sensitive the coaching action is.
///
/// [enforcementMode] applies the FR-D-17 urgency multiplier:
/// flexible ×0.8 / disciplined ×1.0 / extreme ×1.3.
double computeUrgencyScore({
  required GeneratedInsight insight,
  required FocusRealtimeContext ctx,
  EnforcementMode enforcementMode = EnforcementMode.disciplined,
}) {
  // Base from Phase 3 insight urgency.
  var score = insight.urgency;

  // Overdue items amplify urgency.
  if (ctx.overdueCount > 0) {
    final overdueBoost = (ctx.overdueCount / 5).clamp(0.0, 0.3);
    score += overdueBoost + ctx.highestOverdueSeverity * 0.2;
  }

  // In a focus session: suppress actionable recommendations.
  if (ctx.isInFocusSession) {
    score *= 0.4;
  }

  // Apply enforcement mode urgency multiplier (FR-D-17).
  score *= EnforcementModePolicy.urgencyMultiplier(enforcementMode);

  return score.clamp(0.0, 1.0);
}

/// 0–1 strength of current behavioral momentum for the entity.
double computeMomentumScore({
  required GeneratedInsight insight,
  required List<DetectedBehaviorPattern> patterns,
}) {
  // Start from Phase 3 coachingImportance as a baseline proxy.
  var score = insight.coachingImportance * 0.5;

  // Boost if insight is reinforcement bucket (positive momentum signal).
  if (insight.insightBucket == InsightBucket.reinforcement) {
    score += 0.4;
  }

  // Boost for reinforced lifecycle (pattern has persisted across cycles).
  if (insight.lifecycleState == InsightLifecycleState.reinforced) {
    score += 0.15;
  }

  // Look for strongStreak pattern evidence.
  final hasStrongStreak = patterns.any(
    (p) => p.patternCode.name == 'strongStreak',
  );
  if (hasStrongStreak) score += 0.2;

  // Penalise if streak at risk.
  final hasStreakRisk = patterns.any(
    (p) => p.patternCode.name == 'streakRisk',
  );
  if (hasStreakRisk) score -= 0.15;

  return score.clamp(0.0, 1.0);
}

/// 0–1 how feasible / actionable this is RIGHT NOW given timing + schedule.
double computeFeasibilityScore({
  required GeneratedInsight insight,
  required FocusRealtimeContext ctx,
}) {
  var score = 0.5; // neutral baseline

  // Upcoming items window: if something is due soon this is more actionable.
  if (ctx.upcomingScheduledCount > 0) {
    score += (ctx.upcomingScheduledCount / 3).clamp(0.0, 0.25);
  }

  // Morning + doNow: high feasibility.
  if (ctx.timingProfile == DeliveryTimingProfile.morning &&
      insight.action == InsightAction.doNow) {
    score += 0.2;
  }

  // Post-completion: reinforce is most feasible.
  if (ctx.timingProfile == DeliveryTimingProfile.postCompletion &&
      insight.insightBucket == InsightBucket.reinforcement) {
    score += 0.25;
  }

  // In-focus session: nothing else is feasible.
  if (ctx.isInFocusSession) score *= 0.2;

  return score.clamp(0.0, 1.0);
}

/// 0–1 how serious the behavioral risk is if this focus is not addressed.
double computeRiskScore({
  required GeneratedInsight insight,
  required List<DetectedBehaviorPattern> patterns,
}) {
  var score = 0.0;

  if (insight.insightBucket == InsightBucket.risk) {
    score = insight.confidence * 0.8 +
        patterns
                .where(
                  (p) =>
                      p.patternCode.name == 'streakRisk' ||
                      p.patternCode.name == 'tooHard',
                )
                .map((p) => p.severity)
                .fold<double>(0.0, (a, b) => a + b)
                .clamp(0.0, 0.4) /
            0.4 *
            0.2;
  } else if (insight.insightBucket == InsightBucket.neutral) {
    score = insight.confidence * 0.4;
  } else {
    // Reinforcement: minimal risk.
    score = 0.05;
  }

  return score.clamp(0.0, 1.0);
}

/// 0–1 how strong the recovery opportunity is (prior momentum, recoverability).
double computeRecoveryScore({
  required GeneratedInsight insight,
  required List<DetectedBehaviorPattern> patterns,
}) {
  // Recovery applies when there is inconsistency or streak risk but also
  // prior evidence of good behavior.
  var score = 0.0;

  final hasInconsistency = patterns.any(
    (p) => p.patternCode.name == 'inconsistentBehavior',
  );
  final hasStreakRisk = patterns.any(
    (p) => p.patternCode.name == 'streakRisk',
  );

  if (hasInconsistency || hasStreakRisk) {
    score += 0.5;
    // Stronger recovery opportunity when confidence is high (user CAN do it).
    score += insight.confidence * 0.3;
    // Check evidence for recent positive signal (completionRate > 0.5).
    final metrics = insight.supportingMetrics;
    final evidence = metrics.values
        .whereType<Map>()
        .expand((m) => m.entries)
        .where((e) => e.key.toString().contains('completionRate'))
        .map((e) => (e.value as num?)?.toDouble() ?? 0.0)
        .toList();
    if (evidence.any((v) => v >= 0.5)) score += 0.2;
  }

  return score.clamp(0.0, 1.0);
}

// ─── Composite focus score ────────────────────────────────────────────────────

FocusScoreBreakdown computeFocusScoreBreakdown(
  FocusCandidate candidate, {
  FocusScoringWeights weights = kFocusScoringWeights,
}) {
  final urgency = computeUrgencyScore(
    insight: candidate.insight,
    ctx: candidate.realtimeContext,
    enforcementMode: candidate.enforcementMode,
  );
  final momentum = computeMomentumScore(
    insight: candidate.insight,
    patterns: candidate.supportingPatterns,
  );
  final feasibility = computeFeasibilityScore(
    insight: candidate.insight,
    ctx: candidate.realtimeContext,
  );
  final risk = computeRiskScore(
    insight: candidate.insight,
    patterns: candidate.supportingPatterns,
  );
  final recovery = computeRecoveryScore(
    insight: candidate.insight,
    patterns: candidate.supportingPatterns,
  );
  final focusScore = (urgency * weights.urgency +
          momentum * weights.momentum +
          feasibility * weights.feasibility +
          risk * weights.risk +
          recovery * weights.recovery)
      .clamp(0.0, 1.0);

  return FocusScoreBreakdown(
    urgencyScore: urgency,
    momentumScore: momentum,
    feasibilityScore: feasibility,
    riskScore: risk,
    recoveryScore: recovery,
    focusScore: focusScore,
  );
}

// ─── Focus confidence ─────────────────────────────────────────────────────────

/// 0–1 confidence in the PRIORITIZATION decision itself — not the insight.
/// High when the top candidate clearly dominates alternatives.
double computeFocusConfidence({
  required FocusScoreBreakdown topBreakdown,
  required List<FocusScoreBreakdown> allBreakdowns,
}) {
  if (allBreakdowns.isEmpty) return 0.0;
  if (allBreakdowns.length == 1) return topBreakdown.focusScore;
  final sorted = allBreakdowns.map((b) => b.focusScore).toList()
    ..sort((a, b) => b.compareTo(a));
  final best = sorted.first;
  final secondBest = sorted.length > 1 ? sorted[1] : 0.0;
  // Margin of victory becomes confidence.
  final margin = (best - secondBest).clamp(0.0, 1.0);
  return (best * 0.6 + margin * 0.4).clamp(0.0, 1.0);
}

// ─── Evaluation trace ────────────────────────────────────────────────────────

List<String> buildEvaluationTrace({
  required FocusCandidate candidate,
  required FocusScoreBreakdown breakdown,
  required FocusReason reason,
  required bool wasAntiThrashApplied,
  int candidateCount = 1,
}) {
  final trace = <String>[];
  final insight = candidate.insight;
  final ctx = candidate.realtimeContext;

  trace.add(
    'Selected: ${insight.insightType.name} (${insight.insightBucket.name})',
  );
  trace.add('Focus reason: ${reason.name}');
  trace.add(
    'Score: ${breakdown.focusScore.toStringAsFixed(3)}'
    ' [U:${breakdown.urgencyScore.toStringAsFixed(2)}'
    ' M:${breakdown.momentumScore.toStringAsFixed(2)}'
    ' F:${breakdown.feasibilityScore.toStringAsFixed(2)}'
    ' R:${breakdown.riskScore.toStringAsFixed(2)}'
    ' Rec:${breakdown.recoveryScore.toStringAsFixed(2)}]',
  );
  trace.add('Timing: ${ctx.timingProfile.name}');
  if (ctx.overdueCount > 0) {
    trace.add('Overdue items: ${ctx.overdueCount}');
  }
  if (ctx.upcomingScheduledCount > 0) {
    trace.add('Upcoming in window: ${ctx.upcomingScheduledCount}');
  }
  if (ctx.isInFocusSession) {
    trace.add('User in active focus session');
  }
  if (wasAntiThrashApplied) {
    trace.add('Anti-thrash: existing focus retained (min duration active)');
  }
  trace.add('Candidates evaluated: $candidateCount');
  return trace;
}

// ─── Focus reason derivation ─────────────────────────────────────────────────

FocusReason deriveFocusReason(FocusCandidate candidate) {
  final insight = candidate.insight;
  final patterns = candidate.supportingPatterns;

  if (candidate.realtimeContext.overdueCount > 0 &&
      candidate.realtimeContext.highestOverdueSeverity >= 0.7) {
    return FocusReason.overdueItemCritical;
  }

  switch (insight.insightType) {
    case InsightType.streakRiskWarning:
    case InsightType.fragileStreakAlert:
      return FocusReason.imminentStreakRisk;
    case InsightType.highestMomentumLeverage:
    case InsightType.strongStreakPraise:
    case InsightType.consistentBehaviorPraise:
      return FocusReason.highestMomentumLeverage;
    case InsightType.bestRecoveryOpportunity:
    case InsightType.inconsistencyNotice:
      final hasStrongHistory = patterns.any(
        (p) => p.patternCode.name == 'strongStreak',
      );
      return hasStrongHistory
          ? FocusReason.bestRecoveryOpportunity
          : FocusReason.consistencyBreakdownAlert;
    case InsightType.goalAtRisk:
    case InsightType.goalProgressSuccess:
      return FocusReason.goalDriftDetected;
    case InsightType.timingMisalignment:
    case InsightType.latePattern:
      return FocusReason.timingOpportunity;
    case InsightType.overloadTrend:
      return FocusReason.globalOverloadSignal;
    default:
      if (candidate.realtimeContext.upcomingScheduledCount > 0) {
        return FocusReason.scheduledWindowActive;
      }
      return FocusReason.highestMomentumLeverage;
  }
}
