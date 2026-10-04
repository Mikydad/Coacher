import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';

/// The shared look of the two timer screens — the Focus session and the
/// accountability (stake) timer (2026-09-27, Miko: "the reference design as
/// inspiration — the circle, the background — nothing else changes").
///
/// Always dark, in both theme modes: a running session should feel like a
/// different place from the planning screens. Like `OnboardingColors`, the
/// tokens alias [AppPalette.dark] DIRECTLY (not [AppColors]) so light mode
/// cannot invert them; the ring and primary button keep the app's lime.
abstract final class FocusColors {
  static const AppPalette _dark = AppPalette.dark;

  /// Background gradient, top → bottom (deep ink into navy).
  static List<Color> get backgroundGradient => [
    _dark.dark0D1117,
    _dark.dark0F0F1A,
    _dark.dark1A2535,
  ];

  static Color get accent => _dark.accent;
  static Color get onAccent => _dark.onAccent;

  /// Celebration burst confetti, alongside the accent.
  static List<Color> get burst => [
    _dark.accent,
    _dark.cyan,
    _dark.periwinkle,
    _dark.fg,
  ];

  /// Ring fill once a stake session passes its minimum.
  static Color get success => _dark.statusGreen;

  static Color get track => _dark.fg10;
  static Color get surface => _dark.fg10.withValues(alpha: 0.05);
  static Color get surfaceHigh => _dark.fg10;
  static Color get border => _dark.whiteBorder8;

  static Color get textPrimary => _dark.textPrimary;
  static Color get textSecondary => _dark.fg70;
  static Color get textMuted => _dark.fg54;
  static Color get dot => _dark.fg;
}

/// Scaffold with the dark gradient, a transparent app bar and light status
/// bar icons. [title] renders in [PageTitle]'s type, recolored for the dark
/// stage.
class FocusStageScaffold extends StatelessWidget {
  const FocusStageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FocusColors.backgroundGradient.first,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: FocusColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          title.toUpperCase(),
          style: PageTitle.style.copyWith(color: FocusColors.textSecondary),
        ),
        actions: actions,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: FocusColors.backgroundGradient,
          ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}

/// The progress ring with the timer inside it.
///
/// [progress] is 0..1 toward the target; null = no target (open-ended), which
/// draws the faint track only. Progress eases between the 1 s ticks so the
/// arc glides instead of stepping.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.size,
    required this.progress,
    required this.timeText,
    required this.statusLabel,
    this.statusIcon = Icons.track_changes_rounded,
    this.chipLabel,
    this.color,
    this.dimmed = false,
  });

  final double size;
  final double? progress;
  final String timeText;
  final String statusLabel;
  final IconData statusIcon;
  final String? chipLabel;

  /// Arc color; defaults to the accent.
  final Color? color;

  /// Paused: the arc fades back so the stopped state reads at a glance.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final arcColor = (color ?? FocusColors.accent).withValues(
      alpha: dimmed ? 0.45 : 1,
    );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress ?? 0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, _) => CustomPaint(
                painter: _RingPainter(
                  progress: progress == null ? null : value,
                  color: arcColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: size * 0.68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 18,
                      color: FocusColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: FocusColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timeText,
                    maxLines: 1,
                    style: TextStyle(
                      color: FocusColors.textPrimary,
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (chipLabel != null) ...[
                  const SizedBox(height: 10),
                  _FocusChip(label: chipLabel!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: FocusColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FocusColors.border),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: FocusColors.textSecondary, fontSize: 12.5),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double? progress;
  final Color color;

  static const _stroke = 10.0;

  /// Room around the arc for its glow and the end dot.
  static const _pad = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _pad;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Faint inner disc — gives the ring a face, like the reference.
    canvas.drawCircle(
      center,
      radius - _stroke,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.07), color.withValues(alpha: 0)],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = FocusColors.track,
    );

    final p = progress;
    if (p == null || p <= 0) return;
    final sweep = 2 * math.pi * p.clamp(0.0, 1.0);
    const start = -math.pi / 2;
    final capAngle = (_stroke / 2) / radius;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke + 6
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        // Rotated back by the round cap's reach so the cap behind the
        // start point picks up the faint end, not a wrapped bright one.
        ..shader = SweepGradient(
          transform: GradientRotation(start - capAngle),
          colors: [color.withValues(alpha: 0.35), color],
          stops: [0, ((sweep + capAngle) / (2 * math.pi)).clamp(0.01, 1.0)],
        ).createShader(rect),
    );

    // A closed ring has no "head" to mark.
    if (p >= 1) return;
    final end = center + Offset.fromDirection(start + sweep, radius);
    canvas.drawCircle(
      end,
      _stroke,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(end, _stroke * 0.8, Paint()..color = FocusColors.dot);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// One round control: the big lime primary or a smaller quiet secondary,
/// each captioned so the action is never an unlabeled icon.
class FocusRoundButton extends StatelessWidget {
  const FocusRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  /// Swaps the icon for a spinner (e.g. while a session saves).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final diameter = primary ? 88.0 : 64.0;
    final enabled = onPressed != null;
    final fill = primary ? FocusColors.accent : FocusColors.surfaceHigh;
    final fg = primary ? FocusColors.onAccent : FocusColors.textPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      // The caption is part of the target: people tap the word, too.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Opacity(
          opacity: enabled || busy ? 1 : 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: fill,
                shape: CircleBorder(
                  side: primary
                      ? BorderSide.none
                      : BorderSide(color: FocusColors.border),
                ),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Container(
                    width: diameter,
                    height: diameter,
                    alignment: Alignment.center,
                    decoration: primary
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: FocusColors.accent.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 28,
                              ),
                            ],
                          )
                        : null,
                    child: busy
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: fg,
                            ),
                          )
                        : Icon(icon, size: primary ? 40 : 28, color: fg),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: FocusColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The controls row: the primary centered, the secondary to its right (an
/// empty slot on the left keeps the primary on the screen's center line).
class FocusControls extends StatelessWidget {
  const FocusControls({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final FocusRoundButton primary;
  final FocusRoundButton secondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: SizedBox()),
        primary,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: secondary),
          ),
        ),
      ],
    );
  }
}

