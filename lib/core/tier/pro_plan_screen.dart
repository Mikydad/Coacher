import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/app_colors.dart';
import '../presentation/page_headers.dart';
import 'tier_limits.dart';
import 'tier_providers.dart';

/// The Pro plan page every limit prompt links to (PRD monetization §8).
///
/// Step 1 of the subscription build: the comparison and prices, with the
/// purchase button inert until RevenueCat ships (step 3 swaps
/// [_PurchaseButton] for store offerings with localized prices). Every
/// Free number reads from the live [TierLimits], so a console edit updates
/// this page too.
class ProPlanScreen extends ConsumerWidget {
  const ProPlanScreen({super.key});

  static const routeName = '/pro';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(tierLimitsProvider);
    final rows = proPlanRows(limits);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const PageTitle('SidePal Pro'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const SectionHeader(
            'Everything, without limits',
            hero: true,
            subtitle:
                'Free covers the core loop. Pro removes every cap and adds '
                'the insights.',
          ),
          const SizedBox(height: 24),
          const _ColumnLabels(),
          const SizedBox(height: 6),
          for (final row in rows) _PlanRow(row: row),
          const SizedBox(height: 28),
          const _PriceLine(),
          const SizedBox(height: 16),
          const _PurchaseButton(),
        ],
      ),
    );
  }
}

/// One comparison line: feature, what Free gets, what Pro gets.
class ProPlanRow {
  const ProPlanRow(this.feature, this.free, this.pro);

  final String feature;
  final String free;
  final String pro;
}

/// The comparison, built from live limits. Public for tests.
List<ProPlanRow> proPlanRows(TierLimits l) {
  String cap(int n, String unit) => n < 0 ? 'Unlimited' : '$n $unit';
  return [
    ProPlanRow('Tasks', cap(l.freeTasksPerDay, 'a day'), 'Unlimited'),
    ProPlanRow('Habits', cap(l.freeHabitAnchorsPerDay, 'a day'), 'Unlimited'),
    ProPlanRow('Goals', cap(l.freeGoals, 'active'), 'Unlimited'),
    ProPlanRow('Reminders', cap(l.freeReminders, 'active'), 'Unlimited'),
    ProPlanRow('Promises', cap(l.freePromisesPerWeek, 'a week'), 'Unlimited'),
    ProPlanRow(
      'Coach actions',
      cap(l.freeAiInstructionsPerDay, 'a day'),
      'Unlimited',
    ),
    ProPlanRow('Stakes', cap(l.freeStakesPerMonth, 'a month'), 'Unlimited'),
    const ProPlanRow('Money challenges', '—', 'Included'),
    ProPlanRow(
      'Groups',
      l.freeCircles < 0 ? 'Unlimited' : '${l.freeCircles}',
      l.proCircles < 0 ? 'Unlimited' : '${l.proCircles}',
    ),
    const ProPlanRow('Time logging', 'Unlimited', 'Unlimited'),
    const ProPlanRow('Time insights + export', '—', 'Included'),
    const ProPlanRow('Progress history', 'Today', 'Week to year'),
  ];
}

class _ColumnLabels extends StatelessWidget {
  const _ColumnLabels();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );
    return Row(
      children: [
        const Expanded(flex: 5, child: SizedBox()),
        Expanded(flex: 3, child: Text('FREE', style: style)),
        Expanded(
          flex: 3,
          child: Text('PRO', style: style.copyWith(color: AppColors.accent)),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.row});

  final ProPlanRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              row.feature,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.free,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.pro,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      '7 days free, then \$9.99 a month or \$79.99 a year.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton();

  @override
  Widget build(BuildContext context) {
    // Inert until the store integration (step 2) and paywall (step 3).
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: const ValueKey('pro_plan_purchase'),
        onPressed: null,
        child: const Text('Coming soon'),
      ),
    );
  }
}
