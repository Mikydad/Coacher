import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../../domain/models/onboarding_profile.dart';
import '../onboarding_ui.dart';

/// Screen 12 — Your PathPal. Template-rendered dashboard preview
/// personalized from the user's selections (no seeded data — decision log
/// 2026-07-12: interests are tags, not auto-created goals).
class YourPathPalStep extends ConsumerWidget {
  const YourPathPalStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _interestLabels = {
    OnboardingInterests.buildBusiness: (
      'Building your business',
      'outlining your MVP',
    ),
    OnboardingInterests.improveHealth: (
      'Improving your health',
      'your first workout',
    ),
    OnboardingInterests.learnSkills: (
      'Learning new skills',
      'your first practice session',
    ),
    OnboardingInterests.getOrganized: (
      'Getting organized',
      'clearing your task backlog',
    ),
    OnboardingInterests.makeMoney: (
      'Growing your income',
      'mapping your income streams',
    ),
    OnboardingInterests.betterHabits: (
      'Building better habits',
      'your first daily routine',
    ),
    OnboardingInterests.moreDisciplined: (
      'Becoming more disciplined',
      'your first focused block',
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

    final firstInterest = flow.interests.isEmpty
        ? null
        : flow.interests.first;
    final (focusTitle, firstTask) =
        _interestLabels[firstInterest] ??
        ('Your first goal', 'the easiest first step');

    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: onSkip,
      ctaLabel: 'Continue',
      onCta: controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('We\'ve built your PathPal.', style: OnboardingType.headline),
          const SizedBox(height: 10),
          Text(
            'A coach shaped around what you told us.',
            style: OnboardingType.body,
          ),
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
                    const SizedBox(height: 6),
                    Text(
                      'Today\'s priority: $focusTitle.',
                      style: OnboardingType.cardBody.copyWith(
                        fontSize: 14,
                        color: OnboardingColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PreviewRow(
                      icon: Icons.center_focus_strong_outlined,
                      label: 'Today\'s Focus',
                      value: 'Start with $firstTask',
                    ),
                    const SizedBox(height: 10),
                    _PreviewRow(
                      icon: Icons.flag_outlined,
                      label: 'Weekly Goals',
                      value: '${flow.interests.length.clamp(1, 7)} focus '
                          'area${flow.interests.length == 1 ? '' : 's'} mapped',
                    ),
                    const SizedBox(height: 10),
                    _PreviewRow(
                      icon: Icons.auto_awesome,
                      label: 'AI Recommendations',
                      value: 'You\'ve completed 0 of 3 tasks — let\'s start '
                          'with the easiest one.',
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
