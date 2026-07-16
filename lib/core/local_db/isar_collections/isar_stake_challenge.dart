import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/accountability/domain/models/stake_challenge.dart';

part 'isar_stake_challenge.g.dart';

/// Read-only mirror of `stake_challenges/{id}` (server-owned; hydrated by
/// [RemoteIsarMerge], LWW on [updatedAtMs]). The client NEVER writes this
/// doc remotely — mutations go through `StakeFunctions` callables; this row
/// only makes the challenge readable offline.
///
/// Nested structures (participants, results) are stored as JSON strings:
/// mirrors need no field-level queries on them.
@collection
class IsarStakeChallenge {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String challengeId;

  @Index()
  late int updatedAtMs;

  late String typeStorage;

  @Index()
  late String statusStorage;

  late String creatorUid;
  late String circleId;
  late String participantsJson;
  late String frozenGoalJson;
  String? mode;

  /// JSON map teamId → charityId (D5); empty string when absent.
  late String sideCharitiesJson;
  String? bothLoseCharityId;
  String? antiCharityId;

  /// JSON map uid → donation receipt ($-3); empty string when absent.
  late String receiptsJson;
  late int deadlineMs;

  String? photoStateStorage;
  int? revealedAtMs;
  int? revealExpiresAtMs;

  int? decidedAtMs;

  /// JSON list of per-participant results; empty string until decided.
  late String resultsJson;

  late int createdAtMs;

  static IsarStakeChallenge fromDomain(StakeChallenge c) {
    return IsarStakeChallenge()
      ..challengeId = c.id
      ..updatedAtMs = c.updatedAtMs
      ..typeStorage = c.type.storageValue
      ..statusStorage = c.status.storageValue
      ..creatorUid = c.creatorUid
      ..circleId = c.circleId
      ..participantsJson = StakeChallenge.participantsToJson(c.participants)
      ..frozenGoalJson = jsonEncode(c.frozenGoal.toMap())
      ..mode = c.mode
      ..sideCharitiesJson =
          c.sideCharities.isEmpty ? '' : jsonEncode(c.sideCharities)
      ..bothLoseCharityId = c.bothLoseCharityId
      ..antiCharityId = c.antiCharityId
      ..receiptsJson = c.receipts.isEmpty
          ? ''
          : jsonEncode(
              c.receipts.map((k, v) => MapEntry(k, v.toMap())),
            )
      ..deadlineMs = c.deadlineMs
      ..photoStateStorage = c.photoState?.storageValue
      ..revealedAtMs = c.revealedAtMs
      ..revealExpiresAtMs = c.revealExpiresAtMs
      ..decidedAtMs = c.decidedAtMs
      ..resultsJson = c.results.isEmpty
          ? ''
          : jsonEncode(c.results.map((r) => r.toMap()).toList())
      ..createdAtMs = c.createdAtMs;
  }

  StakeChallenge toDomain() {
    final results = resultsJson.isEmpty
        ? const <StakeParticipantResult>[]
        : (jsonDecode(resultsJson) as List)
            .whereType<Map<String, dynamic>>()
            .map(StakeParticipantResult.fromMap)
            .toList();
    return StakeChallenge(
      id: challengeId,
      type: StakeChallengeType.fromStorage(typeStorage),
      status: StakeChallengeStatus.fromStorage(statusStorage),
      creatorUid: creatorUid,
      circleId: circleId,
      participants: StakeChallenge.participantsFromJson(participantsJson),
      frozenGoal: StakeFrozenGoal.fromMap(
          (jsonDecode(frozenGoalJson) as Map).cast<String, dynamic>()),
      mode: mode,
      sideCharities: sideCharitiesJson.isEmpty
          ? const {}
          : (jsonDecode(sideCharitiesJson) as Map)
              .map((k, v) => MapEntry('$k', '$v')),
      bothLoseCharityId: bothLoseCharityId,
      antiCharityId: antiCharityId,
      receipts: receiptsJson.isEmpty
          ? const {}
          : {
              for (final e in ((jsonDecode(receiptsJson) as Map)
                      .cast<String, dynamic>())
                  .entries)
                if (e.value is Map)
                  e.key: StakeDonationReceipt.fromMap(
                      (e.value as Map).cast<String, dynamic>()),
            },
      deadlineMs: deadlineMs,
      photoState: StakePhotoState.fromStorage(photoStateStorage),
      revealedAtMs: revealedAtMs,
      revealExpiresAtMs: revealExpiresAtMs,
      decidedAtMs: decidedAtMs,
      results: results,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs,
    );
  }
}
