import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_task.dart';
import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/core/sync/isar_lww_merge.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../support/isar_test_harness.dart';

PlannedTask _task({required String id, required int updatedAtMs, String planDateKey = '2026-04-05'}) {
  return PlannedTask(
    id: id,
    routineId: 'r1',
    blockId: 'b1',
    title: 'Task',
    durationMinutes: 25,
    priority: 2,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 1,
    updatedAtMs: updatedAtMs,
    planDateKey: planDateKey,
    notes: 'n',
    sequenceIndex: 7,
    strictModeRequired: true,
    modeRefId: 'disciplined',
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
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('does not overwrite newer local task', () async {
    final db = isar!;
    final local = _task(id: 't1', updatedAtMs: 200);
    await db.writeTxn(() async {
      await db.isarTasks.putByTaskId(IsarTask.fromDomain(local));
    });

    final olderRemote = _task(id: 't1', updatedAtMs: 100);
    await mergePlannedTaskLwwIntoIsar(
      db,
      PlannedTask(
        id: olderRemote.id,
        routineId: olderRemote.routineId,
        blockId: olderRemote.blockId,
        title: 'Remote',
        durationMinutes: olderRemote.durationMinutes,
        priority: olderRemote.priority,
        orderIndex: olderRemote.orderIndex,
        reminderEnabled: olderRemote.reminderEnabled,
        reminderTimeIso: olderRemote.reminderTimeIso,
        status: olderRemote.status,
        createdAtMs: olderRemote.createdAtMs,
        updatedAtMs: olderRemote.updatedAtMs,
        planDateKey: olderRemote.planDateKey,
        notes: olderRemote.notes,
        sequenceIndex: olderRemote.sequenceIndex,
        strictModeRequired: olderRemote.strictModeRequired,
        modeRefId: olderRemote.modeRefId,
      ),
    );

    final row = await db.isarTasks.filter().taskIdEqualTo('t1').findFirst();
    expect(row, isNotNull);
    expect(row!.updatedAtMs, 200);
    expect(row.title, 'Task');
  });

  test('applies strictly newer remote task', () async {
    final db = isar!;
    final local = _task(id: 't2', updatedAtMs: 50);
    await db.writeTxn(() async {
      await db.isarTasks.putByTaskId(IsarTask.fromDomain(local));
    });

    final newerRemote = _task(id: 't2', updatedAtMs: 300);
    await mergePlannedTaskLwwIntoIsar(
      db,
      PlannedTask(
        id: newerRemote.id,
        routineId: newerRemote.routineId,
        blockId: newerRemote.blockId,
        title: 'From cloud',
        durationMinutes: newerRemote.durationMinutes,
        priority: newerRemote.priority,
        orderIndex: newerRemote.orderIndex,
        reminderEnabled: newerRemote.reminderEnabled,
        reminderTimeIso: newerRemote.reminderTimeIso,
        status: newerRemote.status,
        createdAtMs: newerRemote.createdAtMs,
        updatedAtMs: newerRemote.updatedAtMs,
        planDateKey: newerRemote.planDateKey,
        notes: newerRemote.notes,
        sequenceIndex: newerRemote.sequenceIndex,
        strictModeRequired: newerRemote.strictModeRequired,
        modeRefId: newerRemote.modeRefId,
      ),
    );

    final row = await db.isarTasks.filter().taskIdEqualTo('t2').findFirst();
    expect(row, isNotNull);
    expect(row!.updatedAtMs, 300);
    expect(row.title, 'From cloud');
  });
}
