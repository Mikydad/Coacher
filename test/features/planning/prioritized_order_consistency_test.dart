import 'dart:io';

import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/execution/application/execution_day_loader.dart';
import 'package:sidepal/features/planning/application/planned_task_providers.dart';
import 'package:sidepal/features/planning/data/isar_planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

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
    // Times must be relative to the real clock: timed tasks are hidden until
    // their scheduled time is reached, so a fixed noon reference would make
    // "overdue" not-yet-due whenever the suite runs before noon.
    //
    // Near-midnight clamp: the ±20-minute offsets below must stay inside
    // TODAY, or a fixture's reminder lands on the wrong side of midnight
    // relative to its planDateKey and the expected order flips (this
    // failed for real at 23:54 local).
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(hours: 24));
    var stableReference = now;
    if (now.subtract(const Duration(minutes: 21)).isBefore(dayStart)) {
      stableReference = dayStart.add(const Duration(minutes: 21));
    } else if (now.add(const Duration(minutes: 21)).isAfter(dayEnd)) {
      stableReference = dayEnd.subtract(const Duration(minutes: 21));
    }

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
        reminderTimeIso: stableReference
            .add(const Duration(minutes: 20))
            .toIso8601String(),
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
        reminderTimeIso: stableReference
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
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
