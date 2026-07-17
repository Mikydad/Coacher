import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/presentation/app_colors.dart';

/// Translucent “watermark” footer shared across main tabs.
class ObsidianBottomNav extends StatelessWidget {
  const ObsidianBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.track_changes_rounded, label: 'Goals'),
    (icon: Icons.handshake_rounded, label: 'Accountability'),
    (icon: Icons.group_rounded, label: 'Community'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  static Color get _kSurface => AppColors.ink;
  static Color get _kVariant => AppColors.textSoft;
  static Color get _kActive => AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottomPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kSurface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.fg.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final selected = i == selectedIndex;
                  final color = selected ? _kActive : _kVariant;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 22, color: color),
                          const SizedBox(height: 3),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.label,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1,
                                  letterSpacing: 0.1,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
