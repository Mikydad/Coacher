import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/context_providers.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/runtime/recompute_scope.dart';
import '../../../core/runtime/unified_recompute_graph.dart';

/// The one-time just-in-time calendar ask (humanizing Phase 4b, PRD §9):
/// shows under the Promises strip once the user holds an open promise —
/// the first moment calendar access has a nameable benefit. "Not now" is
/// remembered forever (Profile toggle can re-enable); the card never
/// returns either way.
final calendarAskVisibleProvider = FutureProvider<bool>(
  (ref) => ref.watch(calendarSignalServiceProvider).shouldOfferAsk(),
);

class CalendarAskCard extends ConsumerWidget {
  const CalendarAskCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(calendarAskVisibleProvider).valueOrNull ?? false;
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
              Icon(Icons.calendar_month_rounded,
                  size: 16, color: AppColors.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan around your calendar?',
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
            'SidePal can time your promises around your real meetings — '
            'read-only, never stored, never leaves this device.',
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
                child: const Text('Use my calendar'),
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
    final granted = await ref.read(calendarSignalServiceProvider).enable();
    ref.invalidate(calendarAskVisibleProvider);
    ref.invalidate(calendarSignalChoiceProvider);
    if (granted) {
      // Replan promises with the new signal.
      UnifiedRecomputeGraph.instance.schedule(
        RecomputeScope.forReminderChange(),
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? "Calendar on — I'll plan around your meetings."
              : 'Calendar access is off. You can grant it in iOS Settings, '
                    'then flip the switch in Profile.',
        ),
        backgroundColor: AppColors.inkCard,
      ),
    );
  }

  void _decline(WidgetRef ref) {
    ref.read(calendarSignalServiceProvider).decline();
    ref.invalidate(calendarAskVisibleProvider);
    ref.invalidate(calendarSignalChoiceProvider);
  }
}
