import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../offline/offline_store.dart';
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
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((it) => it != ConnectivityResult.none);
      if (hasConnection) {
        unawaited(processQueue());
        unawaited(syncFromRemote());
      }
    });
    unawaited(processQueue());
    unawaited(syncFromRemote());
  }

  /// Pulls Firestore into Isar (LWW on [updatedAtMs]).
  ///
  /// When [force] is false, debounced to at most once per 30 seconds.
  /// Concurrent callers await the same in-flight pull when one is running.
  ///
  /// Returns `true` when a remote pull finished successfully (not debounced/skipped).
  Future<bool> syncFromRemote({bool force = false}) async {
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

    final isar = OfflineStore.instance.isar;
    if (isar == null) {
      debugPrint('syncFromRemote: Isar not open, skip');
      return false;
    }

    _lastRemoteSyncStartedAt = now;

    _activeRemotePullUid = uid;
    _activeRemotePullFuture = _runRemotePull(isar);
    try {
      await _activeRemotePullFuture!;
      return _lastRemotePullSucceeded;
    } finally {
      _activeRemotePullFuture = null;
      _activeRemotePullUid = null;
    }
  }

  Future<void> _runRemotePull(Isar isar) async {
    isSyncingFromRemote.value = true;
    _lastRemotePullSucceeded = false;
    try {
      if (debugRemotePullForTests != null) {
        await debugRemotePullForTests!(isar);
      } else {
        await RemoteIsarMerge(isar).run().timeout(
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
    } finally {
      isSyncingFromRemote.value = false;
      if (_lastRemotePullSucceeded) {
        PostSyncRefreshCoordinator.instance.scheduleAfterSuccessfulRemotePull();
      }
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
    _queue = [];
    pendingCount.value = 0;
    if (!debugSkipQueuePersistenceForTests) {
      try {
        await _queueStore.save(_queue);
      } catch (e) {
        debugPrint('SyncService.clearQueue: persist failed: $e');
      }
    }
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
      await _queueStore.save(_queue);
    }
  }

  Future<void> processQueue() async {
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
    try {
      // Snapshot: ops enqueued while this flush awaits network calls must not
      // be lost when the queue is rewritten below.
      final snapshot = List<OfflineOperation>.of(_queue);
      final handledIds = <String>{};
      final failed = <OfflineOperation>[];

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
        try {
          if (debugOpWriterForTests != null) {
            await debugOpWriterForTests!(op);
          } else if (op.operationType == 'upsert') {
            await FirebaseFirestore.instance.doc(op.documentPath).set(
              op.payload ?? const {},
              SetOptions(merge: true),
            );
          } else if (op.operationType == 'delete') {
            await FirebaseFirestore.instance.doc(op.documentPath).delete();
          }
          handledIds.add(op.id);
        } catch (_) {
          // Keep operation for next sync attempt.
          handledIds.add(op.id);
          failed.add(op);
        }
      }

      // Rebuild: failures first (original order), then anything enqueued
      // concurrently during this flush.
      _queue = [
        ...failed,
        ..._queue.where((op) => !handledIds.contains(op.id)),
      ];
      pendingCount.value = _queue.length;
      if (!debugSkipQueuePersistenceForTests) {
        await _queueStore.save(_queue);
      }
      debugPrint('Sync queue processed. Remaining operations: ${_queue.length}');
    } finally {
      _isSyncing = false;
    }
  }
}
