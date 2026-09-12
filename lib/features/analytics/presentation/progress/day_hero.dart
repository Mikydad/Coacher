import 'package:flutter/material.dart';

import '../../application/blended_discipline.dart';
import '../../application/progress_period_series.dart';
import 'day_ring.dart';
import 'progress_design_tokens.dart';

/// The Day horizon's hero: one large ring with the blended % inside.
class DayHero extends StatelessWidget {
  const DayHero({
    super.key,
    required this.point,
    required this.isToday,
    this.sweep = 1.0,
    this.size = 168,
  });

  final ProgressDayPoint point;
  final bool isToday;

  /// Intro animation progress for the arc (0–1).
  final double sweep;
  final double size;

  @override
  Widget build(BuildContext context) {
    final blended = point.blended;
    final shown = blended == null ? null : blended * sweep.clamp(0.0, 1.0);
    final label = switch (point.state) {
      RingState.qualified => 'DAY MET',
      RingState.partial => 'DISCIPLINE',
      RingState.missed => 'MISSED',
      RingState.quiet => 'QUIET DAY',
      RingState.protected => 'PROTECTED',
      RingState.future => 'UPCOMING',
    };
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: DayRingPainter(
                value: shown ?? 0,
                // Animate the qualified ring as a sweep too.
                state: point.state == RingState.qualified && sweep < 1
                    ? RingState.partial
                    : point.state,
                isToday: isToday,
                strokeWidth: 10,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  blended == null ? '—' : '${(shown! * 100).round()}',
                  style: TextStyle(
                    color: ProgressDesignTokens.onSurface,
                    fontSize: (size * 0.3).clamp(32.0, 52.0),
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: ProgressDesignTokens.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
