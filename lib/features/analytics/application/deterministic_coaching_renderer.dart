import '../domain/models/ai_summary_response.dart';
import '../domain/models/coaching_ai_payload.dart';
import '../domain/models/current_coaching_focus.dart';

// ─── Template entry ───────────────────────────────────────────────────────────

class _FallbackTemplate {
  const _FallbackTemplate({
    required this.summary,
    required this.recommendation,
    required this.tone,
  });

  final String summary;
  final String recommendation;
  final CoachingTone tone;
}

// ─── Template map ─────────────────────────────────────────────────────────────

/// Structured fallback templates keyed by [FocusReason] × [CoachingFraming].
///
/// Primary lookup: exact (reason, framing) pair.
/// Secondary lookup: reason-only fallback (any framing).
/// Final fallback: generic consistency message.
///
/// Templates are intentionally high-quality — the app must never feel broken
/// because AI was unavailable.
const Map<(FocusReason, CoachingFraming), _FallbackTemplate> _kTemplates = {
  // ── Imminent streak risk ────────────────────────────────────────────────────
  (
    FocusReason.imminentStreakRisk,
    CoachingFraming.protection,
  ): _FallbackTemplate(
    summary:
        'Your streak is at risk today. A short session now protects weeks of consistent effort.',
    recommendation: 'Complete a brief session before the day ends.',
    tone: CoachingTone.assertive,
  ),
  (FocusReason.imminentStreakRisk, CoachingFraming.momentum): _FallbackTemplate(
    summary:
        'You\'ve built strong momentum. One action today keeps that streak alive and growing.',
    recommendation: 'Keep your streak alive with a quick check-in now.',
    tone: CoachingTone.encouraging,
  ),

  // ── Highest momentum leverage ────────────────────────────────────────────────
  (
    FocusReason.highestMomentumLeverage,
    CoachingFraming.momentum,
  ): _FallbackTemplate(
    summary:
        'You\'re in a strong behavioral momentum window. This is the highest-leverage moment to act.',
    recommendation: 'Take action on your top priority while momentum is high.',
    tone: CoachingTone.encouraging,
  ),
  (
    FocusReason.highestMomentumLeverage,
    CoachingFraming.consistency,
  ): _FallbackTemplate(
    summary:
        'Consistent effort is building results. Staying on track today compounds your progress.',
    recommendation: 'Follow your plan today — consistency is the strategy.',
    tone: CoachingTone.informative,
  ),

  // ── Best recovery opportunity ────────────────────────────────────────────────
  (
    FocusReason.bestRecoveryOpportunity,
    CoachingFraming.recovery,
  ): _FallbackTemplate(
    summary:
        'This is a good moment to get back on track. Small steps now rebuild your routine naturally.',
    recommendation:
        'Start with one simple action to reconnect with your habit.',
    tone: CoachingTone.supportive,
  ),
  (
    FocusReason.bestRecoveryOpportunity,
    CoachingFraming.consistency,
  ): _FallbackTemplate(
    summary: 'Returning to your routine is the most effective move right now.',
    recommendation: 'Pick up where you left off with one small action today.',
    tone: CoachingTone.informative,
  ),

  // ── Overdue item critical ────────────────────────────────────────────────────
  (
    FocusReason.overdueItemCritical,
    CoachingFraming.protection,
  ): _FallbackTemplate(
    summary:
        'An overdue item needs your attention. Resolving it now prevents further drift.',
    recommendation: 'Address your most overdue item before anything else.',
    tone: CoachingTone.assertive,
  ),
  (
    FocusReason.overdueItemCritical,
    CoachingFraming.recovery,
  ): _FallbackTemplate(
    summary:
        'You have overdue items that are holding back your progress. Now is a good time to clear them.',
    recommendation: 'Tackle the oldest overdue item first.',
    tone: CoachingTone.supportive,
  ),

  // ── Scheduled window active ──────────────────────────────────────────────────
  (
    FocusReason.scheduledWindowActive,
    CoachingFraming.momentum,
  ): _FallbackTemplate(
    summary:
        'Your scheduled window is open. Acting now aligns with your planned routine.',
    recommendation: 'Start your scheduled item — the timing is right.',
    tone: CoachingTone.encouraging,
  ),
  (
    FocusReason.scheduledWindowActive,
    CoachingFraming.consistency,
  ): _FallbackTemplate(
    summary:
        'Your schedule has a slot for this. Following your plan keeps your routine stable.',
    recommendation: 'Start the scheduled item in your current time block.',
    tone: CoachingTone.informative,
  ),

  // ── Global overload signal ───────────────────────────────────────────────────
  (
    FocusReason.globalOverloadSignal,
    CoachingFraming.stabilization,
  ): _FallbackTemplate(
    summary:
        'Your load is high across multiple areas. Focusing on essentials prevents burnout.',
    recommendation: 'Prioritize one key action and defer the rest.',
    tone: CoachingTone.informative,
  ),
  (
    FocusReason.globalOverloadSignal,
    CoachingFraming.protection,
  ): _FallbackTemplate(
    summary:
        'Overload is building up. Protecting your core habits now prevents deeper disruption.',
    recommendation:
        'Protect your most important habit — skip non-essentials today.',
    tone: CoachingTone.assertive,
  ),

  // ── Consistency breakdown alert ──────────────────────────────────────────────
  (
    FocusReason.consistencyBreakdownAlert,
    CoachingFraming.protection,
  ): _FallbackTemplate(
    summary:
        'Your consistency pattern is weakening. Re-engaging today stops the slide early.',
    recommendation:
        'Complete today\'s planned action to halt the consistency drop.',
    tone: CoachingTone.assertive,
  ),
  (
    FocusReason.consistencyBreakdownAlert,
    CoachingFraming.stabilization,
  ): _FallbackTemplate(
    summary:
        'Inconsistency is accumulating across your habits. Simplifying your approach helps.',
    recommendation: 'Focus on just one habit today to rebuild a stable base.',
    tone: CoachingTone.informative,
  ),

  // ── Goal drift detected ──────────────────────────────────────────────────────
  (
    FocusReason.goalDriftDetected,
    CoachingFraming.stabilization,
  ): _FallbackTemplate(
    summary:
        'Progress on your goal has slowed. A small step today re-anchors your trajectory.',
    recommendation: 'Take one concrete action toward your goal right now.',
    tone: CoachingTone.informative,
  ),
  (
    FocusReason.goalDriftDetected,
    CoachingFraming.protection,
  ): _FallbackTemplate(
    summary:
        'Your goal is drifting off track. Acting today prevents it from becoming a longer gap.',
    recommendation:
        'Do the smallest useful action for your goal before today ends.',
    tone: CoachingTone.assertive,
  ),

  // ── Reinforcing active streak ─────────────────────────────────────────────────
  (
    FocusReason.reinforcingActiveStreak,
    CoachingFraming.momentum,
  ): _FallbackTemplate(
    summary:
        'Your streak is strong and building. Keep the momentum going — consistency compounds.',
    recommendation: 'Maintain your streak with your usual action today.',
    tone: CoachingTone.encouraging,
  ),
  (
    FocusReason.reinforcingActiveStreak,
    CoachingFraming.consistency,
  ): _FallbackTemplate(
    summary:
        'You\'re building a reliable habit pattern. Steady action today reinforces long-term results.',
    recommendation: 'Follow your routine — you\'re on the right track.',
    tone: CoachingTone.informative,
  ),

  // ── Timing opportunity ────────────────────────────────────────────────────────
  (FocusReason.timingOpportunity, CoachingFraming.momentum): _FallbackTemplate(
    summary:
        'This time slot has historically been your best window for focused work.',
    recommendation: 'Use this window — your productivity peaks here.',
    tone: CoachingTone.encouraging,
  ),
  (
    FocusReason.timingOpportunity,
    CoachingFraming.consistency,
  ): _FallbackTemplate(
    summary:
        'Good timing to follow your routine. Acting during your natural window builds durable habits.',
    recommendation: 'Complete your planned action in this time block.',
    tone: CoachingTone.informative,
  ),
};

