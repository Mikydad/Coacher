import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/daily_analytics_engine.dart';
import '../application/daily_analytics_providers.dart';

class AnalyticsProgressScreen extends ConsumerWidget {
  const AnalyticsProgressScreen({super.key});

  static const routeName = '/progress';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                _ScopeCard(
                  title: 'Goals & Habits',
                  day: bundle.goalHabitDay,
                  week: bundle.goalHabitWeek,
                  month: bundle.goalHabitMonth,
                ),
                const SizedBox(height: 12),
                _ScopeCard(
                  title: 'Tasks',
                  day: bundle.taskDay,
                  week: bundle.taskWeek,
                  month: bundle.taskMonth,
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
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.title,
    required this.day,
    required this.week,
    required this.month,
  });

  final String title;
  final DailyAnalyticsSnapshot day;
  final RollupAnalyticsSnapshot week;
  final RollupAnalyticsSnapshot month;

  @override
  Widget build(BuildContext context) {
    final dayPct = (day.weightedCompletionRate * 100).round();
    final weekPct = (week.weightedCompletionRate * 100).round();
    final monthPct = (month.weightedCompletionRate * 100).round();
    return _ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
          _MetaLine(
            text:
                'Today: ${day.completedCount}/${day.createdCount} | Weighted ${day.weightedCompleted}/${day.weightedCreated}',
          ),
          _MetaLine(
            text:
                'Week: ${week.completedCount}/${week.createdCount} | Weighted ${week.weightedCompleted}/${week.weightedCreated}',
          ),
          _MetaLine(
            text:
                'Month: ${month.completedCount}/${month.createdCount} | Weighted ${month.weightedCompleted}/${month.weightedCreated}',
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
        color: const Color(0xFF101317),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
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
