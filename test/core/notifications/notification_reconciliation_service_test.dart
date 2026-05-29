import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import 'package:coach_for_life/core/notifications/notification_ledger_repository.dart';
import 'package:coach_for_life/core/notifications/notification_ledger_state.dart';
import 'package:coach_for_life/core/notifications/notification_reconciliation_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../support/isar_test_harness.dart';

// ── Fakes implementing the abstract interfaces ────────────────────────────────

class _FakeNotifications implements ActiveNotificationsSource {
  final List<ActiveNotification> active;
  final List<int> cancelledIds = [];

  _FakeNotifications(this.active);

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => active;

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);
}

class _FakeOrchestrator implements OrchestratorReEvaluator {
  final List<String> reEvaluatedIds = [];

  @override
  Future<void> reEvaluateIfAppropriate(String entityId) async {
    reEvaluatedIds.add(entityId);
  }
}

ActiveNotification _notif(int id) =>
    ActiveNotification(id: id, channelId: 'test', title: 'Test', body: 'body');

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  Isar? isar;
  Directory? dir;
  late NotificationLedgerRepository ledger;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    ledger = NotificationLedgerRepository(isar!);
  });

  tearDown(() async => closeTempIsar(isar!, dir!));

  IsarNotificationLedgerEntry _entry({
    required int notifId,
    required String entityId,
    NotificationLedgerState state = NotificationLedgerState.scheduled,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return IsarNotificationLedgerEntry()
      ..notifId = notifId
      ..entityId = entityId
      ..entityKind = 'task'
      ..state = state.name
      ..scheduledForMs = now
      ..sourceContext = 'test'
      ..updatedAtMs = now;
  }

  group('NotificationReconciliationService', () {
    test(
      'ledger entry in scheduled state NOT in OS tray → marked cancelled',
      () async {
        await ledger.upsertEntry(
          _entry(notifId: 100, entityId: 'task-ghost'),
        );

        final fakeNotifs = _FakeNotifications([]); // empty tray
        final fakeOrchestrator = _FakeOrchestrator();

        await NotificationReconciliationService(
          ledger: ledger,
          notifications: fakeNotifs,
          orchestrator: fakeOrchestrator,
        ).reconcile();

        final updated = await ledger.findByEntityId('task-ghost');
        expect(
          updated!.state,
          equals(NotificationLedgerState.cancelled.name),
        );
        expect(fakeOrchestrator.reEvaluatedIds, contains('task-ghost'));
      },
    );

    test(
      'OS tray notification NOT in ledger → cancelled via notifications.cancel',
      () async {
        // Tray has notifId 200 but ledger is empty.
        final fakeNotifs = _FakeNotifications([_notif(200)]);
        final fakeOrchestrator = _FakeOrchestrator();

        await NotificationReconciliationService(
          ledger: ledger,
          notifications: fakeNotifs,
          orchestrator: fakeOrchestrator,
        ).reconcile();

        expect(fakeNotifs.cancelledIds, contains(200));
      },
    );

    test(
      'ledger entry in scheduled state IS in OS tray → unchanged after reconcile',
      () async {
        await ledger.upsertEntry(
          _entry(notifId: 300, entityId: 'task-alive'),
        );

        final fakeNotifs = _FakeNotifications([_notif(300)]); // tray has it
        final fakeOrchestrator = _FakeOrchestrator();

        await NotificationReconciliationService(
          ledger: ledger,
          notifications: fakeNotifs,
          orchestrator: fakeOrchestrator,
        ).reconcile();

        final updated = await ledger.findByEntityId('task-alive');
        // Still scheduled — not cancelled
        expect(
          updated!.state,
          equals(NotificationLedgerState.scheduled.name),
        );
        expect(fakeOrchestrator.reEvaluatedIds, isEmpty);
        expect(fakeNotifs.cancelledIds, isEmpty);
      },
    );
  });
}
