import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/local_db/isar_collections/isar_analytics_event.dart';
import '../../../core/offline/offline_store.dart';
import '../../../features/coaching/domain/models/enforcement_mode.dart';
import '../data/profile_preference_repository.dart';
import '../domain/models/user_profile_preference.dart';
import 'profile_preference_service.dart';
import '../../../core/presentation/async_value_ui.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final profilePreferenceRepositoryProvider =
    Provider<ProfilePreferenceRepository>((ref) {
      return IsarProfilePreferenceRepository();
    });

// ─── Service ──────────────────────────────────────────────────────────────────

final profilePreferenceServiceProvider = Provider<ProfilePreferenceService>((
  ref,
) {
  final repo = ref.watch(profilePreferenceRepositoryProvider);
  return ProfilePreferenceService(repository: repo);
});

// ─── Stream ───────────────────────────────────────────────────────────────────

/// Streams the full [UserProfilePreference] from Isar. Emits null when no
/// record exists yet (e.g. fresh install before the user has edited anything).
final userProfilePreferenceStreamProvider =
    StreamProvider<UserProfilePreference?>((ref) {
      final repo = ref.watch(profilePreferenceRepositoryProvider);
      return repo.watchPreference();
    });

// ─── Convenience providers ────────────────────────────────────────────────────

/// The user's display name; falls back to empty string.
final displayNameProvider = Provider<String>((ref) {
  final async = ref.watch(userProfilePreferenceStreamProvider);
  return async.when(
    data: (pref) => pref?.displayName ?? '',
    loading: () => '',
    error: (e, _) => swallowedAsyncError('profile_providers', e, ''),
  );
});

/// The user's default [EnforcementMode]; falls back to [EnforcementMode.disciplined].
final defaultEnforcementModeProvider = Provider<EnforcementMode>((ref) {
  final async = ref.watch(userProfilePreferenceStreamProvider);
  return async.when(
    data: (pref) => pref?.defaultEnforcementMode ?? EnforcementMode.disciplined,
    loading: () => EnforcementMode.disciplined,
    error: (e, _) => swallowedAsyncError(
      'profile_providers',
      e,
      EnforcementMode.disciplined,
    ),
  );
});

// ─── Total completions ────────────────────────────────────────────────────────

/// Count of all [AnalyticsEventType.habitCompleted] events stored locally.
final totalCompletionsCountProvider = FutureProvider<int>((ref) async {
  final isar = OfflineStore.instance.isar;
  if (isar == null) return 0;
  final all = await isar.isarAnalyticsEvents
      .where()
      .sortByUpdatedAtMsDesc()
      .findAll();
  return all.where((e) => e.typeName == 'habitCompleted').length;
});
