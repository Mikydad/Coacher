import '../domain/models/detected_pattern.dart';
import '../domain/models/generated_insight.dart';

// TODO(Phase-2.2 / Layer-3): migrate mapping to consume [DetectedBehaviorPattern] directly
// (canonical evidence + taxonomy) instead of legacy [DetectedPattern]. Until then,
// [kDeferredLayer2PatternCodesForInsightMapping] gates subtle new codes from user-facing copy.

const int kLayer3InsightPolicyConfigVersion = 2;

class InsightOutputCaps {
  const InsightOutputCaps({
    required this.maxEntityInsights,
    required this.maxGlobalInsights,
  });

  final int maxEntityInsights;
  final int maxGlobalInsights;
}

class InsightMergePolicy {
  const InsightMergePolicy({
    this.combineRelatedSignals = true,
    this.dedupeByTypePerScope = true,
    this.preferHigherPriority = true,
    this.preferHigherConfidence = true,
  });

  final bool combineRelatedSignals;
  final bool dedupeByTypePerScope;
  final bool preferHigherPriority;
  final bool preferHigherConfidence;
}

class InsightMappingRule {
  const InsightMappingRule({
    required this.ruleId,
    required this.insightType,
    required this.insightBucket,
    required this.priority,
    required this.action,
    required this.messageKey,
    required this.fallbackMessage,
    required this.scopeType,
    required this.requiredAllPatterns,
    this.requiredAnyPatterns = const <PatternCode>{},
    this.blockedPatterns = const <PatternCode>{},
    this.minConfidence = 0.0,
  });

  final String ruleId;
  final InsightType insightType;
  final InsightBucket insightBucket;
  final InsightPriority priority;
  final InsightAction action;
  final String messageKey;
  final String fallbackMessage;
  final InsightScopeType scopeType;
  final Set<PatternCode> requiredAllPatterns;
  final Set<PatternCode> requiredAnyPatterns;
  final Set<PatternCode> blockedPatterns;
  final double minConfidence;
}

class Layer3InsightPolicyConfig {
  const Layer3InsightPolicyConfig({
    required this.version,
    required this.outputCaps,
    required this.mergePolicy,
    required this.rules,
  });

  final int version;
  final InsightOutputCaps outputCaps;
  final InsightMergePolicy mergePolicy;
  final List<InsightMappingRule> rules;
}