/// Reason-level fallbacks for when the exact framing pair has no template.
const Map<FocusReason, _FallbackTemplate> _kReasonFallbacks = {
  FocusReason.imminentStreakRisk: _FallbackTemplate(
    summary:
        'Your streak needs attention today. A short session protects your progress.',
    recommendation: 'Complete a brief action before the day ends.',
    tone: CoachingTone.assertive,
  ),
  FocusReason.highestMomentumLeverage: _FallbackTemplate(
    summary:
        'Strong momentum right now. This is a great time to act on your priorities.',
    recommendation: 'Take your next planned action while momentum is high.',
    tone: CoachingTone.encouraging,
  ),
  FocusReason.bestRecoveryOpportunity: _FallbackTemplate(
    summary: 'Good time to get back on track. Small steps rebuild habits.',
    recommendation:
        'Start with one small action to reconnect with your routine.',
    tone: CoachingTone.supportive,
  ),
  FocusReason.overdueItemCritical: _FallbackTemplate(
    summary:
        'Overdue items are accumulating. Clearing one now reduces friction.',
    recommendation: 'Resolve your most overdue item first.',
    tone: CoachingTone.assertive,
  ),
  FocusReason.scheduledWindowActive: _FallbackTemplate(
    summary:
        'Now is your planned time. Follow your schedule for a consistent routine.',
    recommendation: 'Start your scheduled activity now.',
    tone: CoachingTone.informative,
  ),
  FocusReason.globalOverloadSignal: _FallbackTemplate(
    summary:
        'You have a lot on your plate. Focus on one essential action today.',
    recommendation: 'Pick the most important item and do only that.',
    tone: CoachingTone.informative,
  ),
  FocusReason.consistencyBreakdownAlert: _FallbackTemplate(
    summary:
        'Consistency has been lower recently. Re-engaging today makes a difference.',
    recommendation: 'Complete today\'s habit to start rebuilding consistency.',
    tone: CoachingTone.assertive,
  ),
  FocusReason.goalDriftDetected: _FallbackTemplate(
    summary:
        'Your goal progress has slowed. One action today keeps the trajectory alive.',
    recommendation: 'Do the smallest action that moves your goal forward.',
    tone: CoachingTone.informative,
  ),
  FocusReason.reinforcingActiveStreak: _FallbackTemplate(
    summary: 'Great streak! Keep it going with consistent daily action.',
    recommendation: 'Maintain your habit with your usual action today.',
    tone: CoachingTone.encouraging,
  ),
  FocusReason.timingOpportunity: _FallbackTemplate(
    summary: 'Good timing to follow your routine and build steady habits.',
    recommendation:
        'Act during this window — it aligns with your best performance times.',
    tone: CoachingTone.informative,
  ),
};

