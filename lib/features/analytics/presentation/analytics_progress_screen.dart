import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ai_summary_providers.dart';
import '../application/delivery_providers.dart';
import '../application/focus_providers.dart';
import '../application/analytics_period_bundle_notifier.dart';
import 'progress/progress_bundle_skeleton.dart';
import 'progress/goals_habits_section.dart';
import 'progress/progress_design_tokens.dart';
import 'progress/progress_insights_row.dart';
import 'progress/progress_shared_widgets.dart';
import 'progress/task_integrity_section.dart';
import 'progress/weekly_summary_hero.dart';
import '../domain/models/ai_summary_response.dart';

import '../../../core/presentation/app_colors.dart';

class AnalyticsProgressScreen extends ConsumerStatefulWidget {
  const AnalyticsProgressScreen({super.key});

  static const routeName = '/progress';

  @override
  ConsumerState<AnalyticsProgressScreen> createState() =>
      _AnalyticsProgressScreenState();
}

class _AnalyticsProgressScreenState
    extends ConsumerState<AnalyticsProgressScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _summaryFade;
  late final Animation<Offset> _summarySlide;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;
  late final Animation<double> _ringSweep;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _summaryFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _summarySlide =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
          ),
        );
    _cardsFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _ringSweep = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.05, 0.7, curve: Curves.easeOutCubic),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(analyticsPeriodBundleProvider);
    return Scaffold(
      backgroundColor: ProgressDesignTokens.surface,
      appBar: AppBar(
        backgroundColor: ProgressDesignTokens.surface,
        elevation: 0,
        foregroundColor: ProgressDesignTokens.onSurfaceVariant,
        title: const Text(
          'Progress',
          style: TextStyle(
            color: ProgressDesignTokens.primaryDim,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Test AI coaching summary',
            onPressed: () => _testAiSummary(context, ref),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Recompute insights now',
            onPressed: () async {
              ref.invalidate(layer34RecomputeNowProvider);
              final result = await ref.read(layer34RecomputeNowProvider.future);
              // Also run Focus Engine (Layer 4 focus selector) after pipeline.
              ref.invalidate(recomputeCoachingFocusProvider);
              await ref.read(recomputeCoachingFocusProvider.future);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Recomputed (L1:${result.layer1Refreshed ? 'ok' : 'fail'}, '
                    'L2:${result.layer2Refreshed ? 'ok' : 'fail'}, '
                    'L2c:${result.layer2CanonicalPatternsEmitted}, Focus:ok)',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          bundleAsync.when(
            skipLoadingOnReload: true,
            data: (bundle) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(
                  opacity: _summaryFade,
                  child: SlideTransition(
                    position: _summarySlide,
                    child: WeeklySummaryHero(
                      bundle: bundle,
                      ringSweep: _ringSweep.value,
                    ),
                  ),
                ),
                const SizedBox(height: ProgressDesignTokens.sectionSpacing),
                FadeTransition(
                  opacity: _cardsFade,
                  child: SlideTransition(
                    position: _cardsSlide,
                    child: ProgressInsightsRow(bundle: bundle),
                  ),
                ),
                const SizedBox(height: ProgressDesignTokens.sectionSpacing),
                FadeTransition(
                  opacity: _cardsFade,
                  child: SlideTransition(
                    position: _cardsSlide,
                    child: GoalsHabitsSection(
                      day: bundle.goalHabitDay,
                      week: bundle.goalHabitWeek,
                      month: bundle.goalHabitMonth,
                      reveal: _stagedProgress(0.45, 0.95),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _cardsFade,
                  child: SlideTransition(
                    position: _cardsSlide,
                    child: TaskIntegritySection(
                      day: bundle.taskDay,
                      week: bundle.taskWeek,
                      month: bundle.taskMonth,
                      reveal: _stagedProgress(0.58, 1.0),
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const ProgressBundleSkeleton(),
            error: (_, _) => const ProgressTonalCard(
              child: Text(
                'Could not load progress analytics.',
                style: TextStyle(color: ProgressDesignTokens.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testAiSummary(BuildContext context, WidgetRef ref) async {
    // Force bypass of cache by invalidating the recompute provider first.
    ref.invalidate(recomputeAiSummaryProvider);

    // Show loading snackbar immediately.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling AI coaching summarizer…'),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final response = await ref.read(recomputeAiSummaryProvider.future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showAiResultSheet(context, response);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI test failed: $e')),
      );
    }
  }

  void _showAiResultSheet(BuildContext context, AiSummaryResponse response) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AiResultSheet(response: response),
    );
  }

  double _stagedProgress(double start, double end) {
    final t = _introController.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }
}


// ─── AI test result bottom sheet ──────────────────────────────────────────────

class _AiResultSheet extends StatelessWidget {
  const _AiResultSheet({required this.response});
  final AiSummaryResponse response;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = response.isFallback ? 'DETERMINISTIC FALLBACK' : 'AI RESPONSE';
    final sourceColor = response.isFallback
        ? AppColors.scoreAmber
        : AppColors.accent;
    final validColor = response.isValid
        ? AppColors.accent
        : AppColors.scoreCoral;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sourceColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: sourceColor.withAlpha(120)),
                ),
                child: Text(
                  sourceLabel,
                  style: TextStyle(
                    color: sourceColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: validColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: validColor.withAlpha(120)),
                ),
                child: Text(
                  response.isValid ? 'VALID' : response.validationOutcome.name.toUpperCase(),
                  style: TextStyle(
                    color: validColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Daily summary
          _SheetSection(
            label: 'DAILY SUMMARY',
            child: Text(
              response.dailySummary.isEmpty ? '(empty)' : response.dailySummary,
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
            ),
          ),

          const SizedBox(height: 14),

          // Recommendation
          _SheetSection(
            label: 'RECOMMENDATION',
            child: Text(
              response.mainRecommendation.isEmpty
                  ? '(empty)'
                  : response.mainRecommendation,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Metadata row
          _SheetSection(
            label: 'METADATA',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow('Framing', response.framing.name),
                _MetaRow('Tone', response.tone.name),
                _MetaRow('Summary type', response.summaryType.name),
                _MetaRow('Prompt version', response.promptVersion),
                _MetaRow('Focus ID', response.focusId),
                _MetaRow(
                  'Generated',
                  response.generatedAtMs == 0
                      ? '—'
                      : DateTime.fromMillisecondsSinceEpoch(response.generatedAtMs)
                          .toLocal()
                          .toString()
                          .substring(0, 19),
                ),
                if (response.metadata.containsKey('fallbackReason'))
                  _MetaRow(
                    'Fallback reason',
                    response.metadata['fallbackReason'] as String? ?? '—',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
