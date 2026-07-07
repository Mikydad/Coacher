import 'package:flutter/material.dart';

import '../../application/analytics_period_bundle.dart';
import '../../application/discipline_score.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

import '../../../../core/presentation/app_colors.dart';

String progressWeekDateRangeLabel() {
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final end = start.add(const Duration(days: 6));
  String fmt(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  return '${fmt(start)} — ${fmt(end)}';
}

class WeeklySummaryHero extends StatelessWidget {
  const WeeklySummaryHero({
    super.key,
    required this.bundle,
    required this.ringSweep,
  });

  final AnalyticsPeriodBundle bundle;
  final double ringSweep;

  @override
  Widget build(BuildContext context) {
    final discipline = disciplinePercentWeek(bundle);
    final delta = disciplineWeekVsTodayDelta(bundle);
    final deltaLabel = delta >= 0 ? '+$delta%' : '$delta%';
    final streaks = disciplineStreakSummary(bundle);
    final topCategory = disciplineTopCategoryLabel(bundle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Weekly Summary',
              style: TextStyle(
                color: ProgressDesignTokens.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              progressWeekDateRangeLabel().toUpperCase(),
              style: TextStyle(
                color: ProgressDesignTokens.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProgressTonalCard(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ProgressDesignTokens.primaryDim.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: DisciplineHeroRing(
                      percent: discipline,
                      sweep: ringSweep,
                      size: 148,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProgressMiniStatCard(
                    label: 'Top category',
                    title: topCategory,
                    badge: deltaLabel,
                    badgeColor: delta >= 0
                        ? ProgressDesignTokens.primaryDim
                        : AppColors.coral,
                  ),
                  const SizedBox(height: 10),
                  ProgressMiniStatCard(
                    label: 'Streaks',
                    title:
                        'Habit ${streaks.goalHabitCurrentDays}d · Task ${streaks.taskCurrentDays}d',
                    badge:
                        streaks.goalHabitCurrentDays >= 3 &&
                            streaks.taskCurrentDays >= 3
                        ? 'STABLE'
                        : 'BUILDING',
                    badgeColor: ProgressDesignTokens.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
