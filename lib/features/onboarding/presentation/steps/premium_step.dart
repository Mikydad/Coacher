import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 13 — Premium SidePal. UI ONLY for now: no purchase infrastructure
/// exists yet, so both CTAs advance the flow (decision log 2026-07-12).
/// Sells outcomes, not features (PRD).
class PremiumStep extends ConsumerWidget {
  const PremiumStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _outcomes = [
    (Icons.notifications_active_outlined, 'Never forget important work'),
    (Icons.groups_outlined, 'Stay accountable'),
    (Icons.auto_awesome, 'Personal AI planning'),
    (Icons.center_focus_strong_outlined, 'Focus assistance'),
    (Icons.diversity_3_outlined, 'Supportive community'),
    (Icons.all_inclusive, 'Unlimited coaching'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: onSkip,
      ctaLabel: 'Start Free Trial',
      onCta: controller.next,
      belowCta: Center(
        child: TextButton(
          onPressed: controller.next,
          child: Text(
            'Maybe Later',
            style: TextStyle(
              color: OnboardingColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: OnboardingColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'PREMIUM',
                style: OnboardingType.label.copyWith(
                  color: OnboardingColors.primarySoft,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Unlock your full potential.',
            textAlign: TextAlign.center,
            style: OnboardingType.headline,
          ),
          const SizedBox(height: 10),
          Text(
            'Shift from tracking tasks to achieving transformation.',
            textAlign: TextAlign.center,
            style: OnboardingType.body,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                for (final (icon, label) in _outcomes)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: OnboardingColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OnboardingColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 17,
                          color: OnboardingColors.primarySoft,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: OnboardingType.cardBody.copyWith(
                              color: OnboardingColors.textSecondary,
                              fontSize: 12.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '7-day free trial · Cancel anytime',
            textAlign: TextAlign.center,
            style: OnboardingType.cardBody,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
