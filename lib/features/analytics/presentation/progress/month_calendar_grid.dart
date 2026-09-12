import 'package:flutter/material.dart';

import '../../../../core/utils/date_keys.dart';
import '../../application/blended_discipline.dart';
import '../../application/progress_period_series.dart';
import '../../domain/progress_period.dart';
import 'day_ring.dart';
import 'progress_design_tokens.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A month of rings, Monday-first, six rows. Leading and trailing days
/// from the neighbouring months are shown faint and are not tappable.
class MonthCalendarGrid extends StatelessWidget {
  const MonthCalendarGrid({
    super.key,
    required this.period,
    required this.days,
    required this.selectedDateKey,
    required this.onTapDay,
    this.todayKey,
  });

  final ProgressPeriod period;
  final List<ProgressDayPoint> days;
  final String? selectedDateKey;
  final ValueChanged<String> onTapDay;
  final String? todayKey;

  @override
  Widget build(BuildContext context) {
    final today = todayKey ?? DateKeys.todayKey();
    final byKey = {for (final d in days) d.dateKey: d};
    final first = period.start;
    final leading = first.weekday - 1; // Monday = 0
    final gridStart = DateTime(first.year, first.month, first.day - leading);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth / 7).clamp(32.0, 52.0);
        final ringSize = (cell - 8).clamp(28.0, 44.0);
        return Column(
          children: [
            Row(
              children: [
                for (final l in _weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          color: ProgressDesignTokens.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var row = 0; row < 6; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: Center(
                          child: _cell(
                            DateTime(
                              gridStart.year,
                              gridStart.month,
                              gridStart.day + row * 7 + col,
                            ),
                            byKey,
                            today,
                            ringSize,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cell(
    DateTime date,
    Map<String, ProgressDayPoint> byKey,
    String today,
    double size,
  ) {
    final key = DateKeys.yyyymmdd(date);
    final inMonth = period.contains(key);
    final point = inMonth ? byKey[key] : null;
    return DayRing(
      dayNumber: date.day,
      value: point?.blended,
      state: point?.state ?? RingState.future,
      isToday: inMonth && key == today,
      selected: inMonth && key == selectedDateKey,
      muted: !inMonth,
      size: size,
      onTap: inMonth && point != null && point.state != RingState.future
          ? () => onTapDay(key)
          : null,
    );
  }
}
