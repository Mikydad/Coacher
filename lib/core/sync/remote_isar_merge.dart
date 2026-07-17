import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// Query below always means the Firestore one (_afterCursor).
import 'package:isar_community/isar.dart' hide Query;

import '../../features/goals/domain/models/goal_action.dart';
import '../../features/goals/domain/models/goal_check_in.dart';
import '../../features/goals/domain/models/goal_milestone.dart';
import '../../features/goals/domain/models/user_goal.dart';
import '../../features/analytics/domain/models/analytics_event.dart';
import '../../features/analytics/domain/models/analytics_stats_cache.dart';
import '../../features/planning/domain/models/block.dart';
import '../../features/planning/domain/models/routine.dart';
import '../../features/onboarding/domain/models/onboarding_profile.dart';
import '../../features/accountability/domain/models/points.dart';
import '../../features/accountability/domain/models/stake_challenge.dart';
import '../../features/accountability/domain/models/stake_evidence.dart';
import '../../features/planning/domain/models/task_item.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/domain/models/reminder_config.dart';
import '../firebase/firestore_client.dart';
import '../local_db/isar_collections/isar_block.dart';
import '../local_db/isar_collections/isar_analytics_event.dart';
import '../local_db/isar_collections/isar_analytics_stats.dart';
import '../local_db/isar_collections/isar_goal.dart';
import '../local_db/isar_collections/isar_goal_action.dart';
import '../local_db/isar_collections/isar_goal_check_in.dart';
import '../local_db/isar_collections/isar_goal_milestone.dart';
import '../local_db/isar_collections/isar_onboarding_profile.dart';
import '../local_db/isar_collections/isar_reminder.dart';
import '../local_db/isar_collections/isar_blocked_user.dart';
import '../local_db/isar_collections/isar_points.dart';
import '../local_db/isar_collections/isar_routine.dart';
import '../local_db/isar_collections/isar_stake_challenge.dart';
import '../local_db/isar_collections/isar_stake_evidence.dart';
import 'isar_lww_merge.dart';
import 'lww_updated_at.dart';
import 'sync_cursor_store.dart';

String _docFieldId(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  Map<String, dynamic> data, [
  String key = 'id',
]) {
  final v = data[key];
  if (v is String && v.trim().isNotEmpty) return v.trim();
  if (v != null && '$v'.trim().isNotEmpty) return '$v'.trim();
  return doc.id;
}

/// Pulls Firestore planning, reminders, and goals into Isar using last-write-wins on [updatedAtMs].
///
/// The uid is pinned once at construction (via [FirestoreClient]) so every
/// collection in a single pull reads from the same user tree — never a mix of
/// two accounts when auth changes mid-pull. If the signed-in uid changes while
/// the pull is running, the pull aborts before the next phase.
///
/// ## Incremental pulls (AUDIT §7 P1)
///
/// Task, reminder, goal, and analytics queries are filtered by a
/// per-collection cursor (`updatedAtMs > lastMerged`, [SyncCursorStore]) so
/// the periodic pull no longer re-reads the whole account. Routines and
/// blocks are still walked in full — they are the cheap "skeleton", and
/// filtering them would skip descending into unchanged parents and miss task
/// edits underneath. Single-field ranges need no composite index (see
/// errors.md #16/#18 before adding any orderBy here).
///
/// [ignoreCursors] (force pull) reads everything; cursors still advance
/// afterwards. Cursor pulls cannot observe remote deletions — but the merge
/// never deletes locally either (LWW upsert only), so behavior is unchanged
/// and a force pull remains the reconcile escape hatch. Known edge: a second
/// device with a skewed-back clock can write updatedAtMs below the cursor;
/// such a doc is only picked up by a force pull.
class RemoteIsarMerge {
  RemoteIsarMerge(
    this._isar, {
    FirestoreClient? client,
    SyncCursorStore? cursorStore,
    this.ignoreCursors = false,
  }) : _client = client ?? FirestoreClient(),
       _cursors = cursorStore ?? const SyncCursorStore();

  final Isar _isar;
  final FirestoreClient _client;
  final SyncCursorStore _cursors;
  final bool ignoreCursors;

  /// Max updatedAtMs seen per cursor key this pull; flushed on success only.
  final Map<String, int> _maxSeen = {};