const Layer3InsightPolicyConfig
kLayer3InsightPolicyConfig = Layer3InsightPolicyConfig(
  version: kLayer3InsightPolicyConfigVersion,
  outputCaps: InsightOutputCaps(maxEntityInsights: 3, maxGlobalInsights: 3),
  mergePolicy: InsightMergePolicy(),
  rules: <InsightMappingRule>[
    // Risk insights
    InsightMappingRule(
      ruleId: 'risk_streak_warning',
      insightType: InsightType.streakRiskWarning,
      insightBucket: InsightBucket.risk,
      priority: InsightPriority.high,
      action: InsightAction.doNow,
      messageKey: 'streak_risk_1',
      fallbackMessage:
          'You are close to breaking momentum. Do one small action now.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.streakRisk},
    ),
    InsightMappingRule(
      ruleId: 'risk_habit_too_hard',
      insightType: InsightType.habitTooHard,
      insightBucket: InsightBucket.risk,
      priority: InsightPriority.high,
      action: InsightAction.reduceIntensity,
      messageKey: 'habit_too_hard_1',
      fallbackMessage:
          'This habit may be too hard right now. Lower intensity to stay consistent.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.tooHard},
    ),
    InsightMappingRule(
      ruleId: 'risk_timing_misalignment',
      insightType: InsightType.timingMisalignment,
      insightBucket: InsightBucket.risk,
      priority: InsightPriority.medium,
      action: InsightAction.reschedule,
      messageKey: 'timing_misalignment_1',
      fallbackMessage: 'Your timing is off. Move this to a better time window.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.timeMisalignment},
    ),
    InsightMappingRule(
      ruleId: 'risk_goal_at_risk',
      insightType: InsightType.goalAtRisk,
      insightBucket: InsightBucket.risk,
      priority: InsightPriority.high,
      action: InsightAction.focus,
      messageKey: 'goal_at_risk_1',
      fallbackMessage:
          'Your goal is at risk. Focus your effort on one key step today.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.inconsistentBehavior},
      requiredAnyPatterns: <PatternCode>{
        PatternCode.lowEngagement,
        PatternCode.streakRisk,
      },
    ),

    // Neutral insights
    InsightMappingRule(
      ruleId: 'neutral_late_pattern',
      insightType: InsightType.latePattern,
      insightBucket: InsightBucket.neutral,
      priority: InsightPriority.medium,
      action: InsightAction.reschedule,
      messageKey: 'late_pattern_1',
      fallbackMessage:
          'You tend to complete this late. A schedule adjustment may help.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.lateBehavior},
    ),
    InsightMappingRule(
      ruleId: 'neutral_inconsistency_notice',
      insightType: InsightType.inconsistencyNotice,
      insightBucket: InsightBucket.neutral,
      priority: InsightPriority.medium,
      action: InsightAction.focus,
      messageKey: 'inconsistency_notice_1',
      fallbackMessage:
          'Your consistency is unstable. Aim for one repeatable daily win.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.inconsistentBehavior},
      blockedPatterns: <PatternCode>{PatternCode.streakRisk},
    ),
    InsightMappingRule(
      ruleId: 'neutral_low_engagement_notice',
      insightType: InsightType.lowEngagementNotice,
      insightBucket: InsightBucket.neutral,
      priority: InsightPriority.medium,
      action: InsightAction.focus,
      messageKey: 'low_engagement_notice_1',
      fallbackMessage:
          'Engagement is dropping. Simplify and restart with a smaller step.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.lowEngagement},
    ),

    // Reinforcement insights
    InsightMappingRule(
      ruleId: 'positive_strong_streak',
      insightType: InsightType.strongStreakPraise,
      insightBucket: InsightBucket.reinforcement,
      priority: InsightPriority.low,
      action: InsightAction.keepGoing,
      messageKey: 'strong_streak_praise_1',
      fallbackMessage:
          'Great momentum. Keep your streak alive with one deliberate action.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.strongStreak},
      blockedPatterns: <PatternCode>{PatternCode.streakRisk},
    ),
    InsightMappingRule(
      ruleId: 'positive_consistent_behavior',
      insightType: InsightType.consistentBehaviorPraise,
      insightBucket: InsightBucket.reinforcement,
      priority: InsightPriority.low,
      action: InsightAction.keepGoing,
      messageKey: 'consistent_behavior_praise_1',
      fallbackMessage:
          'Your behavior is becoming consistent. Keep this routine stable.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.strongStreak},
      requiredAnyPatterns: <PatternCode>{PatternCode.timeMisalignment},
      blockedPatterns: <PatternCode>{
        PatternCode.streakRisk,
        PatternCode.inconsistentBehavior,
      },
    ),
    InsightMappingRule(
      ruleId: 'positive_goal_progress_success',
      insightType: InsightType.goalProgressSuccess,
      insightBucket: InsightBucket.reinforcement,
      priority: InsightPriority.low,
      action: InsightAction.keepGoing,
      messageKey: 'goal_progress_success_1',
      fallbackMessage:
          'You are making progress toward your goal. Keep this pace.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.strongStreak},
      requiredAnyPatterns: <PatternCode>{PatternCode.lateBehavior},
      blockedPatterns: <PatternCode>{
        PatternCode.streakRisk,
        PatternCode.lowEngagement,
      },
    ),

    // Focus-oriented insights (Phase 3)
    InsightMappingRule(
      ruleId: 'focus_highest_momentum_leverage',
      insightType: InsightType.highestMomentumLeverage,
      insightBucket: InsightBucket.reinforcement,
      priority: InsightPriority.medium,
      action: InsightAction.keepGoing,
      messageKey: 'focus_highest_momentum_1',
      fallbackMessage:
          'This has your strongest momentum right now. Protect it.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.strongStreak},
      blockedPatterns: <PatternCode>{PatternCode.streakRisk},
    ),
    InsightMappingRule(
      ruleId: 'focus_fragile_streak_alert',
      insightType: InsightType.fragileStreakAlert,
      insightBucket: InsightBucket.risk,
      priority: InsightPriority.high,
      action: InsightAction.doNow,
      messageKey: 'focus_fragile_streak_1',
      fallbackMessage: 'Streak at risk. One action now prevents a reset.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.streakRisk},
      blockedPatterns: <PatternCode>{PatternCode.strongStreak},
    ),
    InsightMappingRule(
      ruleId: 'focus_best_recovery_opportunity',
      insightType: InsightType.bestRecoveryOpportunity,
      insightBucket: InsightBucket.neutral,
      priority: InsightPriority.medium,
      action: InsightAction.focus,
      messageKey: 'focus_best_recovery_1',
      fallbackMessage:
          'Behavior is inconsistent but recoverable. Start with one win.',
      scopeType: InsightScopeType.entity,
      requiredAllPatterns: <PatternCode>{PatternCode.inconsistentBehavior},
      blockedPatterns: <PatternCode>{
        PatternCode.streakRisk,
        PatternCode.tooHard,
      },
    ),

    // Global coaching summaries (Phase 3)
    InsightMappingRule(
      ruleId: 'global_overload_trend',
      insightType: InsightType.overloadTrend,
      insightBucket: InsightBucket.risk,
      priority: InsightPriority.high,
      action: InsightAction.reduceLoad,
      messageKey: 'global_overload_trend_1',
      fallbackMessage:
          'Multiple items are at risk. Reduce scope to protect momentum.',
      scopeType: InsightScopeType.global,
      requiredAllPatterns: <PatternCode>{PatternCode.streakRisk},
      requiredAnyPatterns: <PatternCode>{
        PatternCode.tooHard,
        PatternCode.lowEngagement,
      },
    ),
    InsightMappingRule(
      ruleId: 'global_improving_consistency',
      insightType: InsightType.improvingConsistency,
      insightBucket: InsightBucket.reinforcement,
      priority: InsightPriority.low,
      action: InsightAction.keepGoing,
      messageKey: 'global_improving_consistency_1',
      fallbackMessage:
          'System-wide consistency is improving. Maintain current pace.',
      scopeType: InsightScopeType.global,
      requiredAllPatterns: <PatternCode>{PatternCode.strongStreak},
      blockedPatterns: <PatternCode>{PatternCode.streakRisk},
    ),
    InsightMappingRule(
      ruleId: 'global_unstable_routine_pattern',
      insightType: InsightType.unstableRoutinePattern,
      insightBucket: InsightBucket.neutral,
      priority: InsightPriority.medium,
      action: InsightAction.reschedule,
      messageKey: 'global_unstable_routine_1',
      fallbackMessage:
          'Routine instability detected across multiple habits. Pick one anchor.',
      scopeType: InsightScopeType.global,
      requiredAllPatterns: <PatternCode>{PatternCode.scheduleRhythmVolatile},
    ),
  ],
);

int priorityWeight(InsightPriority priority) {
  switch (priority) {
    case InsightPriority.high:
      return 3;
    case InsightPriority.medium:
      return 2;
    case InsightPriority.low:
      return 1;
  }
}

int compareInsightOrdering(GeneratedInsight a, GeneratedInsight b) {
  final priorityCompare = priorityWeight(
    b.priority,
  ).compareTo(priorityWeight(a.priority));
  if (priorityCompare != 0) return priorityCompare;
  final confidenceCompare = b.confidence.compareTo(a.confidence);
  if (confidenceCompare != 0) return confidenceCompare;
  final typeCompare = a.insightType.name.compareTo(b.insightType.name);
  if (typeCompare != 0) return typeCompare;
  return a.insightId.compareTo(b.insightId);
}

String mergeKeyForInsight(GeneratedInsight insight) {
  return '${insight.scopeType.name}::${insight.scopeId}::${insight.insightType.name}';
}
