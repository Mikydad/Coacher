import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../goals/presentation/goal_template_picker_screen.dart';
import '../application/onboarding_handoff.dart';
import '../application/onboarding_providers.dart';
import 'steps/ready_step.dart';

/// Finishes what the onboarding flow could not do without an account
/// (2026-09-25). Mounted once in the main tab shell; renders nothing.
///
/// When a uid appears and a handoff marker is pending:
///  1. re-upserts the saved profile so it replicates through the outbox
///     (the flow's own writes were Isar-only — no uid then);
///  2. for the first-goal kind, pushes the picker in first-goal mode, then
///     the adaptive Ready screen, so the user never sees an empty Home
///     between "Turn this into your first goal" and their goal row.
class OnboardingHandoffBridge extends ConsumerStatefulWidget {
  const OnboardingHandoffBridge({super.key});

  @override
  ConsumerState<OnboardingHandoffBridge> createState() =>
      _OnboardingHandoffBridgeState();
}

class _OnboardingHandoffBridgeState
    extends ConsumerState<OnboardingHandoffBridge> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authUidProvider);
    if (uid != null && !_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_run());
      });
    }
    return const SizedBox.shrink();
  }

  Future<void> _run() async {
    final kind = await OnboardingHandoff.consume();
    if (kind == null || !mounted) return;

    final repo = ref.read(onboardingProfileRepositoryProvider);
    final profile = await repo.getProfile();
    if (profile != null) {
      // Same content, now with a uid — the outbox path is correct.
      try {
        await repo.upsertProfile(profile);
      } catch (e, st) {
        debugPrint('OnboardingHandoffBridge: replicate failed: $e\n$st');
      }
    }
    if (kind != OnboardingHandoffKind.firstGoal || !mounted) return;

    final interests = profile?.interests ?? const <String>[];
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        // Named so the Getting Started tour knows a foreign screen is up.
        settings: const RouteSettings(name: '/onboarding/first-goal'),
        builder: (_) => GoalTemplatePickerScreen(
          firstGoal: FirstGoalPick(interests: interests),
        ),
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/onboarding/ready'),
        builder: (ctx) => ReadyStep(
          goalCreated: saved == true,
          onStart: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}
