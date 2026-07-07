import 'package:flutter/material.dart';

import '../../application/daily_analytics_engine.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

class GoalsHabitsSection extends StatelessWidget {
  const GoalsHabitsSection({
    super.key,
    required this.day,
    required this.week,
    required this.month,
    required this.reveal,
  });

  final DailyAnalyticsSnapshot day;
  final RollupAnalyticsSnapshot week;
  final RollupAnalyticsSnapshot month;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final shownDay = (day.weightedCompletionRate * reveal).clamp(0.0, 1.0);
    final shownWeek = (week.weightedCompletionRate * reveal).clamp(0.0, 1.0);
    final shownMonth = (month.weightedCompletionRate * reveal).clamp(0.0, 1.0);

    return ProgressTonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: ProgressDesignTokens.primaryDim,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Goals & Habits',
                style: TextStyle(
                  color: ProgressDesignTokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ProgressChip(label: 'Today: ${(shownDay * 100).round()}%'),
              ProgressChip(label: 'Week: ${(shownWeek * 100).round()}%'),
              ProgressChip(label: 'Month: ${(shownMonth * 100).round()}%'),
              ProgressChip(
                label:
                    'Streak: ${week.currentStreakDays}d (PB ${week.bestStreakDays}d)',
                highlighted: week.currentStreakDays > 0,
                accentColor: ProgressDesignTokens.primaryDim,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ProgressThinBar(
            label: 'Today',
            ratio: shownDay,
            color: ProgressDesignTokens.primaryDim,
            detail:
                '${day.completedCount}/${day.createdCount} · weighted ${day.weightedCompleted}/${day.weightedCreated}',
          ),
          const SizedBox(height: 14),
          ProgressThinBar(
            label: 'Week',
            ratio: shownWeek,
            color: ProgressDesignTokens.primaryDim,
            detail:
                '${week.completedCount}/${week.createdCount} · weighted ${week.weightedCompleted}/${week.weightedCreated}',
          ),
          const SizedBox(height: 14),
          ProgressThinBar(
            label: 'Month',
            ratio: shownMonth,
            color: ProgressDesignTokens.primaryDim.withValues(alpha: 0.75),
            detail:
                '${month.completedCount}/${month.createdCount} · weighted ${month.weightedCompleted}/${month.weightedCreated}',
          ),
        ],
      ),
    );
  }
}
