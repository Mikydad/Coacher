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

  /// Creates the circle document, adds the creator as active moderator, and
  /// writes the user's `circleIds` index in a single batch (all or nothing).
  Future<void> createCircleWithCreator(AccountabilityCircle circle) async {
    final uid = _currentUserId();
    if (uid.isEmpty) {
      throw StateError('Not signed in');
    }
    if (circle.creatorId != uid) {
      throw ArgumentError('creatorId must match the signed-in user');
    }

    circle.validate();
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = FirebaseFirestore.instance;

    final member = CircleMember(
      userId: uid,
      circleId: circle.id,
      displayName: _currentDisplayName(),
      role: CircleMemberRole.moderator,
      status: CircleMemberStatus.active,
      joinedAtMs: now,
      updatedAtMs: now,
    );

    final batch = db.batch();
    batch.set(db.doc(FirestorePaths.circleDoc(circle.id)), circle.toMap());
    batch.set(
      db.doc(FirestorePaths.circleMemberDoc(circle.id, uid)),
      member.toMap(),
    );
    batch.set(
      db.doc(FirestorePaths.userCircleIdDoc(uid, circle.id)),
      {'circleId': circle.id, 'joinedAtMs': now},
    );
    await batch.commit();
  }

  /// Ensures `users/{uid}/circleIds/{circleId}` exists when the user is already
  /// an active member (repairs partial creates or legacy data).
  Future<void> ensureCircleIndex(String circleId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;

    final member = await _memberRepo.getMember(circleId, uid);
    if (member == null || member.status != CircleMemberStatus.active) return;

    await FirebaseFirestore.instance
        .doc(FirestorePaths.userCircleIdDoc(uid, circleId))
        .set({
      'circleId': circleId,
      'joinedAtMs': member.joinedAtMs,
    }, SetOptions(merge: true));
  }

  /// Join an open circle immediately.
  ///
  /// Throws [CircleLimitException] if the user is already in 3 circles.
  /// Throws [CircleFullException] if the circle already has 8 members.
  Future<void> joinCircle(String circleId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) {
      throw StateError('Not signed in');
    }
    await pruneStaleCircleIndexes();
    await _guardLimit(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final circleRef =
          FirebaseFirestore.instance.doc(FirestorePaths.circleDoc(circleId));
      final memberRef =
          FirebaseFirestore.instance.doc(FirestorePaths.circleMemberDoc(circleId, uid));
      final userCircleRef = FirebaseFirestore.instance
          .doc(FirestorePaths.userCircleIdDoc(uid, circleId));

      final circleSnap = await tx.get(circleRef);
      final circle = AccountabilityCircle.fromMap(
        Map<String, dynamic>.from(circleSnap.data() ?? {})..['id'] = circleId,
      );

      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) {
        final existingData = Map<String, dynamic>.from(memberSnap.data() ?? {});
        existingData['userId'] = uid;
        final existing = CircleMember.fromMap(existingData);
        if (existing.status == CircleMemberStatus.active) {
          // Already a member — repair index only, do not bump memberCount.
          tx.set(userCircleRef, {
            'circleId': circleId,
            'joinedAtMs': existing.joinedAtMs,
          });
          return;
        }
      }

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

      tx.set(memberRef, member.toMap(), SetOptions(merge: true));
      tx.update(circleRef, {'memberCount': FieldValue.increment(1)});
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

  /// Whether the signed-in user is an active member of [circleId].
  Future<bool> isActiveMember(String circleId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return false;
    final member = await _memberRepo.getMember(circleId, uid);
    return member?.status == CircleMemberStatus.active;
  }

  /// Removes `users/{uid}/circleIds/*` entries that no longer reflect active
  /// membership (e.g. after deleting a circle or a failed partial join).
  Future<void> pruneStaleCircleIndexes() async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.userCircleIds(uid))
        .get();

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    var writes = 0;

    for (final doc in snap.docs) {
      final circleId = doc.id;
      final member = await _memberRepo.getMember(circleId, uid);
      final circle = await _circleRepo.getCircle(circleId);

      final keepIndex = member?.status == CircleMemberStatus.active &&
          circle != null;
      if (!keepIndex) {
        batch.delete(doc.reference);
        writes++;
      }
    }

    if (writes > 0) {
      await batch.commit();
    }
  }

  /// How many circles the current user is currently in (active only).
  Future<int> myCircleCount() async {
    final uid = _currentUserId();
    if (uid.isEmpty) return 0;

    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.userCircleIds(uid))
        .get();

    var count = 0;
    for (final doc in snap.docs) {
      final member = await _memberRepo.getMember(doc.id, uid);
      if (member?.status == CircleMemberStatus.active) {
        count++;
      }
    }
    return count;
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  Future<void> _guardLimit(String uid) async {
    if (uid.isEmpty) {
      throw StateError('Not signed in');
    }
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
