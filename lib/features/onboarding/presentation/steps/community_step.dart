import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 5 — Community.
class CommunityStep extends ConsumerWidget {
  const CommunityStep({super.key, required this.onSkip});

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
          const Expanded(
            child: OnboardingIllustration(icon: Icons.diversity_3_outlined),
          ),
          const SizedBox(height: 28),
          Text('Success is easier together.', style: OnboardingType.headline),
          const SizedBox(height: 12),
          Text(
            'We\'ll connect you with people pursuing similar goals so you '
            'can motivate one another, stay accountable, and grow together.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
