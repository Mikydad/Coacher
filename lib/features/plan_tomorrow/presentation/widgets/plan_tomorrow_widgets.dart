import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';

/// Obsidian Pulse tokens for Plan Tomorrow — visual only.
abstract final class PlanTomorrowColors {
  static const lime = AppColors.accent;
  static const cyan = AppColors.cyan;
  static const surface = AppColors.ink;
  static const card = AppColors.inkDeep;
  static const cardRaised = AppColors.inkWarm;
  static const label = AppColors.textSoft;
  static const hint = AppColors.graySlate;
}

class PlanTomorrowHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const PlanTomorrowHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white70),
        onPressed: () => Navigator.maybePop(context),
      ),
      centerTitle: true,
      title: const Text(
        'Plan Tomorrow',
        style: TextStyle(
          color: PlanTomorrowColors.lime,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class PlanTomorrowHero extends StatelessWidget {
  const PlanTomorrowHero({super.key, required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAN TOMORROW',
          style: TextStyle(
            letterSpacing: 3,
            color: PlanTomorrowColors.lime,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Design your tomorrow.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dateLabel,
          style: const TextStyle(color: PlanTomorrowColors.label, fontSize: 15),
        ),
      ],
    );
  }
}

class PlanTomorrowDashedEmpty extends StatelessWidget {
  const PlanTomorrowDashedEmpty({super.key, this.message = 'No tasks yet.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.white.withValues(alpha: 0.18),
          radius: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          alignment: Alignment.center,
          child: Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

class PlanTomorrowAddTaskButton extends StatelessWidget {
  const PlanTomorrowAddTaskButton({
    super.key,
    required this.onPressed,
    this.accentColor = PlanTomorrowColors.lime,
  });

  final VoidCallback onPressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(Icons.add, size: 18, color: accentColor),
          label: Text(
            'ADD TASK',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
        ),
      ),
    );
  }
}

class PlanTomorrowAddSlotButton extends StatelessWidget {
  const PlanTomorrowAddSlotButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.white.withValues(alpha: 0.22),
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text(
                'ADD A NEW SLOT',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanTomorrowDoneButton extends StatelessWidget {
  const PlanTomorrowDoneButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: PlanTomorrowColors.lime,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Text(
          'Done — See Summary',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }
}

class PlanTomorrowSectionLabel extends StatelessWidget {
  const PlanTomorrowSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        letterSpacing: 2,
        color: PlanTomorrowColors.cyan,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const dashWidth = 6.0;
    const dashSpace = 5.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
