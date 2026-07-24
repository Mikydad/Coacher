import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/calendar_signal.dart';
import '../../../core/context/context_providers.dart';
import '../../../core/presentation/app_colors.dart';
import '../application/intentions_providers.dart';

/// The one-time just-in-time motion ask (humanizing Phase 6a, PRD §9
/// Tier 2): shows under the Promises strip once the user holds an open
/// CALL-shaped promise — the first moment motion access has a nameable
/// benefit ("catch you walking"). Progressive permissions (settled Q6):
/// it never appears while the calendar ask is still undecided, so two
/// permission cards can never stack. "Not now" is remembered forever
/// (Profile toggle can re-enable); the card never returns either way.
final activityAskVisibleProvider = FutureProvider<bool>((ref) async {
  // Calendar first: one ask at a time, in ladder order.
  final calendarChoice =
      await ref.watch(calendarSignalServiceProvider).getChoice();
  if (calendarChoice == CalendarSignalChoice.undecided) return false;
  return ref.watch(activitySignalServiceProvider).shouldOfferAsk();
});

class ActivityAskCard extends ConsumerWidget {
  const ActivityAskCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(activityAskVisibleProvider).valueOrNull ?? false;
    if (!visible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyanBorder20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk_rounded,
                  size: 16, color: AppColors.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catch you at the right moment?',
                  style: TextStyle(
                    color: AppColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'SidePal can notice when you\u2019re walking — a good moment '
            'for a call. Checked only when timing a suggestion; never '
            'stored, never leaves this device.',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => _enable(context, ref),
                child: const Text('Use motion'),
              ),
              TextButton(
                onPressed: () => _decline(ref),
                child: Text(
                  'Not now',
                  style: TextStyle(color: AppColors.textSoft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final granted = await ref.read(activitySignalServiceProvider).enable();
    ref.invalidate(activityAskVisibleProvider);
    ref.invalidate(activitySignalChoiceProvider);
    // Activity is a decision-time signal — refresh the seize card, no
    // replan needed (future slots don't depend on current motion).
    ref.invalidate(seizeTheMomentProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? "Motion on — I'll suggest calls when you're walking."
              : 'Motion access is off. You can grant it in iOS Settings '
                    '(Motion & Fitness), then flip the switch in Profile.',
        ),
        backgroundColor: AppColors.inkCard,
      ),
    );
  }

  void _decline(WidgetRef ref) {
    ref.read(activitySignalServiceProvider).decline();
    ref.invalidate(activityAskVisibleProvider);
    ref.invalidate(activitySignalChoiceProvider);
  }
}
