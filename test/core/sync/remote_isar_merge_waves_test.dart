import 'dart:async';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/firebase/firestore_client.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_blocked_user.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_goal_check_in.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_task.dart';
import 'package:sidepal/core/session/session_scope.dart';
import 'package:sidepal/core/sync/remote_isar_merge.dart';
import 'package:sidepal/core/sync/sync_cursor_store.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';

import '../../support/isar_test_harness.dart';

const _uid = 'user_1';

UserGoal _goal(String id, GoalStatus status) => UserGoal(
  id: id,
  title: 'Goal $id',
  categoryId: 'health',
  status: status,
  measurementKind: MeasurementKind.count,
  targetValue: 10,
  intensity: 3,
  periodStartMs: 1,
  periodEndMs: 1000,
  createdAtMs: 1,
  updatedAtMs: 10,
);

/// One document per wave: a task and an active goal's check-in (critical
/// wave), an archived goal's check-in and a blocked user (second wave).
Future<void> _seed(FakeFirebaseFirestore fs) async {
  final user = fs.collection('users').doc(_uid);
  final routines = user.collection('routines');
  await routines
      .doc('r1')
      .set(
        Routine(
          id: 'r1',
          title: 'Day plan',
          dateKey: '2026-07-06',
          orderIndex: 0,
          createdAtMs: 1,
          updatedAtMs: 10,
        ).toMap(),
      );
  final block = routines.doc('r1').collection('blocks').doc('b1');
  await block.set(
    TaskBlock(
      id: 'b1',
      routineId: 'r1',
      title: 'Morning',
      orderIndex: 0,
      createdAtMs: 1,
      updatedAtMs: 10,
    ).toMap(),
  );
  await block
      .collection('tasks')
      .doc('t1')
      .set(
        PlannedTask(
          id: 't1',
          routineId: 'r1',
          blockId: 'b1',
          title: 'Task',
          durationMinutes: 25,
          priority: 3,
          orderIndex: 0,
          reminderEnabled: false,
          reminderTimeIso: null,
          status: TaskStatus.notStarted,
          createdAtMs: 1,
          updatedAtMs: 10,
          planDateKey: '2026-07-06',
        ).toMap(),
      );

  final goals = user.collection('goals');
  await goals.doc('g_active').set(_goal('g_active', GoalStatus.active).toMap());
  await goals
      .doc('g_active')
      .collection('checkIns')
      .doc('2026-07-06')
      .set(
        GoalCheckIn(
          goalId: 'g_active',
          dateKey: '2026-07-06',
          metCommitment: true,
          updatedAtMs: 10,
        ).toMap(),
      );
  await goals.doc('g_done').set(_goal('g_done', GoalStatus.completed).toMap());
  await goals
      .doc('g_done')
      .collection('checkIns')
      .doc('2026-07-05')
      .set(
        GoalCheckIn(
          goalId: 'g_done',
          dateKey: '2026-07-05',
          metCommitment: false,
          updatedAtMs: 10,
        ).toMap(),
      );

  await user.collection('blocked').doc('bad').set({
    'blockedUid': 'bad',
    'active': true,
    'updatedAtMs': 10,
  });
}

void main() {
  group('RemoteIsarMerge waves (2026-09-22)', () {
    late FakeFirebaseFirestore fs;
    Isar? isar;
    Directory? dir;

    RemoteIsarMerge merge() => RemoteIsarMerge(
      isar!,
      client: FirestoreClient(firestore: fs, uid: _uid),
      ignoreCursors: true,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fs = FakeFirebaseFirestore();
      final opened = await openTempIsar();
      isar = opened.isar;
      dir = opened.dir;
      await _seed(fs);
    });

    tearDown(() async {
      if (isar != null && dir != null) await closeTempIsar(isar!, dir!);
    });

    test('signals the first screen after the critical wave, before the pull '
        'ends; every wave still merges and cursors advance', () async {
      final m = merge();
      final order = <String>[];
      unawaited(m.firstScreenReady.then((_) => order.add('first-screen')));

      final applied = await m.run();
      order.add('done');

      expect(applied, isTrue);
      expect(order, ['first-screen', 'done']);
      expect(await isar!.isarTasks.where().count(), 1);
      // Active goal (critical wave) + archived goal (goal_archive phase).
      expect(await isar!.isarGoalCheckIns.where().count(), 2);
      expect(await isar!.isarBlockedUsers.where().count(), 1);
      expect(await const SyncCursorStore().read('tasks'), 10);
    });

    test(
      'cancel() before run: nothing written, first screen still released',
      () async {
        final m = merge()..cancel();

        await expectLater(m.run(), throwsA(isA<SyncCancelled>()));

        await expectLater(m.firstScreenReady, completes);
        expect(await isar!.isarTasks.where().count(), 0);
        expect(await const SyncCursorStore().read('tasks'), 0);
      },
    );

    test('session teardown mid-pull aborts before any write and still '
        'releases the first screen', () async {
      final m = merge();
      final pull = m.run();
      SessionScope.beginTeardown();
      try {
        await expectLater(pull, throwsStateError);
      } finally {
        SessionScope.endTeardown();
      }

      await expectLater(m.firstScreenReady, completes);
      expect(await isar!.isarTasks.where().count(), 0);
      expect(await isar!.isarGoalCheckIns.where().count(), 0);
    });
  });
}
