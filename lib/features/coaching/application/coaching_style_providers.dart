import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coaching_style_repository.dart';
import '../domain/models/coaching_style.dart';
import '../domain/models/user_coaching_profile.dart';
import 'coaching_style_service.dart';
import '../../../core/presentation/async_value_ui.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final coachingStyleRepositoryProvider = Provider<CoachingStyleRepository>((
  ref,
) {
  return IsarCoachingStyleRepository();
});

// ─── Service ──────────────────────────────────────────────────────────────────

final coachingStyleServiceProvider = Provider<CoachingStyleService>((ref) {
  final repo = ref.watch(coachingStyleRepositoryProvider);
  return CoachingStyleService(repository: repo);
});

// ─── Active profile stream ────────────────────────────────────────────────────

/// Streams the full [UserCoachingProfile] from Isar. Emits null when no
/// profile has been saved yet (e.g. fresh install before onboarding).
final coachingProfileStreamProvider = StreamProvider<UserCoachingProfile?>((
  ref,
) {
  final repo = ref.watch(coachingStyleRepositoryProvider);
  return repo.watchProfile();
});

// ─── Convenience: active CoachingStyle ───────────────────────────────────────

/// Resolves to the current [CoachingStyle], defaulting to [CoachingStyle.balanced]
/// until persisted data is available.
final activeCoachingStyleProvider = Provider<CoachingStyle>((ref) {
  final profileAsync = ref.watch(coachingProfileStreamProvider);
  return profileAsync.when(
    data: (profile) => profile?.coachingStyle ?? CoachingStyle.balanced,
    loading: () => CoachingStyle.balanced,
    error: (e, _) => swallowedAsyncError(
      'coaching_style_providers',
      e,
      CoachingStyle.balanced,
    ),
  );
});