/// Generic fallback when no specific template matches.
const _kGenericFallback = _FallbackTemplate(
  summary:
      'Staying consistent with your habits builds lasting results. Small actions compound over time.',
  recommendation: 'Take one planned action today to keep your momentum.',
  tone: CoachingTone.informative,
);

// ─── Renderer ─────────────────────────────────────────────────────────────────

/// Produces high-quality deterministic coaching summaries without AI.
///
/// Used as the mandatory fallback when:
///   - AI request fails or times out
///   - AI returns invalid JSON
///   - Semantic validation rejects the AI response
///   - App is offline
///   - Quota exceeded
///
/// The app must NEVER feel broken because AI was unavailable.
class DeterministicCoachingRenderer {
  const DeterministicCoachingRenderer();

  /// Render a fallback [AiSummaryResponse] from [payload].
  AiSummaryResponse render({
    required CoachingAiPayload payload,
    String? failureReason,
  }) {
    final focusReason = focusReasonFromStorage(payload.focusReason);
    final template =
        _kTemplates[(focusReason, payload.framing)] ??
        _kReasonFallbacks[focusReason] ??
        _kGenericFallback;

    return AiSummaryResponse(
      focusId: payload.focusId,
      summaryType: payload.summaryType,
      tone: template.tone,
      dailySummary: template.summary,
      mainRecommendation: template.recommendation,
      framing: payload.framing,
      generatedAtMs: payload.generatedAtMs,
      promptVersion: payload.promptVersion,
      isFallback: true,
      metadata: {if (failureReason != null) 'fallbackReason': failureReason},
    );
  }
}
