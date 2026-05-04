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

  test('todayAllTasksRowsProvider keeps layered priority ordering', () async {
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
    final past = now.subtract(const Duration(minutes: 10));
    final future = now.add(const Duration(minutes: 10));
    final safePast = (past.year == now.year && past.month == now.month && past.day == now.day)
        ? past
        : DateTime(now.year, now.month, now.day, 0, 0);
    final safeFuture = (future.year == now.year && future.month == now.month && future.day == now.day)
        ? future
        : DateTime(now.year, now.month, now.day, 23, 59);

    Future<void> addTask({
      required String id,
      required int duration,
      required int priority,
      required int orderIndex,
      String? reminderTimeIso,
    }) async {
      await repo.upsertTask(
        PlannedTask(
          id: id,
          routineId: ids.routineId,
          blockId: ids.blockId,
          title: id,
          durationMinutes: duration,
          priority: priority,
          orderIndex: orderIndex,
          reminderEnabled: reminderTimeIso != null,
          reminderTimeIso: reminderTimeIso,
          status: TaskStatus.notStarted,
          createdAtMs: 1,
          updatedAtMs: 1,
          planDateKey: today,
        ),
      );
    }

    await addTask(
      id: 'overdue',
      duration: 25,
      priority: 3,
      orderIndex: 20,
      reminderTimeIso: safePast.toIso8601String(),
    );
    await addTask(
      id: 'upcoming',
      duration: 25,
      priority: 3,
      orderIndex: 21,
      reminderTimeIso: safeFuture.toIso8601String(),
    );
    await addTask(id: 'flex-1', duration: 5, priority: 3, orderIndex: 0);
    await addTask(id: 'flex-2', duration: 8, priority: 3, orderIndex: 1);
    await addTask(id: 'flex-3', duration: 12, priority: 3, orderIndex: 2);
    await addTask(id: 'flex-4', duration: 40, priority: 3, orderIndex: 3);

    final rows = await container.read(todayAllTasksRowsProvider.future);
    final idsOrdered = rows.map((r) => r.task.id).toList();

    expect(idsOrdered.take(2), ['overdue', 'upcoming']);
    expect(idsOrdered.skip(2), ['flex-1', 'flex-2', 'flex-3', 'flex-4']);
  });

  test('manual reorder stays stable after refresh within same section', () async {
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

    Future<void> addTask({
      required String id,
      required int orderIndex,
      required int sequenceIndex,
    }) async {
      await repo.upsertTask(
        PlannedTask(
          id: id,
          routineId: ids.routineId,
          blockId: ids.blockId,
          title: id,
          durationMinutes: 20,
          priority: 3,
          orderIndex: orderIndex,
          reminderEnabled: false,
          reminderTimeIso: null,
          status: TaskStatus.notStarted,
          createdAtMs: 1,
          updatedAtMs: 1,
          planDateKey: today,
          sequenceIndex: sequenceIndex,
        ),
      );
    }

    await addTask(id: 'a', orderIndex: 0, sequenceIndex: 0);
    await addTask(id: 'b', orderIndex: 1, sequenceIndex: 1);
    await addTask(id: 'c', orderIndex: 2, sequenceIndex: 2);

    Future<List<String>> orderedTaskIds() async {
      final rows = await container.read(todayAllTasksRowsProvider.future);
      return rows.map((r) => r.task.id).toList();
    }

    expect(await orderedTaskIds(), ['a', 'b', 'c']);

    // Simulate Tasks Hub reorder result: move "c" to top within flexible section.
    await addTask(id: 'c', orderIndex: 0, sequenceIndex: 0);
    await addTask(id: 'a', orderIndex: 1, sequenceIndex: 1);
    await addTask(id: 'b', orderIndex: 2, sequenceIndex: 2);

    container.invalidate(todayAllTasksRowsProvider);
    final firstRefresh = await orderedTaskIds();
    container.invalidate(todayAllTasksRowsProvider);
    final secondRefresh = await orderedTaskIds();

    expect(firstRefresh, ['c', 'a', 'b']);
    expect(secondRefresh, firstRefresh);
  });
}
