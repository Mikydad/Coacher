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
class BentoCategoryCard extends StatelessWidget {
  const BentoCategoryCard({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.selected = false,
    this.hero = false,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;

  /// The full-width top card: bigger glyph, roomier text.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? Border.all(color: BentoPalette.ink, width: 2.5)
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 96;
              return Padding(
                padding: EdgeInsets.all(compact ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BentoPalette.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: BentoPalette.ink.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: BentoPalette.ink,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      icon,
                      color: BentoPalette.ink,
                      size: hero
                          ? 38
                          : compact
                          ? 18
                          : 26,
                    ),
                    if (subtitle != null && !compact) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: hero ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: BentoPalette.ink.withValues(alpha: 0.72),
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
        ),
      ),
    );
  }
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