  /// Rows actually written this pull (LWW no-ops excluded). Lets callers skip
  /// the post-sync provider refresh when the pull changed nothing — the
  /// common case for the periodic 30s pull.
  int _appliedCount = 0;

  /// Goal ids first seen by this pull (no local row before merge). Their
  /// subcollections are hydrated without cursors — see
  /// [_pullGoalSubcollections].
  final Set<String> _newLocalGoalIds = {};

  Future<int> _cursorFor(String key) async =>
      ignoreCursors ? 0 : _cursors.read(key);

  Query<Map<String, dynamic>> _afterCursor(
    Query<Map<String, dynamic>> query,
    int cursor,
  ) => cursor > 0 ? query.where('updatedAtMs', isGreaterThan: cursor) : query;

  void _noteSeen(String key, int updatedAtMs) {
    if (updatedAtMs > (_maxSeen[key] ?? 0)) _maxSeen[key] = updatedAtMs;
  }

  bool get _uidStillCurrent {
    if (Firebase.apps.isEmpty) return true; // VM tests — no auth to compare
    return FirebaseAuth.instance.currentUser?.uid == _client.uid;
  }

  void _abortIfUidChanged() {
    if (!_uidStillCurrent) {
      throw StateError(
        'RemoteIsarMerge: signed-in uid changed mid-pull — aborting to avoid '
        'writing another account\'s data into local Isar.',
      );
    }
  }

  /// Returns true when at least one row was applied to Isar.
  Future<bool> run() async {
    await _pullRoutinesBlocksTasks();
    _abortIfUidChanged();
    await _pullReminders();
    _abortIfUidChanged();
    await _pullGoals();
    _abortIfUidChanged();
    await _pullGoalSubcollections();
    _abortIfUidChanged();
    await _pullAnalytics();
    _abortIfUidChanged();
    await _pullOnboardingProfile();
    _abortIfUidChanged();
    // Stakes-era phases are individually fault-tolerant: until the stakes
    // backend is deployed (rules + functions — see PHASE3/deploy notes),
    // these queries come back permission-denied on the live project, and
    // one denied mirror must NOT abort the whole account sync. A failed
    // phase discards its own cursor advancement and is retried next pull.
    await _pullGuarded('stake challenges', _pullStakeChallenges);
    _abortIfUidChanged();
    await _pullGuarded('blocked users', _pullBlockedUsers);
    _abortIfUidChanged();
    await _pullGuarded('points ledger', _pullPointsLedger,
        cursorKey: 'points_txns');
    _abortIfUidChanged();
    await _pullGuarded('charities', _pullCharities);
    // Only reached when every phase succeeded — safe to advance cursors.
    for (final entry in _maxSeen.entries) {
      await _cursors.advance(entry.key, entry.value);
    }
    debugPrint('RemoteIsarMerge: pull finished ($_appliedCount rows applied)');
    return _appliedCount > 0;
  }

