import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ai_summary_providers.dart';
import '../application/focus_providers.dart';
import '../application/insight_generation_providers.dart';
import '../domain/models/ai_summary_response.dart';
import '../domain/models/coaching_ai_payload.dart';
import '../domain/models/current_coaching_focus.dart';
import '../domain/models/generated_insight.dart';
import '../../../core/utils/date_keys.dart';

import '../../../core/presentation/app_colors.dart';

// ─── Public entry-point widgets ───────────────────────────────────────────────

/// Full coaching focus card for the Home screen.
/// Shows focus reason badge, AI summary text, framing chip, and focus score bar.
class HomeCoachingFocusCard extends ConsumerWidget {
  const HomeCoachingFocusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(currentCoachingFocusProvider);
    final summaryAsync = ref.watch(currentAiSummaryProvider);

    return _CoachingFocusCardShell(
      focusAsync: focusAsync,
      summaryAsync: summaryAsync,
      compact: false,
      hideWhenEmpty: true,
      onRefresh: () {
        ref.invalidate(recomputeCoachingFocusProvider);
        ref.invalidate(recomputeAiSummaryProvider);
      },
    );
  }
}

/// Compact coaching focus card for the Progress / Analytics screen.
class ProgressCoachingFocusCard extends ConsumerWidget {
  const ProgressCoachingFocusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(currentCoachingFocusProvider);
    final summaryAsync = ref.watch(currentAiSummaryProvider);

    return _CoachingFocusCardShell(
      focusAsync: focusAsync,
      summaryAsync: summaryAsync,
      compact: true,
      onRefresh: null,
    );
  }
}

// ─── Shell ─────────────────────────────────────────────────────────────────────

class _CoachingFocusCardShell extends ConsumerWidget {
  const _CoachingFocusCardShell({
    required this.focusAsync,
    required this.summaryAsync,
    required this.compact,
    required this.onRefresh,
    this.hideWhenEmpty = false,
  });

  final AsyncValue<CurrentCoachingFocus?> focusAsync;
  final AsyncValue<AiSummaryResponse?> summaryAsync;
  final bool compact;
  final VoidCallback? onRefresh;

  /// When true (Home), no card is shown until a live focus exists.
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return focusAsync.when(
      skipLoadingOnReload: true,
      data: (focus) {
        final summary = summaryAsync.valueOrNull;
        if (focus == null || !isFocusLive(focus.lifecycleState)) {
          if (hideWhenEmpty) return const SizedBox.shrink();
          return _EmptyFocusCard(compact: compact);
        }
        return _FocusCard(
          focus: focus,
          summary: summary,
          compact: compact,
          onRefresh: onRefresh,
          ref: ref,
        );
      },
      loading: () {
        if (hideWhenEmpty) return const SizedBox.shrink();
        return _CardShell(
          child: const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      },
      error: (_, _) {
        if (hideWhenEmpty) return const SizedBox.shrink();
        return _EmptyFocusCard(compact: compact);
      },
    );
  }
}

