import 'package:isar_community/isar.dart';

import '../../../features/accountability/domain/models/stake_evidence.dart';

part 'isar_stake_evidence.g.dart';

/// User-own evidence rows (M-5): written locally first, replicated via the
/// outbox to `stake_challenges/{challengeId}/evidence/{evidenceId}`.
/// Fully offline-capable — the server stamps arrival on sync (CC-5).
@collection
class IsarStakeEvidence {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String evidenceId;

  @Index()
  late String challengeId;

  @Index()
  late int updatedAtMs;

  late String uid;
  late int unitIndex;
  late int amount;
  late String source;
  late int recordedAtMs;

  static IsarStakeEvidence fromDomain(StakeEvidence e) {
    return IsarStakeEvidence()
      ..evidenceId = e.id
      ..challengeId = e.challengeId
      ..updatedAtMs = e.updatedAtMs
      ..uid = e.uid
      ..unitIndex = e.unitIndex
      ..amount = e.amount
      ..source = e.source
      ..recordedAtMs = e.recordedAtMs;
  }

  StakeEvidence toDomain() {
    return StakeEvidence(
      id: evidenceId,
      challengeId: challengeId,
      uid: uid,
      unitIndex: unitIndex,
      amount: amount,
      source: source,
      recordedAtMs: recordedAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
