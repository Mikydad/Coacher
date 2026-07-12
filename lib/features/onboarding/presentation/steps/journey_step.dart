import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 14 — Start Your Journey. Celebration; shows the user's own Day One
/// photo when they captured one (the emotional payoff of Screen 8), else the
/// celebration illustration. No Skip — this IS the finish line.
class JourneyStep extends ConsumerWidget {
  const JourneyStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final photoPath = flow.dayOnePhotoPath;
    final photoFile = photoPath == null ? null : File(photoPath);
    final hasPhoto = photoFile?.existsSync() ?? false;

    return OnboardingStepScaffold(
      progress: 1,
      ctaLabel: 'Start My Journey',
      onCta: onStart,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: hasPhoto
                ? Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          Image.file(
                            photoFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              color: OnboardingColors.background.withValues(
                                alpha: 0.55,
                              ),
                              child: Text(
                                'Day One',
                                textAlign: TextAlign.center,
                                style: OnboardingType.label,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const OnboardingIllustration(
                    icon: Icons.celebration_outlined,
                  ),
          ),
          const SizedBox(height: 28),
          Text(
            'You\'re ready.',
            textAlign: TextAlign.center,
            style: OnboardingType.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Your AI coach is waiting. Today is Day One.\n'
            'Let\'s build the future version of you.',
            textAlign: TextAlign.center,
            style: OnboardingType.body,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
