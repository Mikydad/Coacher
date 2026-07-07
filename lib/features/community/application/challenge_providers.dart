import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/challenge_repository.dart';
import '../domain/models/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return FirestoreChallengeRepository();
});

final circleChallengesProvider = StreamProvider.family<List<Challenge>, String>(
  (ref, circleId) {
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
