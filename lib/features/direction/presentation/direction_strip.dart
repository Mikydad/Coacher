import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/direction_providers.dart';
import '../domain/direction_context_lines.dart';
import '../domain/direction_periods.dart';
import 'direction_screen.dart';

/// The Goals-tab strip (decision 6 + OQ-1): ONE quiet line, no card, no
/// background. `This month: Launch SidePal` once set; `Set your direction →`
/// until then — the feature's only discovery surface besides the Profile
/// row, and deliberately not a card, not a notification, not an
/// explanation. Tapping opens the Direction page.
class DirectionStrip extends ConsumerWidget {
  const DirectionStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(currentDirectionProvider);
    final slot = mostSpecificDirectionSlot(slots);
    final String text;
    if (slot == null) {
      text = 'Set your direction →';
    } else {
      final phrase = switch (slot.period.horizon) {
        DirectionHorizon.year => 'This year',
        DirectionHorizon.quarter => 'This quarter',
        DirectionHorizon.month => 'This month',
      };
      text = '$phrase: ${slot.text}';
    }

    return InkWell(
      key: const ValueKey('direction_strip'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pushNamed(context, DirectionScreen.routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
