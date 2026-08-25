import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when an invite callable fails — carries the server's error code
/// so the UI can tell "bad key" / "circle full" from network failures.
class CircleInviteException implements Exception {
  const CircleInviteException(this.code, this.message);

  final String code;
  final String message;

  bool get isRetryable => code == 'unavailable' || code == 'deadline-exceeded';

  @override
  String toString() => 'CircleInviteException($code: $message)';
}

/// What [CircleInviteFunctions.joinWithInvite] resolved to.
class CircleInviteJoinResult {
  const CircleInviteJoinResult({
    required this.circleId,
    required this.name,
    required this.alreadyMember,
  });

  final String circleId;
  final String name;
  final bool alreadyMember;
}

/// Thin typed client for the circle invite callables
/// (functions/src/circles/) — the invite KEY is verified server-side; the
/// client never sees or stores the key registry. Network-inherent:
/// callers wrap these in the optimistic-then-honest envelope (spinner +
/// honest per-item error), never block a gesture silently.
class CircleInviteFunctions {
  CircleInviteFunctions({FirebaseFunctions? functions})
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
      throw CircleInviteException(e.code, e.message ?? 'Request failed.');
    }
  }

  /// The circle's invite key — minted on demand. Any active member may
  /// fetch it; [regenerate] is moderator-only and revokes the old key.
  Future<String> inviteCode(
    String circleId, {
    bool regenerate = false,
  }) async {
    final data = await _call('circleInvite', {
      'circleId': circleId,
      'regenerate': regenerate,
    });
    return (data['code'] as String?) ?? '';
  }

  /// Joins the circle the key belongs to — the key IS the approval, so
  /// this works for private and approval-required circles too.
  Future<CircleInviteJoinResult> joinWithInvite(String code) async {
    final data = await _call('circleJoinWithInvite', {'code': code});
    return CircleInviteJoinResult(
      circleId: (data['circleId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      alreadyMember: data['alreadyMember'] == true,
    );
  }
}

final circleInviteFunctionsProvider = Provider<CircleInviteFunctions>(
  (ref) => CircleInviteFunctions(),
);
