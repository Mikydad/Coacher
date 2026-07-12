import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 4 — Meet PathPal.
class MeetPathPalStep extends ConsumerWidget {
  const MeetPathPalStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  static const _features = [
    (Icons.notifications_active_outlined, 'Remember everything'),
    (Icons.flag_outlined, 'Organize your goals'),
    (Icons.checklist_rounded, 'Plan your tasks'),
    (Icons.alarm_on_outlined, 'Remind you until you act'),
    (Icons.do_not_disturb_on_outlined, 'Reduce distractions'),
    (Icons.groups_outlined, 'Keep you accountable'),
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
          Text('Meet your AI coach.', style: OnboardingType.headline),
          const SizedBox(height: 10),
          Text('PathPal helps you:', style: OnboardingType.body),
          const SizedBox(height: 18),
          Expanded(
            // 2-column feature cards — six items fit without scrolling.
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                for (final (icon, label) in _features)
                  _FeatureCard(icon: icon, label: label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboardingColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OnboardingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: OnboardingColors.cardHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: OnboardingColors.primarySoft),
          ),
          Text(
            label,
            style: OnboardingType.cardTitle.copyWith(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
