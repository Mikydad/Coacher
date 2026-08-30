import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_task.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/time_blocks/domain/models/time_conflict.dart';
import 'package:sidepal/features/time_blocks/application/time_block_sync_service.dart';
import 'package:sidepal/features/time_blocks/data/time_block_repository.dart';

import '../../support/isar_test_harness.dart';

/// Miko's exact repro: task A 2:00pm/30min, task B 2:10pm/25min.
/// Overlap 2:10–2:30 = 20 min = 80% of B. Should NOT be silent.
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
    final i = isar; final d = dir; isar = null; dir = null;
    if (i != null && d != null) await closeTempIsar(i, d);
  });

  test('A(2:00,30m) then B(2:10,25m) → conflict detected', () async {
    final repo = IsarTimeBlockRepository();
    final service = TimeBlockSyncService(repository: repo);
    final twoPm = DateTime(2026, 8, 31, 14, 0);

    // Task A exists (liveness check reads isarTasks).
    await isar!.writeTxn(() async {
      await isar!.isarTasks.putByTaskId(IsarTask.fromDomain(PlannedTask(
        id: 'task-a', routineId: 'r', blockId: 'b', title: 'A',
        durationMinutes: 30, priority: 3, orderIndex: 0,
        reminderEnabled: true, reminderTimeIso: twoPm.toIso8601String(),
        status: TaskStatus.notStarted,
        createdAtMs: 1, updatedAtMs: 1,
      )));
    });

    // Save-path equivalent of syncAddTaskTimeBlock for A.
    final blockA = service.deriveBlock(
      entityId: 'task-a', entityKind: 'task',
      startAt: twoPm, durationMinutes: 30, modeRefId: 'flexible',
    );
    expect(blockA, isNotNull, reason: 'A must derive a block');
    await service.syncBlock(blockA!);

    // Pre-save gate for B.
    final proposedB = service.deriveBlock(
      entityId: 'task-b', entityKind: 'task',
      startAt: twoPm.add(const Duration(minutes: 10)),
      durationMinutes: 25, modeRefId: 'flexible',
    );
    expect(proposedB, isNotNull, reason: 'B must derive a block');

    final overlapping = await repo.listOverlappingBlocks(proposedB!);
    expect(overlapping, hasLength(1),
        reason: 'B must see A\'s stored block');

    final result = await service.checkConflicts(proposedB);
    expect(result.hasConflicts, isTrue);
    print('SEVERITY: ${result.worstSeverity}');
    expect(result.worstSeverity, isNot(ConflictSeverity.minor),
        reason: '20/25 min overlap must not be a snackbar-only minor');
  });
}
