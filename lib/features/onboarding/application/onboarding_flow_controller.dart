import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/onboarding_profile.dart';
import 'onboarding_providers.dart';

/// Ordered steps of the first-launch flow (ONBOARDING_PRD.md; registration
/// inserted after Welcome — decision log 2026-07-12).
enum OnboardingStep {
  welcome,
  register,
  struggles,
  whyThisHappens,
  meetPathPal,
  community,
  aiDemo,
  theProblem,
  dayOnePhoto,
  science,
  chooseGoals,
  personalizing,
  yourPathPal,
  premium,
  journey,
}

/// Why the user is on an auth surface — decides what a successful
/// non-anonymous sign-in means (continue the tour vs. finish immediately).
enum OnboardingAuthIntent { register, login }

@immutable
class OnboardingFlowState {
  const OnboardingFlowState({
    this.step = OnboardingStep.welcome,
    this.struggles = const <String>{},
    this.interests = const <String>{},
    this.dayOnePhotoPath,
    this.dayOnePhotoTakenAtMs,
    this.authIntent = OnboardingAuthIntent.register,
    this.registeredDuringOnboarding = false,
  });

  final OnboardingStep step;
  final Set<String> struggles;
  final Set<String> interests;
  final String? dayOnePhotoPath;
  final int? dayOnePhotoTakenAtMs;
  final OnboardingAuthIntent authIntent;
  final bool registeredDuringOnboarding;

  double get progress => step.index / (OnboardingStep.values.length - 1);

  OnboardingFlowState copyWith({
    OnboardingStep? step,
    Set<String>? struggles,
    Set<String>? interests,
    String? dayOnePhotoPath,
    int? dayOnePhotoTakenAtMs,
    OnboardingAuthIntent? authIntent,
    bool? registeredDuringOnboarding,
  }) => OnboardingFlowState(
    step: step ?? this.step,
    struggles: struggles ?? this.struggles,
    interests: interests ?? this.interests,
    dayOnePhotoPath: dayOnePhotoPath ?? this.dayOnePhotoPath,
    dayOnePhotoTakenAtMs: dayOnePhotoTakenAtMs ?? this.dayOnePhotoTakenAtMs,
    authIntent: authIntent ?? this.authIntent,
    registeredDuringOnboarding:
        registeredDuringOnboarding ?? this.registeredDuringOnboarding,
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
    // (struggles / photo / goals), so a crash mid-flow loses nothing.
    if (target == OnboardingStep.whyThisHappens ||
        target == OnboardingStep.science ||
        target == OnboardingStep.personalizing) {
      saveProgress();
    }
  }

  /// Skips over the registration step (already signed in with a real
  /// account — e.g. keychain-restored session after a reinstall).
  void skipRegisterStep() {
    if (state.step == OnboardingStep.register) {
      state = state.copyWith(step: OnboardingStep.struggles);
    }
  }

  /// Steps back one screen. Returns false when already on Welcome (caller
  /// lets the system pop / exit).
  bool back() {
    final i = state.step.index;
    if (i == 0) return false;
    var target = OnboardingStep.values[i - 1];
    // Never step back INTO registration once past it (account exists) or
    // into the transient personalizing animation.
    if (target == OnboardingStep.register &&
        state.registeredDuringOnboarding) {
      target = OnboardingStep.welcome;
    }
    if (target == OnboardingStep.personalizing) {
      target = OnboardingStep.chooseGoals;
    }
    state = state.copyWith(step: target);
    return true;
  }

  void setAuthIntent(OnboardingAuthIntent intent) {
    state = state.copyWith(authIntent: intent);
  }

  void markRegistered() {
    state = state.copyWith(registeredDuringOnboarding: true);
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

  void setDayOnePhoto(String path) {
    state = state.copyWith(
      dayOnePhotoPath: path,
      dayOnePhotoTakenAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  OnboardingProfile _buildProfile({int completedAtMs = 0}) {
    return OnboardingProfile(
      id: kOnboardingProfileId,
      struggles: state.struggles.toList(),
      interests: state.interests.toList(),
      registeredDuringOnboarding: state.registeredDuringOnboarding,
      completedAtMs: completedAtMs,
      dayOnePhotoLocalPath: state.dayOnePhotoPath,
      dayOnePhotoTakenAtMs: state.dayOnePhotoTakenAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Local Isar write + outbox replication — instant, never awaits network.
  Future<void> saveProgress() async {
    try {
      await _ref
          .read(onboardingProfileRepositoryProvider)
          .upsertProfile(_buildProfile());
    } catch (e, st) {
      debugPrint('OnboardingFlowController: saveProgress failed: $e\n$st');
    }
  }

  /// Final write when the user taps "Start My Journey".
  Future<void> complete() async {
    try {
      await _ref
          .read(onboardingProfileRepositoryProvider)
          .upsertProfile(
            _buildProfile(
              completedAtMs: DateTime.now().millisecondsSinceEpoch,
            ),
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
