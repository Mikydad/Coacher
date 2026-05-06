import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/daily_analytics_engine.dart';
import '../application/daily_analytics_providers.dart';

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
  late final Animation<double> _heatReveal;

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
    _heatReveal = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
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
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          bundleAsync.when(
            data: (bundle) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _summaryFade,
                  child: SlideTransition(
                    position: _summarySlide,
                    child: _VisualSummaryCard(
                      bundle: bundle,
                      ringSweep: _ringSweep.value,
                      heatReveal: _heatReveal.value,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _cardsFade,
                  child: SlideTransition(
                    position: _cardsSlide,
                    child: Column(
                      children: [
                        _ScopeCard(
                          title: 'Goals & Habits',
                          day: bundle.goalHabitDay,
                          week: bundle.goalHabitWeek,
                          month: bundle.goalHabitMonth,
                          reveal: _stagedProgress(0.45, 0.95),
                          accent: const Color(0xFFB7FF00),
                        ),
                        const SizedBox(height: 12),
                        _ScopeCard(
                          title: 'Tasks',
                          day: bundle.taskDay,
                          week: bundle.taskWeek,
                          month: bundle.taskMonth,
                          reveal: _stagedProgress(0.58, 1.0),
                          accent: const Color(0xFF00E6FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const _ProgressCard(
              child: Text(
                'Could not load progress analytics.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _stagedProgress(double start, double end) {
    final t = _introController.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.title,
    required this.day,
    required this.week,
    required this.month,
    required this.reveal,
    required this.accent,
  });

  final String title;
  final DailyAnalyticsSnapshot day;
  final RollupAnalyticsSnapshot week;
  final RollupAnalyticsSnapshot month;
  final double reveal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shownDay = (day.weightedCompletionRate * reveal).clamp(0.0, 1.0);
    final shownWeek = (week.weightedCompletionRate * reveal).clamp(0.0, 1.0);
    final shownMonth = (month.weightedCompletionRate * reveal).clamp(0.0, 1.0);
    final dayPct = (shownDay * 100).round();
    final weekPct = (shownWeek * 100).round();
    final monthPct = (shownMonth * 100).round();
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(label: 'Today', value: '$dayPct%'),
              _StatChip(label: 'Week', value: '$weekPct%'),
              _StatChip(label: 'Month', value: '$monthPct%'),
              _StatChip(
                label: 'Streak',
                value:
                    '${week.currentStreakDays}d (best ${week.bestStreakDays}d)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricLane(
            label: 'Today',
            ratio: shownDay,
            color: accent,
            detail:
                '${day.completedCount}/${day.createdCount} · weighted ${day.weightedCompleted}/${day.weightedCreated}',
          ),
          const SizedBox(height: 8),
          _MetricLane(
            label: 'Week',
            ratio: shownWeek,
            color: accent.withAlpha(220),
            detail:
                '${week.completedCount}/${week.createdCount} · weighted ${week.weightedCompleted}/${week.weightedCreated}',
          ),
          const SizedBox(height: 8),
          _MetricLane(
            label: 'Month',
            ratio: shownMonth,
            color: accent.withAlpha(180),
            detail:
                '${month.completedCount}/${month.createdCount} · weighted ${month.weightedCompleted}/${month.weightedCreated}',
          ),
          const SizedBox(height: 10),
          _MetaLine(
            text: 'Weighted priority model: P1=5, P2=4, P3=3, P4=2, P5=1',
          ),
        ],
      ),
    );
  }
}

class _MetricLane extends StatelessWidget {
  const _MetricLane({
    required this.label,
    required this.ratio,
    required this.color,
    required this.detail,
  });

  final String label;
  final double ratio;
  final Color color;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final pct = (ratio.clamp(0.0, 1.0) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFF2A2D33),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }
}

class _VisualSummaryCard extends StatelessWidget {
  const _VisualSummaryCard({
    required this.bundle,
    required this.ringSweep,
    required this.heatReveal,
  });

  final AnalyticsPeriodBundle bundle;
  final double ringSweep;
  final double heatReveal;

  @override
  Widget build(BuildContext context) {
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Visual Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProgressRing(
                  label: 'Goals/Habits',
                  value: bundle.goalHabitWeek.weightedCompletionRate,
                  sweep: ringSweep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgressRing(
                  label: 'Tasks',
                  value: bundle.taskWeek.weightedCompletionRate,
                  sweep: ringSweep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '7-day consistency',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _HeatStrip(
            label: 'G',
            values: bundle.goalHabitWeekSeries,
            reveal: heatReveal,
          ),
          const SizedBox(height: 6),
          _HeatStrip(
            label: 'T',
            values: bundle.taskWeekSeries,
            reveal: heatReveal,
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.label,
    required this.value,
    required this.sweep,
  });

  final String label;
  final double value;
  final double sweep;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final animated = (clamped * sweep.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    // Show the true value immediately; animate only the ring stroke.
    final pct = (clamped * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: animated,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFF2A2D33),
                  color: const Color(0xFFB7FF00),
                ),
                Center(
                  child: Text(
                    '$pct%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HeatStrip extends StatelessWidget {
  const _HeatStrip({
    required this.label,
    required this.values,
    required this.reveal,
  });

  final String label;
  final List<double> values;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final padded = values.length >= 7
        ? values.sublist(values.length - 7)
        : [...List<double>.filled(7 - values.length, 0), ...values];
    return Opacity(
      opacity: reveal.clamp(0.0, 1.0),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          for (final v in padded)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 16,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF2A2D33),
                    const Color(0xFFB7FF00),
                    v.clamp(0.0, 1.0),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: reveal.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11151A), Color(0xFF0C1014)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}
