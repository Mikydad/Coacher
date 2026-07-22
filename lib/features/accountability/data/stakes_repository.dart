import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_stake_challenge.dart';
import '../../../core/local_db/isar_collections/isar_stake_evidence.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/lww_updated_at.dart';
import '../../../core/sync/outbox_writer.dart';
import '../../../core/utils/stable_id.dart';
import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';

/// Handle over the pair of live listeners [StakesRepository.hydrateChallengeLive]
/// attaches (challenge doc + evidence subcollection). Caller cancels.
class StakeLiveHydration {
  StakeLiveHydration(this._subs);
  final List<StreamSubscription<void>> _subs;

  Future<void> cancel() async {
    for (final s in _subs) {
      await s.cancel();
    }
  }
}

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
    // Store not open (tests, pre-bootstrap frame): empty, never throw.
    final isar = OfflineStore.instance.isar;
    if (isar == null) return Stream.value(const []);
    return isar.isarStakeChallenges
        .where()
        .sortByCreatedAtMsDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  Stream<StakeChallenge?> watchChallenge(String challengeId) {
    final isar = OfflineStore.instance.isar;
    if (isar == null) return Stream.value(null);
    return isar.isarStakeChallenges
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

  /// Live hydration for ONE non-terminal challenge: the doc itself AND its
  /// evidence subcollection. Covers every transient state the background
  /// pull (start/resume/connectivity, 30 s throttle) is too slow for:
  /// photo screening (draft → active in seconds), the opponent accepting
  /// an invite (pending_accept → active), and the other side's day marks
  /// landing while both of you watch the same challenge. Snapshots merge
  /// into the Isar mirror, so the UI still renders local-first; this just
  /// hydrates the mirror at listener speed. Caller cancels.
  StakeLiveHydration hydrateChallengeLive(String challengeId) {
    final docSub = FirebaseFirestore.instance
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
    final evidenceSub = FirebaseFirestore.instance
        .collection('stake_challenges/$challengeId/evidence')
        .snapshots()
        .listen((snap) async {
      for (final doc in snap.docs) {
        await _mergeServerEvidence(doc.data(), doc.id, challengeId);
      }
    });
    return StakeLiveHydration([docSub, evidenceSub]);
  }

  /// One-shot server refresh of a challenge + its evidence — called right
  /// after a state-changing callable (accept/decline) returns, so the
  /// mirror flips before the user looks at a stale screen instead of on
  /// the next throttled pull.
  Future<void> refreshChallenge(String challengeId) async {
    final snap = await FirebaseFirestore.instance
        .doc('stake_challenges/$challengeId')
        .get();
    final data = snap.data();
    if (data != null) {
      final m = Map<String, dynamic>.from(data);
      m['id'] = snap.id;
      final incoming = StakeChallenge.fromMap(m);
      await _isar.writeTxn(() async {
        await _isar.isarStakeChallenges.putByChallengeId(
          IsarStakeChallenge.fromDomain(incoming),
        );
      });
    }
    final evidenceSnap = await FirebaseFirestore.instance
        .collection('stake_challenges/$challengeId/evidence')
        .get();
    for (final doc in evidenceSnap.docs) {
      await _mergeServerEvidence(doc.data(), doc.id, challengeId);
    }
  }

  /// Evidence rows are user-own data replicated via the outbox, so unlike
  /// the challenge doc they take the standard LWW merge (same as
  /// RemoteIsarMerge) — a pending local write never loses to an older
  /// server copy.
  Future<void> _mergeServerEvidence(
    Map<String, dynamic> data,
    String docId,
    String challengeId,
  ) async {
    try {
      final m = Map<String, dynamic>.from(data);
      m['id'] = docId;
      m['challengeId'] = challengeId;
      final incoming = StakeEvidence.fromMap(m);
      final existing = await _isar.isarStakeEvidences
          .filter()
          .evidenceIdEqualTo(incoming.id)
          .findFirst();
      if (!shouldApplyRemoteUpdatedAt(
        localUpdatedAtMs: existing?.updatedAtMs,
        remoteUpdatedAtMs: incoming.updatedAtMs,
      )) {
        return;
      }
      await _isar.writeTxn(() async {
        await _isar.isarStakeEvidences.putByEvidenceId(
          IsarStakeEvidence.fromDomain(incoming),
        );
      });
    } catch (_) {
      // Malformed row: skip, the periodic pull logs these.
    }
  }

  // ─── Evidence (user-own, offline-first) ───────────────────────────────────

  /// Every locally-mirrored evidence row, all challenges — feeds the
  /// needs-action badge (evidence volume is small: open challenges × days).
  Stream<List<StakeEvidence>> watchAllEvidence() {
    final isar = OfflineStore.instance.isar;
    if (isar == null) return Stream.value(const []);
    return isar.isarStakeEvidences
        .where()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  Stream<List<StakeEvidence>> watchEvidence(String challengeId) {
    final isar = OfflineStore.instance.isar;
    if (isar == null) return Stream.value(const []);
    return isar.isarStakeEvidences
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
