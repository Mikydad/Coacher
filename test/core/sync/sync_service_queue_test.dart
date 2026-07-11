import 'dart:async';

import 'package:coach_for_life/core/sync/offline_operation.dart';
import 'package:coach_for_life/core/sync/sync_service.dart';
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
}
