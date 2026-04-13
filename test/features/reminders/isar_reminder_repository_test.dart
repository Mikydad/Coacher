import 'dart:io';

import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/core/sync/sync_service.dart';
import 'package:coach_for_life/features/reminders/data/isar_reminder_repository.dart';
import 'package:coach_for_life/features/reminders/data/reminder_repository.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../support/isar_test_harness.dart';

class _MemoryRemoteReminders implements ReminderRepository {
  _MemoryRemoteReminders(this.rows);
  final List<ReminderConfig> rows;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => [];

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async {
    final s = taskIds.toSet();
    return rows.where((r) => s.contains(r.taskId)).toList();
  }

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
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

  test('upsertReminder and listAllReminders', () async {
    final remote = _MemoryRemoteReminders(const []);
    final repo = IsarReminderRepository(remote);
    final r = ReminderConfig(
      id: 'rem-a',
      taskId: 't-a',
      enabled: true,
      scheduledAtIso: '2026-04-05T08:00:00.000',
      pendingAction: false,
      escalationLevel: 0,
      emergencyBypass: false,
      createdAtMs: 1,
      updatedAtMs: 2,
    );
    await repo.upsertReminder(r);
    final all = await repo.listAllReminders();
    expect(all, hasLength(1));
    expect(all.single.id, 'rem-a');
  });

  test('getRemindersForTasks filters by task id', () async {
    final remote = _MemoryRemoteReminders(const []);
    final repo = IsarReminderRepository(remote);
    await repo.upsertReminder(
      ReminderConfig(
        id: 'r1',
        taskId: 'ta',
        enabled: true,
        scheduledAtIso: null,
        pendingAction: false,
        escalationLevel: 0,
        emergencyBypass: false,
        createdAtMs: 1,
        updatedAtMs: 1,
      ),
    );
    await repo.upsertReminder(
      ReminderConfig(
        id: 'r2',
        taskId: 'tb',
        enabled: true,
        scheduledAtIso: null,
        pendingAction: false,
        escalationLevel: 0,
        emergencyBypass: false,
        createdAtMs: 1,
        updatedAtMs: 1,
      ),
    );
    final slice = await repo.getRemindersForTasks(['tb']);
    expect(slice, hasLength(1));
    expect(slice.single.taskId, 'tb');
  });

  test('hydrateFromRemoteForTasks merges remote rows', () async {
    final incoming = ReminderConfig(
      id: 'r-remote',
      taskId: 'tx',
      enabled: true,
      scheduledAtIso: null,
      pendingAction: true,
      escalationLevel: 1,
      emergencyBypass: false,
      createdAtMs: 5,
      updatedAtMs: 100,
    );
    final remote = _MemoryRemoteReminders([incoming]);
    final repo = IsarReminderRepository(remote);
    await repo.hydrateFromRemoteForTasks(['tx']);
    final all = await repo.listAllReminders();
    expect(all, hasLength(1));
    expect(all.single.updatedAtMs, 100);
  });
}
