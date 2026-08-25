import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/application/profile_providers.dart';
import '../../application/ai_summary_providers.dart';
import '../../application/announced_insight_store.dart';
import '../../application/analytics_period_bundle.dart';
import '../../application/delivery_providers.dart';
import '../../application/discipline_score.dart';
import '../../application/focus_providers.dart';
import '../../application/insight_generation_providers.dart';
import '../../domain/models/ai_summary_response.dart';
import '../../domain/models/current_coaching_focus.dart';
import '../../domain/models/delivery_decision.dart';
import '../../domain/models/generated_insight.dart';
import '../coaching_insight_copy.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';
import '../../../../core/presentation/async_value_ui.dart';

/// Coaching Focus + Streak at Risk (replaces legacy Progress Delivery card).
class ProgressInsightsRow extends ConsumerWidget {
  const ProgressInsightsRow({super.key, this.bundle});

  final AnalyticsPeriodBundle? bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(currentCoachingFocusProvider);
    final summaryAsync = ref.watch(currentAiSummaryProvider);
    final decisionAsync = ref.watch(layer4TodayProgressDecisionProvider);
    final insightsAsync = ref.watch(layer3TodayDeliveryInsightsProvider);

    // Showing a live focus here is what "the user saw it" means — it clears
    // the unseen-focus dot on the Profile tab and Profile's Progress row
    // (2026-08-23). Resolve the service during build: the callback can
    // outlive this element, and `ref` would throw.
    final focus = focusAsync.valueOrNull;
    if (focus != null && isFocusLive(focus.lifecycleState)) {
      final prefService = ref.read(profilePreferenceServiceProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(prefService.markCoachingFocusSeen(focus.focusId));
      });
    }

    return Column(
      children: [
        _CoachingFocusGlass(focusAsync: focusAsync, summaryAsync: summaryAsync),
        const SizedBox(height: 12),
        _StreakAtRiskGlass(
          decisionAsync: decisionAsync,
          insightsAsync: insightsAsync,
          bundle: bundle,
          announced: ref.watch(announcedInsightTodayProvider).valueOrNull,
        ),
      ],
    );
  }
}

class _CoachingFocusGlass extends StatelessWidget {
  const _CoachingFocusGlass({
    required this.focusAsync,
    required this.summaryAsync,
  });

  final AsyncValue<CurrentCoachingFocus?> focusAsync;
  final AsyncValue<AiSummaryResponse?> summaryAsync;

  @override
  Widget build(BuildContext context) {
    return focusAsync.when(
      skipLoadingOnReload: true,
      data: (focus) {
        if (focus == null || !isFocusLive(focus.lifecycleState)) {
          return ProgressGlassCard(
            accentColor: ProgressDesignTokens.secondary,
            icon: Icons.psychology_outlined,
            title: 'Coaching Focus',
          helpId: 'coachingFocus',
            headline: 'Your coach is learning your rhythm.',
            body:
                'Complete a few tasks or check in on a goal — we\'ll surface your peak focus window here.',
          );
        }
        final summary = summaryAsync.valueOrNull;
        // Full summary, not `_firstSentence` (2026-08-23): this card is the
        // only place the coach's daily summary is shown now that Home's
        // focus card is gone, so a second sentence would exist nowhere.
        // The streak card below still truncates — its source is a long
        // generated insight, not prose written to be read whole.
        final headline =
            summary != null && summary.dailySummary.trim().isNotEmpty
            ? summary.dailySummary.trim()
            : 'Stay aligned with what matters today.';
        final body =
            summary != null && summary.mainRecommendation.trim().isNotEmpty
            ? summary.mainRecommendation.trim()
            : 'Protect this window — your highest-impact work lands here.';

        return ProgressGlassCard(
          accentColor: ProgressDesignTokens.secondary,
          icon: Icons.psychology_outlined,
          title: 'Coaching Focus',
          helpId: 'coachingFocus',
          headline: headline,
          body: body,
        );
      },
      loading: () => const _InsightLoadingPlaceholder(),
      error: (e, _) => swallowedAsyncError(
        'progress_insights_row',
        e,
        ProgressGlassCard(
          accentColor: ProgressDesignTokens.secondary,
          icon: Icons.psychology_outlined,
          title: 'Coaching Focus',
          helpId: 'coachingFocus',
          headline: 'Focus data unavailable.',
          body: 'Pull to refresh or open Settings to recompute insights.',
        ),
      ),
    );
  }
}

class _StreakAtRiskGlass extends StatelessWidget {
  const _StreakAtRiskGlass({
    required this.decisionAsync,
    required this.insightsAsync,
    required this.bundle,
    required this.announced,
  });

  final AsyncValue<DeliveryDecision?> decisionAsync;
  final AsyncValue<List<GeneratedInsight>> insightsAsync;
  final AnalyticsPeriodBundle? bundle;

  /// Today's frozen banner copy — the insight the OS notification
  /// advertised, kept renderable even after a recompute replaced it.
  final AnnouncedInsight? announced;

