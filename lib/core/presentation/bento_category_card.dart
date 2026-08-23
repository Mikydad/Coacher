import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One card's three-part color recipe: a near-black tinted [surface], a
/// muted [accent] that the glyph (and the selection comet) carries, and a
/// dim [border] for the resting hairline / selection track.
///
/// The premium look depends on the surface staying almost black: saturated
/// fills read as cheap against the app's black scaffold, so the color lives
/// in the icon and the ring, never in the fill.
class BentoTone {
  const BentoTone({
    required this.surface,
    required this.accent,
    required this.border,
  });

  final Color surface;
  final Color accent;
  final Color border;
}

/// Bento palette for the category-first pickers (Add Task, New Goal).
/// Deliberately fixed raw colors (NOT AppColors tokens): per the design
/// reference these cards look identical in dark and light themes — only the
/// page background behind them adapts.
///
/// Two families live here:
/// - [BentoTone]s — the dark charcoal mosaic cards of the New Goal picker
///   ([BentoCategoryCard]): black surface, colored icon, colored ring.
/// - The bright flat colors below — the Add Task mini chips, which invert
///   to [ink] on select and so need a saturated fill.
abstract final class BentoPalette {
  // Charcoal tones — warm/brown/green/purple/blue tinted blacks.
  static const study = BentoTone(
    surface: Color(0xFF2A2622),
    accent: Color(0xFFF2D9A5),
    border: Color(0xFFBFA77A),
  );
  static const fitness = BentoTone(
    surface: Color(0xFF292521),
    accent: Color(0xFFD99A68),
    border: Color(0xFF5F4A3A),
  );
  static const learn = BentoTone(
    surface: Color(0xFF242C29),
    accent: Color(0xFF9ACFC2),
    border: Color(0xFF465C55),
  );
  static const read = BentoTone(
    surface: Color(0xFF252329),
    accent: Color(0xFFA98BCE),
    border: Color(0xFF554965),
  );
  static const focus = BentoTone(
    surface: Color(0xFF20262C),
    accent: Color(0xFF8FB8DD),
    border: Color(0xFF45586B),
  );

  /// Text drawn on a charcoal card.
  static const cardText = Color(0xFFF5F5F5);
  static const cardTextMuted = Color(0xFFA8A8A8);

  // Bright flat colors — Add Task mini chips only.
  static const yellow = Color(0xFFF6D14E);
  static const orange = Color(0xFFEF8D43);
  static const green = Color(0xFF92E3A9);
  static const purple = Color(0xFFC79BF2);
  static const blue = Color(0xFF8FC9F5);
  static const teal = Color(0xFF56C2AB);
  static const ink = Color(0xFF17191C);
}

/// One charcoal mosaic card: uppercase label top-left, a check chip
/// top-right when selected, a colored hero glyph, one soft supporting line
/// below. Sizes itself to whatever height its mosaic slot gives it — short
/// slots drop the subtitle and shrink the glyph instead of overflowing.
///
/// Resting state carries a hairline of the tone's border; selection lights
/// that hairline up and sends an accent-colored comet around it, plus a
/// check chip in the top-right corner. [dimmed] softly recedes the
/// non-chosen siblings.
class BentoCategoryCard extends StatefulWidget {
  const BentoCategoryCard({
    super.key,
    required this.tone,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.selected = false,
    this.dimmed = false,
    this.hero = false,
  });

  final BentoTone tone;
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
    final tone = widget.tone;
    // Chip ground: the accent barely mixed into the surface, so each card's
    // check sits in its own family instead of a foreign gray.
    final chipBg = Color.alphaBlend(
      tone.accent.withValues(alpha: 0.18),
      tone.surface,
    );
    return AnimatedOpacity(
      opacity: widget.dimmed ? 0.82 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: tone.surface,
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
                            color: BentoPalette.cardText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          widget.icon,
                          color: tone.accent,
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
                            style: const TextStyle(
                              color: BentoPalette.cardTextMuted,
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
              // Resting hairline — just enough edge to separate the charcoal
              // card from the black page without competing with selection.
              if (!widget.selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: tone.border.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.selected) ...[
                // Accent ring with a comet sweep: a bright highlight (with
                // fading tail) travels the border; the rest of the ring
                // stays a dim steady accent. Painter, not BoxShadow — the
                // glow must hug the stroke, never haze the card face.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) => CustomPaint(
                          painter: _CometRingPainter(
                            t: _pulse.value,
                            track: tone.border,
                            comet: tone.accent,
                          ),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: chipBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: BentoPalette.cardText,
                    ),
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

/// Accent selection ring with a traveling comet: a dim steady [track] ring,
/// and a bright [comet] highlight with a fading tail that laps the border
/// once per [t] cycle (sweep-gradient stroke rotated by t). The comet also
/// carries a blurred halo so the moving light glows along the stroke only.
class _CometRingPainter extends CustomPainter {
  const _CometRingPainter({
    required this.t,
    required this.track,
    required this.comet,
  });

  /// Lap progress, 0..1 → one full trip around the border.
  final double t;
  final Color track;
  final Color comet;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(23));

    // Dim steady track.
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = track;
    canvas.drawRRect(rrect, base);

    // Comet: tail brightens toward the head, then cuts off.
    final sweep = SweepGradient(
      colors: [
        comet.withValues(alpha: 0),
        comet.withValues(alpha: 0),
        comet.withValues(alpha: 0.45),
        comet,
        comet.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.62, 0.86, 0.97, 0.98],
      transform: GradientRotation(2 * math.pi * t),
    ).createShader(rect);

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = sweep
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, halo);

    final head = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = sweep;
    canvas.drawRRect(rrect, head);
  }

  @override
  bool shouldRepaint(_CometRingPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.track != track ||
      oldDelegate.comet != comet;
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
