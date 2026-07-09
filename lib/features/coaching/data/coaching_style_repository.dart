import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_user_coaching_profile.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/user_coaching_profile.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class CoachingStyleRepository {
  Future<UserCoachingProfile?> getProfile();

  Future<void> upsertProfile(UserCoachingProfile profile);

  /// Reactive stream — emits the current profile whenever it changes in Isar.
  Stream<UserCoachingProfile?> watchProfile();
}

// ─── Isar implementation ──────────────────────────────────────────────────────

class IsarCoachingStyleRepository implements CoachingStyleRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<UserCoachingProfile?> getProfile() async {
    final row = await _isar.isarUserCoachingProfiles
        .filter()
        .profileIdEqualTo(kUserCoachingProfileId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsertProfile(UserCoachingProfile profile) async {
    profile.validate();
    await _isar.writeTxn(() async {
      await _isar.isarUserCoachingProfiles.putByProfileId(
        IsarUserCoachingProfile.fromDomain(profile),
      );
    });
  }

  @override
  Stream<UserCoachingProfile?> watchProfile() {
    return _isar.isarUserCoachingProfiles
        .filter()
        .profileIdEqualTo(kUserCoachingProfileId)
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getProfile());
  }
}
