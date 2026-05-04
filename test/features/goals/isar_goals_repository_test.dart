import 'dart:io';

import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/core/sync/sync_service.dart';
import 'package:coach_for_life/features/goals/data/isar_goals_repository.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_categories.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../support/isar_test_harness.dart';
import '../../support/no_op_goals_repository.dart';

UserGoal _sampleGoal({required String id, required int updatedAtMs}) {
  return UserGoal(
    id: id,
    title: 'Goal $id',
    categoryId: GoalCategories.study,
    horizon: GoalHorizon.weekly,
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
    final repo = IsarGoalsRepository(NoOpGoalsRepository());
    await repo.upsertGoal(_sampleGoal(id: 'a', updatedAtMs: 10));
    await repo.upsertGoal(_sampleGoal(id: 'b', updatedAtMs: 50));
    final list = await repo.fetchGoalsOnce();
    expect(list.map((g) => g.id).toList(), ['b', 'a']);
  });

  test('watchGoals emits after upsert', () async {
    final repo = IsarGoalsRepository(NoOpGoalsRepository());
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
    final repo = IsarGoalsRepository(NoOpGoalsRepository());
    await repo.upsertGoal(_sampleGoal(id: 'del-g', updatedAtMs: 1));
    await repo.deleteGoal('del-g');
    expect(await repo.fetchGoalsOnce(), isEmpty);
  });
}
