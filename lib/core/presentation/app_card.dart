import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared surfaces for the 2026-09-14 Home redesign (PRD/The new Design):
/// white cards on a warm off-white page, soft diffused shadows instead of
/// borders, one radius hierarchy (cards 24, tiles 22, empty states 18,
/// pills 999, icon buttons circular).
///
/// Every widget here reads [AppColors] only, so dark mode maps through the
/// existing dark palette with no per-screen work.

/// The one card shadow — neutral, low, wide.
List<BoxShadow> get appCardShadow => [
  BoxShadow(
    color: AppColors.cardShadow,
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

/// A slightly stronger shadow for the one filled primary tile.
List<BoxShadow> get appPrimaryShadow => [
  BoxShadow(
    color: AppColors.accent.withValues(alpha: 0.28),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

/// White (dark: panel) card with the shared shadow and no border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color,
    this.margin,
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  /// Whole-card tap; the ripple is clipped to the card's corners.
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    final shape = BorderRadius.circular(radius);
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: shape, child: body),
      );
    }
    return Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfacePanel,
        borderRadius: shape,
        boxShadow: appCardShadow,
      ),
      child: body,
    );
  }
}

/// Circular icon button on a white disc — header actions, section "+".
///
/// Pass a null [onPressed] for a purely decorative control: it renders
/// identically but has no ripple, so it never fakes a pressed state.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 48,
    this.iconSize = 22,
    this.iconColor,
    this.background,
    this.shadow = true,
    this.child,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? background;
  final bool shadow;

  /// Replaces the icon (e.g. a progress spinner while syncing).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    final glyph =
        child ??
        Icon(icon, size: iconSize, color: iconColor ?? AppColors.textPrimary);
    Widget disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? AppColors.surfacePanel,
        shape: BoxShape.circle,
        boxShadow: shadow ? appCardShadow : null,
      ),
      child: Center(child: glyph),
    );
    if (onPressed != null) {
      disc = Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: disc,
        ),
      );
    }
    if (tooltip == null) return disc;
    return Tooltip(message: tooltip!, child: disc);
  }
}

/// Soft pill action — pale accent wash, accent text ("Do now").
class AppSoftPill extends StatelessWidget {
  const AppSoftPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.background,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    return Material(
      color: background ?? AppColors.actionTint,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Deliberate empty state: a dashed hairline box that says "this space is
/// waiting for content", instead of a lone gray sentence.
class AppDashedEmptyState extends StatelessWidget {
  const AppDashedEmptyState({
    super.key,
    required this.message,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    this.radius = 18,
  });

  final String message;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.divider,
        radius: radius,
        strokeWidth: 1.2,
        dash: 6,
        gap: 5,
      ),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surfacePanel.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dash != dash ||
      old.gap != gap;
}

/// Uppercase tracked micro-label used above Home sections ("PROMISES",
/// "ON YOUR RADAR · 2"). One style, so every section header matches.
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key});

  final String text;

  static TextStyle get style => TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    return Text(text, style: style);
  }
}
