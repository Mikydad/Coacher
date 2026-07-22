import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/presentation/app_colors.dart';

/// Translucent “watermark” footer shared across main tabs.
class ObsidianBottomNav extends StatelessWidget {
  const ObsidianBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCounts = const <int, int>{},
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// tab index → needs-action count; > 0 renders a count bubble on the
  /// tab's icon (e.g. pending challenge invites on Accountability).
  final Map<int, int> badgeCounts;

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
                  final badge = badgeCounts[i] ?? 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BadgedIcon(
                            icon: item.icon,
                            color: color,
                            count: badge,
                          ),
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

/// Tab icon with an optional needs-action count bubble, top-right.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 22, color: color);
    if (count <= 0) return iconWidget;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -7,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 14),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.fg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
