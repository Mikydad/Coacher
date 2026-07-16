import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/utils/stable_id.dart';

/// Thrown when a stake callable fails — carries the server's error code so
/// the UI can distinguish "banned" / "window closed" from network failures.
class StakeActionException implements Exception {
  const StakeActionException(this.code, this.message);

  /// Firebase Functions error code (`permission-denied`,
  /// `failed-precondition`, `unavailable`, …).
  final String code;
  final String message;

  bool get isRetryable => code == 'unavailable' || code == 'deadline-exceeded';

  @override
  String toString() => 'StakeActionException($code: $message)';
}

/// Thin typed client for the stake callables (functions/src/stakes/).
///
/// Stakes are NETWORK-INHERENT (PRD §7.1): these calls need the server,
/// so callers wrap them in the optimistic-then-honest envelope — show the
/// pending state instantly, reconcile on ack, per-item error + retry on
/// genuine failure. Never block a gesture on these futures.
class StakeFunctions {
  StakeFunctions({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<T> _call<T>(String name, Map<String, dynamic> data) async {
    try {
      final result =
          await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return result.data as T;
    } on FirebaseFunctionsException catch (e) {
      throw StakeActionException(e.code, e.message ?? 'Request failed.');
    }
  }

  /// Creates a challenge; returns its id. For photo stakes the photo must
  /// already be uploaded to `stake_photos/{id}/{uid}.jpg` (owner-only path)
  /// before calling — pass the same client-generated [challengeId].
  /// For h2h: [opponentUid], [stakeAmount], [charityId] (your side's loved
  /// pick, D5) and [bothLoseCharityId] (D6) are required.
  Future<String> createChallenge({
    String? challengeId,
    required String type,
    required String circleId,
    required Map<String, dynamic> goal,
    required String mode,
    required int deadlineMs,
    Map<String, dynamic>? photo,
    String? opponentUid,
    int? stakeAmount,
    String? charityId,
    String? bothLoseCharityId,
    required String pledgeWhy,
  }) async {
    final id = challengeId ?? StableId.generate('stk');
    await _call<Map<String, dynamic>>('stakeCreateChallenge', {
      'id': id,
      'type': type,
      'circleId': circleId,
      'goal': goal,
      'mode': mode,
      'deadlineMs': deadlineMs,
      'photo': ?photo,
      'opponentUid': ?opponentUid,
      'stakeAmount': ?stakeAmount,
      'charityId': ?charityId,
      'bothLoseCharityId': ?bothLoseCharityId,
      'pledge': {'why': pledgeWhy},
    });
    return id;
  }

  /// PT-4 — accept an h2h invite; locks BOTH stakes atomically.
  /// [charityId] is your side's loved pick (D5).
  Future<void> acceptChallenge({
    required String challengeId,
    required String charityId,
  }) =>
      _call<Map<String, dynamic>>('stakeAcceptChallenge', {
        'challengeId': challengeId,
        'charityId': charityId,
      });

  Future<void> declineChallenge(String challengeId) =>
      _call<Map<String, dynamic>>('stakeDeclineChallenge', {
        'challengeId': challengeId,
      });

  /// P-5/D9 — early takedown of a live reveal (30% floor, 300 points).
  Future<void> removePhoto(String challengeId) =>
      _call<Map<String, dynamic>>('stakeRemovePhoto', {
        'challengeId': challengeId,
      });

  Future<void> cancelDraft(String challengeId) =>
      _call<Map<String, dynamic>>('stakeCancelDraft', {'challengeId': challengeId});

  /// M-6 — request the monthly mercy veto (photo stakes only, applied at
  /// decision time; the loss is still recorded).
  Future<void> applyVeto(String challengeId) =>
      _call<Map<String, dynamic>>('stakeApplyVeto', {'challengeId': challengeId});

  /// V-2 — confirm or dispute another participant's completion.
  Future<void> confirmOutcome({
    required String challengeId,
    required String aboutUid,
    required bool dispute,
  }) =>
      _call<Map<String, dynamic>>('stakeConfirmOutcome', {
        'challengeId': challengeId,
        'aboutUid': aboutUid,
        'kind': dispute ? 'dispute' : 'confirm',
      });

  /// V-3 — circle member's vote on a disputed participant.
  Future<void> castVote({
    required String challengeId,
    required String aboutUid,
    required bool pass,
  }) =>
      _call<Map<String, dynamic>>('stakeCastVote', {
        'challengeId': challengeId,
        'aboutUid': aboutUid,
        'pass': pass,
      });

  /// P-6/P-7 — self-report from the offending device's iOS screenshot
  /// detection. Returns nothing the offender gets to negotiate with.
  Future<void> reportScreenshot(String challengeId) =>
      _call<Map<String, dynamic>>('stakeReportScreenshot', {'challengeId': challengeId});

  /// P-8 — report a revealed photo (hidden pending review).
  Future<void> reportPhoto(String challengeId) =>
      _call<Map<String, dynamic>>('stakeReportPhoto', {'challengeId': challengeId});
}
