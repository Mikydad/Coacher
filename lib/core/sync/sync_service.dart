import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../offline/offline_store.dart';
import '../utils/stable_id.dart';
import 'offline_operation.dart';
import 'offline_sync_queue.dart';
import 'remote_isar_merge.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  /// Injected clock for debounce tests; cleared after tests.
  @visibleForTesting
  static DateTime Function()? debugClockForTests;

  /// When set, replaces [RemoteIsarMerge] during [syncFromRemote].
  @visibleForTesting
  static Future<void> Function(Isar isar)? debugRemotePullForTests;

  /// When true, [enqueueUpsert]/[enqueueDelete] update memory only (no [path_provider]).
  @visibleForTesting
  static bool debugSkipQueuePersistenceForTests = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final OfflineSyncQueue _queueStore = const OfflineSyncQueue();
  List<OfflineOperation> _queue = const [];
  bool _isSyncing = false;
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  DateTime? _lastRemoteSyncStartedAt;
  Future<void>? _activeRemotePullFuture;
  final ValueNotifier<bool> isSyncingFromRemote = ValueNotifier<bool>(false);

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
  Future<void> syncFromRemote({bool force = false}) async {
    if (_activeRemotePullFuture != null) {
      await _activeRemotePullFuture!;
      return;
    }

    final now = debugClockForTests?.call() ?? DateTime.now();
    if (!force) {
      if (_lastRemoteSyncStartedAt != null &&
          now.difference(_lastRemoteSyncStartedAt!).inSeconds < 30) {
        return;
      }
    }

    final isar = OfflineStore.instance.isar;
    if (isar == null) {
      debugPrint('syncFromRemote: Isar not open, skip');
      return;
    }

    _lastRemoteSyncStartedAt = now;

    _activeRemotePullFuture = _runRemotePull(isar);
    try {
      await _activeRemotePullFuture!;
    } finally {
      _activeRemotePullFuture = null;
    }
  }

  Future<void> _runRemotePull(Isar isar) async {
    isSyncingFromRemote.value = true;
    try {
      if (debugRemotePullForTests != null) {
        await debugRemotePullForTests!(isar);
      } else {
        await RemoteIsarMerge(isar).run();
      }
    } catch (e, st) {
      debugPrint('syncFromRemote failed: $e\n$st');
      rethrow;
    } finally {
      isSyncingFromRemote.value = false;
    }
  }

  @visibleForTesting
  void resetRemoteSyncStateForTests() {
    _lastRemoteSyncStartedAt = null;
    _activeRemotePullFuture = null;
    isSyncingFromRemote.value = false;
  }

  @visibleForTesting
  Future<void> clearOfflineQueueForTests() async {
    _queue = [];
    pendingCount.value = 0;
    await _queueStore.save(_queue);
  }

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
    _isSyncing = true;
    try {
      final remaining = <OfflineOperation>[];
      for (final op in _queue) {
        try {
          if (op.operationType == 'upsert') {
            await FirebaseFirestore.instance.doc(op.documentPath).set(
              op.payload ?? const {},
              SetOptions(merge: true),
            );
          } else if (op.operationType == 'delete') {
            await FirebaseFirestore.instance.doc(op.documentPath).delete();
          }
        } catch (_) {
          // Keep operation for next sync attempt.
          remaining.add(op);
        }
      }
      _queue = remaining;
      pendingCount.value = _queue.length;
      await _queueStore.save(_queue);
      debugPrint('Sync queue processed. Remaining operations: ${_queue.length}');
    } finally {
      _isSyncing = false;
    }
  }
}
