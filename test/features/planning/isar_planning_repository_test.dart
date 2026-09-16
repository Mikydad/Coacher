import 'dart:io';

import 'package:sidepal/core/local_db/isar_collections/isar_block.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_deleted_entity.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_routine.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_task.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/planning/data/isar_planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';
import '../../support/no_op_planning_repository.dart';

void main() {
  Isar? isar;
  Directory? dir;
  late IsarPlanningRepository repo;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    SyncService.debugSkipQueuePersistenceForTests = true;
    SyncService.instance.debugResetQueueInMemoryOnly();
    repo = IsarPlanningRepository(NoOpPlanningRepository());
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

  test('upsertTask persists locally and enqueues sync', () async {
    final today = '2026-04-05';
    final ids = await repo.ensureDefaultDayPlan(today);
    await repo.upsertTask(
      PlannedTask(
        id: 'task-x',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Write tests',
        durationMinutes: 30,
        priority: 2,
        orderIndex: 0,
        reminderEnabled: false,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );

    final tasks = await repo.getTasks(routineId: ids.routineId, blockId: ids.blockId);
    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Write tests');
    expect(SyncService.instance.pendingCount.value, greaterThan(0));
  });

  test('deleteTask removes row and enqueues delete', () async {
    final today = '2026-04-06';
    final ids = await repo.ensureDefaultDayPlan(today);
    await repo.upsertTask(
      PlannedTask(
        id: 'task-y',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Temp',
        durationMinutes: 15,
        priority: 3,
        orderIndex: 0,
        reminderEnabled: false,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );
    await repo.deleteTask(routineId: ids.routineId, blockId: ids.blockId, taskId: 'task-y');
    final tasks = await repo.getTasks(routineId: ids.routineId, blockId: ids.blockId);
    expect(tasks, isEmpty);
    expect(SyncService.instance.pendingCount.value, greaterThan(0));
  });

  // ── Pre-launch audit H15 — deletes leave replicated tombstones ──────────

  test('deleteTask writes a local tombstone and replicates it', () async {
    final today = '2026-04-05';
    final ids = await repo.ensureDefaultDayPlan(today);
    await repo.upsertTask(
      PlannedTask(
        id: 'task-z',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Doomed',
        durationMinutes: 10,
        priority: 3,
        orderIndex: 0,
        reminderEnabled: false,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );
    SyncService.instance.debugResetQueueInMemoryOnly();

    await repo.deleteTask(
      routineId: ids.routineId,
      blockId: ids.blockId,
      taskId: 'task-z',
    );

    final tomb = await isar!.isarDeletedEntitys
        .filter()
        .entityKeyEqualTo('task:task-z')
        .findFirst();
    expect(tomb, isNotNull);
    expect(tomb!.deletedAtMs, greaterThan(0));
    // Tombstone upsert + document delete both queued.
    expect(SyncService.instance.pendingCount.value, 2);
  });

  test('deleteRoutine tombstones the routine and every child', () async {
    final today = '2026-04-06';
    final ids = await repo.ensureDefaultDayPlan(today);
    await repo.upsertTask(
      PlannedTask(
        id: 'task-child',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Child',
        durationMinutes: 10,
        priority: 3,
        orderIndex: 0,
        reminderEnabled: false,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );

    await repo.deleteRoutine(ids.routineId);

    final keys = (await isar!.isarDeletedEntitys.where().findAll())
        .map((t) => t.entityKey)
        .toSet();
    expect(keys, containsAll(['routine:${ids.routineId}', 'block:${ids.blockId}', 'task:task-child']));
    expect(await isar!.isarTasks.where().count(), 0);
    expect(await isar!.isarBlocks.where().count(), 0);
    expect(await isar!.isarRoutines.where().count(), 0);
  });
}
