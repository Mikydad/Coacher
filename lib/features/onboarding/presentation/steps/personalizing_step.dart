import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 11 — Personalizing Your Coach. Scripted ~3s full-screen animation
/// (no interaction, no network), then auto-advances.
class PersonalizingStep extends ConsumerStatefulWidget {
  const PersonalizingStep({super.key});

  @override
  ConsumerState<PersonalizingStep> createState() => _PersonalizingStepState();
}

class _PersonalizingStepState extends ConsumerState<PersonalizingStep> {
  static const _messages = [
    'Analyzing your goals…',
    'Understanding your habits…',
    'Building your first plan…',
    'Preparing your AI coach…',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) return;
      if (_index >= _messages.length - 1) {
        t.cancel();
        // Brief hold on the final message before the reveal.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            ref.read(onboardingFlowControllerProvider.notifier).next();
          }
        });
        return;
      }
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: OnboardingColors.primarySoft,
                ),
              ),
              const SizedBox(height: 36),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  _messages[_index],
                  key: ValueKey(_index),
                  textAlign: TextAlign.center,
                  style: OnboardingType.cardTitle.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
