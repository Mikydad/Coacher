import '../data/coaching_style_repository.dart';
import '../domain/models/coaching_style.dart';
import '../domain/models/user_coaching_profile.dart';

/// Manages the lifecycle of the user's [CoachingStyle].
///
/// All mutations go through this service to ensure [styleChangeHistory]
/// is updated consistently and [lastChangedAtMs] is set correctly.
class CoachingStyleService {
  CoachingStyleService({
    required CoachingStyleRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final CoachingStyleRepository _repository;
  final DateTime Function() _now;

  /// Change the active coaching style at any time (e.g. from settings).
  /// Appends a [StyleChangeEntry] to the history.
  Future<void> setStyle(CoachingStyle style) async {
    final existing = await _repository.getProfile();
    final nowMs = _now().millisecondsSinceEpoch;
    final updated = (existing ?? _defaultProfile(nowMs)).withStyleChange(
      style,
      nowMs,
    );
    await _repository.upsertProfile(updated);
  }

  /// Set the coaching style during onboarding — also records
  /// [onboardingCompletedAtMs].
  Future<void> setOnboardingStyle(CoachingStyle style) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final existing = await _repository.getProfile();
    final base = existing ?? _defaultProfile(nowMs);
    final withStyle = base.withStyleChange(style, nowMs);
    final withOnboarding = withStyle.copyWith(
      onboardingCompletedAtMs: nowMs,
    );
    await _repository.upsertProfile(withOnboarding);
  }

  /// Returns the persisted coaching style, or [CoachingStyle.balanced] if
  /// no profile exists yet.
  Future<CoachingStyle> getActiveStyle() async {
    final profile = await _repository.getProfile();
    return profile?.coachingStyle ?? CoachingStyle.balanced;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  UserCoachingProfile _defaultProfile(int nowMs) => UserCoachingProfile(
    id: kUserCoachingProfileId,
    coachingStyle: CoachingStyle.balanced,
    lastChangedAtMs: nowMs,
    updatedAtMs: nowMs,
  );
}
