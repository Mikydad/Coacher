import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/theme_brightness_controller.dart';

/// Appearance bottom sheet (Profile reorg 2026-08-23): Obsidian Pulse dark
/// or light, replacing the old blind row-tap toggle.
Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.inkWarm,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends ConsumerWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(themeBrightnessProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.textSoft,
              ),
            ),
            const SizedBox(height: 16),
            _ModeOption(
              icon: Icons.dark_mode_outlined,
              title: 'Dark',
              subtitle: 'Obsidian Pulse',
              selected: brightness == Brightness.dark,
              onTap: () => _pick(context, ref, Brightness.dark),
            ),
            const SizedBox(height: 10),
            _ModeOption(
              icon: Icons.light_mode_outlined,
              title: 'Light',
              subtitle: 'Obsidian Pulse Light',
              selected: brightness == Brightness.light,
              onTap: () => _pick(context, ref, Brightness.light),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    Brightness value,
  ) async {
    await ref.read(themeBrightnessProvider.notifier).set(value);
    if (context.mounted) Navigator.pop(context);
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accentBright.withValues(alpha: 0.08)
          : AppColors.inkDeep,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.accentDim.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.limeCream : AppColors.textSoft,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.limeCream : AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: AppColors.textSoft),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.limeCream,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
