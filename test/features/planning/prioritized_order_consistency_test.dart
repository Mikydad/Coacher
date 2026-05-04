import 'dart:io';

import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/core/sync/sync_service.dart';
import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/execution/application/execution_day_loader.dart';
import 'package:coach_for_life/features/planning/application/planned_task_providers.dart';
import 'package:coach_for_life/features/planning/data/isar_planning_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../support/isar_test_harness.dart';
import '../../support/no_op_planning_repository.dart';

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

  test('hub, focus, and home use the same first prioritized task', () async {
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          IsarPlanningRepository(NoOpPlanningRepository()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(planningRepositoryProvider);
    final today = DateKeys.todayKey();
    final ids = await repo.ensureDefaultDayPlan(today);
    final now = DateTime.now();

    await repo.upsertTask(
      PlannedTask(
        id: 'upcoming',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Upcoming',
        durationMinutes: 15,
        priority: 2,
        orderIndex: 2,
        reminderEnabled: true,
        reminderTimeIso: now.add(const Duration(minutes: 20)).toIso8601String(),
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );
    await repo.upsertTask(
      PlannedTask(
        id: 'overdue',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Overdue',
        durationMinutes: 10,
        priority: 3,
        orderIndex: 3,
        reminderEnabled: true,
        reminderTimeIso: now.subtract(const Duration(minutes: 20)).toIso8601String(),
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );
    await repo.upsertTask(
      PlannedTask(
        id: 'flex',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Flexible',
        durationMinutes: 5,
        priority: 1,
        orderIndex: 1,
        reminderEnabled: false,
        reminderTimeIso: null,
        status: TaskStatus.notStarted,
        createdAtMs: 1,
        updatedAtMs: 1,
        planDateKey: today,
      ),
    );

    final hubRows = await container.read(todayAllTasksRowsProvider.future);
    final focusRows = await container.read(executionDayTasksProvider.future);
    final homeSnap = await container.read(homeFlowSnapshotProvider.future);

    expect(hubRows.first.task.id, 'overdue');
    expect(focusRows.first.id, hubRows.first.task.id);
    expect(homeSnap.nextTaskRow?.task.id, hubRows.first.task.id);
  });
}
