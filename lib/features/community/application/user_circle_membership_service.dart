import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../data/circle_member_repository.dart';
import '../data/circle_repository.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';
import '../domain/models/circle_member.dart';

/// Thrown when the user tries to join a 4th circle (max is 3 per user).
class CircleLimitException implements Exception {
  @override
  String toString() => 'You can only be in 3 circles at a time.';
}

/// Thrown when the target circle already has 8 members.
class CircleFullException implements Exception {
  @override
  String toString() => 'This circle is full (8/8 members).';
}

/// Thrown when the caller is not a moderator of the circle.
class NotModeratorException implements Exception {
  @override
  String toString() => 'Only moderators can perform this action.';
}

/// Manages all circle join / leave / approval flows.
///
/// Keeps `circles/{id}.memberCount` and `users/{uid}/circleIds/{circleId}`
/// in sync with `circles/{id}/members/{userId}` using Firestore batches and
/// transactions.
class UserCircleMembershipService {
  UserCircleMembershipService({
    required CircleMemberRepository memberRepo,
    required CircleRepository circleRepo,
    required String Function() currentUserId,
    required String Function() currentDisplayName,
  })  : _memberRepo = memberRepo,
        _circleRepo = circleRepo,
        _currentUserId = currentUserId,
        _currentDisplayName = currentDisplayName;

  static const int kMaxCirclesPerUser = 3;

  final CircleMemberRepository _memberRepo;
  final CircleRepository _circleRepo;
  final String Function() _currentUserId;
  final String Function() _currentDisplayName;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Join an open circle immediately.
  ///
  /// Throws [CircleLimitException] if the user is already in 3 circles.
  /// Throws [CircleFullException] if the circle already has 8 members.
  Future<void> joinCircle(String circleId) async {
    final uid = _currentUserId();
    await _guardLimit(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final circleRef =
          FirebaseFirestore.instance.doc(FirestorePaths.circleDoc(circleId));
      final circleSnap = await tx.get(circleRef);
      final circle = AccountabilityCircle.fromMap(
        Map<String, dynamic>.from(circleSnap.data() ?? {})..['id'] = circleId,
      );

      if (circle.memberCount >= AccountabilityCircle.kMaxMembers) {
        throw CircleFullException();
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final member = CircleMember(
        userId: uid,
        circleId: circleId,
        displayName: _currentDisplayName(),
        role: CircleMemberRole.member,
        status: CircleMemberStatus.active,
        joinedAtMs: now,
        updatedAtMs: now,
      );

      // Write member doc
      final memberRef = FirebaseFirestore.instance
          .doc(FirestorePaths.circleMemberDoc(circleId, uid));
      tx.set(memberRef, member.toMap(), SetOptions(merge: true));

      // Increment memberCount
      tx.update(circleRef, {'memberCount': FieldValue.increment(1)});

      // Write circleId index under user doc
      final userCircleRef = FirebaseFirestore.instance
          .doc(FirestorePaths.userCircleIdDoc(uid, circleId));
      tx.set(userCircleRef, {
        'circleId': circleId,
        'joinedAtMs': now,
      });
    });
  }

  /// Request to join an approval-required circle.
  ///
  /// Sets member status = `pending`. Moderator must approve via [approveJoin].
  /// Throws [CircleLimitException] if already at limit.
  Future<void> requestJoin(String circleId) async {
    final uid = _currentUserId();
    await _guardLimit(uid);

    final now = DateTime.now().millisecondsSinceEpoch;
    final member = CircleMember(
      userId: uid,
      circleId: circleId,
      displayName: _currentDisplayName(),
      role: CircleMemberRole.member,
      status: CircleMemberStatus.pending,
      joinedAtMs: now,
      updatedAtMs: now,
    );
    await _memberRepo.setMember(member);
  }

