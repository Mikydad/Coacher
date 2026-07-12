import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../../domain/models/onboarding_profile.dart';
import '../onboarding_ui.dart';

/// Screen 2 — What Sounds Like You? Multi-select; list may scroll (the one
/// agreed exception to the no-scroll rule, selection screens only).
class StrugglesStep extends ConsumerWidget {
  const StrugglesStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _options = [
    (
      OnboardingStruggles.forgetting,
      'Forgetting things',
      'Losing track of tasks or appointments easily.',
    ),
    (
      OnboardingStruggles.planningNoAction,
      'Planning but never taking action',
      'Stuck in the \'prep\' phase indefinitely.',
    ),
    (
      OnboardingStruggles.procrastination,
      'Procrastination',
      'Waiting until the last possible second to start.',
    ),
    (
      OnboardingStruggles.difficultyFocusing,
      'Difficulty focusing',
      'Finding it hard to stay on a single task.',
    ),
    (
      OnboardingStruggles.gettingDistracted,
      'Getting distracted',
      'Phone or surroundings constantly pull you away.',
    ),
    (
      OnboardingStruggles.losingMotivation,
      'Losing motivation',
      'Excitement fades shortly after starting.',
    ),
    (
      OnboardingStruggles.overplanning,
      'Overplanning',
      'Complexity becomes a barrier to actually starting.',
    ),
    (
      OnboardingStruggles.notKnowingNext,
      'Not knowing what to do next',
      'The "blank page" effect at every transition.',
    ),
    (
      OnboardingStruggles.neverFinishing,
      'Starting but never finishing',
      'A graveyard of 80%-complete projects.',
    ),
    (
      OnboardingStruggles.needAccountability,
      'Needing accountability',
      'Working better when others are watching.',
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
      onCta: flow.struggles.isEmpty ? null : controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Which of these do you struggle with?',
            style: OnboardingType.headline,
          ),
          const SizedBox(height: 10),
          Text(
            'Select all that sound like you. We use this to tailor your '
            'focus map.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: _options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final (key, title, subtitle) = _options[i];
                return OnboardingSelectableCard(
                  title: title,
                  subtitle: subtitle,
                  selected: flow.struggles.contains(key),
                  onTap: () => controller.toggleStruggle(key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
