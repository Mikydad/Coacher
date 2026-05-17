import 'detected_pattern.dart';
import 'generated_insight.dart';

/// Phase 3 insight families — stable classification orthogonal to [InsightBucket].
enum CoachingInsightFamily {
  risk,
  timing,
  momentum,
  reinforcement,
  focus,
  globalSummary,
}

CoachingInsightFamily coachingInsightFamilyFromStorage(String? raw) {
  for (final value in CoachingInsightFamily.values) {
    if (value.name == raw) return value;
  }
  return CoachingInsightFamily.risk;
}

CoachingInsightFamily coachingInsightFamilyForType(InsightType type) {
  switch (type) {
    case InsightType.streakRiskWarning:
    case InsightType.habitTooHard:
    case InsightType.goalAtRisk:
      return CoachingInsightFamily.risk;
    case InsightType.timingMisalignment:
    case InsightType.latePattern:
      return CoachingInsightFamily.timing;
    case InsightType.strongStreakPraise:
    case InsightType.consistentBehaviorPraise:
    case InsightType.goalProgressSuccess:
    case InsightType.improvingConsistency:
      return CoachingInsightFamily.reinforcement;
    case InsightType.inconsistencyNotice:
    case InsightType.lowEngagementNotice:
      return CoachingInsightFamily.momentum;
    case InsightType.highestMomentumLeverage:
    case InsightType.fragileStreakAlert:
    case InsightType.bestRecoveryOpportunity:
      return CoachingInsightFamily.focus;
    case InsightType.overloadTrend:
    case InsightType.unstableRoutinePattern:
      return CoachingInsightFamily.globalSummary;
  }
}

/// Cooldown policy: minimum recompute cycles before this insight can fire again
/// for the same (scopeType, scopeId) combination.
class InsightCooldownPolicy {
  const InsightCooldownPolicy({
    required this.minCyclesBeforeRepeat,
    this.cooldownHours = 0,
  });

  /// How many recompute passes must occur before re-emitting (0 = no cooldown).
  final int minCyclesBeforeRepeat;

  /// Optional wall-clock cooldown in hours (0 = no wall-clock limit).
  final int cooldownHours;

  static const none = InsightCooldownPolicy(minCyclesBeforeRepeat: 0);
  static const oneDay = InsightCooldownPolicy(
    minCyclesBeforeRepeat: 1,
    cooldownHours: 20,
  );
  static const twoDays = InsightCooldownPolicy(
    minCyclesBeforeRepeat: 2,
    cooldownHours: 44,
  );
}

/// Resolution rule: what pattern absence ends this insight.
class InsightResolutionRule {
  const InsightResolutionRule({
    required this.resolvedWhenPatternsAbsent,
  });

  /// Insight transitions to [InsightLifecycleState.resolved] when ALL of
  /// these pattern codes are absent for the entity on the next recompute.
  final Set<PatternCode> resolvedWhenPatternsAbsent;

  static const noAutoResolve = InsightResolutionRule(
    resolvedWhenPatternsAbsent: {},
  );
}

/// Canonical spec per [InsightType] — deterministic metadata, no AI, no copy.
class CoachingInsightSpec {
  const CoachingInsightSpec({
    required this.insightType,
    required this.family,
    required this.description,
    required this.requiredPatternCodes,
    required this.cooldown,
    required this.resolutionRule,
    this.isFocusOriented = false,
  });

  final InsightType insightType;
  final CoachingInsightFamily family;

  /// One-line description of coaching meaning (for engineers/debug).
  final String description;

  /// Pattern codes that must be present for this insight to be relevant
  /// (mirrors requiredAllPatterns in the mapping rule; duplicated here for
  /// lifecycle/resolution resolution without importing policy).
  final Set<PatternCode> requiredPatternCodes;

  final InsightCooldownPolicy cooldown;
  final InsightResolutionRule resolutionRule;

  /// True for insights that guide the user's next focused action.
  final bool isFocusOriented;
}

