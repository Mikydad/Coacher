import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/models/onboarding_profile.dart';
import 'onboarding_handoff.dart';
import 'onboarding_providers.dart';

/// Ordered steps of the first-launch flow (guest-first restructure,
/// decision log 2026-09-25): one story — what gets in your way → what
/// matters → why following through is hard → how SidePal helps → set up →
/// your SidePal → (first goal, after sign-in) → ready.
///
/// Registration is no longer a step: the flow ends in the anonymous account
/// and the account prompt comes later (Home backup card, Profile).
enum OnboardingStep {
  welcome,
  struggles,
  chooseGoals,
  whyThisHappens,
  aiDemo,
  personalizing,
  yourSidePal,

  /// In-flow closing screen — reached only via "Not now" on Your SidePal.
  /// The "created a goal" variant is shown after sign-in by
  /// [OnboardingHandoffBridge], because a real goal needs a uid.
  ready,
}

@immutable
class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = OnboardingStep.welcome,
    this.struggles = const <String>{},
    this.interests = const <String>{},
  });

  final OnboardingStep step;
  final Set<String> struggles;
  final Set<String> interests;

  double get progress => step.index / (OnboardingStep.values.length - 1);

  OnboardingFlowState copyWith({
    OnboardingStep? step,
    Set<String>? struggles,
    Set<String>? interests,
  }) => OnboardingFlowState(
    step: step ?? this.step,
    struggles: struggles ?? this.struggles,
    interests: interests ?? this.interests,
  );
}

class OnboardingFlowController extends StateNotifier<OnboardingFlowState> {
  OnboardingFlowController(this._ref) : super(const OnboardingFlowState());

  final Ref _ref;

  // ── Navigation ──────────────────────────────────────────────────────────────

  void next() {
    final i = state.step.index;
    if (i >= OnboardingStep.values.length - 1) return;
    final target = OnboardingStep.values[i + 1];
    state = state.copyWith(step: target);
    // Answers persist as the user leaves the step that produced them
    // (struggles / goals), so a crash mid-flow loses nothing.
    if (target == OnboardingStep.whyThisHappens ||
        target == OnboardingStep.personalizing) {
      saveProgress();
    }
  }

  /// Steps back one screen. Returns false when already on Welcome (caller
  /// lets the system pop / exit).
  bool back() {
    final i = state.step.index;
    if (i == 0) return false;
    var target = OnboardingStep.values[i - 1];
    // Never step back INTO the transient personalizing animation.
    if (target == OnboardingStep.personalizing) {
      target = OnboardingStep.values[target.index - 1];
    }
    state = state.copyWith(step: target);
    return true;
  }

  // ── Answers ─────────────────────────────────────────────────────────────────

  void toggleStruggle(String key) {
    final next = {...state.struggles};
    next.contains(key) ? next.remove(key) : next.add(key);
    state = state.copyWith(struggles: next);
  }

  void toggleInterest(String key) {
    final next = {...state.interests};
    next.contains(key) ? next.remove(key) : next.add(key);
    state = state.copyWith(interests: next);
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  OnboardingProfile _buildProfile({int completedAtMs = 0}) {
    return OnboardingProfile(
      id: kOnboardingProfileId,
      struggles: state.struggles.toList(),
      interests: state.interests.toList(),
      registeredDuringOnboarding: false,
      completedAtMs: completedAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// The flow runs above AuthGate, so there is usually no uid yet: the
  /// profile is committed to Isar only, and [OnboardingHandoffBridge]
  /// replicates it once the account exists. A keychain-restored session is
  /// the one case where a uid already exists — then it replicates now.
  bool get _canReplicate =>
      _ref.read(authRepositoryProvider).currentUser != null;

  /// Local Isar write — instant, never awaits network.
  Future<void> saveProgress() async {
    try {
      await _ref
          .read(onboardingProfileRepositoryProvider)
          .upsertProfile(_buildProfile(), replicate: _canReplicate);
    } catch (e, st) {
      debugPrint('OnboardingFlowController: saveProgress failed: $e\n$st');
    }
  }

  /// Final write when the flow ends. [wantsFirstGoal] records the CTA the
  /// user chose on Your SidePal; the bridge reads it after sign-in.
  Future<void> complete({required bool wantsFirstGoal}) async {
    try {
      await _ref
          .read(onboardingProfileRepositoryProvider)
          .upsertProfile(
            _buildProfile(completedAtMs: DateTime.now().millisecondsSinceEpoch),
            replicate: _canReplicate,
          );
      await OnboardingHandoff.schedule(
        wantsFirstGoal ? OnboardingHandoffKind.firstGoal : OnboardingHandoffKind.syncOnly,
      );
    } catch (e, st) {
      debugPrint('OnboardingFlowController: complete write failed: $e\n$st');
    }
  }
}

final onboardingFlowControllerProvider =
    StateNotifierProvider<OnboardingFlowController, OnboardingFlowState>(
      (ref) => OnboardingFlowController(ref),
    );