  @override
  Widget build(BuildContext context) {
    return decisionAsync.when(
      skipLoadingOnReload: true,
      data: (decision) {
        final insights =
            insightsAsync.valueOrNull ?? const <GeneratedInsight>[];
        final byId = {for (final i in insights) i.insightId: i};
        final primary = decision?.selectedPrimaryInsightId == null
            ? null
            : byId[decision!.selectedPrimaryInsightId!];

        if (primary != null) {
          final caption = coachingDetailCaption(primary);
          return ProgressGlassCard(
            accentColor: ProgressDesignTokens.primaryDim,
            icon: Icons.warning_amber_rounded,
            title: 'Streak at risk',
          helpId: 'streakAtRisk',
            headline: _firstSentence(primary.message),
            body: caption ?? _streakFallbackBody(bundle),
          );
        }

        // The banner's promise outlives recomputes: when the advertised
        // insight no longer resolves live, honor the tap from the frozen
        // copy instead of shrugging with the generic fallback.
        if (announced != null) {
          return ProgressGlassCard(
            accentColor: ProgressDesignTokens.primaryDim,
            icon: Icons.warning_amber_rounded,
            title: 'Coaching insight',
            helpId: 'streakAtRisk',
            headline: _firstSentence(announced!.message),
            body: announced!.caption.isNotEmpty
                ? announced!.caption
                : _streakFallbackBody(bundle),
          );
        }

        final riskInsight = _pickRiskInsight(insights);
        if (riskInsight != null) {
          return ProgressGlassCard(
            accentColor: ProgressDesignTokens.primaryDim,
            icon: Icons.warning_amber_rounded,
            title: 'Streak at risk',
          helpId: 'streakAtRisk',
            headline: _firstSentence(riskInsight.message),
            body:
                coachingDetailCaption(riskInsight) ??
                _streakFallbackBody(bundle),
          );
        }

        return ProgressGlassCard(
          accentColor: ProgressDesignTokens.primaryDim,
          icon: Icons.warning_amber_rounded,
          title: 'Streak at risk',
          helpId: 'streakAtRisk',
          headline: _streakHeadline(bundle),
          body: _streakFallbackBody(bundle),
        );
      },
      loading: () => const _InsightLoadingPlaceholder(),
      error: (e, _) => swallowedAsyncError(
        'progress_insights_row',
        e,
        ProgressGlassCard(
          accentColor: ProgressDesignTokens.primaryDim,
          icon: Icons.warning_amber_rounded,
          title: 'Streak at risk',
          helpId: 'streakAtRisk',
          headline: _streakHeadline(bundle),
          body: _streakFallbackBody(bundle),
        ),
      ),
    );
  }

  static GeneratedInsight? _pickRiskInsight(List<GeneratedInsight> insights) {
    for (final i in insights) {
      if (i.linkedPatternCodes.contains('streakRisk') ||
          i.linkedPatternCodes.contains('inconsistentBehavior') ||
          i.insightBucket == InsightBucket.risk) {
        return i;
      }
    }
    return insights.isNotEmpty ? insights.first : null;
  }
}

String _firstSentence(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  final dot = trimmed.indexOf('.');
  if (dot > 0 && dot < 120) return trimmed.substring(0, dot + 1);
  if (trimmed.length > 100) return '${trimmed.substring(0, 97)}…';
  return trimmed;
}

String _streakHeadline(AnalyticsPeriodBundle? bundle) {
  if (bundle == null) return 'Stay consistent today.';
  final s = disciplineStreakSummary(bundle);
  if (s.goalHabitCurrentDays <= 0 && s.taskCurrentDays <= 0) {
    return 'Start a streak with one intentional action.';
  }
  if (s.goalHabitCurrentDays < 3) {
    return 'Habit consistency dropped this week.';
  }
  if (s.taskCurrentDays >= 3) {
    return 'Task consistency is strong (${s.taskCurrentDays} days).';
  }
  return 'Protect your habit momentum (${s.goalHabitCurrentDays} days).';
}

String _streakFallbackBody(AnalyticsPeriodBundle? bundle) {
  if (bundle == null) {
    return 'One intentional action now prevents a reset of your progress.';
  }
  final s = disciplineStreakSummary(bundle);
  if (s.goalHabitCurrentDays <= 0 && s.taskCurrentDays <= 0) {
    return 'Log a task or goal check-in today to begin tracking consistency.';
  }
  return 'Habit streak: ${s.goalHabitCurrentDays}d (best ${s.goalHabitBestDays}d). '
      'Task streak: ${s.taskCurrentDays}d (best ${s.taskBestDays}d). '
      'One intentional action today keeps both moving.';
}

class _InsightLoadingPlaceholder extends StatelessWidget {
  const _InsightLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ProgressTonalCard(
      padding: EdgeInsets.symmetric(vertical: 28),
      color: ProgressDesignTokens.surfaceContainerHigh,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
