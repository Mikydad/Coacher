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
  Future<void> cancelForEntity(String entityId) async {
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
    scheduledAtIso:
        now.subtract(const Duration(minutes: 30)).toIso8601String(),
    modeRefId: modeRefId,
    blockUrgencyScore: 90,
    pendingAction: pendingAction,
    escalationLevel: escalationLevel,
    emergencyBypass: false,
    lastTriggeredAtMs: null,
    nextPromptAtIso:
        now.subtract(const Duration(minutes: 10)).toIso8601String(),
    createdAtMs: now.millisecondsSinceEpoch,
    updatedAtMs: now.millisecondsSinceEpoch,
  );
}

ReminderSyncService _makeService(
  _FakeReminderRepository repo,
  _FakeOrchestratorService orchestrator,
  DateTime now,
) {
  return ReminderSyncService(
    repository: repo,
    notifications: _FakeNotifications(),
    orchestratorService: orchestrator,
    now: () => now,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  test('scheduleFromCache produces exactly one evaluated intent per enabled reminder', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    expect(orchestrator.evaluated.length, 1);
    expect(orchestrator.evaluated.first.entityId, 't1');
    expect(orchestrator.evaluated.first.proposedAt.isAfter(now), isTrue);
  });

  test('disabled reminder is not evaluated', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([_reminder(now: now).copyWith(enabled: false)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    expect(orchestrator.evaluated, isEmpty);
  });

  test('cancelForEntity is called once per reminder during applyReminders', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    // cancelForEntity called once (before evaluate) — not 64 times.
    expect(orchestrator.cancelled.where((id) => id == 't1').length, 1);
  });

  test('requestSnooze produces a followUp ReminderIntent', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.requestSnooze('t1');

    expect(orchestrator.evaluated.length, 1);
    expect(
      orchestrator.evaluated.first.reminderType,
      ReminderType.followUp,
    );
    expect(orchestrator.evaluated.first.entityId, 't1');
  });

  test('markLogicalReasonProvided disables the reminder and cancels entity', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()..seed([_reminder(now: now)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.markLogicalReasonProvided('t1');

    final reminders = await repo.listAllReminders();
    expect(reminders.first.enabled, isFalse);
    expect(reminders.first.pendingAction, isFalse);
    expect(orchestrator.cancelled, contains('t1'));
  });

  test('reminder without taskTitle is skipped (no intent produced)', () async {
    final now = DateTime(2026, 3, 24, 10, 0);
    final repo = _FakeReminderRepository()
      ..seed([_reminder(now: now, taskTitle: null)]);
    final orchestrator = _FakeOrchestratorService();
    final service = _makeService(repo, orchestrator, now);

    await service.scheduleFromCache();

    expect(orchestrator.evaluated, isEmpty);
  });
}
