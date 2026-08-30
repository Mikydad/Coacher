import 'package:sidepal/features/analytics/data/focus_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:sidepal/features/context_override/data/context_override_repository.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:sidepal/features/reminders/application/attention_orchestrator_service.dart';
import 'package:sidepal/features/reminders/application/reminder_sync_service.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/attention_decision.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_intent.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_type.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/no_op_notification_ledger.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeReminderRepository implements ReminderRepository {
  final List<ReminderConfig> _all = [];

  @override
  Future<void> deleteRemindersForTask(String taskId) async {
    _all.removeWhere((r) => r.taskId == taskId);
  }

  void seed(Iterable<ReminderConfig> items) {
    _all
      ..clear()
      ..addAll(items);
  }

  @override
  Future<List<ReminderConfig>> listAllReminders() async =>
      List<ReminderConfig>.from(_all);

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async {
    final idSet = taskIds.toSet();
    return _all.where((r) => idSet.contains(r.taskId)).toList();
  }

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {
    final i = _all.indexWhere((r) => r.id == reminder.id);
    if (i >= 0) {
      _all[i] = reminder;
    } else {
      _all.add(reminder);
    }
  }
}

class _FakeNotifications implements ReminderNotificationsPort {
  final cancelled = <int>[];

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  int idFromTaskId(String taskId, {int slot = 0}) =>
      ('task:$taskId:$slot').hashCode.abs() % 2147483647;

  @override
  Future<bool> requestPermissionsIfNeeded() async => true;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {}
}

/// Stub orchestrator that records evaluated intents without touching Isar/OS.
class _FakeOrchestratorService extends AttentionOrchestratorService {
  _FakeOrchestratorService()
    : super(
        contextOverrideRepository: _NoOpOverrideRepo(),
        focusRepository: _NoOpFocusRepo(),
        reminderRepository: _NoOpReminderRepo(),
        notifications: LocalNotificationsService.instance,
        ledger: NoOpNotificationLedger(),
        logEvent: _noOpLog,
      );

  final List<ReminderIntent> evaluated = [];
  final List<String> cancelled = [];

  @override
  Future<AttentionDecision> evaluate(ReminderIntent intent) async {
    evaluated.add(intent);
    return AttentionDecision.approved(
      intentId: intent.id,
      deliverAt: intent.proposedAt,
    );
  }

  @override
  Future<void> cancelForEntity(String entityId, {int slotCount = 4}) async {
    cancelled.add(entityId);
  }
}

Future<void> _noOpLog({
  required AnalyticsEventType type,
  required String entityId,
  required String entityKind,
  required String sourceSurface,
  required String idempotencyKey,
  String? reason,
}) async {}

class _NoOpOverrideRepo implements ContextOverrideRepository {
  @override
  Future<UserAttentionState?> getAttentionState() async => null;
  @override
  Future<void> upsertAttentionState(UserAttentionState state) async {}
  @override
  Stream<UserAttentionState?> watchAttentionState() => const Stream.empty();
}

class _NoOpFocusRepo implements FocusRepository {
  @override
  Future<CurrentCoachingFocus?> getActiveFocus() async => null;
  @override
  Future<void> upsertFocus(CurrentCoachingFocus focus) async {}
  @override
  Future<List<CurrentCoachingFocus>> getRecentFocusHistory({
    int limit = 150,
  }) async => const [];
  @override
  Future<void> transitionFocus({
    required String focusId,
    required FocusLifecycleState newState,
    int? resolvedAtMs,
    FocusReplacementReason? replacementReason,
  }) async {}
  @override
  Future<void> archiveStaleFocus({required int nowMs}) async {}
}

class _NoOpReminderRepo implements ReminderRepository {
  @override
  Future<void> deleteRemindersForTask(String taskId) async {}

