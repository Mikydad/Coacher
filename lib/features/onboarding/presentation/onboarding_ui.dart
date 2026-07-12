import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';

/// Visual tokens for the first-launch onboarding flow ("Ethereal Path",
/// PRD/Onboarding/DESIGN.md), mapped onto the existing dark palette.
///
/// Aliases [AppPalette.dark] DIRECTLY (not [AppColors]) on purpose: the flow
/// is dark-only regardless of the device/theme mode, and it renders before
/// the user has ever seen a theme toggle. Everything else follows the
/// feature-palette rule — no raw hex in widgets.
abstract final class OnboardingColors {
  static const AppPalette _dark = AppPalette.dark;

  /// Deep charcoal base — "infinite background".
  static Color get background => _dark.dark0F0F1A;

  /// Level-1 cards.
  static Color get card => _dark.dark1F2026;

  /// Nested / elevated elements inside cards.
  static Color get cardHigh => _dark.dark2A2D32;

  /// 1px "machined" borders on cards.
  static Color get border => _dark.whiteBorder8;

  /// Indigo-violet — the AI's "consciousness"; gradient start.
  static Color get primary => _dark.violet;

  /// Lavender-blue — gradient end / soft highlights.
  static Color get primarySoft => _dark.periwinkle;

  /// Cyan — success states and "pathway" indicators.
  static Color get pathway => _dark.cyan;

  static Color get textPrimary => _dark.fg;
  static Color get textSecondary => _dark.fg70;
  static Color get textMuted => _dark.fg54;
  static Color get textFaint => _dark.fg38;

  /// Soft outer glow behind the primary CTA (10% of primary per DESIGN.md).
  static Color get ctaGlow => _dark.violet.withValues(alpha: 0.28);

  /// The signature "Aether Gradient" — always bottom-left → top-right.
  static LinearGradient get aetherGradient => LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [primary, primarySoft],
  );
}

/// Shared type ramp (system font; Inter-adjacent metrics from DESIGN.md).
abstract final class OnboardingType {
  static TextStyle get headline => TextStyle(
    color: OnboardingColors.textPrimary,
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static TextStyle get headlineLarge => TextStyle(
    color: OnboardingColors.textPrimary,
    fontSize: 36,
    height: 42 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );

  static TextStyle get body => TextStyle(
    color: OnboardingColors.textSecondary,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get cardTitle => TextStyle(
    color: OnboardingColors.textPrimary,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get cardBody => TextStyle(
    color: OnboardingColors.textMuted,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get label => TextStyle(
    color: OnboardingColors.textMuted,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.65,
  );
}

/// Primary pill CTA with the Aether gradient and a soft glow.
class AetherButton extends StatefulWidget {
  const AetherButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<AetherButton> createState() => _AetherButtonState();
}

class _AetherButtonState extends State<AetherButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    return AnimatedScale(
      // Tactile 98% press-down per DESIGN.md.
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: enabled ? widget.onPressed : null,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enabled
                ? OnboardingColors.aetherGradient
                : LinearGradient(
                    colors: [
                      OnboardingColors.cardHigh,
                      OnboardingColors.cardHigh,
                    ],
                  ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: OnboardingColors.ctaGlow,
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: OnboardingColors.textPrimary,
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: enabled
                        ? OnboardingColors.textPrimary
                        : OnboardingColors.textFaint,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

/// "Journey Line" progress — a thin 2px track with a glowing dot at the head
/// (DESIGN.md Path Indicators). One consistent indicator for the whole flow.
class JourneyProgressLine extends StatelessWidget {
  const JourneyProgressLine({super.key, required this.progress});

  /// 0..1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final headX = (width - 10) * progress.clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: OnboardingColors.cardHigh,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: 2,
                width: headX + 5,
                decoration: BoxDecoration(
                  gradient: OnboardingColors.aetherGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: headX,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: OnboardingColors.primarySoft,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: OnboardingColors.ctaGlow,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Standard step layout: top bar (back + journey line), flexible content,
/// then a fixed CTA area with the flow-level Skip underneath.
///
/// Content must fit the viewport (no-scroll rule): put the illustration in a
/// [Flexible]/[Expanded] inside [content] so artwork absorbs size pressure,
/// never the copy or the CTA.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.progress,
    required this.content,
    this.ctaLabel,
    this.onCta,
    this.ctaLoading = false,
    this.onBack,
    this.onSkip,
    this.belowCta,
  });

  final double progress;
  final Widget content;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool ctaLoading;
  final VoidCallback? onBack;

  /// Flow-level skip — straight to the anonymous account. Null hides it
  /// (celebration step).
  final VoidCallback? onSkip;

  /// Optional secondary line between CTA and Skip (e.g. "Maybe Later").
  final Widget? belowCta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onBack != null)
                    _QuietIconButton(icon: Icons.arrow_back, onTap: onBack!)
                  else
                    const SizedBox(width: 40),
                  const SizedBox(width: 12),
                  Expanded(child: JourneyProgressLine(progress: progress)),
                  const SizedBox(width: 52),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: content),
              const SizedBox(height: 16),
              if (ctaLabel != null)
                AetherButton(
                  label: ctaLabel!,
                  onPressed: onCta,
                  isLoading: ctaLoading,
                ),
              if (belowCta != null) ...[const SizedBox(height: 4), belowCta!],
              SizedBox(
                height: 44,
                child: onSkip == null
                    ? null
                    : Center(
                        child: TextButton(
                          onPressed: onSkip,
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: OnboardingColors.textFaint,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietIconButton extends StatelessWidget {
  const _QuietIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: OnboardingColors.textSecondary, size: 22),
      ),
    );
  }
}

/// Ultra-rounded selectable card for the struggle / goal-category grids.
/// Animates border + wash on selection and scales down on press.
class OnboardingSelectableCard extends StatefulWidget {
  const OnboardingSelectableCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<OnboardingSelectableCard> createState() =>
      _OnboardingSelectableCardState();
}

class _OnboardingSelectableCardState extends State<OnboardingSelectableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    OnboardingColors.primary.withValues(alpha: 0.14),
                    OnboardingColors.card,
                  )
                : OnboardingColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? OnboardingColors.primarySoft
                  : OnboardingColors.border,
            ),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: OnboardingColors.cardHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: selected
                        ? OnboardingColors.primarySoft
                        : OnboardingColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: OnboardingType.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: OnboardingType.cardBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: OnboardingColors.primarySoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient placeholder illustration area — swapped for exported artwork
/// later. Renders a soft radial Aether wash with a themed icon.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.icon,
    this.borderRadius = 32,
  });

  final IconData icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: OnboardingColors.border),
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.1,
                colors: [
                  OnboardingColors.primary.withValues(alpha: 0.32),
                  OnboardingColors.background,
                ],
              ),
            ),
            child: Icon(
              icon,
              size: (side * 0.3).clamp(40.0, 96.0),
              color: OnboardingColors.primarySoft.withValues(alpha: 0.9),
            ),
          ),
        );
      },
    );
  }
}
