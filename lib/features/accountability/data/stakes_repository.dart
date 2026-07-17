import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_stake_challenge.dart';
import '../../../core/local_db/isar_collections/isar_stake_evidence.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../../core/utils/stable_id.dart';
import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';

/// Local-first reads for stake challenges + the one client-writable path
/// (evidence, M-5).
///
/// Challenges are a SERVER-OWNED mirror: this repository never writes them —
/// mutations go through [StakeFunctions] callables and come back via
/// [RemoteIsarMerge]. Evidence is user-own data: Isar first, replicated via
/// the outbox; the server stamps arrival (CC-5) and rules make it immutable.
class StakesRepository {
  StakesRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  // ─── Challenge mirror (read-only) ─────────────────────────────────────────

  Stream<List<StakeChallenge>> watchChallenges() {
    return _isar.isarStakeChallenges
        .where()
        .sortByCreatedAtMsDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  Stream<StakeChallenge?> watchChallenge(String challengeId) {
    return _isar.isarStakeChallenges
        .filter()
        .challengeIdEqualTo(challengeId)
        .watch(fireImmediately: true)
        .map((rows) => rows.isEmpty ? null : rows.first.toDomain());
  }

  /// Optimistic local insert right after a successful create callable, so
  /// the new challenge renders instantly instead of waiting for the next
  /// pull (the pull later LWW-overwrites with the server truth).
  Future<void> upsertLocalMirror(StakeChallenge challenge) async {
    await _isar.writeTxn(() async {
      await _isar.isarStakeChallenges.putByChallengeId(
        IsarStakeChallenge.fromDomain(challenge),
      );
    });
  }

  /// Live hydration for ONE challenge while a transient server-side state
  /// resolves (photo screening: the trigger flips draft → active within
  /// seconds, but the background pull runs on start/resume/connectivity
  /// and throttles to 30 s — far slower than the state itself). Snapshots
  /// LWW-merge into the Isar mirror, so the UI still renders local-first;
  /// this just hydrates the mirror at listener speed. Caller cancels.
  StreamSubscription<void> hydrateChallengeLive(String challengeId) {
    return FirebaseFirestore.instance
        .doc('stake_challenges/$challengeId')
        .snapshots()
        .listen((snap) async {
      final data = snap.data();
      if (data == null) return;
      final m = Map<String, dynamic>.from(data);
      m['id'] = snap.id;
      final incoming = StakeChallenge.fromMap(m);
      // No LWW here, deliberately: this collection is SERVER-OWNED — the
      // only client-side writes are optimistic placeholders, so a live
      // server snapshot is authoritative by definition. (LWW here once
      // let a clock-skewed placeholder outrank the real server flip and
      // the screening result never showed until a logout wipe.)
      await _isar.writeTxn(() async {
        await _isar.isarStakeChallenges.putByChallengeId(
          IsarStakeChallenge.fromDomain(incoming),
        );
      });
    });
  }

  // ─── Evidence (user-own, offline-first) ───────────────────────────────────

  Stream<List<StakeEvidence>> watchEvidence(String challengeId) {
    return _isar.isarStakeEvidences
        .filter()
        .challengeIdEqualTo(challengeId)
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  /// Records evidence for one unit: Isar commit (instant), then outbox
  /// replication. Never waits on the network. The doc id is uid-prefixed —
  /// firestore.rules requires it, so one user can never clobber another's
  /// evidence.
  Future<StakeEvidence> addEvidence({
    required String challengeId,
    required int unitIndex,
    required int amount,
    required String source,
    int? recordedAtMs,
  }) async {
    final uid = FirestorePaths.activeUid;
    final now = _now();
    final evidence = StakeEvidence(
      id: '${uid}_${unitIndex}_${StableId.generate('ev')}',
      challengeId: challengeId,
      uid: uid,
      unitIndex: unitIndex,
      amount: amount,
      source: source,
      recordedAtMs: recordedAtMs ?? now,
      updatedAtMs: now,
    );
    await _isar.writeTxn(() async {
      await _isar.isarStakeEvidences.putByEvidenceId(
        IsarStakeEvidence.fromDomain(evidence),
      );
    });
    final payload = evidence.toMap()..remove('challengeId');
    await outboxUpsert(
      entityType: 'stakeEvidence',
      documentPath: 'stake_challenges/$challengeId/evidence/${evidence.id}',
      payload: payload,
    );
    return evidence;
  }
}
