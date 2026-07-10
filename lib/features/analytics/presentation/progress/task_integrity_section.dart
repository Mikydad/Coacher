import 'package:flutter/material.dart';
import '../../../education/presentation/help_dot.dart';

import '../../application/daily_analytics_engine.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

class TaskIntegritySection extends StatelessWidget {
  const TaskIntegritySection({
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
                decoration: BoxDecoration(
                  color: ProgressDesignTokens.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Task Integrity',
                style: TextStyle(
                  color: ProgressDesignTokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const HelpDot('taskIntegrity'),
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
            ],
          ),
          const SizedBox(height: 20),
          ProgressThinBar(
            label: 'Current velocity',
            ratio: shownDay,
            color: ProgressDesignTokens.secondary,
            detail: '${day.completedCount}/${day.createdCount} completed today',
          ),
          const SizedBox(height: 14),
          ProgressThinBar(
            label: '7-day average',
            ratio: shownWeek,
            color: ProgressDesignTokens.secondary,
            detail:
                '${week.completedCount}/${week.createdCount} · weighted ${week.weightedCompleted}/${week.weightedCreated}',
          ),
        ],
      ),
    );
  }
}
