import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/login_screen.dart';
import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 1 — Welcome. "Get started" begins as a guest (guest-first,
/// decision log 2026-09-25); "Log in" is for people who already have an
/// account — a real sign-in ends the flow (shell's auth listener).
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    return OnboardingStepScaffold(
      progress: 0,
      onSkip: onSkip,
      ctaLabel: 'Get started',
      onCta: controller.next,
      belowCta: Center(
        child: TextButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(LoginScreen.routeName),
          child: Text(
            'Already have an account? Log in',
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
          const Expanded(
            child: OnboardingIllustration(icon: Icons.route_outlined),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to SidePal.',
            textAlign: TextAlign.center,
            style: OnboardingType.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Plan what matters, see where your time really goes, and get '
            'help following through.',
            textAlign: TextAlign.center,
            style: OnboardingType.body,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
