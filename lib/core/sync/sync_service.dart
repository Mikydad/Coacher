import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/stable_id.dart';
import 'offline_operation.dart';
import 'offline_sync_queue.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final OfflineSyncQueue _queueStore = const OfflineSyncQueue();
  List<OfflineOperation> _queue = const [];
  bool _isSyncing = false;
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  Future<void> initialize() async {
    _queue = await _queueStore.load();
    pendingCount.value = _queue.length;
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((it) => it != ConnectivityResult.none);
      if (hasConnection) {
        unawaited(processQueue());
      }
    });
    unawaited(processQueue());
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
    await _queueStore.save(_queue);
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
