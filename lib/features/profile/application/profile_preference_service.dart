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
