import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/challenge_repository.dart';
import '../domain/models/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return FirestoreChallengeRepository();
});

/// Auth-scoped (audit H6): re-subscribes on account change and emits
/// nothing while signed out, so a cached list never outlives its account.
final circleChallengesProvider = StreamProvider.family<List<Challenge>, String>(
  (ref, circleId) {
    final uid = ref.watch(authUidProvider);
    if (uid == null || uid.isEmpty) return Stream.value(const []);
    return ref.watch(challengeRepositoryProvider).watchChallenges(circleId);
  },
);

final activeChallengesProvider =
    Provider.family<AsyncValue<List<Challenge>>, String>((ref, circleId) {
      return ref
          .watch(circleChallengesProvider(circleId))
          .whenData(
            (list) =>
                list.where((c) => c.status == ChallengeStatus.active).toList(),
          );
    });

final pendingChallengesProvider =
    Provider.family<AsyncValue<List<Challenge>>, String>((ref, circleId) {
      return ref
          .watch(circleChallengesProvider(circleId))
          .whenData(
            (list) =>
                list.where((c) => c.status == ChallengeStatus.pending).toList(),
          );
    });

final completedChallengesProvider =
    Provider.family<AsyncValue<List<Challenge>>, String>((ref, circleId) {
      return ref
          .watch(circleChallengesProvider(circleId))
          .whenData(
            (list) => list
                .where((c) => c.status == ChallengeStatus.completed)
                .toList(),
          );
    });
