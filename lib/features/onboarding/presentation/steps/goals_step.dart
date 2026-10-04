import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../../domain/models/onboarding_profile.dart';
import '../onboarding_ui.dart';

/// Screen 3 — What matters to you right now. Multi-select interests, stored
/// as tags (never auto-created goals — decision log 2026-07-12); the
/// first-goal picker after sign-in is where one becomes real (2026-09-25).
class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _options = [
    (OnboardingInterests.buildBusiness, Icons.rocket_launch_outlined),
    (OnboardingInterests.improveHealth, Icons.favorite_outline),
    (OnboardingInterests.learnSkills, Icons.menu_book_outlined),
    (OnboardingInterests.getOrganized, Icons.grid_view_outlined),
    (OnboardingInterests.makeMoney, Icons.payments_outlined),
    (OnboardingInterests.betterHabits, Icons.refresh),
    (OnboardingInterests.moreDisciplined, Icons.shield_outlined),
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
      onCta: flow.interests.isEmpty ? null : controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What matters most to you right now?',
            style: OnboardingType.headline,
          ),
          const SizedBox(height: 10),
          Text('Choose as many as you like.', style: OnboardingType.body),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: _options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final (key, icon) = _options[i];
                return OnboardingSelectableCard(
                  title: OnboardingInterests.label(key),
                  icon: icon,
                  selected: flow.interests.contains(key),
                  onTap: () => controller.toggleInterest(key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
