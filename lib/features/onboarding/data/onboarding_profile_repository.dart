import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_onboarding_profile.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/onboarding_profile.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class OnboardingProfileRepository {
  Future<OnboardingProfile?> getProfile();

  /// Commits to Isar, then replicates via the outbox (local-first Rule 1).
  Future<void> upsertProfile(OnboardingProfile profile);

  /// Reactive stream — emits the current profile whenever it changes.
  Stream<OnboardingProfile?> watchProfile();
}

// ─── Isar implementation ──────────────────────────────────────────────────────

class IsarOnboardingProfileRepository implements OnboardingProfileRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<OnboardingProfile?> getProfile() async {
    final row = await _isar.isarOnboardingProfiles
        .filter()
        .profileIdEqualTo(kOnboardingProfileId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsertProfile(OnboardingProfile profile) async {
    profile.validate();
    await _isar.writeTxn(() async {
      await _isar.isarOnboardingProfiles.putByProfileId(
        IsarOnboardingProfile.fromDomain(profile),
      );
    });
    await outboxUpsert(
      entityType: 'onboardingProfile',
      documentPath: FirestorePaths.onboardingProfileDoc,
      payload: profile.toMap(),
    );
  }

  @override
  Stream<OnboardingProfile?> watchProfile() {
    return _isar.isarOnboardingProfiles
        .filter()
        .profileIdEqualTo(kOnboardingProfileId)
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getProfile());
  }
}
