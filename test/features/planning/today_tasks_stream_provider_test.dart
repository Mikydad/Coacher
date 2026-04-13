import 'dart:async';
import 'dart:io';

import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/core/sync/sync_service.dart';
import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/planning/application/planned_task_collect.dart';
import 'package:coach_for_life/core/offline/offline_store.dart';
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

  test('todayAllTasksRowsProvider emits after task upsert', () async {
    final container = ProviderContainer(
      overrides: [
        planningRepositoryProvider.overrideWithValue(
          IsarPlanningRepository(NoOpPlanningRepository()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final todayMatch = Completer<List<PlannedTaskRow>>();
    var sawTarget = false;

    void checkNext(AsyncValue<List<PlannedTaskRow>> next) {
      next.whenData((rows) {
        if (sawTarget) return;
        if (rows.any((r) => r.task.id == 'stream-task')) {
          sawTarget = true;
          if (!todayMatch.isCompleted) {
            todayMatch.complete(rows);
          }
        }
      });
    }

    container.listen(todayAllTasksRowsProvider, (_, next) => checkNext(next), fireImmediately: true);

    final repo = container.read(planningRepositoryProvider);
    final today = DateKeys.todayKey();
    final ids = await repo.ensureDefaultDayPlan(today);
    await repo.upsertTask(
      PlannedTask(
        id: 'stream-task',
        routineId: ids.routineId,
        blockId: ids.blockId,
        title: 'Reactive',
        durationMinutes: 20,
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

    final rows = await todayMatch.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw TimeoutException('No stream emission with new task'),
    );
    expect(rows.any((r) => r.task.id == 'stream-task'), isTrue);
  });
}
