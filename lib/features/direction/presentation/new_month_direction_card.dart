import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_colors.dart';
import '../application/direction_providers.dart';
import '../application/new_month_prompt.dart';
import '../domain/direction_periods.dart';
import 'direction_screen.dart';

/// Home's month-rollover card (decision 7 + OQ-3):
///
/// ```
/// A NEW MONTH
/// What's your focus for September?
/// + Add your direction                      ×
/// ```
///
/// Tapping the body or the CTA opens the Direction page (which shows last
/// month's text as a suggestion); × dismisses. Either way the month is
/// marked handled and the card never returns until the next rollover.
/// Renders nothing otherwise — silence is the normal state.
class NewMonthDirectionCard extends ConsumerWidget {
  const NewMonthDirectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(showNewMonthDirectionCardProvider);
    final now = ref.watch(directionClockProvider);
    final month = DirectionPeriods.current(DirectionHorizon.month, now);

    // The month got a direction by any path (page, Keep, another device):
    // record it so a later clear this month doesn't resurrect the card.
    ref.listen(currentDirectionProvider, (_, slots) {
      final slot = slots[DirectionHorizon.month];
      if (slot != null && slot.hasText) {
        ref
            .read(newMonthPromptControllerProvider.notifier)
            .markHandled(slot.period.key);
      }
    });

    if (!show) return const SizedBox.shrink();

    Future<void> handle() => ref
        .read(newMonthPromptControllerProvider.notifier)
        .markHandled(month.key);

    return AppCard(
      key: const ValueKey('new_month_direction_card'),
      margin: const EdgeInsets.only(bottom: 12),
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      clipBehavior: Clip.antiAlias,
      onTap: () {
        handle();
        Navigator.pushNamed(context, DirectionScreen.routeName);
      },
      child: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A NEW MONTH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppColors.textSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "What's your focus for ${month.label}?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextButton(
                      key: const ValueKey('new_month_direction_cta'),
                      onPressed: () {
                        handle();
                        Navigator.pushNamed(context, DirectionScreen.routeName);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '+ Add your direction',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('new_month_direction_dismiss'),
                tooltip: 'Dismiss',
                icon: Icon(Icons.close, size: 18, color: AppColors.textSoft),
                onPressed: handle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
