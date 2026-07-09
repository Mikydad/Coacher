import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import 'package:coach_for_life/core/notifications/notification_ledger_repository.dart';
import 'package:coach_for_life/core/notifications/notification_ledger_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;
  late NotificationLedgerRepository repo;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    repo = NotificationLedgerRepository(isar!);
  });

  tearDown(() async {
    await closeTempIsar(isar!, dir!);
  });

  // ── helpers ─────────────────────────────────────────────────────────────────

  IsarNotificationLedgerEntry _makeEntry({
    int notifId = 42,
    String entityId = 'task-abc',
    String entityKind = 'task',
    NotificationLedgerState state = NotificationLedgerState.scheduled,
    int? scheduledForMs,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return IsarNotificationLedgerEntry()
      ..notifId = notifId
      ..entityId = entityId
      ..entityKind = entityKind
      ..state = state.name
      ..scheduledForMs = scheduledForMs ?? now
      ..sourceContext = 'test'
      ..updatedAtMs = now;
  }

  // ── tests ────────────────────────────────────────────────────────────────────

  group('NotificationLedgerRepository', () {
    test('upsertEntry then findByNotifId returns the same entry', () async {
      final entry = _makeEntry(notifId: 10, entityId: 'task-1');
      await repo.upsertEntry(entry);

      final found = await repo.findByNotifId(10);
      expect(found, isNotNull);
      expect(found!.entityId, equals('task-1'));
      expect(found.state, equals(NotificationLedgerState.scheduled.name));
    });

    test('findByEntityId returns most recent entry for entity', () async {
      final first = _makeEntry(notifId: 1, entityId: 'task-x');
      await repo.upsertEntry(first);

      final second = IsarNotificationLedgerEntry()
        ..notifId = 2
        ..entityId = 'task-x'
        ..entityKind = 'task'
        ..state = NotificationLedgerState.delivered.name
        ..scheduledForMs = DateTime.now().millisecondsSinceEpoch
        ..sourceContext = 'test'
        ..updatedAtMs = DateTime.now().millisecondsSinceEpoch + 100;
      await repo.upsertEntry(second);

      final found = await repo.findByEntityId('task-x');
      expect(found, isNotNull);
      expect(found!.notifId, equals(2)); // most recent by updatedAtMs
    });

    test('markCancelled transitions state to cancelled', () async {
      final entry = _makeEntry(notifId: 20, entityId: 'task-cancel');
      await repo.upsertEntry(entry);

      await repo.markCancelled('task-cancel');

      final updated = await repo.findByEntityId('task-cancel');
      expect(updated!.state, equals(NotificationLedgerState.cancelled.name));
      expect(updated.cancelledAtMs, isNotNull);
    });

    test('markDelivered sets deliveredAtMs', () async {
      final entry = _makeEntry(notifId: 30, entityId: 'task-deliver');
      await repo.upsertEntry(entry);

      await repo.markDelivered(30);

      final updated = await repo.findByNotifId(30);
      expect(updated!.state, equals(NotificationLedgerState.delivered.name));
      expect(updated.deliveredAtMs, isNotNull);
    });

    test('markInteraction records interactionType and resets ignoredCount', () async {
      final entry = _makeEntry(notifId: 40, entityId: 'task-interact')
        ..ignoredCount = 5;
      await repo.upsertEntry(entry);

      await repo.markInteraction(40, 'opened');

      final updated = await repo.findByNotifId(40);
      expect(updated!.interactionType, equals('opened'));
      expect(updated.interactedAtMs, isNotNull);
      expect(updated.ignoredCount, equals(0)); // reset on positive interaction
    });

    test('getByState returns only matching entries', () async {
      await repo.upsertEntry(
        _makeEntry(notifId: 1, entityId: 'a', state: NotificationLedgerState.scheduled),
      );
      await repo.upsertEntry(
        _makeEntry(notifId: 2, entityId: 'b', state: NotificationLedgerState.delivered),
      );
      await repo.upsertEntry(
        _makeEntry(notifId: 3, entityId: 'c', state: NotificationLedgerState.scheduled),
      );

      final scheduled = await repo.getByState(NotificationLedgerState.scheduled);
      expect(scheduled.length, equals(2));
      expect(scheduled.map((e) => e.entityId).toSet(), equals({'a', 'c'}));

      final delivered = await repo.getByState(NotificationLedgerState.delivered);
      expect(delivered.length, equals(1));
    });

    test('pruneOlderThan deletes old entries and leaves fresh ones', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oldMs = now - const Duration(hours: 80).inMilliseconds;
      final freshMs = now - const Duration(hours: 1).inMilliseconds;

      final old = _makeEntry(notifId: 100, entityId: 'old-task')
        ..scheduledForMs = oldMs;
      final fresh = _makeEntry(notifId: 101, entityId: 'fresh-task')
        ..scheduledForMs = freshMs;

      await repo.upsertEntry(old);
      await repo.upsertEntry(fresh);

      await repo.pruneOlderThan(const Duration(hours: 72));

      expect(await repo.findByNotifId(100), isNull); // pruned
      expect(await repo.findByNotifId(101), isNotNull); // kept
    });
  });
}