// ─── Main populated card ──────────────────────────────────────────────────────

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.focus,
    required this.summary,
    required this.compact,
    required this.onRefresh,
    required this.ref,
  });

  final CurrentCoachingFocus focus;
  final AiSummaryResponse? summary;
  final bool compact;
  final VoidCallback? onRefresh;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final framing =
        summary?.framing ??
        deriveCoachingFraming(
          focusReason: focus.focusReason,
          focusScore: focus.focusScore,
          urgencyScore: focus.scoreBreakdown.urgencyScore,
        );
    final framingColor = _framingColor(framing);
    final reasonLabel = _focusReasonLabel(focus.focusReason);
    final hasSummary =
        summary != null && summary!.dailySummary.trim().isNotEmpty;

    return _CardShell(
      accentColor: framingColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COACHING FOCUS',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _FocusReasonBadge(label: reasonLabel, color: framingColor),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Colors.white38,
                  ),
                  tooltip: 'Refresh coaching',
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Summary text (AI or deterministic fallback) ───────────────────
          if (hasSummary) ...[
            Text(
              summary!.dailySummary,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary!.mainRecommendation,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: framingColor,
                height: 1.3,
              ),
            ),
          ] else ...[
            // Fallback to raw deterministic trace when no summary yet.
            if (focus.evaluationTrace.isNotEmpty)
              Text(
                focus.evaluationTrace.first,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
          ],

          const SizedBox(height: 12),

          // ── Focus score bar ────────────────────────────────────────────────
          _FocusScoreBar(
            score: focus.focusScore,
            urgency: focus.scoreBreakdown.urgencyScore,
            accentColor: framingColor,
          ),

          const SizedBox(height: 10),

          // ── Chip row ──────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(label: _framingLabel(framing), color: framingColor),
              _Chip(
                label: 'confidence ${(focus.focusConfidence * 100).round()}%',
                color: AppColors.accent,
              ),
              if (summary?.isFallback == false)
                const _Chip(label: 'AI', color: AppColors.cyan),
              if (summary?.isFallback == true)
                const _Chip(label: 'template', color: Colors.white38),
              if (!compact) ..._secondaryInsightChips(ref),
            ],
          ),

          // ── Evaluation trace (non-compact only) ───────────────────────────
          if (!compact && focus.evaluationTrace.isNotEmpty) ...[
            const SizedBox(height: 10),
            _TraceSection(traces: focus.evaluationTrace),
          ],
        ],
      ),
    );
  }

  List<Widget> _secondaryInsightChips(WidgetRef ref) {
    if (focus.secondaryInsightId == null) return const [];
    final today = DateKeys.todayKey();
    final insights =
        ref.read(layer3DeliveryDayInsightsProvider(today)).valueOrNull ??
        const <GeneratedInsight>[];
    final secondary = insights.cast<GeneratedInsight?>().firstWhere(
      (i) => i?.insightId == focus.secondaryInsightId,
      orElse: () => null,
    );
    if (secondary == null) return const [];
    return [
      _Chip(
        label: 'Also · ${_shortInsightType(secondary.insightType)}',
        color: Colors.white54,
      ),
    ];
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyFocusCard extends StatelessWidget {
  const _EmptyFocusCard({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COACHING FOCUS',
            style: TextStyle(
              color: AppColors.cyan,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No active focus right now. Keep completing actions to unlock coaching.',
            style: TextStyle(color: Colors.white70),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            const Text(
              'Coaching focuses are generated once enough behavioral data has been collected for the day.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FocusReasonBadge extends StatelessWidget {
  const _FocusReasonBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(120),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FocusScoreBar extends StatelessWidget {
  const _FocusScoreBar({
    required this.score,
    required this.urgency,
    required this.accentColor,
  });
  final double score;
  final double urgency;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Focus score',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '${(score * 100).round()}%',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.dark2A2D33,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ],
    );
  }
}

class _TraceSection extends StatelessWidget {
  const _TraceSection({required this.traces});
  final List<String> traces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why this focus',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        for (final trace in traces.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '· ',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Expanded(
                  child: Text(
                    trace,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.accentColor});
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Colors.white12;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfacePanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Label helpers ─────────────────────────────────────────────────────────────

Color _framingColor(CoachingFraming framing) {
  switch (framing) {
    case CoachingFraming.momentum:
      return AppColors.accent;
    case CoachingFraming.recovery:
      return AppColors.cyan;
    case CoachingFraming.protection:
      return AppColors.scoreCoral;
    case CoachingFraming.stabilization:
      return AppColors.scoreAmber;
    case CoachingFraming.consistency:
      return AppColors.tealSoft;
  }
}

String _framingLabel(CoachingFraming framing) {
  switch (framing) {
    case CoachingFraming.momentum:
      return 'momentum';
    case CoachingFraming.recovery:
      return 'recovery';
    case CoachingFraming.protection:
      return 'protection';
    case CoachingFraming.stabilization:
      return 'stabilization';
    case CoachingFraming.consistency:
      return 'consistency';
  }
}

String _focusReasonLabel(FocusReason reason) {
  switch (reason) {
    case FocusReason.imminentStreakRisk:
      return 'Streak at risk';
    case FocusReason.highestMomentumLeverage:
      return 'Peak momentum';
    case FocusReason.bestRecoveryOpportunity:
      return 'Recovery window';
    case FocusReason.overdueItemCritical:
      return 'Overdue items';
    case FocusReason.scheduledWindowActive:
      return 'Scheduled now';
    case FocusReason.globalOverloadSignal:
      return 'Overload signal';
    case FocusReason.consistencyBreakdownAlert:
      return 'Consistency alert';
    case FocusReason.goalDriftDetected:
      return 'Goal drifting';
    case FocusReason.reinforcingActiveStreak:
      return 'Strong streak';
    case FocusReason.timingOpportunity:
      return 'Good timing';
  }
}

String _shortInsightType(InsightType type) {
  switch (type) {
    case InsightType.streakRiskWarning:
      return 'streak risk';
    case InsightType.habitTooHard:
      return 'too hard';
    case InsightType.timingMisalignment:
      return 'timing off';
    case InsightType.goalAtRisk:
      return 'goal risk';
    case InsightType.latePattern:
      return 'late pattern';
    case InsightType.inconsistencyNotice:
      return 'inconsistent';
    case InsightType.lowEngagementNotice:
      return 'low engagement';
    case InsightType.strongStreakPraise:
      return 'great streak';
    case InsightType.consistentBehaviorPraise:
      return 'consistent';
    case InsightType.goalProgressSuccess:
      return 'goal progress';
    case InsightType.highestMomentumLeverage:
      return 'peak momentum';
    case InsightType.fragileStreakAlert:
      return 'fragile streak';
    case InsightType.bestRecoveryOpportunity:
      return 'recovery';
    case InsightType.overloadTrend:
      return 'overload';
    case InsightType.improvingConsistency:
      return 'improving';
    case InsightType.unstableRoutinePattern:
      return 'unstable routine';
  }
}
