import 'package:flutter/material.dart';

import '../onboarding_ui.dart';

/// The closing screen, adaptive (2026-09-25). Two homes:
///
///  * in the flow, after "Not now" on Your SidePal ([goalCreated] false);
///  * pushed by `OnboardingHandoffBridge` after the first-goal picker,
///    once an account exists ([goalCreated] true when a goal was saved).
///
/// Self-styled (onboarding palette), so it renders the same inside the
/// onboarding MaterialApp and on the main app's Navigator. No Skip — this
/// IS the finish line.
class ReadyStep extends StatelessWidget {
  const ReadyStep({super.key, required this.goalCreated, required this.onStart});

  final bool goalCreated;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      progress: 1,
      ctaLabel: goalCreated ? 'Start my first action' : 'Go to Home',
      onCta: onStart,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: OnboardingIllustration(icon: Icons.celebration_outlined),
          ),
          const SizedBox(height: 28),
          Text(
            'You\'re ready.',
            textAlign: TextAlign.center,
            style: OnboardingType.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            goalCreated
                ? 'Your first goal is set. SidePal will help you plan it, '
                      'keep an eye on your time, and adjust when things change.'
                : 'SidePal is set up around what you told us. Add a goal '
                      'whenever you like, and your coach will help you plan it.',
            textAlign: TextAlign.center,
            style: OnboardingType.body,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
