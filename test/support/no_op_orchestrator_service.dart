import 'package:coach_for_life/core/notifications/local_notifications_service.dart';
import 'package:coach_for_life/features/analytics/data/focus_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:coach_for_life/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:coach_for_life/features/context_override/data/context_override_repository.dart';
import 'package:coach_for_life/features/context_override/domain/models/user_attention_state.dart';
import 'package:coach_for_life/features/reminders/application/attention_orchestrator_service.dart';
import 'package:coach_for_life/features/reminders/data/reminder_repository.dart';
import 'package:coach_for_life/features/reminders/domain/models/attention_decision.dart';
import 'package:coach_for_life/features/reminders/domain/models/notification_interaction_type.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_config.dart';
import 'package:coach_for_life/features/reminders/domain/models/reminder_intent.dart';

import 'no_op_notification_ledger.dart';

/// Orchestrator stub for tests that need an [AttentionOrchestratorService]
/// dependency but never exercise real scheduling (no Isar, no OS calls).
class NoOpOrchestratorService extends AttentionOrchestratorService {
  NoOpOrchestratorService()
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

  @override
  Future<void> onInteractionReceived(
    String entityId,
    NotificationInteractionType type,
  ) async {
    interactions.add((entityId, type));
  }

  final List<(String, NotificationInteractionType)> interactions = [];
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
  }) async =>
      const [];
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
  ) async =>
      const [];
  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}
  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}
