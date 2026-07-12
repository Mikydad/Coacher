import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 9 — Science & Proof. Condensed to three research cards so the
/// screen fits the viewport (no-scroll rule).
class ScienceStep extends ConsumerWidget {
  const ScienceStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _cards = [
    (
      Icons.groups_outlined,
      'Accountability works',
      'Sharing goals with someone dramatically increases follow-through.',
    ),
    (
      Icons.nightlight_outlined,
      'Plan tomorrow, tonight',
      'Planning the next day in advance improves task completion.',
    ),
    (
      Icons.trending_up,
      'Small actions compound',
      'Tiny daily steps compound into long-term success.',
    ),
  ];

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
          Text('Science supports consistency.', style: OnboardingType.headline),
          const SizedBox(height: 10),
          Text(
            'You\'re not betting on willpower — you\'re building a system '
            'that research backs.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (icon, title, body) in _cards) ...[
                  _ResearchCard(icon: icon, title: title, body: body),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResearchCard extends StatelessWidget {
  const _ResearchCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OnboardingColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OnboardingColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OnboardingColors.cardHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: OnboardingColors.pathway),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OnboardingType.cardTitle),
                const SizedBox(height: 3),
                Text(body, style: OnboardingType.cardBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
