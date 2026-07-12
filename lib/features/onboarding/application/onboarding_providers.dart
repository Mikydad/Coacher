import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_profile_repository.dart';
import '../domain/models/onboarding_profile.dart';

final onboardingProfileRepositoryProvider =
    Provider<OnboardingProfileRepository>(
      (ref) => IsarOnboardingProfileRepository(),
    );

/// Reads Isar watch stream — the local write IS the update; the merge phase
/// hydrates remote changes in the background.
final onboardingProfileStreamProvider = StreamProvider<OnboardingProfile?>(
  (ref) => ref.watch(onboardingProfileRepositoryProvider).watchProfile(),
);
