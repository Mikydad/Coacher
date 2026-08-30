import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:sidepal/features/analytics/data/focus_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:sidepal/features/context_override/data/context_override_repository.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:sidepal/features/reminders/application/attention_orchestrator_service.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/attention_decision.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_intent.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_type.dart';
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
  Future<void> deleteRemindersForTask(String taskId) async =>
      _all.removeWhere((r) => r.taskId == taskId);

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> ids) async =>
      _all.where((r) => ids.contains(r.taskId)).toList();

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

/// Real [reEvaluateIfAppropriate], intercepted [evaluate] — so the test sees
/// exactly what the reconciliation path would hand to the delivery pipeline.
class _Service extends AttentionOrchestratorService {
  _Service(ReminderRepository repo)
    : super(
        contextOverrideRepository: _NoOpOverrideRepo(),
        focusRepository: _NoOpFocusRepo(),
        reminderRepository: repo,
        notifications: LocalNotificationsService.instance,
        ledger: NoOpNotificationLedger(),
        logEvent: _noOpLog,
        now: () => _fixedNow,
      );

  final List<ReminderIntent> evaluated = [];

  @override
  Future<AttentionDecision> evaluate(ReminderIntent intent) async {
    evaluated.add(intent);
    return AttentionDecision.approved(
      intentId: intent.id,
      deliverAt: intent.proposedAt,
    );
  }
}

final _fixedNow = DateTime(2026, 8, 30, 14, 0);

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

ReminderConfig _config({
  bool enabled = true,
  DateTime? scheduledAt,
  String? taskTitle = 'Evening study',
}) => ReminderConfig(
  id: 'r1',
  taskId: 't1',
  taskTitle: taskTitle,
  enabled: enabled,
  scheduledAtIso: scheduledAt?.toIso8601String(),
  modeRefId: 'disciplined',
  blockUrgencyScore: 60,
  createdAtMs: _fixedNow.millisecondsSinceEpoch,
  updatedAtMs: _fixedNow.millisecondsSinceEpoch,
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  final tonight = _fixedNow.add(const Duration(hours: 7)); // 21:00
  final earlier = _fixedNow.subtract(const Duration(hours: 2)); // 12:00

  group('reEvaluateIfAppropriate — FR-R-01 / FR-R-02', () {
    test(
      'restores a lost FUTURE reminder at its original time, not now '
      '(the 9 PM reminder must not fire at 2 PM)',
      () async {
        final repo = _FakeReminderRepository()
          ..seed([_config(scheduledAt: tonight)]);
        final service = _Service(repo);

        await service.reEvaluateIfAppropriate('t1', scheduledFor: tonight);

        expect(service.evaluated.length, 1);
        expect(service.evaluated.single.proposedAt, equals(tonight));
        expect(service.evaluated.single.proposedAt.isAfter(_fixedNow), isTrue);
      },
    );

    test('falls back to the config time when the caller passes none', () async {
      final repo = _FakeReminderRepository()
        ..seed([_config(scheduledAt: tonight)]);
      final service = _Service(repo);

      await service.reEvaluateIfAppropriate('t1');

      expect(service.evaluated.single.proposedAt, equals(tonight));
    });

    test('a disabled reminder is never re-armed', () async {
      final repo = _FakeReminderRepository()
        ..seed([_config(enabled: false, scheduledAt: tonight)]);
      final service = _Service(repo);

      await service.reEvaluateIfAppropriate('t1', scheduledFor: tonight);

      expect(service.evaluated, isEmpty);
    });

    test('a time already in the past produces no delivery', () async {
      final repo = _FakeReminderRepository()
        ..seed([_config(scheduledAt: earlier)]);
      final service = _Service(repo);

      await service.reEvaluateIfAppropriate('t1', scheduledFor: earlier);

      expect(service.evaluated, isEmpty);
    });

    test('a config with no stored time and no caller time is skipped', () async {
      final repo = _FakeReminderRepository()..seed([_config()]);
      final service = _Service(repo);

      await service.reEvaluateIfAppropriate('t1');

      expect(service.evaluated, isEmpty);
    });

    test('a deleted task is skipped', () async {
      final repo = _FakeReminderRepository()..seed([]);
      final service = _Service(repo);

      await service.reEvaluateIfAppropriate('t1', scheduledFor: tonight);

      expect(service.evaluated, isEmpty);
    });

    test(
      'the restored intent is scheduled, not a follow-up, so the coaching '
      'back-off cannot suppress the user\'s own original reminder',
      () async {
        final repo = _FakeReminderRepository()
          ..seed([_config(scheduledAt: tonight)]);
        final service = _Service(repo);

        await service.reEvaluateIfAppropriate('t1', scheduledFor: tonight);

        expect(
          service.evaluated.single.reminderType,
          equals(ReminderType.scheduled),
        );
      },
    );
  });
}
