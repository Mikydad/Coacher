import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bento card palette for the category-first pickers (Add Task, New Goal).
/// Deliberately fixed raw colors (NOT AppColors tokens): per the design
/// reference these bright cards look identical in dark and light themes —
/// only the page background behind them adapts. [ink] is the dark text
/// drawn on top of every card.
abstract final class BentoPalette {
  static const yellow = Color(0xFFF6D14E);
  static const orange = Color(0xFFEF8D43);
  static const green = Color(0xFF92E3A9);
  static const purple = Color(0xFFC79BF2);
  static const blue = Color(0xFF8FC9F5);
  static const teal = Color(0xFF56C2AB);
  static const ink = Color(0xFF17191C);
}

/// One colored mosaic card: uppercase label top-left, a check chip top-right
/// when selected, a hero glyph, one soft supporting line below. Sizes itself
/// to whatever height its mosaic slot gives it — short slots drop the
/// subtitle and shrink the glyph instead of overflowing.
///
/// Selection keeps the card's color untouched and draws an inner accent ring
/// (inset from the edge) with a soft glow that gently pulses — lights and
/// dims — plus a check chip centered on the right edge; [dimmed] softly
/// recedes the non-chosen siblings.
class BentoCategoryCard extends StatefulWidget {
  const BentoCategoryCard({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.selected = false,
    this.dimmed = false,
    this.hero = false,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;

  /// Softly fades the card when a sibling is selected (kept subtle — the
  /// options must still read as available).
  final bool dimmed;

  /// The full-width top card: bigger glyph, roomier text.
  final bool hero;

  @override
  State<BentoCategoryCard> createState() => _BentoCategoryCardState();
}

class _BentoCategoryCardState extends State<BentoCategoryCard>
    with SingleTickerProviderStateMixin {
  /// Drives the comet sweep — one lap of the ring per cycle; runs only while
  /// selected. Linear on purpose: a curve would make the comet speed pulse.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.selected) _pulse.repeat();
  }

  @override
  void didUpdateWidget(BentoCategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;
    if (widget.selected) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fg = BentoPalette.ink;
    return AnimatedOpacity(
      opacity: widget.dimmed ? 0.82 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: widget.color,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            // Non-positioned children fill the slot — keeps the hero card
            // full-width even under the mosaic Column's loose constraints.
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 96;
                  return Padding(
                    padding: EdgeInsets.all(compact ? 10 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: fg,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          widget.icon,
                          color: fg,
                          size: widget.hero
                              ? 38
                              : compact
                              ? 18
                              : 26,
                        ),
                        if (widget.subtitle != null && !compact) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            maxLines: widget.hero ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.72),
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (widget.selected) ...[
                // Inner white ring with a comet sweep: a bright highlight
                // (with fading tail) travels the border; the rest of the
                // ring stays a dim steady white. Painter, not BoxShadow —
                // the glow must hug the stroke, never haze the card face.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) => CustomPaint(
                          painter: _CometRingPainter(t: _pulse.value),
                        ),
                      ),
                    ),
                  ),
                ),
                // Check chip: top-right corner.
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_rounded, size: 14, color: fg),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// White selection ring with a traveling comet: a dim steady base ring, and
/// a bright highlight with a fading tail that laps the border once per [t]
/// cycle (sweep-gradient stroke rotated by t). The comet also carries a
/// blurred halo so the moving light glows along the stroke only.
class _CometRingPainter extends CustomPainter {
  const _CometRingPainter({required this.t});

  /// Lap progress, 0..1 → one full trip around the border.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(19));

    // Dim steady track.
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.38);
    canvas.drawRRect(rrect, base);

    // Comet: tail brightens toward the head, then cuts off.
    final comet = SweepGradient(
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.55),
        Colors.white,
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.62, 0.86, 0.97, 0.98],
      transform: GradientRotation(2 * math.pi * t),
    ).createShader(rect);

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = comet
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect, halo);

    final head = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = comet;
    canvas.drawRRect(rrect, head);
  }

  @override
  bool shouldRepaint(_CometRingPainter oldDelegate) => oldDelegate.t != t;
}

/// The dark "pill" action button that sits under a bento mosaic (Custom
/// category / Custom goal). Optionally shows a highlight ring when active.
class BentoPillButton extends StatelessWidget {
  const BentoPillButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.icon = Icons.add,
    this.ringColor,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final IconData icon;

  /// Border drawn when [active] is true (e.g. a custom value is selected).
  final Color? ringColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          decoration: active && ringColor != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ringColor!, width: 2),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
