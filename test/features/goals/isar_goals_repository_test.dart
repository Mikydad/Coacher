import 'dart:io';

import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/goals/data/isar_goals_repository.dart';
import 'package:sidepal/features/goals/domain/models/goal_categories.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/goal_action.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_milestone.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

UserGoal _sampleGoal({required String id, required int updatedAtMs}) {
  return UserGoal(
    id: id,
    title: 'Goal $id',
    categoryId: GoalCategories.study,
    repeatCadence: GoalRepeatCadence.weekly,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.minutes,
    targetValue: 60,
    intensity: 3,
    periodStartMs: 0,
    periodEndMs: 10000,
    reminderEnabled: false,
    createdAtMs: 1,
    updatedAtMs: updatedAtMs,
  );
}

void main() {
  Isar? isar;
  Directory? dir;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    SyncService.debugSkipQueuePersistenceForTests = true;
    SyncService.instance.debugResetQueueInMemoryOnly();
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    SyncService.debugSkipQueuePersistenceForTests = false;
    SyncService.instance.debugResetQueueInMemoryOnly();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('fetchGoalsOnce returns Isar order', () async {
    final repo = IsarGoalsRepository();
    await repo.upsertGoal(_sampleGoal(id: 'a', updatedAtMs: 10));
    await repo.upsertGoal(_sampleGoal(id: 'b', updatedAtMs: 50));
    final list = await repo.fetchGoalsOnce();
    expect(list.map((g) => g.id).toList(), ['b', 'a']);
  });

  test('watchGoals emits after upsert', () async {
    final repo = IsarGoalsRepository();
    final expectation = expectLater(
      repo.watchGoals(),
      emitsInOrder(<Matcher>[
        isEmpty,
        predicate<List<UserGoal>>(
          (g) => g.length == 1 && g.single.id == 'watch-g',
        ),
      ]),
    );
    await Future<void>.delayed(Duration.zero);
    await repo.upsertGoal(_sampleGoal(id: 'watch-g', updatedAtMs: 99));
    await expectation;
  });

  test('deleteGoal removes local row', () async {
    final repo = IsarGoalsRepository();
    await repo.upsertGoal(_sampleGoal(id: 'del-g', updatedAtMs: 1));
    await repo.deleteGoal('del-g');
    expect(await repo.fetchGoalsOnce(), isEmpty);
  });

  test(
    'actions live in Isar: upsert stamps updatedAtMs, get sorts by order',
    () async {
      final repo = IsarGoalsRepository();
      await repo.upsertAction(
        const GoalAction(
          id: 'a2',
          goalId: 'g1',
          title: 'Second',
          orderIndex: 1,
        ),
      );
      await repo.upsertAction(
        const GoalAction(id: 'a1', goalId: 'g1', title: 'First', orderIndex: 0),
      );

      final actions = await repo.getActions('g1');
      expect(actions.map((a) => a.id).toList(), ['a1', 'a2']);
      // LWW stamp applied by the repository (const input had 0).
      expect(actions.every((a) => a.updatedAtMs > 0), isTrue);
      // Other goals see nothing.
      expect(await repo.getActions('other'), isEmpty);
    },
  );

  test('watchActions emits on tick without any refetch', () async {
    final repo = IsarGoalsRepository();
    await repo.upsertAction(
      const GoalAction(id: 'a1', goalId: 'g1', title: 'Step', orderIndex: 0),
    );

    final expectation = expectLater(
      repo.watchActions('g1'),
      emitsThrough(
        predicate<List<GoalAction>>(
          (list) => list.length == 1 && list.single.completed,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final current = (await repo.getActions('g1')).single;
    await repo.upsertAction(current.copyWith(completed: true));
    await expectation;
  });

  test('milestones and check-ins roundtrip through Isar', () async {
    final repo = IsarGoalsRepository();
    await repo.upsertMilestone(
      const GoalMilestone(
        id: 'm1',
        goalId: 'g1',
        title: 'Ship',
        completed: false,
        orderIndex: 0,
      ),
    );
    expect((await repo.getMilestones('g1')).single.title, 'Ship');

    await repo.upsertCheckIn(
      const GoalCheckIn(
        goalId: 'g1',
        dateKey: '2026-07-12',
        metCommitment: true,
        updatedAtMs: 0,
        value: 3,
      ),
    );
    final todays = await repo.getTodayCheckIn('g1', '2026-07-12');
    expect(todays?.metCommitment, isTrue);
    expect(todays?.value, 3);

    // Range filtering stays lexicographic on dateKey.
    await repo.upsertCheckIn(
      const GoalCheckIn(
        goalId: 'g1',
        dateKey: '2026-07-10',
        metCommitment: false,
        updatedAtMs: 0,
      ),
    );
    final windowed = await repo.getCheckInsForGoal(
      'g1',
      startDateKey: '2026-07-11',
      endDateKey: '2026-07-12',
    );
    expect(windowed.map((c) => c.dateKey).toList(), ['2026-07-12']);
  });

  test(
    'deleteGoal purges subcollection rows and queues cloud deletes',
    () async {
      final repo = IsarGoalsRepository();
      SyncService.debugUidForTests = 'test-uid';
      addTearDown(() => SyncService.debugUidForTests = null);

      await repo.upsertGoal(_sampleGoal(id: 'g1', updatedAtMs: 1));
      await repo.upsertAction(
        const GoalAction(id: 'a1', goalId: 'g1', title: 'Step', orderIndex: 0),
      );
      await repo.upsertCheckIn(
        const GoalCheckIn(
          goalId: 'g1',
          dateKey: '2026-07-12',
          metCommitment: true,
          updatedAtMs: 0,
        ),
      );

      final pendingBefore = SyncService.instance.pendingCount.value;
      await repo.deleteGoal('g1');

      expect(await repo.getActions('g1'), isEmpty);
      expect(await repo.getCheckInsForGoal('g1'), isEmpty);
      // Goal doc + action + check-in deletes queued for the cloud.
      expect(
        SyncService.instance.pendingCount.value,
        greaterThanOrEqualTo(pendingBefore + 3),
      );
    },
  );

  test(
    'mutations enqueue outbox ops instead of awaiting the network',
    () async {
      final repo = IsarGoalsRepository();
      final before = SyncService.instance.pendingCount.value;
      await repo.upsertAction(
        const GoalAction(
          id: 'a9',
          goalId: 'g9',
          title: 'Queued',
          orderIndex: 0,
        ),
      );
      expect(SyncService.instance.pendingCount.value, greaterThan(before));
    },
  );
}
