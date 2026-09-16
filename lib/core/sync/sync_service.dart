import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../offline/offline_store.dart';
import '../telemetry/nonfatal.dart';
import '../utils/stable_id.dart';
import 'offline_operation.dart';
import 'offline_sync_queue.dart';
import 'post_sync_refresh_coordinator.dart';
import 'remote_isar_merge.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  /// Firestore → Isar pull; avoids an indefinite white "loading" gate if the network stalls.
  static const Duration remotePullTimeout = Duration(seconds: 60);

  /// Injected clock for debounce tests; cleared after tests.
  @visibleForTesting
  static DateTime Function()? debugClockForTests;

  /// When set, replaces [RemoteIsarMerge] during [syncFromRemote].
  @visibleForTesting
  static Future<void> Function(Isar isar)? debugRemotePullForTests;

  /// When true, [enqueueUpsert]/[enqueueDelete] update memory only (no [path_provider]).
  @visibleForTesting
  static bool debugSkipQueuePersistenceForTests = false;

  /// When set, used instead of [FirebaseAuth] for the current uid (VM tests).
  @visibleForTesting
  static String? debugUidForTests;

  /// When set, replaces the Firestore write in [processQueue] (VM tests).
  @visibleForTesting
  static Future<void> Function(OfflineOperation op)? debugOpWriterForTests;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final OfflineSyncQueue _queueStore = const OfflineSyncQueue();
  List<OfflineOperation> _queue = const [];
  bool _isSyncing = false;
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Bumped by [clearQueue] (audit M4): a flush that was mid-flight when
  /// the queue was cleared must not write its `failed` list back.
  int _flushGeneration = 0;

  /// Serialises disk writes of the queue file (audit M3): two interleaved
  /// writers of one file are how it got corrupted.
  Future<void> _saveChain = Future.value();

  /// Per-write network bound (audit M4). With Firestore offline persistence
  /// on, an offline `set()` never throws — it hangs until ack — so without
  /// this the flush never finished and the amber line never showed.
  static const Duration writeTimeout = Duration(seconds: 15);

  /// Shorter bound for VM tests of the timeout path.
  @visibleForTesting
  static Duration? debugWriteTimeoutForTests;

  static Duration get _writeTimeout => debugWriteTimeoutForTests ?? writeTimeout;

  /// Audit M7 — a full (cursor-less) reconcile pull at least once a day, so
  /// convergence does not depend on the user pressing the sync button.
  static const Duration fullPullEvery = Duration(hours: 24);
  static const String _lastFullPullPrefsKey = 'sync_cursor_v1_last_full_pull';

  /// `true` when the last queue flush left pending writes that failed to reach
  /// Firestore (i.e. the queue is stuck and needs the user's attention).
  ///
  /// Routine background sync never sets this — only a genuine push failure does.
  /// It clears as soon as a later flush drains the queue. Kept as a
  /// [ValueNotifier] to match [pendingCount] so UI can listen without Riverpod.
  final ValueNotifier<bool> hasSyncIssue = ValueNotifier<bool>(false);

  DateTime? _lastRemoteSyncStartedAt;
  Future<void>? _activeRemotePullFuture;
  String? _activeRemotePullUid;
  bool _lastRemotePullSucceeded = false;
  final ValueNotifier<bool> isSyncingFromRemote = ValueNotifier<bool>(false);

  /// Current uid, or null when signed out / Firebase unavailable (VM tests).
  static String? _currentUid() {
    if (debugUidForTests != null) return debugUidForTests;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> initialize() async {
    _queue = await _queueStore.load();
    pendingCount.value = _queue.length;
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = results.any((it) => it != ConnectivityResult.none);
      if (hasConnection) unawaited(flushThenPull());
    });
    unawaited(flushThenPull());
  }

  /// Push before pull (audit H15): a queued delete must reach Firestore
  /// before the pull reads that document, or the pull resurrects the row.
  /// Tombstones make the race harmless either way; this ordering makes it
  /// rare.
  Future<void> flushThenPull() async {
    await processQueue();
    await syncFromRemote();
  }

  /// Pulls Firestore into Isar (LWW on [updatedAtMs]).
  ///
  /// When [force] is false, debounced to at most once per 30 seconds.
  /// Concurrent callers await the same in-flight pull when one is running.
  ///
  /// Returns `true` when a remote pull finished successfully (not debounced/skipped).
  /// While Voice Mode is live, background sync stays off the network:
  /// device logs showed remote pulls + outbox storms competing with voice
  /// requests for bandwidth mid-turn (voice Level 2 slice). Deferred work
  /// resumes on the next trigger after voice mode ends.
  bool voiceModeActive = false;

  Future<bool> syncFromRemote({bool force = false}) async {
    if (voiceModeActive && !force) {
      debugPrint('syncFromRemote: voice mode active, deferring');
      return false;
    }
    // No authenticated user → there is no user-scoped data to pull, and any
    // Firestore query would fail with permission-denied. Skip silently.
    final uid = _currentUid();
    if (uid == null) {
      debugPrint('syncFromRemote: no signed-in user, skip');
      return false;
    }

    if (_activeRemotePullFuture != null) {
      // Join the in-flight pull only when it belongs to the same uid. After
      // an account switch the in-flight pull is the previous user's — joining
      // it would leave the new account with stale/mixed data, so wait for it
      // to settle and start a fresh pull below.
      if (_activeRemotePullUid == uid) {
        await _activeRemotePullFuture!;
        return _lastRemotePullSucceeded;
      }
      await _activeRemotePullFuture!;
    }

    final now = debugClockForTests?.call() ?? DateTime.now();
    if (!force) {
      if (_lastRemoteSyncStartedAt != null &&
          now.difference(_lastRemoteSyncStartedAt!).inSeconds < 30) {
        return false;
      }
    }
    // Daily full reconcile (audit M7) — promotes this pull to cursor-less.
    var effectiveForce = force;
    if (!effectiveForce && await _fullPullDue(now)) effectiveForce = true;

    final isar = OfflineStore.instance.isar;
    if (isar == null) {
      debugPrint('syncFromRemote: Isar not open, skip');
      return false;
    }

    _lastRemoteSyncStartedAt = now;

    _activeRemotePullUid = uid;
    _activeRemotePullFuture = _runRemotePull(isar, force: effectiveForce);
    try {
      await _activeRemotePullFuture!;
      if (_lastRemotePullSucceeded && effectiveForce) {
        await _stampFullPull(now);
      }
      return _lastRemotePullSucceeded;
    } finally {
      _activeRemotePullFuture = null;
      _activeRemotePullUid = null;
    }
  }

  Future<bool> _fullPullDue(DateTime now) async {
    if (debugRemotePullForTests != null) return false; // VM tests
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_lastFullPullPrefsKey) ?? 0;
      return now.millisecondsSinceEpoch - last >= fullPullEvery.inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> _stampFullPull(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastFullPullPrefsKey, now.millisecondsSinceEpoch);
    } catch (_) {
      // Prefs unavailable (tests) — the next pull is simply full again.
    }
  }

  Future<void> _runRemotePull(Isar isar, {bool force = false}) async {
    isSyncingFromRemote.value = true;
    _lastRemotePullSucceeded = false;
    // Conservative default for the test-override path, which can't report
    // whether it applied rows.
    var appliedAny = true;
    try {
      if (debugRemotePullForTests != null) {
        await debugRemotePullForTests!(isar);
      } else {
        // force → ignore sync cursors: full reconcile pull.
        appliedAny = await RemoteIsarMerge(isar, ignoreCursors: force)
            .run()
            .timeout(
              remotePullTimeout,
              onTimeout: () => throw TimeoutException(
                'RemoteIsarMerge exceeded ${remotePullTimeout.inSeconds}s',
                remotePullTimeout,
              ),
            );
      }
      _lastRemotePullSucceeded = true;
    } catch (e, st) {
      // Do not rethrow: many callers are fire-and-forget (connectivity
      // listener, bootstrap) and an escaped exception would surface as an
      // unhandled zone error. Callers that await get `false` back instead.
      debugPrint('syncFromRemote failed: $e\n$st');
      reportNonfatal('sync.remotePull', e, st);
    } finally {
      isSyncingFromRemote.value = false;
      // A pull that changed no local rows (the common case for the periodic
      // 30s pull) does not invalidate providers or schedule a full
      // analytics/coaching recompute.
      if (_lastRemotePullSucceeded && appliedAny) {
        PostSyncRefreshCoordinator.instance.scheduleAfterSuccessfulRemotePull();
      }
    }
  }

  /// Waits for an in-flight remote pull to settle (audit H2). Called by the
  /// session teardown AFTER the session generation is bumped: the merge
  /// aborts at its next guarded write, so this returns quickly; the timeout
  /// is only a belt for a pull stuck on the network.
  Future<void> drainInFlightPull({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final inFlight = _activeRemotePullFuture;
    if (inFlight == null) return;
    try {
      await inFlight.timeout(timeout);
    } catch (e) {
      debugPrint('drainInFlightPull: $e');
    }
  }

  @visibleForTesting
  void resetRemoteSyncStateForTests() {
    _lastRemoteSyncStartedAt = null;
    _activeRemotePullFuture = null;
    _activeRemotePullUid = null;
    _lastRemotePullSucceeded = false;
    isSyncingFromRemote.value = false;
  }

  /// Clears all queued offline operations (memory + disk).
  ///
  /// Called on logout / account switch so a previous user's pending writes
  /// can never replay after a different account signs in.
  Future<void> clearQueue() async {
    _flushGeneration++;
    _queue = [];
    pendingCount.value = 0;
    hasSyncIssue.value = false;
    if (!debugSkipQueuePersistenceForTests) {
      try {
        await _persistQueue();
      } catch (e) {
        debugPrint('SyncService.clearQueue: persist failed: $e');
      }
    }
  }

  /// Serialised, atomic persistence of the current queue snapshot.
  Future<void> _persistQueue() {
    final snapshot = List<OfflineOperation>.of(_queue);
    _saveChain = _saveChain
        .then((_) => _queueStore.save(snapshot))
        .catchError((Object e) {
          debugPrint('SyncService: queue persist failed: $e');
        });
    return _saveChain;
  }

  @visibleForTesting
  Future<void> clearOfflineQueueForTests() => clearQueue();

  /// Clears the in-memory queue only (no [path_provider]; for VM unit tests).
  @visibleForTesting
  void debugResetQueueInMemoryOnly() {
    _queue = [];
    pendingCount.value = 0;
  }

  Future<void> enqueueUpsert({
    required String entityType,
    required String documentPath,
    required Map<String, dynamic> payload,
  }) async {
    await _enqueue(
      OfflineOperation(
        id: StableId.generate('op'),
        entityType: entityType,
        operationType: 'upsert',
        documentPath: documentPath,
        payload: payload,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        uid: _currentUid(),
      ),
    );
  }

  Future<void> enqueueDelete({
    required String entityType,
    required String documentPath,
  }) async {
    await _enqueue(
      OfflineOperation(
        id: StableId.generate('op'),
        entityType: entityType,
        operationType: 'delete',
        documentPath: documentPath,
        payload: null,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        uid: _currentUid(),
      ),
    );
  }

  Future<void> _enqueue(OfflineOperation operation) async {
    _queue = [..._queue, operation];
    pendingCount.value = _queue.length;
    if (!debugSkipQueuePersistenceForTests) {
      await _persistQueue();
    }
  }

  /// Audit M4 — error classification. A denied or malformed write will
  /// never succeed on retry: it is dropped (the local row stays; the next
  /// local edit re-stamps and re-queues it). Everything else backs off.
  ///
  /// `permission-denied` on an upsert is also how the server-side LWW rule
  /// (audit H16) rejects a stale offline edit — the other device's newer
  /// version wins, and the next pull brings it here.
  @visibleForTesting
  static bool isPermanentFailure(Object error) {
    if (error is FirebaseException) {
      return const {
        'permission-denied',
        'invalid-argument',
        'not-found',
        'failed-precondition',
        'already-exists',
      }.contains(error.code);
    }
    return false;
  }

  /// Exponential back-off with jitter: 5s · 2^(attempts−1), capped at 10 min.
  @visibleForTesting
  static Duration backoffFor(int attempts) {
    final base = Duration(seconds: 5 * (1 << (attempts - 1).clamp(0, 7)));
    final capped = base > const Duration(minutes: 10)
        ? const Duration(minutes: 10)
        : base;
    final jitterMs = (capped.inMilliseconds * 0.2 *
            ((DateTime.now().microsecondsSinceEpoch % 1000) / 1000))
        .round();
    return capped + Duration(milliseconds: jitterMs);
  }

  Future<void> processQueue() async {
    if (voiceModeActive) {
      debugPrint('processQueue: voice mode active, deferring');
      return;
    }
    if (_isSyncing || _queue.isEmpty) return;
    final currentUid = _currentUid();
    if (currentUid == null && Firebase.apps.isNotEmpty) {
      // Signed out (e.g. brief window during startup/auth restore): keep the
      // queue untouched — writes would fail rules anyway, and dropping here
      // could lose a legitimate user's pending ops.
      debugPrint('Sync queue: no signed-in user, flush skipped');
      return;
    }
    _isSyncing = true;
    final generation = _flushGeneration;
    try {
      // Snapshot: ops enqueued while this flush awaits network calls must not
      // be lost when the queue is rewritten below.
      final snapshot = List<OfflineOperation>.of(_queue);
      final handledIds = <String>{};
      final failed = <OfflineOperation>[];
      final nowMs =
          (debugClockForTests?.call() ?? DateTime.now()).millisecondsSinceEpoch;

      for (final op in snapshot) {
        // Drop ops that belong to a different account (or legacy ops with no
        // uid when someone is signed in) — replaying them would write one
        // user's data into another user's Firestore tree.
        if (op.uid != currentUid) {
          handledIds.add(op.id);
          debugPrint(
            'Sync queue: dropped ${op.operationType} for foreign uid '
            '(op=${op.id}, entity=${op.entityType})',
          );
          continue;
        }
        // Backing off after earlier failures — stays pending, not attempted.
        if (op.nextAttemptMs > nowMs) {
          handledIds.add(op.id);
          failed.add(op);
          continue;
        }
        try {
          if (debugOpWriterForTests != null) {
            await debugOpWriterForTests!(op).timeout(_writeTimeout);
          } else if (op.operationType == 'upsert') {
            await FirebaseFirestore.instance
                .doc(op.documentPath)
                .set(op.payload ?? const {}, SetOptions(merge: true))
                .timeout(_writeTimeout);
          } else if (op.operationType == 'delete') {
            await FirebaseFirestore.instance
                .doc(op.documentPath)
                .delete()
                .timeout(_writeTimeout);
          }
          handledIds.add(op.id);
        } catch (e) {
          handledIds.add(op.id);
          if (isPermanentFailure(e)) {
            debugPrint(
              'Sync queue: dropped ${op.operationType} ${op.entityType} '
              '(op=${op.id}) — permanent: $e',
            );
            reportNonfatal('sync.outboxDropped.${op.entityType}', e);
            continue;
          }
          final attempts = op.attempts + 1;
          failed.add(
            op.withRetryScheduled(
              attempts: attempts,
              nextAttemptMs: nowMs + backoffFor(attempts).inMilliseconds,
            ),
          );
        }
      }

      // The queue was cleared (logout) while this flush was mid-flight: the
      // outgoing account's failures must not be written back (audit M4).
      if (generation != _flushGeneration) {
        debugPrint('Sync queue: flush superseded by clearQueue — discarded');
        return;
      }

      // Rebuild: failures first (original order), then anything enqueued
      // concurrently during this flush.
      _queue = [
        ...failed,
        ..._queue.where((op) => !handledIds.contains(op.id)),
      ];
      pendingCount.value = _queue.length;
      // A flush that left failures behind means writes are stuck and the user
      // should know; a clean flush clears the warning. Ops enqueued mid-flush
      // (not yet attempted) are routine and do not count as an issue.
      hasSyncIssue.value = failed.isNotEmpty;
      if (!debugSkipQueuePersistenceForTests) {
        await _persistQueue();
      }
      debugPrint(
        'Sync queue processed. Remaining operations: ${_queue.length}',
      );
    } finally {
      _isSyncing = false;
    }
  }
}