  /// Approve a pending member (moderator only).
  ///
  /// Activates the member and increments the circle's `memberCount`.
  Future<void> approveJoin(String circleId, String userId) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final circleRef =
          FirebaseFirestore.instance.doc(FirestorePaths.circleDoc(circleId));
      final circleSnap = await tx.get(circleRef);
      final circle = AccountabilityCircle.fromMap(
        Map<String, dynamic>.from(circleSnap.data() ?? {})..['id'] = circleId,
      );

      if (circle.memberCount >= AccountabilityCircle.kMaxMembers) {
        throw CircleFullException();
      }

      final memberRef = FirebaseFirestore.instance
          .doc(FirestorePaths.circleMemberDoc(circleId, userId));
      final now = DateTime.now().millisecondsSinceEpoch;

      tx.update(memberRef, {
        'status': CircleMemberStatus.active.storageValue,
        'updatedAtMs': now,
      });
      tx.update(circleRef, {'memberCount': FieldValue.increment(1)});

      // Write circleId index under user doc
      final userCircleRef = FirebaseFirestore.instance
          .doc(FirestorePaths.userCircleIdDoc(userId, circleId));
      tx.set(userCircleRef, {
        'circleId': circleId,
        'joinedAtMs': now,
      });
    });
  }

  /// Decline a pending join request.
  Future<void> declineJoin(String circleId, String userId) async {
    await _memberRepo.deleteMember(circleId, userId);
  }

  /// Leave a circle. Decrements `memberCount` and removes the user index doc.
  Future<void> leaveCircle(String circleId) async {
    final uid = _currentUserId();
    await _removeMemberInternal(circleId, uid);
  }

  /// Direct removal — Phase 1: creator only.
  Future<void> removeMember(String circleId, String userId) async {
    await _removeMemberInternal(circleId, userId);
  }

  /// Delete a circle entirely (creator only).
  ///
  /// Removes every member's `circleIds` index entry, deletes all member docs,
  /// and finally deletes the circle document itself.
  Future<void> deleteCircle(String circleId) async {
    final uid = _currentUserId();

    // Fetch all member docs so we can clean up every user's index.
    final membersSnap = await FirebaseFirestore.instance
        .collection(FirestorePaths.circleMembers(circleId))
        .get();

    final db = FirebaseFirestore.instance;

    // Firestore batch writes are limited to 500 ops; circles cap at 8 members
    // so a single batch is always sufficient.
    final batch = db.batch();

    for (final doc in membersSnap.docs) {
      final memberId = doc.id;
      // Remove the circleId index under each member's user doc.
      batch.delete(db.doc(FirestorePaths.userCircleIdDoc(memberId, circleId)));
      // Delete the member document itself.
      batch.delete(
          db.doc(FirestorePaths.circleMemberDoc(circleId, memberId)));
    }

    // Also ensure the creator's own index is removed (covers edge cases where
    // the creator is not in the members subcollection).
    batch.delete(db.doc(FirestorePaths.userCircleIdDoc(uid, circleId)));

    await batch.commit();

    // Delete the top-level circle document.
    await _circleRepo.deleteCircle(circleId);
  }

  /// How many circles the current user is currently in (active only).
  Future<int> myCircleCount() async {
    final uid = _currentUserId();
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.userCircleIds(uid))
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  Future<void> _guardLimit(String uid) async {
    final count = await myCircleCount();
    if (count >= kMaxCirclesPerUser) throw CircleLimitException();
  }

  Future<void> _removeMemberInternal(String circleId, String userId) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final circleRef =
          FirebaseFirestore.instance.doc(FirestorePaths.circleDoc(circleId));
      final memberRef = FirebaseFirestore.instance
          .doc(FirestorePaths.circleMemberDoc(circleId, userId));
      final userCircleRef = FirebaseFirestore.instance
          .doc(FirestorePaths.userCircleIdDoc(userId, circleId));

      tx.update(memberRef, {
        'status': CircleMemberStatus.removed.storageValue,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });
      tx.update(circleRef, {'memberCount': FieldValue.increment(-1)});
      tx.delete(userCircleRef);
    });
  }
}
