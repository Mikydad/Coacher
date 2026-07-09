import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_user_profile_preference.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/user_profile_preference.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class ProfilePreferenceRepository {
  Future<UserProfilePreference?> getPreference();

  Future<void> upsertPreference(UserProfilePreference pref);

  /// Reactive stream — emits the current preference whenever it changes.
  Stream<UserProfilePreference?> watchPreference();
}

// ─── Isar implementation ──────────────────────────────────────────────────────

class IsarProfilePreferenceRepository implements ProfilePreferenceRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<UserProfilePreference?> getPreference() async {
    final row = await _isar.isarUserProfilePreferences
        .filter()
        .profileIdEqualTo(kUserProfilePreferenceId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsertPreference(UserProfilePreference pref) async {
    pref.validate();
    await _isar.writeTxn(() async {
      await _isar.isarUserProfilePreferences.putByProfileId(
        IsarUserProfilePreference.fromDomain(pref),
      );
    });
  }

  @override
  Stream<UserProfilePreference?> watchPreference() {
    return _isar.isarUserProfilePreferences
        .filter()
        .profileIdEqualTo(kUserProfilePreferenceId)
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getPreference());
  }
}
