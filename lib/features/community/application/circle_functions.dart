import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when a circle membership callable fails. [reason] is the server's
/// machine-readable `details.reason` (`circle_full`, `circle_limit`,
/// `invite_only`, `not_moderator`, `not_pending`, `not_creator`,
/// `cannot_remove_creator`, `not_found`) — the UI maps it to the typed
/// exceptions in `UserCircleMembershipService` instead of string-matching.
class CircleActionException implements Exception {
  const CircleActionException(this.code, this.message, {this.reason});

  /// Firebase Functions error code (`permission-denied`, `unavailable`, …).
  final String code;
  final String message;
  final String? reason;

  bool get isRetryable => code == 'unavailable' || code == 'deadline-exceeded';

  @override
  String toString() => 'CircleActionException($code/$reason: $message)';
}

/// Result of a discovery join: open circles activate immediately,
/// request-approval circles park the caller as `pending`.
class CircleJoinResult {
  const CircleJoinResult({
    required this.circleId,
    required this.status,
    required this.alreadyMember,
  });

  final String circleId;

  /// `active` or `pending`.
  final String status;
  final bool alreadyMember;

  bool get isPending => status == 'pending';
}

/// Thin typed client for the circle membership callables
/// (functions/src/circles/callables.ts).
///
/// Pre-launch audit C1/M2 (decision log 2026-09-15, D8): membership is
/// SERVER-OWNED. Rules deny every client write to member docs, the
/// memberCount, and the `users/{uid}/circleIds` index, so the only way in
/// or out of a circle is one of these calls. They are network-inherent:
/// callers wrap them in the optimistic-then-honest envelope (spinner +
/// honest per-item error), never block a gesture silently.
class CircleFunctions {
  CircleFunctions({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      throw CircleActionException(
        e.code,
        e.message ?? 'Request failed.',
        reason: reason,
      );
    }
  }

  /// Creates the circle with the caller as active moderator and writes
  /// their index — one server transaction. [circle] is the client model's
  /// `toMap()`; the server ignores creator/count/streak fields.
  Future<String> create(Map<String, dynamic> circle) async {
    final data = await _call('circleCreate', {'circle': circle});
    return (data['circleId'] as String?) ?? (circle['id'] as String? ?? '');
  }

  /// Discovery join. Private circles refuse (`invite_only`) — use the
  /// invite key path (`CircleInviteFunctions.joinWithInvite`).
  Future<CircleJoinResult> join(String circleId) async {
    final data = await _call('circleJoin', {'circleId': circleId});
    return CircleJoinResult(
      circleId: (data['circleId'] as String?) ?? circleId,
      status: (data['status'] as String?) ?? 'active',
      alreadyMember: data['alreadyMember'] == true,
    );
  }

  Future<void> approveJoin(String circleId, String userId) =>
      _call('circleApproveJoin', {'circleId': circleId, 'userId': userId});

  Future<void> declineJoin(String circleId, String userId) =>
      _call('circleDeclineJoin', {'circleId': circleId, 'userId': userId});

  Future<void> leave(String circleId) =>
      _call('circleLeave', {'circleId': circleId});

  Future<void> removeMember(String circleId, String userId) =>
      _call('circleRemoveMember', {'circleId': circleId, 'userId': userId});

  Future<void> delete(String circleId) =>
      _call('circleDelete', {'circleId': circleId});

  /// Index present ⇔ member doc active. Returns whether the caller is an
  /// active member after the repair.
  Future<bool> repairIndex(String circleId) async {
    final data = await _call('circleRepairIndex', {'circleId': circleId});
    return data['active'] == true;
  }
}

final circleFunctionsProvider = Provider<CircleFunctions>(
  (ref) => CircleFunctions(),
);
