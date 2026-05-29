import '../../../features/analytics/application/coaching_insight_notification_policy.dart'
    as coaching_notify_policy;
import '../../../features/coaching/domain/models/enforcement_mode.dart';
import '../data/profile_preference_repository.dart';
import '../domain/models/user_profile_preference.dart';

/// Manages mutations to [UserProfilePreference].
///
/// All writes go through this service so that [updatedAtMs] is always set
/// correctly and the single-record invariant is maintained.
class ProfilePreferenceService {
  ProfilePreferenceService({
    required ProfilePreferenceRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final ProfilePreferenceRepository _repository;
  final DateTime Function() _now;

  /// Seeds local display name from Firebase Auth when the user has not set one.
  ///
  /// Does not overwrite a non-empty name the user already chose in Profile.
  Future<void> syncDisplayNameFromAuthIfEmpty(String authDisplayName) async {
    final trimmed = authDisplayName.trim();
    if (trimmed.isEmpty) return;

    final existing = await _repository.getPreference();
    final current = existing?.displayName.trim() ?? '';
    if (current.isNotEmpty) return;

    await setDisplayName(trimmed);
  }

  /// Updates the user's display name.
  Future<void> setDisplayName(String name) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final existing = await _repository.getPreference();
    final updated = (existing ?? _defaultPreference(nowMs)).copyWith(
      displayName: name.trim(),
      updatedAtMs: nowMs,
    );
    await _repository.upsertPreference(updated);
  }

  /// Updates the default [EnforcementMode] for new entities.
  Future<void> setDefaultEnforcementMode(EnforcementMode mode) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final existing = await _repository.getPreference();
    final updated = (existing ?? _defaultPreference(nowMs)).copyWith(
      defaultEnforcementMode: mode,
      updatedAtMs: nowMs,
    );
    await _repository.upsertPreference(updated);
  }

  /// Enables or disables push notifications for Layer 4 coaching insights.
  Future<void> setCoachingInsightNotificationsEnabled(bool enabled) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final existing = await _repository.getPreference();
    final updated = (existing ?? _defaultPreference(nowMs)).copyWith(
      coachingInsightNotificationsEnabled: enabled,
      updatedAtMs: nowMs,
    );
    await _repository.upsertPreference(updated);
  }

  Future<coaching_notify_policy.CoachingInsightNotificationSendEvaluation>
  evaluateCoachingInsightNotificationSend({
    DateTime? now,
  }) async {
    final ts = now ?? _now();
    final existing = await _repository.getPreference();
    final base = existing ?? _defaultPreference(ts.millisecondsSinceEpoch);
    return coaching_notify_policy.evaluateCoachingInsightNotificationSend(
      base,
      ts,
    );
  }

  Future<void> recordCoachingInsightNotificationSent({DateTime? now}) async {
    final ts = now ?? _now();
    final nowMs = ts.millisecondsSinceEpoch;
    final existing = await _repository.getPreference();
    final base = existing ?? _defaultPreference(nowMs);
    final updated = coaching_notify_policy
        .recordCoachingInsightNotificationSent(base, ts)
        .copyWith(updatedAtMs: nowMs);
    await _repository.upsertPreference(updated);
  }

  /// Enables or disables the morning brief notification.
  Future<void> setMorningBriefEnabled(bool enabled) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final existing = await _repository.getPreference();
    final updated = (existing ?? _defaultPreference(nowMs)).copyWith(
      morningBriefEnabled: enabled,
      updatedAtMs: nowMs,
    );
    await _repository.upsertPreference(updated);
  }

  /// Returns the persisted preference, or an in-memory default if none exists.
  Future<UserProfilePreference> getPreference() async {
    final nowMs = _now().millisecondsSinceEpoch;
    return (await _repository.getPreference()) ?? _defaultPreference(nowMs);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  UserProfilePreference _defaultPreference(int nowMs) => UserProfilePreference(
    id: kUserProfilePreferenceId,
    displayName: '',
    defaultEnforcementMode: EnforcementMode.disciplined,
    updatedAtMs: nowMs,
  );
}
