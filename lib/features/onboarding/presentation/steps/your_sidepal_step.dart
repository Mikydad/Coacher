import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../../domain/models/onboarding_profile.dart';
import '../onboarding_ui.dart';

/// Screen 7 — Your SidePal. Template-rendered preview personalized from the
/// user's selections (no seeded data — decision log 2026-07-12: interests
/// are tags, not auto-created goals). Every row is derived from what they
/// told us; nothing pretends to be user data (2026-09-25).
///
/// The primary CTA hands off to the first-goal picker AFTER sign-in (the
/// flow has no uid); "Not now" continues to the in-flow ready screen.
class YourSidePalStep extends ConsumerWidget {
  const YourSidePalStep({
    super.key,
    required this.onSkip,
    required this.onFirstGoal,
  });

  final VoidCallback onSkip;

  /// "Turn this into your first goal" — the shell completes the flow with
  /// the first-goal handoff scheduled.
  final VoidCallback onFirstGoal;

  static const _focus = {
    OnboardingInterests.buildBusiness: (
      'Building your business',
      'Outline what your first version needs to do',
    ),
    OnboardingInterests.improveHealth: (
      'Improving your health',
      'Pick three days this week to move',
    ),
    OnboardingInterests.learnSkills: (
      'Learning a new skill',
      'Choose one thing to learn and book the first session',
    ),
    OnboardingInterests.getOrganized: (
      'Getting organized',
      'Write down everything on your mind, then pick tomorrow\'s three',
    ),
    OnboardingInterests.makeMoney: (
      'Growing your income',
      'List every way money could come in this year',
    ),
    OnboardingInterests.betterHabits: (
      'Building better habits',
      'Pick one small habit and attach it to something you already do',
    ),
    OnboardingInterests.moreDisciplined: (
      'Becoming more disciplined',
      'Protect one focused hour tomorrow',
    ),
  };

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning.';
    if (h < 18) return 'Good afternoon.';
    return 'Good evening.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);

    final firstInterest = flow.interests.isEmpty ? null : flow.interests.first;
    final (focusTitle, firstStep) =
        _focus[firstInterest] ??
        ('Your first goal', 'Pick the smallest step you could take today');

    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: onSkip,
      ctaLabel: 'Turn this into your first goal',
      onCta: onFirstGoal,
      belowCta: Center(
        child: TextButton(
          onPressed: controller.next,
          child: Text(
            'Not now',
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
          Text(
            'We\'ve personalized your SidePal.',
            style: OnboardingType.headline,
          ),
          const SizedBox(height: 10),
          Text('Shaped around what you told us.', style: OnboardingType.body),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OnboardingColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: OnboardingColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: OnboardingType.cardTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _PreviewRow(
                      icon: Icons.center_focus_strong_outlined,
                      label: 'Your current focus',
                      value: focusTitle,
                    ),
                    const SizedBox(height: 10),
                    _PreviewRow(
                      icon: Icons.flag_outlined,
                      label: 'A good place to start',
                      value: firstStep,
                    ),
                    const SizedBox(height: 10),
                    const _PreviewRow(
                      icon: Icons.auto_awesome,
                      label: 'Your coach',
                      value: 'Ready to help when your plan changes',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OnboardingColors.cardHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: OnboardingColors.primarySoft),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: OnboardingType.label.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: OnboardingType.cardBody.copyWith(
                    color: OnboardingColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
