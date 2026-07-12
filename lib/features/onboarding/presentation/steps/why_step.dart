import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 3 — Why This Happens.
class WhyStep extends ConsumerWidget {
  const WhyStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: onSkip,
      ctaLabel: 'Continue',
      onCta: controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your brain isn\'t working against you.',
              style: OnboardingType.headline),
          const SizedBox(height: 14),
          Text(
            'We are biologically wired to seek immediate rewards — an '
            'ancient survival mechanism that conflicts with today\'s '
            'long-term goals.\n\nThat doesn\'t mean you\'re lazy. It means '
            'your brain naturally chooses comfort over difficult work. '
            'Understanding this is the first step toward lasting change.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 20),
          const Expanded(child: _RewardComparisonVisual()),
        ],
      ),
    );
  }
}

/// Minimal Instant Reward → Long-Term Success comparison (very little text,
/// focus on clarity — PRD).
class _RewardComparisonVisual extends StatelessWidget {
  const _RewardComparisonVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: OnboardingColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: OnboardingColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RewardRow(
              icon: Icons.bolt,
              label: 'Instant Reward',
              color: OnboardingColors.textMuted,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Icon(
                Icons.south,
                size: 20,
                color: OnboardingColors.textFaint,
              ),
            ),
            _RewardRow(
              icon: Icons.emoji_events_outlined,
              label: 'Long-Term Success',
              color: OnboardingColors.pathway,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: OnboardingType.cardTitle.copyWith(color: color, fontSize: 17),
        ),
      ],
    );
  }
}
