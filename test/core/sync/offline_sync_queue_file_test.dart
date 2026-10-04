import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/storage/app_storage_dir.dart';
import 'package:sidepal/core/sync/offline_operation.dart';
import 'package:sidepal/core/sync/offline_sync_queue.dart';

/// Pre-launch audit M3 — the queue file survives a kill mid-write and a
/// corrupt file no longer breaks bootstrap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = OfflineSyncQueue();

  Future<File> file() async {
    final dir = await getAppStorageDirectory();
    return File('${dir.path}/offline_sync_queue.json');
  }

  setUp(() async {
    final f = await file();
    if (await f.exists()) await f.delete();
    final dir = f.parent;
    for (final entity in dir.listSync()) {
      if (entity.path.contains('offline_sync_queue.json.corrupt-')) {
        await entity.delete();
      }
    }
  });

  test('save round-trips and leaves no temp file behind', () async {
    await store.save([
      const OfflineOperation(
        id: 'op1',
        entityType: 'task',
        operationType: 'upsert',
        documentPath: 'users/u/tasks/t1',
        payload: {'n': 1},
        updatedAtMs: 5,
        uid: 'u',
        attempts: 2,
        nextAttemptMs: 99,
      ),
    ]);
    final loaded = await store.load();
    expect(loaded.single.id, 'op1');
    expect(loaded.single.attempts, 2);
    expect(loaded.single.nextAttemptMs, 99);
    final f = await file();
    expect(await File('${f.path}.tmp').exists(), isFalse);
  });

  test('a corrupt file loads as empty and is set aside for diagnostics', () async {
    final f = await file();
    await f.writeAsString('[{"id": "truncated', flush: true);
    final loaded = await store.load();
    expect(loaded, isEmpty);
    expect(await f.exists(), isFalse);
    final aside = f.parent
        .listSync()
        .where((e) => e.path.contains('offline_sync_queue.json.corrupt-'));
    expect(aside, isNotEmpty);
  });

  test('legacy entries without attempts fields still load', () async {
    final f = await file();
    await f.writeAsString(
      '[{"id":"op1","entityType":"task","operationType":"delete",'
      '"documentPath":"users/u/tasks/t1","payload":null,"updatedAtMs":1}]',
      flush: true,
    );
    final loaded = await store.load();
    expect(loaded.single.attempts, 0);
    expect(loaded.single.nextAttemptMs, 0);
  });
}
