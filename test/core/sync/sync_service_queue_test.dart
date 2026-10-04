import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:sidepal/core/sync/offline_operation.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// VM tests for the offline queue: uid scoping, logout clearing, and
/// preservation of ops enqueued while a flush is in progress.
///
/// Uses [SyncService.debugUidForTests], [SyncService.debugOpWriterForTests],
/// and [SyncService.debugSkipQueuePersistenceForTests] so no Firebase or
/// path_provider is needed.
void main() {
  setUp(() {
    SyncService.debugSkipQueuePersistenceForTests = true;
    SyncService.debugUidForTests = 'user-a';
    SyncService.debugOpWriterForTests = (_) async {};
    SyncService.instance.debugResetQueueInMemoryOnly();
    SyncService.instance.hasSyncIssue.value = false;
  });

  tearDown(() {
    SyncService.debugSkipQueuePersistenceForTests = false;
    SyncService.debugUidForTests = null;
    SyncService.debugOpWriterForTests = null;
    SyncService.debugClockForTests = null;
    SyncService.debugWriteTimeoutForTests = null;
    SyncService.instance.debugResetQueueInMemoryOnly();
    SyncService.instance.hasSyncIssue.value = false;
  });

  test('enqueued operations are stamped with the current uid', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'title': 'Task'},
    );
    expect(SyncService.instance.pendingCount.value, 1);

    // Flush as the same user — the op is written and removed.
    final written = <OfflineOperation>[];
    SyncService.debugOpWriterForTests = (op) async => written.add(op);
    await SyncService.instance.processQueue();

    expect(written, hasLength(1));
    expect(written.single.uid, 'user-a');
    expect(SyncService.instance.pendingCount.value, 0);
  });

  test('ops from another uid are dropped, not written', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'title': 'A\'s task'},
    );

    // Account switch: user B signs in with A's op still queued.
    SyncService.debugUidForTests = 'user-b';
    final written = <OfflineOperation>[];
    SyncService.debugOpWriterForTests = (op) async => written.add(op);
    await SyncService.instance.processQueue();

    expect(written, isEmpty, reason: "user A's op must not replay as user B");
    expect(SyncService.instance.pendingCount.value, 0);
  });

  test('clearQueue empties the queue', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'x': 1},
    );
    expect(SyncService.instance.pendingCount.value, 1);

    await SyncService.instance.clearQueue();

    expect(SyncService.instance.pendingCount.value, 0);
    final written = <OfflineOperation>[];
    SyncService.debugOpWriterForTests = (op) async => written.add(op);
    await SyncService.instance.processQueue();
    expect(written, isEmpty);
  });

  test('ops enqueued during a flush are preserved', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'n': 1},
    );

    // Slow writer: while op1 is being "written", enqueue op2.
    final gate = Completer<void>();
    final written = <String>[];
    SyncService.debugOpWriterForTests = (op) async {
      await gate.future;
      written.add(op.documentPath);
    };

    final flush = SyncService.instance.processQueue();
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t2',
      payload: {'n': 2},
    );
    gate.complete();
    await flush;

    expect(written, ['users/user-a/tasks/t1']);
    // op2 arrived mid-flush and must still be pending, not silently lost.
    expect(SyncService.instance.pendingCount.value, 1);

    await SyncService.instance.processQueue();
    expect(written, ['users/user-a/tasks/t1', 'users/user-a/tasks/t2']);
    expect(SyncService.instance.pendingCount.value, 0);
  });

  test('failed ops are retried on the next flush', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'n': 1},
    );

    SyncService.debugOpWriterForTests = (_) async => throw Exception('offline');
    await SyncService.instance.processQueue();
    expect(SyncService.instance.pendingCount.value, 1);
    // A flush that left writes behind must flag a sync issue so the UI can
    // surface it — this is the one time routine sync becomes visible.
    expect(SyncService.instance.hasSyncIssue.value, isTrue);

    final written = <OfflineOperation>[];
    SyncService.debugOpWriterForTests = (op) async => written.add(op);
    // Back-off (audit M4): an immediate re-flush leaves the op untouched…
    await SyncService.instance.processQueue();
    expect(written, isEmpty);
    expect(SyncService.instance.pendingCount.value, 1);
    // …and it is attempted again once the back-off window has passed.
    SyncService.debugClockForTests =
        () => DateTime.now().add(const Duration(minutes: 1));
    await SyncService.instance.processQueue();
    expect(written, hasLength(1));
    expect(SyncService.instance.pendingCount.value, 0);
    // Draining the queue clears the warning — back to silent operation.
    expect(SyncService.instance.hasSyncIssue.value, isFalse);
  });

  test('a routine flush that drains cleanly never flags a sync issue', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'n': 1},
    );

    final written = <OfflineOperation>[];
    SyncService.debugOpWriterForTests = (op) async => written.add(op);
    await SyncService.instance.processQueue();

    expect(written, hasLength(1));
    expect(SyncService.instance.pendingCount.value, 0);
    expect(SyncService.instance.hasSyncIssue.value, isFalse);
  });

  // ── Pre-launch audit M4 / H16 ────────────────────────────────────────────

  test('a permanently denied op is dropped, not retried forever', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'updatedAtMs': 1},
    );
    var attempts = 0;
    SyncService.debugOpWriterForTests = (_) async {
      attempts++;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    };
    await SyncService.instance.processQueue();
    expect(attempts, 1);
    expect(SyncService.instance.pendingCount.value, 0);
    expect(SyncService.instance.hasSyncIssue.value, isFalse);
    await SyncService.instance.processQueue();
    expect(attempts, 1, reason: 'dropped ops never come back');
  });

  test('classification: denied / malformed are permanent, network is not', () {
    expect(
      SyncService.isPermanentFailure(
        FirebaseException(plugin: 'x', code: 'permission-denied'),
      ),
      isTrue,
    );
    expect(
      SyncService.isPermanentFailure(
        FirebaseException(plugin: 'x', code: 'invalid-argument'),
      ),
      isTrue,
    );
    expect(
      SyncService.isPermanentFailure(
        FirebaseException(plugin: 'x', code: 'unavailable'),
      ),
      isFalse,
    );
    expect(SyncService.isPermanentFailure(TimeoutException('t')), isFalse);
    expect(SyncService.isPermanentFailure(Exception('offline')), isFalse);
  });

  test('back-off grows and is capped', () {
    expect(SyncService.backoffFor(1) >= const Duration(seconds: 5), isTrue);
    expect(SyncService.backoffFor(1) < const Duration(seconds: 7), isTrue);
    expect(SyncService.backoffFor(3) >= const Duration(seconds: 20), isTrue);
    expect(SyncService.backoffFor(30) <= const Duration(minutes: 12), isTrue);
  });

  test('a write that hangs times out and is retried later', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'n': 1},
    );
    // Simulates Firestore offline persistence: the write never resolves.
    SyncService.debugOpWriterForTests = (_) => Completer<void>().future;
    SyncService.debugWriteTimeoutForTests = const Duration(milliseconds: 50);
    await SyncService.instance.processQueue();
    expect(SyncService.instance.pendingCount.value, 1);
    expect(SyncService.instance.hasSyncIssue.value, isTrue);
  });

  test('clearQueue during a flush discards that flush\'s failures', () async {
    await SyncService.instance.enqueueUpsert(
      entityType: 'task',
      documentPath: 'users/user-a/tasks/t1',
      payload: {'n': 1},
    );
    final gate = Completer<void>();
    SyncService.debugOpWriterForTests = (_) async {
      await gate.future;
      throw Exception('offline');
    };
    final flush = SyncService.instance.processQueue();
    await SyncService.instance.clearQueue(); // logout while the write hangs
    gate.complete();
    await flush;
    expect(
      SyncService.instance.pendingCount.value,
      0,
      reason: 'the superseded flush must not resurrect the cleared op',
    );
    expect(SyncService.instance.hasSyncIssue.value, isFalse);
  });
}
