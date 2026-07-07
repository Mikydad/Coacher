import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// Query below always means the Firestore one (_afterCursor).
import 'package:isar/isar.dart' hide Query;

import '../../features/goals/domain/models/user_goal.dart';
import '../../features/analytics/domain/models/analytics_event.dart';
import '../../features/analytics/domain/models/analytics_stats_cache.dart';
import '../../features/planning/domain/models/block.dart';
import '../../features/planning/domain/models/routine.dart';
import '../../features/planning/domain/models/task_item.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/domain/models/reminder_config.dart';
import '../firebase/firestore_client.dart';
import '../local_db/isar_collections/isar_block.dart';
import '../local_db/isar_collections/isar_analytics_event.dart';
import '../local_db/isar_collections/isar_analytics_stats.dart';
import '../local_db/isar_collections/isar_goal.dart';
import '../local_db/isar_collections/isar_reminder.dart';
import '../local_db/isar_collections/isar_routine.dart';
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
    await _pullAnalytics();
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
