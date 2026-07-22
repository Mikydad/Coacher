import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../data/stakes_repository.dart';
import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';
import 'stake_functions.dart';
import 'stake_seen_store.dart';

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

/// Every mirrored evidence row (all challenges) — the needs-action badge
/// checks "did I log today's unit yet" without a per-challenge family.
final allStakeEvidenceStreamProvider = StreamProvider<List<StakeEvidence>>(
  (ref) => ref.watch(stakesRepositoryProvider).watchAllEvidence(),
);

/// Invites waiting on ME: pending_accept challenges I'm a participant of
/// but didn't create. Feeds the badge and the arrival notifier.
final stakePendingInvitesProvider = Provider<List<StakeChallenge>>((ref) {
  final uid = FirestorePaths.activeUid;
  final list = ref.watch(stakeChallengesStreamProvider).value ?? const [];
  return list
      .where((c) =>
          c.status == StakeChallengeStatus.pendingAccept &&
          c.creatorUid != uid &&
          c.participant(uid) != null)
      .toList();
});

/// The Accountability tab badge: how many badge-worthy items the user has
/// NOT yet looked at —
///  * an invite to accept/decline,
///  * today's evidence not yet at the mercy target on an active challenge,
///  * a multiparty outcome awaiting my confirm/dispute ("their word").
/// Seen-semantics (notification-tray model): opening the challenge's
/// detail screen marks the item's current state seen and removes it from
/// the count — acting isn't required. New state = new marker, so the badge
/// re-arms when something genuinely new happens (including each new day's
/// due evidence). Doing the action removes the item outright.
final stakeActionsNeededProvider = Provider<int>((ref) {
  final uid = FirestorePaths.activeUid;
  final challenges = ref.watch(stakeChallengesStreamProvider).value ?? const [];
  final evidence = ref.watch(allStakeEvidenceStreamProvider).value ?? const [];
  final seen = ref.watch(stakeSeenProvider);

  var count = 0;
  for (final c in challenges) {
    if (c.participant(uid) == null) continue;
    switch (c.status) {
      case StakeChallengeStatus.pendingAccept:
        if (c.creatorUid != uid && !seen.contains(StakeSeenKeys.invite(c.id))) {
          count++;
        }
      case StakeChallengeStatus.active:
        final today = c.todayUnitIndex;
        if (today >= 0 &&
            today < c.frozenGoal.totalUnits &&
            !seen.contains(StakeSeenKeys.evidence(c.id, today))) {
          var logged = 0;
          for (final e in evidence) {
            if (e.challengeId == c.id && e.uid == uid && e.unitIndex == today) {
              logged += e.amount;
            }
          }
          if (logged < c.mercyUnitTarget) count++;
        }
      case StakeChallengeStatus.pendingVerification:
        if (c.type.isMultiParty &&
            !seen.contains(StakeSeenKeys.confirm(c.id))) {
          count++;
        }
      default:
        break;
    }
  }
  return count;
});

/// Goal ids currently staked by a NON-TERMINAL challenge — the Goals hub
/// renders the staked badge from this (CC-6).
final stakedGoalIdsProvider = Provider<Set<String>>((ref) {
  final list = ref.watch(stakeChallengesStreamProvider).value ?? const [];
  return {
    for (final c in list)
      if (!c.status.isTerminal && c.frozenGoal.linkedGoalId != null)
        c.frozenGoal.linkedGoalId!,
  };
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
