import 'dart:ui';

import 'package:flutter/material.dart';

import '../presentation/app_colors.dart';

/// Shared Pro lock for a section: the real content renders underneath a
/// blur so the page keeps its shape, taps are absorbed, and one pill offers
/// the upgrade. Pure widget — the caller decides [blocked] from a
/// `TierGate` getter. Used by Progress history and Time insights so every
/// locked surface looks the same.
class ProLocked extends StatelessWidget {
  const ProLocked({
    super.key,
    required this.blocked,
    required this.label,
    required this.onUnlock,
    required this.child,
  });

  final bool blocked;

  /// Pill text, e.g. "Unlock Progress".
  final String label;
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
              borderRadius: BorderRadius.circular(16),
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
                  AppColors.ink.withValues(alpha: 0.0),
                  AppColors.ink.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: label,
          child: Material(
            color: AppColors.accentBright,
            shape: const StadiumBorder(),
            elevation: 6,
            shadowColor: AppColors.accentDim.withValues(alpha: 0.4),
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
                      color: AppColors.accentDeep,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.accentDeep,
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
