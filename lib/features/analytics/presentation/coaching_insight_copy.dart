import '../domain/models/generated_insight.dart';

const Map<String, String> _patternCodeLabels = <String, String>{
  'streakRisk': 'streak at risk',
  'strongStreak': 'strong streak',
  'inconsistentBehavior': 'inconsistent follow-through',
  'lateBehavior': 'often completed late',
  'timeMisalignment': 'timing mismatch',
  'tooHard': 'intensity may be too high',
  'lowEngagement': 'low engagement',
};

/// Short explanation of which signals triggered the insight (patterns from Layer 2).
String coachingPatternSummary(GeneratedInsight insight) {
  if (insight.linkedPatternCodes.isEmpty) return '';
  final parts = <String>[];
  for (final code in insight.linkedPatternCodes) {
    final label = _patternCodeLabels[code] ?? _fallbackLabel(code);
    if (label.isEmpty) continue;
    parts.add(label);
  }
  return parts.join(', ');
}

String _fallbackLabel(String code) {
  if (code.isEmpty) return '';
  final withSpaces = code
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .toLowerCase();
  return withSpaces.trim();
}

/// Layer 1 metrics for the **single entity** this insight is about — not the same
/// math as Progress dashboard totals (tasks vs goals aggregate).
String? coachingMetricsCaption(GeneratedInsight insight) {
  final raw = insight.metadata['featureContext'];
  if (raw is! Map) return null;
  final map = raw.cast<String, dynamic>();
  final bits = <String>[];
  final streak = map['currentStreak'];
  if (streak is num && streak.round() >= 0) {
    bits.add('streak ${streak.round()}d');
  }
  final rate = map['completionRate7d'];
  if (rate is num) {
    final pct = (rate.clamp(0.0, 1.0) * 100).round();
    bits.add('7d follow-through $pct%');
  }
  if (bits.isEmpty) return null;
  return 'On this item: ${bits.join(' · ')}';
}

/// User-visible subject line when Layer 3 resolved a goal/task title.
String? coachingInsightAboutLine(GeneratedInsight insight) {
  final raw = insight.metadata['displayTitle'];
  if (raw is! String) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  return 'About: $t';
}

/// Combined subtitle for UI: optional named entity + what the model saw + metrics.
String? coachingDetailCaption(GeneratedInsight insight) {
  final summary = coachingPatternSummary(insight);
  final metrics = coachingMetricsCaption(insight);
  final about = coachingInsightAboutLine(insight);
  if (summary.isEmpty && metrics == null && about == null) return null;
  final lines = <String>[];
  if (about != null && about.isNotEmpty) {
    lines.add(about);
  }
  if (summary.isNotEmpty) {
    lines.add('Why: $summary');
  }
  if (metrics != null && metrics.isNotEmpty) {
    lines.add(metrics);
  }
  return lines.join('\n');
}

bool shouldShowSecondaryInsight({
  required GeneratedInsight primary,
  required GeneratedInsight secondary,
}) {
  if (secondary.insightId == primary.insightId) return false;
  if (secondary.message.trim() == primary.message.trim()) return false;
  return true;
}

/// Short UI label for an extra ranked insight (not raw enum names).
String coachingInsightTypeShortLabel(InsightType type) {
  switch (type) {
    case InsightType.streakRiskWarning:
      return 'Streak risk';
    case InsightType.habitTooHard:
      return 'Intensity';
    case InsightType.timingMisalignment:
      return 'Timing';
    case InsightType.goalAtRisk:
      return 'Goal focus';
    case InsightType.latePattern:
      return 'Late completions';
    case InsightType.inconsistencyNotice:
      return 'Consistency';
    case InsightType.lowEngagementNotice:
      return 'Engagement';
    case InsightType.strongStreakPraise:
      return 'Momentum';
    case InsightType.consistentBehaviorPraise:
      return 'Steady habits';
    case InsightType.goalProgressSuccess:
      return 'Goal progress';
    // Phase 3 focus-oriented
    case InsightType.highestMomentumLeverage:
      return 'Best momentum';
    case InsightType.fragileStreakAlert:
      return 'Fragile streak';
    case InsightType.bestRecoveryOpportunity:
      return 'Recovery chance';
    // Phase 3 global summaries
    case InsightType.overloadTrend:
      return 'System overload';
    case InsightType.improvingConsistency:
      return 'Rising consistency';
    case InsightType.unstableRoutinePattern:
      return 'Routine instability';
  }
}
