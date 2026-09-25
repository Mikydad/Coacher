import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/telemetry/nonfatal.dart';
import '../data/circle_member_repository.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';
import 'circle_functions.dart';

/// Thrown when joining would exceed the user's circle-membership limit
/// (tier-dependent — see `tier_limits_v1`; legacy app-wide cap is 3).
class CircleLimitException implements Exception {
  CircleLimitException([
    this.limit = UserCircleMembershipService.kMaxCirclesPerUser,
  ]);

  final int limit;

  @override
  String toString() => limit == 1
      ? 'Free accounts can be in 1 group at a time.'
      : 'You can only be in $limit groups at a time.';
}

/// Thrown when the target circle already has 8 members.
class CircleFullException implements Exception {
  @override
  String toString() => 'This group is full (8/8 members).';
}

/// Thrown when the caller is not a moderator of the circle.
class NotModeratorException implements Exception {
  @override
  String toString() => 'Only moderators can perform this action.';
}

/// Thrown when a discovery join targets a private (invite-only) circle.
class CirclePrivateException implements Exception {
  @override
  String toString() =>
      'This group is private — ask a member for the invite key.';
}

/// Manages all circle join / leave / approval flows.
///
/// Pre-launch audit C1/M2 (decision log 2026-09-15, D8): every membership
/// mutation is a Cloud Function ([CircleFunctions]). `circles/{id}.memberCount`,
/// `circles/{id}/members/*`, and the `users/{uid}/circleIds` index are
/// server-owned and rules deny client writes, so a stranger can no longer
/// self-write an active member doc or index entry and read a private
/// circle. This service keeps the instant client-side pre-checks (limit,
/// already-a-member) so the common failures surface before a round-trip,
/// and maps the server's `reason` codes to the typed exceptions above.
class UserCircleMembershipService {
  UserCircleMembershipService({
    required CircleMemberRepository memberRepo,
    required CircleFunctions functions,
    required String Function() currentUserId,
    int Function()? maxCirclesPerUser,
    FirebaseFirestore? firestore,
  }) : _memberRepo = memberRepo,
       _functions = functions,
       _currentUserId = currentUserId,
       _maxCirclesPerUser = maxCirclesPerUser ?? (() => kMaxCirclesPerUser),
       _firestore = firestore;

  /// Legacy app-wide cap, used while tier enforcement is off (and as the
  /// default when no tier-aware callback is injected, e.g. in tests). The
  /// server enforces the same cap (`FREE_MAX_CIRCLES`) and lifts it for a
  /// server-owned Pro entitlement.
  static const int kMaxCirclesPerUser = 3;

  final CircleMemberRepository _memberRepo;
  final CircleFunctions _functions;
  final String Function() _currentUserId;
  final FirebaseFirestore? _firestore;

  /// Tier-aware membership limit; -1 = unlimited.
  final int Function() _maxCirclesPerUser;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Creates the circle document, adds the creator as active moderator, and
  /// writes the user's `circleIds` index — one server transaction.
  Future<void> createCircleWithCreator(AccountabilityCircle circle) async {
    final uid = _currentUserId();
    if (uid.isEmpty) {
      throw StateError('Not signed in');
    }
    if (circle.creatorId != uid) {
      throw ArgumentError('creatorId must match the signed-in user');
    }
    // Creating a circle also joins it — same membership limit applies.
    await _guardLimit(uid);
    circle.validate();
    await _run(() => _functions.create(circle.toMap()));
  }