  @override
  Future<List<ReminderConfig>> listAllReminders() async => const [];
  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async => const [];
  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}
  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ReminderConfig _reminder({
  required DateTime now,
  bool pendingAction = true,
  String modeRefId = 'disciplined',
  int escalationLevel = 1,
  String? taskTitle = 'Test Task',
}) {
  return ReminderConfig(
    id: 'r1',
    taskId: 't1',
    taskTitle: taskTitle,
    enabled: true,
    scheduledAtIso: now.subtract(const Duration(minutes: 30)).toIso8601String(),
    modeRefId: modeRefId,
    blockUrgencyScore: 90,
    pendingAction: pendingAction,
    escalationLevel: escalationLevel,
    emergencyBypass: false,
    lastTriggeredAtMs: null,
    nextPromptAtIso: now
        .subtract(const Duration(minutes: 10))
        .toIso8601String(),
    createdAtMs: now.millisecondsSinceEpoch,
    updatedAtMs: now.millisecondsSinceEpoch,
  );
}

/// Counts ladder re-arms, so tests can assert the delegation rather than
/// the scheduling this service no longer owns.
class _RearmSpy {
  int calls = 0;
  Future<void> call() async => calls++;
}

ReminderSyncService _makeService(
  _FakeReminderRepository repo,
  _FakeOrchestratorService orchestrator,
  DateTime now, {
  _RearmSpy? rearm,
}) {
  return ReminderSyncService(
    repository: repo,
    notifications: _FakeNotifications(),
    orchestratorService: orchestrator,
    rearmLadders: rearm?.call,
    now: () => now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  test(
    'scheduleFromCache produces exactly one evaluated intent per enabled reminder',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.scheduleFromCache();

      expect(orchestrator.evaluated.length, 1);
      expect(orchestrator.evaluated.first.entityId, 't1');
      expect(orchestrator.evaluated.first.proposedAt.isAfter(now), isTrue);
    },
  );

  test('disabled reminder is not evaluated', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([_reminder(now: now).copyWith(enabled: false)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    expect(orchestrator.evaluated, isEmpty);
  });

  // ── C6: the armed alarm survives an evaluation that arms nothing ──────────

  test(
    'applyReminders does not pre-cancel a reminder it is about to evaluate '
    '(C6: the orchestrator owns the swap, after approval)',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.scheduleFromCache();

      // The reminder WAS evaluated...
      expect(orchestrator.evaluated.length, 1);
      // ...and the caller did not destroy the live slot on the way in. The
      // cancel now happens inside _executeDecision, after the budget check
      // approves — so a suppression or denial leaves the user's alarm intact.
      expect(orchestrator.cancelled, isEmpty);
    },
  );

  test(
    'applyReminders cancels a reminder it will NOT arm a replacement for',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()
        ..seed([_reminder(now: now).copyWith(enabled: false)]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.scheduleFromCache();

      expect(orchestrator.evaluated, isEmpty);
      expect(orchestrator.cancelled.where((id) => id == 't1').length, 1);
    },
  );

  test(
    'a blank-title reminder produces no intent and still gets cancelled',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()
        ..seed([_reminder(now: now, taskTitle: '  ')]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.scheduleFromCache();

      expect(orchestrator.evaluated, isEmpty);
      expect(orchestrator.cancelled.where((id) => id == 't1').length, 1);
    },
  );

  test(
    'removeForDeletedTask cancels the OS notification and deletes the config '
    'so scheduleFromCache cannot re-arm it',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.removeForDeletedTask('t1');

      expect(orchestrator.cancelled, contains('t1'));
      expect(await repo.listAllReminders(), isEmpty);

      // The boot path must find nothing to re-arm.
      await service.scheduleFromCache();
      expect(orchestrator.evaluated, isEmpty);
    },
  );

  test('requestSnooze produces a followUp ReminderIntent', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.requestSnooze('t1');

    expect(orchestrator.evaluated.length, 1);
    expect(orchestrator.evaluated.first.reminderType, ReminderType.followUp);
    expect(orchestrator.evaluated.first.entityId, 't1');
  });

  test(
    'markLogicalReasonProvided disables the reminder and cancels entity',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.markLogicalReasonProvided('t1');

      final reminders = await repo.listAllReminders();
      expect(reminders.first.enabled, isFalse);
      expect(reminders.first.pendingAction, isFalse);
      expect(orchestrator.cancelled, contains('t1'));
    },
  );

  test('reminder without taskTitle is skipped (no intent produced)', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([_reminder(now: now, taskTitle: null)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    expect(orchestrator.evaluated, isEmpty);
  });

  // ── R3 ownership: the ladder arms scheduled slots, not this service ───────

  test(
    'a scheduled (non-snoozed) reminder is NOT armed here — the ladder '
    'compiler owns it, so slot 0 has exactly one owner',
    () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()
        ..seed([
          _reminder(now: now, pendingAction: false).copyWith(
            scheduledAtIso: DateTime(2026, 3, 24, 18, 0).toIso8601String(),
          ),
        ]);
      final orchestrator = _FakeOrchestratorService();
      final service = _makeService(repo, orchestrator, now);

      await service.scheduleFromCache();

      expect(orchestrator.evaluated, isEmpty);
      // ...and the live slot is NOT destroyed on the way past (C6 still holds).
      expect(orchestrator.cancelled, isEmpty);
    },
  );

  test('a snoozed reminder IS still re-planned here', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([_reminder(now: now, pendingAction: true)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    expect(orchestrator.evaluated, hasLength(1));
    expect(orchestrator.evaluated.single.reminderType, ReminderType.followUp);
  });

  test('saving a reminder triggers a ladder re-arm', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final rearm = _RearmSpy();
    final service = _makeService(
      repo,
      _FakeOrchestratorService(),
      now,
      rearm: rearm,
    );

    await service.syncForTaskIds(['t1']);

    expect(rearm.calls, 1);
  });

  // ── C3: a task carried to tomorrow keeps a reminder ────────────────────────

  group('shiftToDate — carry-forward (AUDIT §10 C3)', () {
    test('shiftIsoToDate moves the date and keeps the time of day', () {
      final shifted = ReminderSyncService.shiftIsoToDate(
        DateTime(2026, 3, 24, 7, 45).toIso8601String(),
        DateTime(2026, 3, 25, 23, 59),
      );
      expect(shifted, DateTime(2026, 3, 25, 7, 45));
    });

    test('shiftIsoToDate is null-safe', () {
      expect(
        ReminderSyncService.shiftIsoToDate(null, DateTime(2026, 3, 25)),
        isNull,
      );
      expect(
        ReminderSyncService.shiftIsoToDate('not a date', DateTime(2026, 3, 25)),
        isNull,
      );
    });

    test(
      "moving a task to tomorrow moves its reminder's DATE, keeping the time "
      'of day — the whole of C3',
      () async {
        final now = DateTime(2026, 3, 24, 10, 0);
        // A reminder set for 07:00 today — already past, which is exactly the
        // stale state a carried-forward task used to inherit forever.
        final repo = _FakeReminderRepository()
          ..seed([
            _reminder(now: now, pendingAction: false).copyWith(
              scheduledAtIso: DateTime(2026, 3, 24, 7, 0).toIso8601String(),
            ),
          ]);
        final service = _makeService(repo, _FakeOrchestratorService(), now);

        await service.shiftToDate('t1', targetDay: DateTime(2026, 3, 25));

        final stored = (await repo.listAllReminders()).single;
        expect(
          DateTime.parse(stored.scheduledAtIso!),
          DateTime(2026, 3, 25, 7, 0),
        );
      },
    );

    test('shiftToDate clears any stale escalation state', () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()
        ..seed([_reminder(now: now, escalationLevel: 3)]);
      final service = _makeService(repo, _FakeOrchestratorService(), now);

      await service.shiftToDate('t1', targetDay: DateTime(2026, 3, 25));

      final stored = (await repo.listAllReminders()).single;
      expect(stored.escalationLevel, 0);
      expect(stored.pendingAction, isFalse);
      expect(stored.nextPromptAtIso, isNull);
    });

    test('shiftToDate on an unknown task is a safe no-op', () async {
      final now = DateTime(2026, 3, 24, 10, 0);
      final repo = _FakeReminderRepository()..seed([]);
      final service = _makeService(repo, _FakeOrchestratorService(), now);
      await service.shiftToDate('nobody', targetDay: DateTime(2026, 3, 25));
      expect(await repo.listAllReminders(), isEmpty);
    });
  });
}
