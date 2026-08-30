import 'dart:io';

import 'package:sidepal/core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import 'package:sidepal/core/notifications/notification_ledger_repository.dart';
import 'package:sidepal/core/notifications/notification_ledger_state.dart';
import 'package:sidepal/core/notifications/notification_reconciliation_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

// ── Fakes implementing the abstract interfaces ────────────────────────────────

/// Models the two OS queues independently, as the real platform does: a
/// future-scheduled notification lives ONLY in `pending`, one already on
/// screen lives ONLY in `active`.
class _FakeNotifications implements ActiveNotificationsSource {
  _FakeNotifications({
    List<ActiveNotification>? active,
    List<PendingNotificationRequest>? pending,
  }) : active = active ?? const [],
       pending = pending ?? const [];

  final List<ActiveNotification> active;
  final List<PendingNotificationRequest> pending;
  final List<int> cancelledIds = [];

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => active;

  @override
  Future<List<PendingNotificationRequest>>
  getPendingNotificationRequests() async => pending;

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);
}

class _ReArmCall {
  const _ReArmCall(this.entityId, this.scheduledFor);
  final String entityId;
  final DateTime? scheduledFor;
}

class _FakeOrchestrator implements OrchestratorReEvaluator {
  final List<_ReArmCall> calls = [];

  List<String> get reEvaluatedIds =>
      calls.map((c) => c.entityId).toList(growable: false);

  @override
  Future<void> reEvaluateIfAppropriate(
    String entityId, {
    DateTime? scheduledFor,
  }) async {
    calls.add(_ReArmCall(entityId, scheduledFor));
  }
}

ActiveNotification _notif(int id) =>
    ActiveNotification(id: id, channelId: 'test', title: 'Test', body: 'body');

