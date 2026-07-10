import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../education/presentation/help_dot.dart';
import 'progress_design_tokens.dart';

class ProgressTonalCard extends StatelessWidget {
  ProgressTonalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? ProgressDesignTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ProgressDesignTokens.cardRadius),
      ),
      child: child,
    );
  }
}

class ProgressMiniStatCard extends StatelessWidget {
  ProgressMiniStatCard({
    super.key,
    required this.label,
    required this.title,
    this.badge,
    this.badgeColor,
  });

  final String label;
  final String title;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProgressDesignTokens.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ProgressDesignTokens.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    badge!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: badgeColor ?? ProgressDesignTokens.primaryDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ProgressDesignTokens.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressGlassCard extends StatelessWidget {
  const ProgressGlassCard({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.headline,
    required this.body,
    this.helpId,
  });

  final Color? accentColor;
  final IconData icon;
  final String title;
  final String headline;
  final String body;

  /// Feature-guide id — renders a `?` that opens the help sheet.
  final String? helpId;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ProgressDesignTokens.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ProgressDesignTokens.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
            borderRadius: BorderRadius.circular(
              ProgressDesignTokens.cardRadius,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor ?? ProgressDesignTokens.primaryDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: accentColor ?? ProgressDesignTokens.primaryDim,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            color:
                                accentColor ?? ProgressDesignTokens.primaryDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                        if (helpId != null) HelpDot(helpId!),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      headline,
                      style: TextStyle(
                        color: ProgressDesignTokens.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        color: ProgressDesignTokens.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressChip extends StatelessWidget {
  ProgressChip({
    super.key,
    required this.label,
    this.highlighted = false,
    this.accentColor,
  });

  final String label;
  final bool highlighted;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? (accentColor ?? ProgressDesignTokens.primaryDim).withValues(
                alpha: 0.12,
              )
            : ProgressDesignTokens.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted
              ? accentColor ?? ProgressDesignTokens.primaryDim
              : ProgressDesignTokens.onSurface,
          fontSize: 13,
          fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class ProgressThinBar extends StatelessWidget {
  const ProgressThinBar({
    super.key,
    required this.label,
    required this.ratio,
    required this.color,
    this.showDetail = true,
    this.detail,
  });

  final String label;
  final double ratio;
  final Color color;
  final bool showDetail;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final clamped = ratio.clamp(0.0, 1.0);
    final pct = (clamped * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: ProgressDesignTokens.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: clamped,
              backgroundColor: ProgressDesignTokens.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        if (showDetail && detail != null) ...[
          const SizedBox(height: 4),
          Text(
            detail!,
            style: TextStyle(
              color: ProgressDesignTokens.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class DisciplineHeroRing extends StatelessWidget {
  const DisciplineHeroRing({
    super.key,
    required this.percent,
    required this.sweep,
    this.size = 168,
  });

  final int percent;
  final double sweep;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = (percent / 100.0 * sweep.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    final scoreSize = (size * 0.36).clamp(36.0, 48.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              color: ProgressDesignTokens.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _GradientRingPainter(
                progress: progress,
                strokeWidth: 10,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent',
                style: TextStyle(
                  color: ProgressDesignTokens.onSurface,
                  fontSize: scoreSize,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DISCIPLINE',
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
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  _GradientRingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = ProgressDesignTokens.ringGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -3.141592653589793 / 2,
      2 * 3.141592653589793 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
