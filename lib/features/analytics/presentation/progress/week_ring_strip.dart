import 'package:flutter/material.dart';

import '../../../../core/utils/date_keys.dart';
import '../../application/progress_period_series.dart';
import 'day_ring.dart';
import 'progress_design_tokens.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Seven rings, Monday → Sunday. Tapping a ring opens that day's detail.
class WeekRingStrip extends StatelessWidget {
  const WeekRingStrip({
    super.key,
    required this.days,
    required this.selectedDateKey,
    required this.onTapDay,
    this.todayKey,
  });

  /// Exactly the period's 7 points, Monday first.
  final List<ProgressDayPoint> days;
  final String? selectedDateKey;
  final ValueChanged<String> onTapDay;
  final String? todayKey;

  @override
  Widget build(BuildContext context) {
    final today = todayKey ?? DateKeys.todayKey();
    return Row(
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _weekdayLabels[i % 7],
                  style: TextStyle(
                    color: days[i].dateKey == today
                        ? ProgressDesignTokens.primaryDim
                        : ProgressDesignTokens.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                DayRing(
                  dayNumber: int.parse(days[i].dateKey.substring(8)),
                  value: days[i].blended,
                  state: days[i].state,
                  isToday: days[i].dateKey == today,
                  selected: days[i].dateKey == selectedDateKey,
                  size: 42,
                  onTap: () => onTapDay(days[i].dateKey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
