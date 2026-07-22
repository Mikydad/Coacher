import 'dart:io';

import 'package:sidepal/core/firebase/firestore_client.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_task.dart';
import 'package:sidepal/core/sync/remote_isar_merge.dart';
import 'package:sidepal/core/sync/sync_cursor_store.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/isar_test_harness.dart';

const _uid = 'user_1';

Map<String, dynamic> _task({
  required String id,
  required int updatedAtMs,
  String title = 'Task',
}) =>
    PlannedTask(
      id: id,
      routineId: 'r1',
      blockId: 'b1',
      title: title,
      durationMinutes: 25,
      priority: 3,
      orderIndex: 0,
      reminderEnabled: false,
      reminderTimeIso: null,
      status: TaskStatus.notStarted,
      createdAtMs: 1,
      updatedAtMs: updatedAtMs,
      planDateKey: '2026-07-06',
    ).toMap();

Future<void> _seedSkeleton(FakeFirebaseFirestore fs) async {
  final routines = fs.collection('users').doc(_uid).collection('routines');
  await routines.doc('r1').set(Routine(
        id: 'r1',
        title: 'Day plan',
        dateKey: '2026-07-06',
        orderIndex: 0,
        createdAtMs: 1,
        updatedAtMs: 10,
      ).toMap());
  await routines.doc('r1').collection('blocks').doc('b1').set(TaskBlock(
        id: 'b1',
        routineId: 'r1',
        title: 'Morning',
        orderIndex: 0,
        createdAtMs: 1,
        updatedAtMs: 10,
      ).toMap());
}

Future<int> _taskCount(Isar isar) => isar.isarTasks.where().count();

void main() {
  group('SyncCursorStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to 0, advances monotonically, clears', () async {
      const store = SyncCursorStore();
      expect(await store.read('tasks'), 0);

      await store.advance('tasks', 100);
      expect(await store.read('tasks'), 100);

      await store.advance('tasks', 50); // never backwards
      expect(await store.read('tasks'), 100);

      await store.advance('tasks', 0); // non-positive ignored
      expect(await store.read('tasks'), 100);

      await SyncCursorStore.clearAll();
      expect(await store.read('tasks'), 0);
    });
  });

  group('RemoteIsarMerge cursors', () {
    late FakeFirebaseFirestore fs;
    Isar? isar;
    Directory? dir;

    RemoteIsarMerge merge({bool force = false}) => RemoteIsarMerge(
          isar!,
          client: FirestoreClient(firestore: fs, uid: _uid),
          ignoreCursors: force,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fs = FakeFirebaseFirestore();
      final opened = await openTempIsar();
      isar = opened.isar;
      dir = opened.dir;
      await _seedSkeleton(fs);
    });

    tearDown(() async {
      if (isar != null && dir != null) await closeTempIsar(isar!, dir!);
    });

    Future<void> addRemoteTask(String id, int updatedAtMs) => fs
        .collection('users')
        .doc(_uid)
        .collection('routines')
        .doc('r1')
        .collection('blocks')
        .doc('b1')
        .collection('tasks')
        .doc(id)
        .set(_task(id: id, updatedAtMs: updatedAtMs));

    test('first pull reads all; cursor advances to max updatedAtMs seen',
        () async {
      await addRemoteTask('t1', 100);
      await addRemoteTask('t2', 200);

      final applied = await merge().run();

      expect(applied, isTrue);
      expect(await _taskCount(isar!), 2);
      expect(await const SyncCursorStore().read('tasks'), 200);
    });

    test('second pull only sees docs newer than the cursor', () async {
      await addRemoteTask('t1', 100);
      await merge().run();
      expect(await const SyncCursorStore().read('tasks'), 100);

      // Newer doc → picked up; older-than-cursor doc → filtered out.
      await addRemoteTask('t2', 400);
      await addRemoteTask('t_stale', 50);

      final applied = await merge().run();

      expect(applied, isTrue);
      expect(await _taskCount(isar!), 2); // t1 + t2, NOT t_stale
      final staleRow =
          await isar!.isarTasks.filter().taskIdEqualTo('t_stale').findFirst();
      expect(staleRow, isNull);
      expect(await const SyncCursorStore().read('tasks'), 400);
    });

    test('force pull (ignoreCursors) reads everything again', () async {
      await addRemoteTask('t1', 100);
      await merge().run();
      await addRemoteTask('t_stale', 50); // below cursor

      await merge().run(); // normal pull skips it
      expect(
        await isar!.isarTasks.filter().taskIdEqualTo('t_stale').findFirst(),
        isNull,
      );

      final applied = await merge(force: true).run(); // reconcile
      expect(applied, isTrue);
      expect(
        await isar!.isarTasks.filter().taskIdEqualTo('t_stale').findFirst(),
        isNotNull,
      );
    });

    test('no-change pull applies nothing and reports false', () async {
      await addRemoteTask('t1', 100);
      await merge().run();

      final applied = await merge().run();
      expect(applied, isFalse);
    });
  });
}