  Future<void> _pullRoutinesBlocksTasks() async {
    final routinesCol = _client.userCollection('routines');
    // Routines and blocks are walked in FULL on purpose: filtering the
    // skeleton would skip descending into unchanged parents and miss task
    // edits underneath. Only the leaf task queries use the cursor.
    final tasksCursor = await _cursorFor('tasks');
    final routinesSnap = await routinesCol.get();
    for (final doc in routinesSnap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = _docFieldId(doc, m);
        final routine = Routine.fromMap(m);
        await _mergeRoutine(routine);
        final routineId = routine.id;
        final blocksSnap = await routinesCol
            .doc(routineId)
            .collection('blocks')
            .get();
        for (final bDoc in blocksSnap.docs) {
          try {
            final bm = Map<String, dynamic>.from(bDoc.data());
            bm['id'] = _docFieldId(bDoc, bm);
            final rid = bm['routineId'];
            bm['routineId'] = rid is String && rid.trim().isNotEmpty
                ? rid.trim()
                : routineId;
            final block = TaskBlock.fromMap(bm);
            await _mergeBlock(block);
            final tasksSnap = await _afterCursor(
              routinesCol
                  .doc(routineId)
                  .collection('blocks')
                  .doc(block.id)
                  .collection('tasks'),
              tasksCursor,
            ).get();
            for (final tDoc in tasksSnap.docs) {
              try {
                final tm = Map<String, dynamic>.from(tDoc.data());
                tm['id'] = _docFieldId(tDoc, tm);
                final tr = tm['routineId'];
                tm['routineId'] = tr is String && tr.trim().isNotEmpty
                    ? tr.trim()
                    : routineId;
                final tb = tm['blockId'];
                tm['blockId'] = tb is String && tb.trim().isNotEmpty
                    ? tb.trim()
                    : block.id;
                final task = PlannedTask.fromMap(tm);
                _noteSeen('tasks', task.updatedAtMs);
                await _mergeTask(task);
              } catch (e, st) {
                debugPrint('RemoteIsarMerge: skip task ${tDoc.id}: $e\n$st');
              }
            }
          } catch (e, st) {
            debugPrint('RemoteIsarMerge: skip block ${bDoc.id}: $e\n$st');
          }
        }
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip routine ${doc.id}: $e\n$st');
      }
    }
  }

  Future<void> _pullReminders() async {
    // Use the pinned client (not FirestorePaths, which resolves the uid at
    // call time) so a mid-pull account switch can't mix user trees.
    final cursor = await _cursorFor('reminders');
    final snap = await _afterCursor(
      _client.userCollection('reminders'),
      cursor,
    ).get();
    for (final doc in snap.docs) {
      try {
        final r = reminderConfigFromFirestoreDoc(doc);
        _noteSeen('reminders', r.updatedAtMs);
        await _mergeReminder(r);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip reminder ${doc.id}: $e\n$st');
      }
    }
  }

  Future<void> _pullGoals() async {
    final cursor = await _cursorFor('goals');
    final snap = await _afterCursor(
      _client.userCollection('goals'),
      cursor,
    ).get();
    for (final doc in snap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = _docFieldId(doc, m);
        final g = UserGoal.fromMap(m);
        _noteSeen('goals', g.updatedAtMs);
        await _mergeGoal(g);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip goal ${doc.id}: $e\n$st');
      }
    }
  }

  /// Hydrates goal subcollections (actions / milestones / check-ins) into
  /// their Isar mirrors so goal detail renders and mutates fully offline.
  ///
  /// Walks goals present in LOCAL Isar (a goal deleted locally is never
  /// resurrected through its subdocuments). Goals that just appeared this
  /// pull ([_newLocalGoalIds]) are read without cursors — their historical
  /// subdocuments predate any cursor watermark; everything else uses the
  /// shared per-collection cursor.
  Future<void> _pullGoalSubcollections() async {
    // Active goals only, plus anything that just appeared this pull — paused
    // and completed goals were hydrated while they were live, and walking
    // them every periodic pull would grow with archive size. A force pull
    // (ignoreCursors) walks everything as the reconcile escape hatch.
    final activeIds = await _isar.isarGoals
        .filter()
        .statusStorageEqualTo('active')
        .goalIdProperty()
        .findAll();
    final goalIds = ignoreCursors
        ? await _isar.isarGoals.where().goalIdProperty().findAll()
        : {...activeIds, ..._newLocalGoalIds}.toList();
    if (goalIds.isEmpty) return;

    final actionsCursor = await _cursorFor('goal_actions');
    final milestonesCursor = await _cursorFor('goal_milestones');
    final checkInsCursor = await _cursorFor('goal_check_ins');
    final goalsCol = _client.userCollection('goals');

    for (final goalId in goalIds) {
      _abortIfUidChanged();
      final isNewLocally = _newLocalGoalIds.contains(goalId);
      final goalDoc = goalsCol.doc(goalId);

      try {
        final snap = await _afterCursor(
          goalDoc.collection('actions'),
          isNewLocally ? 0 : actionsCursor,
        ).get();
        for (final doc in snap.docs) {
          try {
            final m = Map<String, dynamic>.from(doc.data());
            m['id'] = _docFieldId(doc, m);
            m['goalId'] = goalId;
            final a = GoalAction.fromMap(m);
            _noteSeen('goal_actions', a.updatedAtMs);
            await _mergeGoalAction(a);
          } catch (e, st) {
            debugPrint('RemoteIsarMerge: skip goal action ${doc.id}: $e\n$st');
          }
        }
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip actions of $goalId: $e\n$st');
      }

      try {
        final snap = await _afterCursor(
          goalDoc.collection('milestones'),
          isNewLocally ? 0 : milestonesCursor,
        ).get();
        for (final doc in snap.docs) {
          try {
            final m = Map<String, dynamic>.from(doc.data());
            m['id'] = _docFieldId(doc, m);
            m['goalId'] = goalId;
            final ms = GoalMilestone.fromMap(m);
            _noteSeen('goal_milestones', ms.updatedAtMs);
            await _mergeGoalMilestone(ms);
          } catch (e, st) {
            debugPrint(
              'RemoteIsarMerge: skip goal milestone ${doc.id}: $e\n$st',
            );
          }
        }
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip milestones of $goalId: $e\n$st');
      }

      try {
        final snap = await _afterCursor(
          goalDoc.collection('checkIns'),
          isNewLocally ? 0 : checkInsCursor,
        ).get();
        for (final doc in snap.docs) {
          try {
            final m = Map<String, dynamic>.from(doc.data());
            m['goalId'] = goalId;
            m['dateKey'] = (m['dateKey'] as String?) ?? doc.id;
            final c = GoalCheckIn.fromMap(m);
            _noteSeen('goal_check_ins', c.updatedAtMs);
            await _mergeGoalCheckIn(c);
          } catch (e, st) {
            debugPrint(
              'RemoteIsarMerge: skip goal check-in ${doc.id}: $e\n$st',
            );
          }
        }
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip check-ins of $goalId: $e\n$st');
      }
    }
  }

  Future<void> _pullAnalytics() async {
    final eventsCursor = await _cursorFor('analytics_events');
    final eventsSnap = await _afterCursor(
      _client.userCollection('analytics_events'),
      eventsCursor,
    ).get();
    for (final doc in eventsSnap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = _docFieldId(doc, m);
        final event = AnalyticsEvent.fromMap(m);
        _noteSeen('analytics_events', event.updatedAtMs);
        await _mergeAnalyticsEvent(event);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip analytics event ${doc.id}: $e\n$st');
      }
    }

    final statsCursor = await _cursorFor('analytics_stats');
    final statsSnap = await _afterCursor(
      _client.userCollection('analytics_stats'),
      statsCursor,
    ).get();
    for (final doc in statsSnap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = _docFieldId(doc, m);
        final stats = AnalyticsStatsCache.fromMap(m);
        _noteSeen('analytics_stats', stats.updatedAtMs);
        await _mergeAnalyticsStats(stats);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip analytics stats ${doc.id}: $e\n$st');
      }
    }
  }

  /// Singleton doc — one read per pull, no cursor (cheaper than tracking one).
  Future<void> _pullOnboardingProfile() async {
    final snap = await _client.userCollection('onboarding').get();
    for (final doc in snap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        final profile = OnboardingProfile.fromMap(m);
        await _mergeOnboardingProfile(profile);
      } catch (e, st) {
        debugPrint(
          'RemoteIsarMerge: skip onboarding profile ${doc.id}: $e\n$st',
        );
      }
    }
  }

  /// Stake challenges are a TOP-LEVEL server-owned collection (outcomes are
  /// decided by Cloud Functions — PRD accountability-stakes §7.1). Pulled by
  /// `participantUids arrayContains uid`, full pull every time: a user has a
  /// handful of challenges, and arrayContains + updatedAtMs range would need
  /// a composite index (errors.md #16/#18) for no real saving. LWW makes
  /// re-merges no-ops. Evidence of NON-terminal challenges is pulled too so
  /// a second device sees this account's own logged units.
  /// Runs one non-core pull phase, swallowing its failure so the rest of
  /// the sync survives. [cursorKey] is dropped from this pull's cursor
  /// advancement on failure — a partially-read phase must not skip docs
  /// on the next attempt (unordered reads under a max-seen cursor would).
  Future<void> _pullGuarded(
    String label,
    Future<void> Function() phase, {
    String? cursorKey,
  }) async {
    try {
      await phase();
    } on StateError {
      rethrow; // uid-changed abort — never swallow account isolation
    } catch (e) {
      if (cursorKey != null) _maxSeen.remove(cursorKey);
      debugPrint('RemoteIsarMerge: $label pull failed, skipping: $e');
    }
  }

  Future<void> _pullStakeChallenges() async {
    final snap = await _client
        .topCollection('stake_challenges')
        .where('participantUids', arrayContains: _client.uid)
        .get();
    final openChallengeIds = <String>[];
    for (final doc in snap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = doc.id;
        final challenge = StakeChallenge.fromMap(m);
        await _mergeStakeChallenge(challenge);
        if (!challenge.status.isTerminal) openChallengeIds.add(challenge.id);
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip stake challenge ${doc.id}: $e\n$st');
      }
    }
    for (final challengeId in openChallengeIds) {
      _abortIfUidChanged();
      final evidenceSnap = await _client
          .topCollection('stake_challenges')
          .doc(challengeId)
          .collection('evidence')
          .get();
      for (final doc in evidenceSnap.docs) {
        try {
          final m = Map<String, dynamic>.from(doc.data());
          m['id'] = doc.id;
          m['challengeId'] = challengeId;
          await _mergeStakeEvidence(StakeEvidence.fromMap(m));
        } catch (e, st) {
          debugPrint('RemoteIsarMerge: skip stake evidence ${doc.id}: $e\n$st');
        }
      }
    }
  }

  /// Block list (`users/{uid}/blocked`) — tiny, full pull, LWW.
  Future<void> _pullBlockedUsers() async {
    final snap = await _client.userCollection('blocked').get();
    for (final doc in snap.docs) {
      try {
        final m = doc.data();
        final blockedUid = (m['blockedUid'] as String?) ?? doc.id;
        final updatedAtMs = (m['updatedAtMs'] as num?)?.toInt() ?? 0;
        final existing = await _isar.isarBlockedUsers
            .filter()
            .blockedUidEqualTo(blockedUid)
            .findFirst();
        if (!shouldApplyRemoteUpdatedAt(
          localUpdatedAtMs: existing?.updatedAtMs,
          remoteUpdatedAtMs: updatedAtMs,
        )) {
          continue;
        }
        final row = IsarBlockedUser()
          ..blockedUid = blockedUid
          ..active = (m['active'] as bool?) ?? true
          ..createdAtMs = (m['createdAtMs'] as num?)?.toInt() ?? updatedAtMs
          ..updatedAtMs = updatedAtMs;
        await _isar.writeTxn(() async {
          await _isar.isarBlockedUsers.putByBlockedUid(row);
        });
        _appliedCount++;
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip blocked user ${doc.id}: $e\n$st');
      }
    }
  }

  /// Points ledger mirror: the balance doc plus txns after the cursor
  /// (txns are immutable, `updatedAtMs == atMs`, so a single-field range
  /// needs no composite index — errors.md #16/#18).
  Future<void> _pullPointsLedger() async {
    final uid = _client.uid;
    final balanceSnap =
        await _client.topCollection('points_ledger').doc(uid).get();
    final balanceData = balanceSnap.data();
    if (balanceData != null) {
      final updatedAtMs = (balanceData['updatedAtMs'] as num?)?.toInt() ?? 0;
      final existing = await _isar.isarPointsBalances
          .filter()
          .uidEqualTo(uid)
          .findFirst();
      if (shouldApplyRemoteUpdatedAt(
        localUpdatedAtMs: existing?.updatedAtMs,
        remoteUpdatedAtMs: updatedAtMs,
      )) {
        final row = IsarPointsBalance()
          ..uid = uid
          ..balance = (balanceData['balance'] as num?)?.toInt() ?? 0
          ..updatedAtMs = updatedAtMs;
        await _isar.writeTxn(() async {
          await _isar.isarPointsBalances.putByUid(row);
        });
        _appliedCount++;
      }
    }

    final cursor = await _cursorFor('points_txns');
    final txnsSnap = await _afterCursor(
      _client.topCollection('points_ledger').doc(uid).collection('txns'),
      cursor,
    ).get();
    for (final doc in txnsSnap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = doc.id;
        final txn = PointsTxn.fromMap(m);
        _noteSeen('points_txns', txn.atMs);
        final existing = await _isar.isarPointsTxns
            .filter()
            .txnIdEqualTo(txn.id)
            .findFirst();
        if (existing != null) continue; // immutable — once is enough
        await _isar.writeTxn(() async {
          await _isar.isarPointsTxns.putByTxnId(IsarPointsTxn.fromDomain(txn));
        });
        _appliedCount++;
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip points txn ${doc.id}: $e\n$st');
      }
    }
  }

  /// Curated charities (D7). Rules only permit reading active entries, so
  /// the query MUST carry the filter or the whole read is denied.
  Future<void> _pullCharities() async {
    final snap = await _client
        .topCollection('charities')
        .where('active', isEqualTo: true)
        .get();
    for (final doc in snap.docs) {
      try {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = doc.id;
        final charity = Charity.fromMap(m);
        final updatedAtMs = (m['updatedAtMs'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final existing = await _isar.isarCharitys
            .filter()
            .charityIdEqualTo(charity.id)
            .findFirst();
        if (existing != null && existing.name == charity.name) continue;
        await _isar.writeTxn(() async {
          await _isar.isarCharitys.putByCharityId(
            IsarCharity.fromDomain(charity, updatedAtMs),
          );
        });
        _appliedCount++;
      } catch (e, st) {
        debugPrint('RemoteIsarMerge: skip charity ${doc.id}: $e\n$st');
      }
    }
  }

  Future<void> _mergeStakeChallenge(StakeChallenge incoming) async {
    final existing = await _isar.isarStakeChallenges
        .filter()
        .challengeIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarStakeChallenges.putByChallengeId(
        IsarStakeChallenge.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeStakeEvidence(StakeEvidence incoming) async {
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
    _appliedCount++;
  }

  Future<void> _mergeOnboardingProfile(OnboardingProfile incoming) async {
    final existing = await _isar.isarOnboardingProfiles
        .filter()
        .profileIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarOnboardingProfiles.putByProfileId(
        IsarOnboardingProfile.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeRoutine(Routine incoming) async {
    final existing = await _isar.isarRoutines
        .filter()
        .routineIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarRoutines.putByRoutineId(IsarRoutine.fromDomain(incoming));
    });
    _appliedCount++;
  }

  Future<void> _mergeBlock(TaskBlock incoming) async {
    final existing = await _isar.isarBlocks
        .filter()
        .blockIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarBlocks.putByBlockId(IsarBlock.fromDomain(incoming));
    });
    _appliedCount++;
  }

  Future<void> _mergeTask(PlannedTask incoming) async {
    if (await mergePlannedTaskLwwIntoIsar(_isar, incoming)) {
      _appliedCount++;
    }
  }

  Future<void> _mergeReminder(ReminderConfig incoming) async {
    final existing = await _isar.isarReminders
        .filter()
        .reminderIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarReminders.putByReminderId(
        IsarReminder.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeGoal(UserGoal incoming) async {
    final existing = await _isar.isarGoals
        .filter()
        .goalIdEqualTo(incoming.id)
        .findFirst();
    if (existing == null) _newLocalGoalIds.add(incoming.id);
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarGoals.putByGoalId(IsarGoal.fromDomain(incoming));
    });
    _appliedCount++;
  }

  Future<void> _mergeGoalAction(GoalAction incoming) async {
    final existing = await _isar.isarGoalActions
        .filter()
        .actionIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarGoalActions.putByActionId(
        IsarGoalAction.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeGoalMilestone(GoalMilestone incoming) async {
    final existing = await _isar.isarGoalMilestones
        .filter()
        .milestoneIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarGoalMilestones.putByMilestoneId(
        IsarGoalMilestone.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeGoalCheckIn(GoalCheckIn incoming) async {
    final existing = await _isar.isarGoalCheckIns.getByCheckInKey(
      IsarGoalCheckIn.keyFor(incoming.goalId, incoming.dateKey),
    );
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarGoalCheckIns.putByCheckInKey(
        IsarGoalCheckIn.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeAnalyticsEvent(AnalyticsEvent incoming) async {
    final existing = await _isar.isarAnalyticsEvents
        .filter()
        .eventIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarAnalyticsEvents.putByEventId(
        IsarAnalyticsEvent.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }

  Future<void> _mergeAnalyticsStats(AnalyticsStatsCache incoming) async {
    final existing = await _isar.isarAnalyticsStats
        .filter()
        .statsIdEqualTo(incoming.id)
        .findFirst();
    if (!shouldApplyRemoteUpdatedAt(
      localUpdatedAtMs: existing?.updatedAtMs,
      remoteUpdatedAtMs: incoming.updatedAtMs,
    )) {
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.isarAnalyticsStats.putByStatsId(
        IsarAnalyticsStats.fromDomain(incoming),
      );
    });
    _appliedCount++;
  }
}
