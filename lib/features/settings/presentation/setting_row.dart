import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';

/// One settings row — icon + title + subtitle + trailing — shared by the
/// Profile hub list and the settings sub-pages so the two can't drift
/// (extracted from profile_screen's private `_SettingRow`, 2026-08-23).
/// Stack rows inside a `ClipRRect(borderRadius: 16)` to get the card look.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inkDeep,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.limeCream.withValues(alpha: 0.05),
        splashColor: AppColors.limeCream.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSoft, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: AppColors.textSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// The default trailing chevron for navigation rows.
class SettingRowChevron extends StatelessWidget {
  const SettingRowChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textSoft,
      size: 20,
    );
  }
}
