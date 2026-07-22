import 'package:flutter/material.dart';

import '../../core/presentation/app_colors.dart';

/// Text-only animated launch splash shown over the app while it boots.
///
/// Sequence (~3.4s, finite — never loops, so tests can settle):
///  1. The letters of "SidePal" rise and fade in one by one ("Path" in the
///     foreground ink, "Pal" in the brand accent).
///  2. A lime underline sweeps across beneath the wordmark.
///  3. The tagline fades up, holds for ~1.5s, then the overlay fades out
///     and hands over to the app (which has been building behind it).
///
/// Sits ABOVE MaterialApp, so it provides its own [Directionality]. Uses
/// [AppColors], matching the persisted dark/light mode (loaded pre-frame).
class AnimatedSplashGate extends StatefulWidget {
  const AnimatedSplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedSplashGate> createState() => _AnimatedSplashGateState();
}

class _AnimatedSplashGateState extends State<AnimatedSplashGate>
    with SingleTickerProviderStateMixin {
  static const String _word = 'SidePal';
  static const int _accentFrom = 4; // "Pal" gets the accent color.

  late final AnimationController _c;
  bool _done = false;

  late final List<Animation<double>> _letters;
  late final Animation<double> _underline;
  late final Animation<double> _tagline;
  late final Animation<double> _overlayFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    // Staggered letter entrances across the first ~45% of the timeline.
    _letters = List.generate(_word.length, (i) {
      final start = 0.03 + i * 0.033;
      return CurvedAnimation(
        parent: _c,
        curve: Interval(start, start + 0.10, curve: Curves.easeOutCubic),
      );
    });
    _underline = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 0.42, curve: Curves.easeOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.38, 0.52, curve: Curves.easeOut),
    );
    _overlayFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
    );

    _c.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    // This gate sits ABOVE MaterialApp, so nothing has provided text
    // direction yet — Stack/Text require an explicit Directionality here.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return IgnorePointer(
                child: Opacity(
                  opacity: 1.0 - _overlayFade.value,
                  child: Container(
                    color: AppColors.scaffold,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Wordmark: staggered letters.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            for (var i = 0; i < _word.length; i++)
                              Opacity(
                                opacity: _letters[i].value,
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    22 * (1 - _letters[i].value),
                                  ),
                                  child: Text(
                                    _word[i],
                                    style: TextStyle(
                                      color: i >= _accentFrom
                                          ? AppColors.accent
                                          : AppColors.fg,
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.0,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Lime underline sweeps out from the center.
                        Container(
                          height: 4,
                          width: 148 * _underline.value,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tagline rises in last.
                        Opacity(
                          opacity: _tagline.value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - _tagline.value)),
                            child: Text(
                              'YOUR PATH. YOUR PACE.',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
