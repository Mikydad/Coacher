import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 1 — Welcome (ONBOARDING_PRD.md).
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  void _getStarted(WidgetRef ref) {
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    controller.next(); // → register
    // Keychain-restored session after a reinstall: the account already
    // exists, don't ask them to create one.
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null && !user.isAnonymous) controller.skipRegisterStep();
  }

  void _logIn(BuildContext context, WidgetRef ref) {
    ref
        .read(onboardingFlowControllerProvider.notifier)
        .setAuthIntent(OnboardingAuthIntent.login);
    Navigator.of(context).pushNamed(LoginScreen.routeName).then((_) {
      // Came back without signing in — restore register semantics.
      ref
          .read(onboardingFlowControllerProvider.notifier)
          .setAuthIntent(OnboardingAuthIntent.register);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingStepScaffold(
      progress: 0,
      onSkip: onSkip,
      ctaLabel: 'Get Started',
      onCta: () => _getStarted(ref),
      belowCta: Center(
        child: TextButton(
          onPressed: () => _logIn(context, ref),
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
            'Welcome to PathPal.',
            textAlign: TextAlign.center,
            style: OnboardingType.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Today is the first step toward becoming the person you want '
            'to be. Your journey starts here.',
            textAlign: TextAlign.center,
            style: OnboardingType.body,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
