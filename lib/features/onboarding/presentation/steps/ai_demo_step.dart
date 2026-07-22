import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 6 — AI Demonstration. Fully scripted (no network) so the flow
/// passes the airplane-mode test; it *shows* the product, it doesn't run it.
class AiDemoStep extends ConsumerStatefulWidget {
  const AiDemoStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  ConsumerState<AiDemoStep> createState() => _AiDemoStepState();
}

class _AiDemoStepState extends ConsumerState<AiDemoStep> {
  static const _reveals = [
    (Icons.flag_outlined, 'Goal — Startup Launch'),
    (Icons.route_outlined, 'Weekly roadmap'),
    (Icons.checklist_rounded, 'Today\'s tasks'),
    (Icons.calendar_month_outlined, 'Schedule'),
    (Icons.notifications_active_outlined, 'Smart reminders'),
  ];

  int _revealed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Staggered build-out: user message lands, then the plan assembles.
    _timer = Timer.periodic(const Duration(milliseconds: 450), (t) {
      if (!mounted) return;
      if (_revealed >= _reveals.length) {
        t.cancel();
        return;
      }
      setState(() => _revealed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: widget.onSkip,
      ctaLabel: 'Continue',
      onCta: controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Just tell SidePal what you want.',
              style: OnboardingType.headline),
          const SizedBox(height: 10),
          Text(
            'Watch simple ideas become structured, actionable plans.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 18),
          // User bubble.
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: OnboardingColors.aetherGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '"I want to launch my startup."',
                style: OnboardingType.cardTitle.copyWith(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OnboardingColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: OnboardingColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: OnboardingColors.pathway,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Instantly creating your growth blueprint…',
                          style: OnboardingType.cardBody.copyWith(
                            color: OnboardingColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reveals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final visible = i < _revealed;
                        final (icon, label) = _reveals[i];
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: visible ? 1 : 0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            offset: visible
                                ? Offset.zero
                                : const Offset(0, 0.25),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: OnboardingColors.pathway,
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  icon,
                                  size: 18,
                                  color: OnboardingColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: OnboardingType.cardTitle.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