const Map<InsightType, CoachingInsightSpec> kCoachingInsightTaxonomy =
    <InsightType, CoachingInsightSpec>{
      InsightType.streakRiskWarning: CoachingInsightSpec(
        insightType: InsightType.streakRiskWarning,
        family: CoachingInsightFamily.risk,
        description: 'Recent missed days risk ending current momentum streak.',
        requiredPatternCodes: {PatternCode.streakRisk},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.streakRisk},
        ),
        isFocusOriented: true,
      ),
      InsightType.habitTooHard: CoachingInsightSpec(
        insightType: InsightType.habitTooHard,
        family: CoachingInsightFamily.risk,
        description: 'Effort demand + low completion signal: habit may be unsustainable.',
        requiredPatternCodes: {PatternCode.tooHard},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.tooHard},
        ),
      ),
      InsightType.timingMisalignment: CoachingInsightSpec(
        insightType: InsightType.timingMisalignment,
        family: CoachingInsightFamily.timing,
        description: 'Scheduled time block does not match observed completion block.',
        requiredPatternCodes: {PatternCode.timeMisalignment},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.timeMisalignment},
        ),
      ),
      InsightType.goalAtRisk: CoachingInsightSpec(
        insightType: InsightType.goalAtRisk,
        family: CoachingInsightFamily.risk,
        description:
            'Inconsistent behavior + engagement drop signal goal is being deprioritized.',
        requiredPatternCodes: {PatternCode.inconsistentBehavior},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {
            PatternCode.inconsistentBehavior,
            PatternCode.lowEngagement,
          },
        ),
        isFocusOriented: true,
      ),
      InsightType.latePattern: CoachingInsightSpec(
        insightType: InsightType.latePattern,
        family: CoachingInsightFamily.timing,
        description: 'Consistent late completions — schedule drift detected.',
        requiredPatternCodes: {PatternCode.lateBehavior},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.lateBehavior},
        ),
      ),
      InsightType.inconsistencyNotice: CoachingInsightSpec(
        insightType: InsightType.inconsistencyNotice,
        family: CoachingInsightFamily.momentum,
        description: 'Short-window completion signal below stable baseline.',
        requiredPatternCodes: {PatternCode.inconsistentBehavior},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.inconsistentBehavior},
        ),
      ),
      InsightType.lowEngagementNotice: CoachingInsightSpec(
        insightType: InsightType.lowEngagementNotice,
        family: CoachingInsightFamily.momentum,
        description: 'Elevated snooze/defer pressure combined with weak completion.',
        requiredPatternCodes: {PatternCode.lowEngagement},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.lowEngagement},
        ),
      ),
      InsightType.strongStreakPraise: CoachingInsightSpec(
        insightType: InsightType.strongStreakPraise,
        family: CoachingInsightFamily.reinforcement,
        description: 'Current streak exceeds strong-streak threshold.',
        requiredPatternCodes: {PatternCode.strongStreak},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.strongStreak},
        ),
      ),
      InsightType.consistentBehaviorPraise: CoachingInsightSpec(
        insightType: InsightType.consistentBehaviorPraise,
        family: CoachingInsightFamily.reinforcement,
        description: 'Strong streak with timing signals — behavior becoming consistent.',
        requiredPatternCodes: {PatternCode.strongStreak},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.strongStreak},
        ),
      ),
      InsightType.goalProgressSuccess: CoachingInsightSpec(
        insightType: InsightType.goalProgressSuccess,
        family: CoachingInsightFamily.reinforcement,
        description: 'Strong streak while managing late completions — goal pacing good.',
        requiredPatternCodes: {PatternCode.strongStreak},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.strongStreak},
        ),
      ),
      InsightType.highestMomentumLeverage: CoachingInsightSpec(
        insightType: InsightType.highestMomentumLeverage,
        family: CoachingInsightFamily.focus,
        description: 'Entity with the strongest current streak — highest momentum to preserve.',
        requiredPatternCodes: {PatternCode.strongStreak},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.strongStreak},
        ),
        isFocusOriented: true,
      ),
      InsightType.fragileStreakAlert: CoachingInsightSpec(
        insightType: InsightType.fragileStreakAlert,
        family: CoachingInsightFamily.focus,
        description:
            'Entity with streak risk — earliest candidate for streak breakage.',
        requiredPatternCodes: {PatternCode.streakRisk},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.streakRisk},
        ),
        isFocusOriented: true,
      ),
      InsightType.bestRecoveryOpportunity: CoachingInsightSpec(
        insightType: InsightType.bestRecoveryOpportunity,
        family: CoachingInsightFamily.focus,
        description:
            'Inconsistent entity with prior strong streak — best candidate for rapid recovery.',
        requiredPatternCodes: {PatternCode.inconsistentBehavior},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule(
          resolvedWhenPatternsAbsent: {PatternCode.inconsistentBehavior},
        ),
        isFocusOriented: true,
      ),
      InsightType.overloadTrend: CoachingInsightSpec(
        insightType: InsightType.overloadTrend,
        family: CoachingInsightFamily.globalSummary,
        description: 'Multiple entities showing streakRisk or tooHard simultaneously.',
        requiredPatternCodes: {PatternCode.streakRisk},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule.noAutoResolve,
      ),
      InsightType.improvingConsistency: CoachingInsightSpec(
        insightType: InsightType.improvingConsistency,
        family: CoachingInsightFamily.reinforcement,
        description: 'Multiple entities showing strongStreak — system-wide momentum improving.',
        requiredPatternCodes: {PatternCode.strongStreak},
        cooldown: InsightCooldownPolicy.oneDay,
        resolutionRule: InsightResolutionRule.noAutoResolve,
      ),
      InsightType.unstableRoutinePattern: CoachingInsightSpec(
        insightType: InsightType.unstableRoutinePattern,
        family: CoachingInsightFamily.globalSummary,
        description:
            'Multiple entities showing scheduleRhythmVolatile — routine instability detected.',
        requiredPatternCodes: {PatternCode.scheduleRhythmVolatile},
        cooldown: InsightCooldownPolicy.twoDays,
        resolutionRule: InsightResolutionRule.noAutoResolve,
      ),
    };
