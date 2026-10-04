import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../education/presentation/help_dot.dart';
import '../../application/progress_period_series.dart';
import '../../domain/progress_period.dart';
import 'progress_design_tokens.dart';
import 'progress_shared_widgets.dart';

/// The period's headline numbers: blended %, days met, delta vs the previous
/// period. (Streak chips retired 2026-09-25 — the day streak is not a
/// user-facing concept any more.)
class PeriodRollupCard extends StatelessWidget {
  const PeriodRollupCard({super.key, required this.series});

  final ProgressPeriodSeries series;

  static String previousLabel(ProgressHorizon h) => switch (h) {
    ProgressHorizon.day => 'yesterday',
    ProgressHorizon.week => 'last week',
    ProgressHorizon.month => 'last month',
    ProgressHorizon.quarter => 'last quarter',
    ProgressHorizon.year => 'last year',
  };

  @override
  Widget build(BuildContext context) {
    final rate = series.periodRate;
    final pct = rate == null ? '—' : '${(rate * 100).round()}%';
    final delta = series.deltaPoints;
    final isDay = series.period.horizon == ProgressHorizon.day;

    return ProgressTonalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'DISCIPLINE · ${series.period.scopeLabel()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ProgressDesignTokens.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const HelpDot('weeklySummary', dense: true),
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _DeltaChip(
                delta: delta,
                label: previousLabel(series.period.horizon),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pct,
                style: TextStyle(
                  color: ProgressDesignTokens.onSurface,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    rate == null
                        ? 'Nothing planned${isDay ? ' this day' : ' yet'}'
                        : isDay
                        ? (series.daysMet > 0 ? 'Day met' : 'Below your bar')
                        : '${series.daysMet} of ${series.daysPlanned} planned '
                              'day${series.daysPlanned == 1 ? '' : 's'} met',
                    style: TextStyle(
                      color: ProgressDesignTokens.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta, required this.label});
  final int delta;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = delta >= 0 ? ProgressDesignTokens.primaryDim : AppColors.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${delta >= 0 ? '+' : ''}$delta pts vs $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
