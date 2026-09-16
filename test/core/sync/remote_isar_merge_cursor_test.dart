import 'dart:io';

import 'package:sidepal/core/firebase/firestore_client.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_deleted_entity.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_routine.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_task.dart';
import 'package:sidepal/core/sync/deleted_entity.dart';
import 'package:sidepal/core/session/session_scope.dart';
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

    // Timestamps are wall-clock ms: the cursor re-reads a 5-minute overlap
    // window (audit M7), so "older than the cursor" means older than
    // cursor − 5 min, and tombstones older than 30 days are purged.
    final base = DateTime.now().millisecondsSinceEpoch - 60 * 60 * 1000;
    int at(int minutes) => base + minutes * 60 * 1000;

    test('second pull only sees docs newer than the cursor', () async {
      await addRemoteTask('t1', at(10));
      await merge().run();
      expect(await const SyncCursorStore().read('tasks'), at(10));

      // Newer doc → picked up; older-than-overlap doc → filtered out.
      await addRemoteTask('t2', at(20));
      await addRemoteTask('t_stale', at(1));

      final applied = await merge().run();

      expect(applied, isTrue);
      expect(await _taskCount(isar!), 2); // t1 + t2, NOT t_stale
      final staleRow =
          await isar!.isarTasks.filter().taskIdEqualTo('t_stale').findFirst();
      expect(staleRow, isNull);
      expect(await const SyncCursorStore().read('tasks'), at(20));
    });

    test('force pull (ignoreCursors) reads everything again', () async {
      await addRemoteTask('t1', at(10));
      await merge().run();
      await addRemoteTask('t_stale', at(1)); // below cursor − overlap

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

    // Pre-launch audit H2: a pull that was started before logout must not
    // write rows after the session ended — the wipe would otherwise be
    // repopulated with the outgoing account's data.
    test('a pull started before teardown aborts at its first write', () async {
      await addRemoteTask('t1', 100);
      final pull = merge(); // captures the current session generation
      SessionScope.beginTeardown();
      addTearDown(SessionScope.resetForTests);

      await expectLater(pull.run(), throwsA(isA<StateError>()));
      expect(await _taskCount(isar!), 0);
      expect(await const SyncCursorStore().read('tasks'), 0,
          reason: 'an aborted pull never advances cursors');
    });

    // Pre-launch audit H15 — tombstones.
    test('a local tombstone blocks resurrection by an older remote row', () async {
      await addRemoteTask('t1', at(10));
      await isar!.writeTxn(() async {
        await isar!.isarDeletedEntitys.putByEntityKey(
          IsarDeletedEntity.fromDomain(
            DeletedEntity(entityType: 'task', entityId: 't1', deletedAtMs: at(15)),
          ),
        );
      });

      await merge().run();

      expect(await _taskCount(isar!), 0, reason: 'deleted after the last edit');
    });

    test('an edit made after the deletion wins (deliberate resurrection)', () async {
      await addRemoteTask('t1', at(20));
      await isar!.writeTxn(() async {
        await isar!.isarDeletedEntitys.putByEntityKey(
          IsarDeletedEntity.fromDomain(
            DeletedEntity(entityType: 'task', entityId: 't1', deletedAtMs: at(15)),
          ),
        );
      });

      await merge().run();

      expect(await _taskCount(isar!), 1);
    });

    test('a remote tombstone removes the local row and is kept locally', () async {
      await addRemoteTask('t1', at(10));
      await merge().run();
      expect(await _taskCount(isar!), 1);

      await fs
          .collection('users')
          .doc(_uid)
          .collection('deletedEntities')
          .doc('task_t1')
          .set(DeletedEntity(entityType: 'task', entityId: 't1', deletedAtMs: at(30)).toMap());

      final applied = await merge().run();

      expect(applied, isTrue);
      expect(await _taskCount(isar!), 0);
      expect(
        await isar!.isarDeletedEntitys.filter().entityKeyEqualTo('task:t1').findFirst(),
        isNotNull,
      );
      // The task doc still exists remotely with its old updatedAtMs — a
      // later pull must not bring it back either.
      await merge(force: true).run();
      expect(await _taskCount(isar!), 0);
    });

    test('a tombstoned routine is not descended into', () async {
      await addRemoteTask('t1', at(10));
      await fs
          .collection('users')
          .doc(_uid)
          .collection('deletedEntities')
          .doc('routine_r1')
          .set(DeletedEntity(entityType: 'routine', entityId: 'r1', deletedAtMs: at(50)).toMap());

      await merge().run();

      expect(await _taskCount(isar!), 0);
      expect(await isar!.isarRoutines.where().count(), 0);
    });

    test('cursor overlap re-reads a doc stamped just below the high-water mark', () async {
      await addRemoteTask('t1', at(10));
      await merge().run(); // cursor = at(10)
      // A second device's clock ran 1 min behind: its edit is BELOW the
      // cursor but inside the 5-min overlap window.
      await addRemoteTask('t_skewed', at(9));

      final applied = await merge().run();

      expect(applied, isTrue);
      expect(await _taskCount(isar!), 2);
    });

    test('a pull started after the teardown ends applies normally', () async {
      await addRemoteTask('t1', 100);
      SessionScope.beginTeardown();
      SessionScope.endTeardown();
      addTearDown(SessionScope.resetForTests);

      expect(await merge().run(), isTrue);
      expect(await _taskCount(isar!), 1);
    });
  });
}
