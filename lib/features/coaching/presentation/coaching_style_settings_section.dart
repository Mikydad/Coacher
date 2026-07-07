import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/coaching_style_providers.dart';
import '../domain/models/coaching_style.dart';
import 'coaching_style_selection_screen.dart';
import '../../../core/presentation/app_colors.dart';

/// Settings section widget that shows the user's current [CoachingStyle] and
/// provides a tap-to-change action. Embed directly in the settings screen.
class CoachingStyleSettingsSection extends ConsumerWidget {
  const CoachingStyleSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(activeCoachingStyleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COACHING STYLE',
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 11,
            color: AppColors.fg54,
          ),
        ),
        const SizedBox(height: 8),
        _StyleTile(style: style, onTap: () => _openSelector(context)),
      ],
    );
  }

  void _openSelector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CoachingStyleSelectionScreen(),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({required this.style, required this.onTap});

  final CoachingStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fg.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fg12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    style.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    style.description,
                    style: TextStyle(fontSize: 12, color: AppColors.fg54),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.fg38, size: 20),
          ],
        ),
      ),
    );
  }
}
