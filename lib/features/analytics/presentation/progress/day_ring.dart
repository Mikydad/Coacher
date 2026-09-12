import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../application/blended_discipline.dart';
import 'progress_design_tokens.dart';

/// One calendar day as a ring (PRD §4.3). Fill = blended rate; state
/// decides the stroke. The same painter draws the 40 px calendar cells and
/// the 168 px Day hero.
class DayRingPainter extends CustomPainter {
  DayRingPainter({
    required this.value,
    required this.state,
    required this.isToday,
    required this.strokeWidth,
    this.selected = false,
  });

  /// 0–1; ignored for quiet / future.
  final double value;
  final RingState state;
  final bool isToday;
  final double strokeWidth;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2 - (isToday ? 3 : 0);
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (selected) {
      canvas.drawCircle(
        center,
        size.shortestSide / 2,
        Paint()..color = ProgressDesignTokens.surfaceBright,
      );
    }

    if (isToday) {
      canvas.drawCircle(
        center,
        size.shortestSide / 2 - 0.75,
        Paint()
          ..color = ProgressDesignTokens.primaryDim.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final track = Paint()
      ..color = ProgressDesignTokens.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    switch (state) {
      case RingState.future:
        return;
      case RingState.quiet:
        _dashedCircle(canvas, center, radius, track..strokeWidth = 1);
        return;
      case RingState.missed:
        canvas.drawCircle(center, radius, track);
        return;
      case RingState.protected:
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = ProgressDesignTokens.secondary.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth,
        );
        return;
      case RingState.qualified:
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = ProgressDesignTokens.primaryDim
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          center,
          radius - strokeWidth / 2,
          Paint()
            ..color = ProgressDesignTokens.primaryDim.withValues(alpha: 0.14),
        );
        return;
      case RingState.partial:
        canvas.drawCircle(center, radius, track);
        final sweep = 2 * math.pi * value.clamp(0.0, 1.0);
        canvas.drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          Paint()
            ..shader = ProgressDesignTokens.ringGradient.createShader(rect)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
        return;
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    const dashes = 12;
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * step,
        step * 0.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DayRingPainter old) =>
      old.value != value ||
      old.state != state ||
      old.isToday != isToday ||
      old.selected != selected ||
      old.strokeWidth != strokeWidth;
}

/// A tappable calendar-cell ring with the day number inside.
class DayRing extends StatelessWidget {
  const DayRing({
    super.key,
    required this.dayNumber,
    required this.value,
    required this.state,
    required this.isToday,
    this.selected = false,
    this.muted = false,
    this.size = 40,
    this.onTap,
  });

  final int dayNumber;
  final double? value;
  final RingState state;
  final bool isToday;
  final bool selected;

  /// Leading / trailing days of a month grid: number only, faint.
  final bool muted;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final faint = muted || state == RingState.future || state == RingState.quiet;
    final ring = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: muted
            ? null
            : DayRingPainter(
                value: value ?? 0,
                state: state,
                isToday: isToday,
                strokeWidth: size >= 60 ? 6 : 3,
                selected: selected,
              ),
        child: Center(
          child: Text(
            '$dayNumber',
            style: TextStyle(
              color: faint
                  ? ProgressDesignTokens.onSurfaceVariant.withValues(
                      alpha: muted ? 0.4 : 0.8,
                    )
                  : ProgressDesignTokens.onSurface,
              fontSize: size * 0.3,
              fontWeight: state == RingState.qualified || isToday
                  ? FontWeight.w800
                  : FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return ring;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Day $dayNumber',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        splashColor: AppColors.whiteGlow20,
        child: ring,
      ),
    );
  }
}
