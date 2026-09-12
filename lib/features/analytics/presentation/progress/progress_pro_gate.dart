import 'dart:ui';

import 'package:flutter/material.dart';

import 'progress_design_tokens.dart';

/// Pro gate for Progress history (Week and beyond; decision 2026-09-12).
/// The real content renders underneath a blur so the page keeps its shape,
/// taps are absorbed, and one pill offers the upgrade. Pure widget: the
/// caller decides [blocked] from `TierGate.canViewProgressHistory`.
class ProgressProGate extends StatelessWidget {
  const ProgressProGate({
    super.key,
    required this.blocked,
    required this.onUnlock,
    required this.child,
  });

  final bool blocked;
  final VoidCallback onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!blocked) return child;
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: AbsorbPointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ProgressDesignTokens.cardRadius,
              ),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Opacity(opacity: 0.7, child: child),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ProgressDesignTokens.surface.withValues(alpha: 0.0),
                  ProgressDesignTokens.surface.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Unlock Progress',
          child: Material(
            color: ProgressDesignTokens.primaryContainer,
            shape: const StadiumBorder(),
            elevation: 6,
            shadowColor: ProgressDesignTokens.primaryDim.withValues(alpha: 0.4),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onUnlock,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_open_rounded,
                      size: 20,
                      color: ProgressDesignTokens.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Unlock Progress',
                      style: TextStyle(
                        color: ProgressDesignTokens.onPrimaryContainer,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