/// The "Working on" card at the bottom of the stage (display only).
class FocusWorkingOnCard extends StatelessWidget {
  const FocusWorkingOnCard({
    super.key,
    required this.title,
    this.icon = Icons.description_outlined,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FocusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FocusColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FocusColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: FocusColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKING ON',
                  style: TextStyle(
                    color: FocusColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FocusColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet one-line notice on the stage (auto-start countdown, "ready for
/// scoring"), with an optional trailing action.
class FocusNotice extends StatelessWidget {
  const FocusNotice({super.key, required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 4, action == null ? 14 : 4, 4),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: FocusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FocusColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: FocusColors.textSecondary),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Ring diameter for the available box: big, but leaves room for the
/// controls and the card on short phones.
double focusRingSize(BoxConstraints c) =>
    math.min(300, math.min(c.maxWidth - 40, c.maxHeight * 0.46));

/// The "task done" moment (2026-09-27, Miko: finishing should celebrate,
/// not jump straight to the next-task question). The ring closes, a check
/// pops in with a confetti burst and a success haptic; [onContinue] leads
/// on to the rest of the flow. Null [onContinue] hides the button (the
/// flow already moved on and this sits under its dialog).
class FocusCelebration extends StatefulWidget {
  const FocusCelebration({
    super.key,
    required this.ringSize,
    required this.taskLabel,
    required this.focusedMinutes,
    required this.onContinue,
  });

  final double ringSize;
  final String taskLabel;
  final int focusedMinutes;
  final VoidCallback? onContinue;

  @override
  State<FocusCelebration> createState() => _FocusCelebrationState();
}

class _FocusCelebrationState extends State<FocusCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.05, 0.6, curve: Curves.elasticOut),
    );
    final burst = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.1, 1, curve: Curves.easeOutCubic),
    );
    final text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
    final minutes = widget.focusedMinutes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: widget.ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(progress: 1, color: FocusColors.accent),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: burst,
                  builder: (context, _) =>
                      CustomPaint(painter: _BurstPainter(t: burst.value)),
                ),
              ),
              ScaleTransition(
                scale: pop,
                child: Container(
                  width: widget.ringSize * 0.36,
                  height: widget.ringSize * 0.36,
                  decoration: BoxDecoration(
                    color: FocusColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: FocusColors.accent.withValues(alpha: 0.45),
                        blurRadius: 36,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: widget.ringSize * 0.22,
                    color: FocusColors.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: text,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(text),
            child: Column(
              children: [
                Text(
                  'Task done!',
                  style: SectionHeader.heroStyle.copyWith(
                    color: FocusColors.textPrimary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.taskLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FocusColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (minutes >= 1) ...[
                  const SizedBox(height: 12),
                  _FocusChip(
                    label: minutes == 1
                        ? '1 min of focus'
                        : '$minutes min of focus',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        AnimatedOpacity(
          opacity: widget.onContinue == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: FocusColors.accent,
                foregroundColor: FocusColors.onAccent,
                shape: const StadiumBorder(),
              ),
              onPressed: widget.onContinue,
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Confetti dots flying out past the ring, fading as they go.
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.t});

  final double t;

  static const _count = 22;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.2;
    final reach = size.shortestSide * 0.56;
    final colors = FocusColors.burst;
    // Hold full strength early, then fade (quadratic) so the burst reads.
    final fade = (1 - t * t).clamp(0.0, 1.0);
    for (var i = 0; i < _count; i++) {
      // Deterministic jitter so the burst looks organic, not a clock face.
      final jitter = math.sin(i * 12.9898) * 0.5;
      final angle = (2 * math.pi * i / _count) + jitter * 0.35;
      final speed = 0.7 + (math.cos(i * 4.1414).abs() * 0.3);
      final dist = base + (reach - base) * t * speed;
      final p = center + Offset.fromDirection(angle, dist);
      final r = (i.isEven ? 7.0 : 4.5) * (1 - t * 0.4);
      canvas.drawCircle(
        p,
        r,
        Paint()..color = colors[i % colors.length].withValues(alpha: fade),
      );
    }
    // One soft shockwave ring expanding out of the progress ring.
    canvas.drawCircle(
      center,
      size.shortestSide / 2 - 14 + 30 * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade
        ..color = FocusColors.accent.withValues(alpha: 0.5 * fade),
    );
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
