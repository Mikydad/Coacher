import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stakes_repository.dart';
import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';
import 'stake_functions.dart';

final stakesRepositoryProvider = Provider<StakesRepository>(
  // Local-first reads (Isar watch streams); challenge mutations go through
  // stakeFunctionsProvider (network-inherent, optimistic-then-honest).
  (ref) => StakesRepository(),
);

final stakeFunctionsProvider = Provider<StakeFunctions>(
  (ref) => StakeFunctions(),
);

/// All of this account's stake challenges (server mirror, newest first).
final stakeChallengesStreamProvider =
    StreamProvider<List<StakeChallenge>>((ref) {
  return ref.watch(stakesRepositoryProvider).watchChallenges();
});

final stakeChallengeStreamProvider =
    StreamProvider.family<StakeChallenge?, String>((ref, challengeId) {
  return ref.watch(stakesRepositoryProvider).watchChallenge(challengeId);
});

final stakeEvidenceStreamProvider =
    StreamProvider.family<List<StakeEvidence>, String>((ref, challengeId) {
  return ref.watch(stakesRepositoryProvider).watchEvidence(challengeId);
});

/// Challenges that still need something from the user (not terminal),
/// newest deadline first — the Stakes hub's "active" list.
final openStakeChallengesProvider =
    Provider<AsyncValue<List<StakeChallenge>>>((ref) {
  final async = ref.watch(stakeChallengesStreamProvider);
  return async.when(
    data: (list) {
      final open = list.where((c) => !c.status.isTerminal).toList()
        ..sort((a, b) => a.deadlineMs.compareTo(b.deadlineMs));
      return AsyncValue.data(open);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});
