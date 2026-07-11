import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/activity_feed_repository.dart';
import '../data/circle_member_repository.dart';
import '../data/circle_message_repository.dart';
import '../data/circle_proof_storage.dart';
import '../data/circle_repository.dart';
import '../data/removal_vote_repository.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/activity_feed_item.dart';
import '../domain/models/circle_member.dart';
import '../domain/models/circle_message.dart';
import '../domain/models/removal_vote.dart';

// ── Repository providers ──────────────────────────────────────────────────────

final circleRepositoryProvider = Provider<CircleRepository>(
  (ref) => FirestoreCircleRepository(),
);

final circleMemberRepositoryProvider = Provider<CircleMemberRepository>(
  (ref) => FirestoreCircleMemberRepository(),
);

final circleMessageRepositoryProvider = Provider<CircleMessageRepository>(
  (ref) => FirestoreCircleMessageRepository(),
);

final circleProofStorageProvider = Provider<CircleProofStorage>(
  (ref) => CircleProofStorage(),
);

// ── My circles ────────────────────────────────────────────────────────────────

/// Live stream of circle IDs the current user belongs to.
/// Reacts instantly when the user joins or leaves a circle.
final myCircleIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  // Re-subscribe when the signed-in uid changes (logout / account switch).
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null || uid.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users/$uid/circleIds')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toList());
});

/// Live stream of all circles the current user belongs to.
final myCirclesProvider = StreamProvider.autoDispose<List<AccountabilityCircle>>(
  (ref) {
    final idsAsync = ref.watch(myCircleIdsProvider);

    if (idsAsync.hasError) {
      return Stream.error(idsAsync.error!, idsAsync.stackTrace);
    }

    // While ids are loading after an account switch, avoid Stream.empty() which
    // never emits and surfaces as a provider error in CommunityScreen.
    final ids = idsAsync.value;
    if (ids == null) return Stream.value([]);

    if (ids.isEmpty) return Stream.value([]);

    return ref.watch(circleRepositoryProvider).watchCircles(ids);
  },
);

// ── Discovery (public circles) ──────────────────────────────────────────────

/// Public circles for the discovery/browse experience — powers the
/// "Discover circles" screen's Browse tab and the zero-circles state on the
/// Community tab. Pass `null` (or `'all'`) for [category] to fetch every
/// category.
final discoverCirclesProvider = FutureProvider.autoDispose
    .family<List<AccountabilityCircle>, String?>((ref, category) {
      return ref
          .watch(circleRepositoryProvider)
          .searchCircles(
            category: (category == null || category == 'all')
                ? null
                : category,
          );
    });

// ── Per-circle providers ──────────────────────────────────────────────────────
// Circle-scoped streams key off `authUidProvider` (auth_providers.dart) so
// they rebuild when the signed-in uid changes.

/// Clears cached per-circle streams after logout / account switch.
void invalidateCircleScopedProviders(WidgetRef ref) {
  ref.invalidate(myCircleIdsProvider);
  ref.invalidate(myCirclesProvider);
  ref.invalidate(circleDetailProvider);
  ref.invalidate(circleMembersProvider);
  ref.invalidate(circleMessagesProvider);
  ref.invalidate(circleActivityFeedProvider);
  ref.invalidate(circleRemovalVotesProvider);
}

/// Live stream of a single circle document.
final circleDetailProvider = StreamProvider.autoDispose
    .family<AccountabilityCircle?, String>((ref, circleId) {
      final uid = ref.watch(authUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value(null);

      return ref.watch(circleRepositoryProvider).watchCircle(circleId);
    });

/// Live stream of all members in a circle (ordered by joinedAtMs asc).
final circleMembersProvider = StreamProvider.autoDispose
    .family<List<CircleMember>, String>((ref, circleId) {
      final uid = ref.watch(authUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value([]);

      return ref.watch(circleMemberRepositoryProvider).watchMembers(circleId);
    });

/// Live stream of the latest 50 messages in a circle (ordered by createdAtMs desc).
final circleMessagesProvider = StreamProvider.autoDispose
    .family<List<CircleMessage>, String>((ref, circleId) {
      final uid = ref.watch(authUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value([]);

      return ref.watch(circleMessageRepositoryProvider).watchMessages(circleId);
    });

/// Tracks the active bottom-tab index for a given circle detail screen.
/// 0 = Chat, 1 = Activity, 2 = Commitments, 3 = Challenges, 4 = Members, 5 = Info
final circleActiveTabProvider = StateProvider.family<int, String>(
  (ref, circleId) => 0,
);

// ── Activity feed ─────────────────────────────────────────────────────────────

final activityFeedRepositoryProvider = Provider<ActivityFeedRepository>(
  (ref) => FirestoreActivityFeedRepository(),
);

/// Live stream of the latest 30 activity feed items for a circle.
final circleActivityFeedProvider = StreamProvider.autoDispose
    .family<List<ActivityFeedItem>, String>((ref, circleId) {
      final uid = ref.watch(authUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value([]);

      return ref.watch(activityFeedRepositoryProvider).watchFeed(circleId);
    });

// ── Removal votes ─────────────────────────────────────────────────────────────

final removalVoteRepositoryProvider = Provider<RemovalVoteRepository>((ref) {
  return FirestoreRemovalVoteRepository(
    membershipSvc: ref.read(userCircleMembershipServiceProvider),
  );
});

/// Live stream of pending removal votes for a circle.
final circleRemovalVotesProvider = StreamProvider.autoDispose
    .family<List<RemovalVote>, String>((ref, circleId) {
      final uid = ref.watch(authUidProvider);
      if (uid == null || uid.isEmpty) return Stream.value([]);

      return ref
          .watch(removalVoteRepositoryProvider)
          .watchActiveVotes(circleId);
    });
