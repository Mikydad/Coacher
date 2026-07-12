import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../../domain/models/onboarding_profile.dart';
import '../onboarding_ui.dart';

/// Screen 10 — Choose Your Goals. Multi-select goal CATEGORIES, stored as
/// interest tags (never auto-created goals — decision log 2026-07-12).
class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _options = [
    (OnboardingInterests.buildBusiness, Icons.rocket_launch_outlined,
        'Build a business'),
    (OnboardingInterests.improveHealth, Icons.favorite_outline,
        'Improve my health'),
    (OnboardingInterests.learnSkills, Icons.menu_book_outlined,
        'Learn new skills'),
    (OnboardingInterests.getOrganized, Icons.grid_view_outlined,
        'Get organized'),
    (OnboardingInterests.makeMoney, Icons.payments_outlined,
        'Make more money'),
    (OnboardingInterests.betterHabits, Icons.refresh,
        'Build better habits'),
    (OnboardingInterests.moreDisciplined, Icons.shield_outlined,
        'Become more disciplined'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: onSkip,
      ctaLabel: 'Start Building',
      onCta: flow.interests.isEmpty ? null : controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What\'s your biggest goal?', style: OnboardingType.headline),
          const SizedBox(height: 10),
          Text(
            'What do you want to achieve first? Pick as many as you like.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: _options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final (key, icon, title) = _options[i];
                return OnboardingSelectableCard(
                  title: title,
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
