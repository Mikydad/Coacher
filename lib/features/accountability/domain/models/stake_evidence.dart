/// One evidence record for one unit of a stake challenge — the ONLY part of
/// a challenge the client writes directly (user-own data, Isar + outbox to
/// `stake_challenges/{challengeId}/evidence/{id}`, rules-validated).
///
/// The server arrival stamp (`arrivedAtMs`, CC-5) is added by a Cloud
/// Function trigger on creation — the client never sets it, and the outcome
/// engine ignores evidence without it.
class StakeEvidence {
  const StakeEvidence({
    required this.id,
    required this.challengeId,
    required this.uid,
    required this.unitIndex,
    required this.amount,
    required this.source,
    required this.recordedAtMs,
    required this.updatedAtMs,
  });

  /// Client StableId; also the Firestore doc id (`{uid}_{unitIndex}_{suffix}`
  /// layout is enforced by rules so one user cannot clobber another's docs).
  final String id;
  final String challengeId;
  final String uid;

  /// 0-based unit (day) index within the challenge window.
  final int unitIndex;

  /// Minutes or count, per the challenge's frozen goal unitKind.
  final int amount;

  /// `'timer' | 'camera' | 'checkin'` (M-5).
  final String source;

  /// Client capture time — offline-capable, informational.
  final int recordedAtMs;
  final int updatedAtMs;

  factory StakeEvidence.fromMap(Map<String, dynamic> m) => StakeEvidence(
        id: (m['id'] as String?) ?? '',
        challengeId: (m['challengeId'] as String?) ?? '',
        uid: (m['uid'] as String?) ?? '',
        unitIndex: (m['unitIndex'] as num?)?.toInt() ?? 0,
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        source: (m['source'] as String?) ?? 'timer',
        recordedAtMs: (m['recordedAtMs'] as num?)?.toInt() ?? 0,
        updatedAtMs: (m['updatedAtMs'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'challengeId': challengeId,
        'uid': uid,
        'unitIndex': unitIndex,
        'amount': amount,
        'source': source,
        'recordedAtMs': recordedAtMs,
        'updatedAtMs': updatedAtMs,
      };
}
