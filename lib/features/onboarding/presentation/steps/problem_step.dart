import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 7 — The Problem.
class ProblemStep extends ConsumerWidget {
  const ProblemStep({super.key, required this.onSkip});

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
            child: OnboardingIllustration(
              icon: Icons.notifications_paused_outlined,
            ),
          ),
          const SizedBox(height: 28),
          Text('You\'re not lazy.', style: OnboardingType.headline),
          const SizedBox(height: 12),
          Text(
            'Most people don\'t fail because they lack ambition. They fail '
            'because they forget, lose momentum, become distracted, and '
            'have nobody keeping them accountable.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