  /// Repairs `users/{uid}/circleIds/{circleId}` to match the member doc
  /// (index present ⇔ active). Server-side now that the index is
  /// server-owned; genuinely safe to fire and forget: it NEVER throws.
  ///
  /// The callable is network-inherent — on a weak link it times out or the
  /// connection drops — and callers do not await it, so an escaped error
  /// became an unhandled zone error that Crashlytics filed as a FATAL
  /// (2026-09-24). Network failures are logged only (the next open repairs
  /// again); anything else is a real defect and goes to the non-fatal
  /// funnel.
  Future<void> ensureCircleIndex(String circleId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return;
    try {
      await _run(() => _functions.repairIndex(circleId));
    } on CircleActionException catch (e, st) {
      debugPrint('[Circles] repairIndex($circleId) failed: $e');
      if (!e.isRetryable && e.code != 'unknown') {
        reportNonfatal('circles.repairIndex', e, st);
      }
    } catch (e, st) {
      debugPrint('[Circles] repairIndex($circleId) failed: $e');
      reportNonfatal('circles.repairIndex', e, st);
    }
  }

  /// Join an open circle immediately. For a request-approval circle this
  /// parks the caller as `pending` (same as [requestJoin]).
  ///
  /// Throws [CircleLimitException] if the user is already at their limit,
  /// [CircleFullException] if the circle already has 8 members,
  /// [CirclePrivateException] for private (invite-only) circles.
  Future<CircleJoinResult> joinCircle(String circleId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) {
      throw StateError('Not signed in');
    }
    if (!await isActiveMember(circleId)) {
      await _guardLimit(uid);
    }
    return _run(() => _functions.join(circleId));
  }

  /// Request to join an approval-required circle.
  ///
  /// Sets member status = `pending`. Moderator must approve via [approveJoin].
  /// Throws [CircleLimitException] if already at limit.
  Future<void> requestJoin(String circleId) async {
    await joinCircle(circleId);
  }

  /// Approve a pending member (moderator only).
  ///
  /// Activates the member, increments the circle's `memberCount`, and writes
  /// the member's own index (a cross-user write only the server can make).
  Future<void> approveJoin(String circleId, String userId) =>
      _run(() => _functions.approveJoin(circleId, userId));

  /// Decline a pending join request (moderator only).
  Future<void> declineJoin(String circleId, String userId) =>
      _run(() => _functions.declineJoin(circleId, userId));

  /// Leave a circle. Decrements `memberCount` and removes the user index doc.
  Future<void> leaveCircle(String circleId) =>
      _run(() => _functions.leave(circleId));

  /// Moderator removal of another member.
  Future<void> removeMember(String circleId, String userId) =>
      _run(() => _functions.removeMember(circleId, userId));

  /// Delete a circle entirely (creator only) — every member's index, the
  /// invite key, and the whole circle tree.
  Future<void> deleteCircle(String circleId) =>
      _run(() => _functions.delete(circleId));

  /// Whether the signed-in user is an active member of [circleId].
  Future<bool> isActiveMember(String circleId) async {
    final uid = _currentUserId();
    if (uid.isEmpty) return false;
    final member = await _memberRepo.getMember(circleId, uid);
    return member?.status == CircleMemberStatus.active;
  }

  /// How many circles the current user is currently in. The index is
  /// server-owned (present ⇔ active), so its size is the count.
  Future<int> myCircleCount() async {
    final uid = _currentUserId();
    if (uid.isEmpty) return 0;
    final snap = await _db.collection(FirestorePaths.userCircleIds(uid)).get();
    return snap.size;
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  Future<void> _guardLimit(String uid) async {
    if (uid.isEmpty) {
      throw StateError('Not signed in');
    }
    final max = _maxCirclesPerUser();
    if (max < 0) return; // unlimited
    final count = await myCircleCount();
    if (count >= max) throw CircleLimitException(max);
  }

  /// Maps the server's `reason` to the typed exceptions the screens catch.
  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on CircleActionException catch (e) {
      switch (e.reason) {
        case 'circle_full':
          throw CircleFullException();
        case 'circle_limit':
          throw CircleLimitException(_maxCirclesPerUser());
        case 'invite_only':
          throw CirclePrivateException();
        case 'not_moderator':
        case 'not_creator':
        case 'cannot_remove_creator':
          throw NotModeratorException();
        default:
          rethrow;
      }
    }
  }
}