PendingNotificationRequest _pending(int id) =>
    PendingNotificationRequest(id, 'Test', 'body', null);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  Isar? isar;
  Directory? dir;
  late NotificationLedgerRepository ledger;

  // Fixed clock so "future" and "past" are unambiguous.
  final now = DateTime(2026, 8, 30, 14, 0);
  final future = now.add(const Duration(hours: 7)); // tonight at 21:00
  final past = now.subtract(const Duration(hours: 2)); // noon, already gone

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    ledger = NotificationLedgerRepository(isar!);
  });

  tearDown(() async => closeTempIsar(isar!, dir!));

  IsarNotificationLedgerEntry entry({
    required int notifId,
    required String entityId,
    required DateTime scheduledFor,
    NotificationLedgerState state = NotificationLedgerState.scheduled,
    String entityKind = 'task',
  }) {
    return IsarNotificationLedgerEntry()
      ..notifId = notifId
      ..entityId = entityId
      ..entityKind = entityKind
      ..state = state.name
      ..scheduledForMs = scheduledFor.millisecondsSinceEpoch
      ..sourceContext = 'test'
      ..updatedAtMs = now.millisecondsSinceEpoch;
  }

  NotificationReconciliationService service(
    _FakeNotifications notifs,
    _FakeOrchestrator orchestrator,
  ) => NotificationReconciliationService(
    ledger: ledger,
    notifications: notifs,
    orchestrator: orchestrator,
    now: () => now,
  );

  group('NotificationReconciliationService — T1: the pending queue counts', () {
    test(
      'a correctly armed FUTURE reminder sits in the pending queue and is '
      'left completely alone (the at-app-open misfire)',
      () async {
        await ledger.upsertEntry(
          entry(notifId: 100, entityId: 'task-tonight', scheduledFor: future),
        );

        // Empty tray — exactly the cold-start state that used to mark this
        // row cancelled and re-deliver it immediately.
        final notifs = _FakeNotifications(pending: [_pending(100)]);
        final orchestrator = _FakeOrchestrator();

        await service(notifs, orchestrator).reconcile();

        final updated = await ledger.findByNotifId(100);
        expect(updated!.state, equals(NotificationLedgerState.scheduled.name));
        expect(orchestrator.calls, isEmpty);
        expect(notifs.cancelledIds, isEmpty);
      },
    );

    test(
      'a row sitting in the delivered tray is stamped delivered, not '
      're-delivered (FR-R-81 / L1)',
      () async {
        await ledger.upsertEntry(
          entry(notifId: 300, entityId: 'task-alive', scheduledFor: past),
        );

        final notifs = _FakeNotifications(active: [_notif(300)]);
        final orchestrator = _FakeOrchestrator();

        await service(notifs, orchestrator).reconcile();

        final updated = await ledger.findByNotifId(300);
        expect(updated!.state, equals(NotificationLedgerState.delivered.name));
        expect(orchestrator.calls, isEmpty);
        expect(notifs.cancelledIds, isEmpty);
      },
    );
  });

  group('NotificationReconciliationService — genuinely lost rows', () {
    test(
      'lost row still in the FUTURE re-arms at its ORIGINAL time, never now',
      () async {
        await ledger.upsertEntry(
          entry(notifId: 110, entityId: 'task-lost', scheduledFor: future),
        );

        final notifs = _FakeNotifications(); // both queues empty
        final orchestrator = _FakeOrchestrator();

        await service(notifs, orchestrator).reconcile();

        expect(orchestrator.calls.length, 1);
        expect(orchestrator.calls.single.entityId, 'task-lost');
        expect(orchestrator.calls.single.scheduledFor, equals(future));
        // and emphatically not "now"
        expect(orchestrator.calls.single.scheduledFor, isNot(equals(now)));
      },
    );

    test(
      'a row past its time and no longer pending is PRESUMED FIRED — the '
      'closest thing iOS gives to a delivery callback (L1)',
      () async {
        await ledger.upsertEntry(
          entry(notifId: 120, entityId: 'task-missed', scheduledFor: past),
        );

        final notifs = _FakeNotifications();
        final orchestrator = _FakeOrchestrator();

        await service(notifs, orchestrator).reconcile();

        final updated = await ledger.findByNotifId(120);
        expect(updated!.state, equals(NotificationLedgerState.delivered.name));
        // Presumed fired is NOT permission to fire it again.
        expect(orchestrator.calls, isEmpty);
      },
    );

    test('a row with no stored time is never re-delivered', () async {
      final row = entry(notifId: 130, entityId: 'task-untimed', scheduledFor: future)
        ..scheduledForMs = null;
      await ledger.upsertEntry(row);

      final notifs = _FakeNotifications();
      final orchestrator = _FakeOrchestrator();

      await service(notifs, orchestrator).reconcile();

      expect(orchestrator.calls, isEmpty);
      final updated = await ledger.findByNotifId(130);
      expect(updated!.state, equals(NotificationLedgerState.delivered.name));
    });

    test('the pass records what it did, for the health row (FR-R-80)', () async {
      await ledger.upsertEntry(
        entry(notifId: 150, entityId: 'fired', scheduledFor: past),
      );

      await service(_FakeNotifications(), _FakeOrchestrator()).reconcile();

      expect(NotificationReconciliationService.lastRunAtMs, isNotNull);
      expect(
        NotificationReconciliationService.lastRunSummary,
        contains('1 delivered'),
      );
    });

    test(
      'reconciling one lost slot of a multi-slot entity spares its siblings',
      () async {
        // Intention ladders arm several slots under ONE entityId; the old
        // entity-scoped markCancelled took out whichever row it found first.
        await ledger.upsertEntry(
          entry(
            notifId: 140,
            entityId: 'intention-1',
            entityKind: 'intention',
            scheduledFor: past,
          ),
        );
        await ledger.upsertEntry(
          entry(
            notifId: 141,
            entityId: 'intention-1',
            entityKind: 'intention',
            scheduledFor: future,
          ),
        );

        // Slot 141 is still correctly armed; slot 140 is gone.
        final notifs = _FakeNotifications(pending: [_pending(141)]);
        final orchestrator = _FakeOrchestrator();

        await service(notifs, orchestrator).reconcile();

        // Slot 140's time has passed and it is no longer pending → fired.
        expect(
          (await ledger.findByNotifId(140))!.state,
          equals(NotificationLedgerState.delivered.name),
        );
        expect(
          (await ledger.findByNotifId(141))!.state,
          equals(NotificationLedgerState.scheduled.name),
        );
      },
    );
  });

  group('NotificationReconciliationService — phantom pass', () {
    test('a tray notification with no ledger row at all is cancelled', () async {
      final notifs = _FakeNotifications(active: [_notif(200)]);
      final orchestrator = _FakeOrchestrator();

      await service(notifs, orchestrator).reconcile();

      expect(notifs.cancelledIds, contains(200));
    });

    test(
      'a tray notification whose row a snooze race left in snoozed state is '
      'NOT cancelled (L2 fallout)',
      () async {
        await ledger.upsertEntry(
          entry(
            notifId: 210,
            entityId: 'task-snoozed',
            scheduledFor: past,
            state: NotificationLedgerState.snoozed,
          ),
        );

        final notifs = _FakeNotifications(active: [_notif(210)]);
        final orchestrator = _FakeOrchestrator();

        await service(notifs, orchestrator).reconcile();

        expect(notifs.cancelledIds, isEmpty);
      },
    );

    test('a tray notification whose row is cancelled is swept', () async {
      await ledger.upsertEntry(
        entry(
          notifId: 220,
          entityId: 'task-dead',
          scheduledFor: past,
          state: NotificationLedgerState.cancelled,
        ),
      );

      final notifs = _FakeNotifications(active: [_notif(220)]);
      final orchestrator = _FakeOrchestrator();

      await service(notifs, orchestrator).reconcile();

      expect(notifs.cancelledIds, contains(220));
    });
  });
}
