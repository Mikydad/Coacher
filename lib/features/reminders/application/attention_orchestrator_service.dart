import 'package:flutter/foundation.dart';

import '../../../core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/notifications/notification_budget.dart';
import '../../../core/notifications/notification_ledger_repository.dart';
import '../../../core/notifications/notification_ledger_state.dart';
import '../../../core/notifications/notification_reconciliation_service.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/data/focus_repository.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../coaching/domain/models/coaching_style.dart';
import '../../context_override/data/context_override_repository.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../context_override/domain/models/post_override_review.dart';
import '../../context_override/domain/models/suppressed_item.dart';
import '../../context_override/domain/models/user_attention_state.dart';
import '../data/reminder_repository.dart';
import '../domain/models/attention_decision.dart';
import '../domain/models/attention_outcome.dart';
import '../domain/models/notification_interaction_type.dart';
import '../domain/models/recent_delivery.dart';
import '../domain/models/reminder_intent.dart';
import '../domain/models/reminder_type.dart';
import 'attention_orchestrator.dart';
import 'interruption_level_resolver.dart';
import 'notification_route_resolver.dart';

const String kAttentionOrchestratorSurface = 'attention_orchestrator';

/// Maximum age of a suppressed intent that is still considered relevant
/// when re-evaluating after an override ends (FR-C-25).
const Duration kSuppressedIntentStaleThreshold = Duration(hours: 2);

/// Number of snoozes within 24 hours that triggers [AnalyticsEventType.repeatedSnoozePattern].
const int kSnoozePatternThreshold = 3;

/// Riverpod-wired service wrapping [AttentionOrchestrator].
///
/// Responsibilities:
///   - Reads [UserAttentionState] + [CurrentCoachingFocus] from repos.
///   - Evaluates [ReminderIntent]s through the pure orchestrator.
///   - Executes decisions: schedules/cancels OS notifications.
///   - Logs analytics fatigue events.
///   - Manages the suppressed intent queue.
///   - Handles interaction callbacks and override-end queue flush.
class AttentionOrchestratorService implements OrchestratorReEvaluator {
  AttentionOrchestratorService({
    required ContextOverrideRepository contextOverrideRepository,
    required FocusRepository focusRepository,
    required ReminderRepository reminderRepository,
    required LocalNotificationsService notifications,
    required NotificationLedgerRepository ledger,
    required Future<void> Function({
      required AnalyticsEventType type,
      required String entityId,
      required String entityKind,
      required String sourceSurface,
      required String idempotencyKey,
      String? reason,
    })
    logEvent,

    /// Callback to read the user's current [CoachingStyle] synchronously.
    /// Injected so this service stays free of Riverpod (FR-D-16).
    CoachingStyle Function()? getCoachingStyle,

    /// Optional guard against iOS's 64-pending-notification cap.
    /// Null (tests, legacy wiring) means unlimited.
    NotificationBudget? budget,
    DateTime Function()? now,
  }) : _getCoachingStyle = getCoachingStyle ?? (() => CoachingStyle.balanced),
       _overrideRepo = contextOverrideRepository,
       _focusRepo = focusRepository,
       _reminderRepo = reminderRepository,
       _notifications = notifications,
       _ledger = ledger,
       _logEvent = logEvent,
       _budget = budget,
       _now = now ?? DateTime.now;

  final CoachingStyle Function() _getCoachingStyle;
  final ContextOverrideRepository _overrideRepo;
  final FocusRepository _focusRepo;
  final ReminderRepository _reminderRepo;
  final LocalNotificationsService _notifications;
  final NotificationLedgerRepository _ledger;
  final Future<void> Function({
    required AnalyticsEventType type,
    required String entityId,
    required String entityKind,
    required String sourceSurface,
    required String idempotencyKey,
    String? reason,
  })
  _logEvent;
  final NotificationBudget? _budget;
  final DateTime Function() _now;

  // ── In-memory state ────────────────────────────────────────────────────────

  /// Notifications delivered in the last 30 minutes for collision management.
  final List<RecentDelivery> _recentDeliveries = [];

  /// Intents suppressed with retryAllowed = true, keyed by intent id.
  final Map<String, ReminderIntent> _suppressedQueue = {};

  // NOTE: _activeNotificationIds, _snoozeTimestampsMs, and _ignoredCountByEntity
  // have been replaced by the persistent [NotificationLedgerRepository] (_ledger).

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Evaluate [intent] through the orchestrator and execute the resulting decision.
  Future<AttentionDecision> evaluate(ReminderIntent intent) async {
    _trimRecentDeliveries();

    final attentionState =
        await _overrideRepo.getAttentionState() ??
        UserAttentionState(
          id: kUserAttentionStateId,
          activeOverride: ContextOverride.none,
          manuallyMuted: false,
          updatedAtMs: _now().millisecondsSinceEpoch,
        );
    final focus = await _focusRepo.getActiveFocus();

    // Read consecutive ignored count from the persistent ledger.
    final ledgerEntry = await _ledger.findByEntityId(intent.entityId);
    final ignoredCount = ledgerEntry?.ignoredCount ?? 0;

    final decision = AttentionOrchestrator.evaluate(
      intent: intent,
      attentionState: attentionState,
      now: _now(),
      focus: focus,
      recentDeliveries: List.unmodifiable(_recentDeliveries),
      pendingIntents: List.unmodifiable(_suppressedQueue.values),
      coachingStyle: _getCoachingStyle(),
      consecutiveIgnoredCount: ignoredCount,
    );

    await _executeDecision(intent, decision);
    return decision;
  }

  /// Record a user interaction with a delivered notification.
  Future<void> onInteractionReceived(
    String entityId,
    NotificationInteractionType type,
  ) async {
    final ledgerEntry = await _ledger.findByEntityId(entityId);
    final notifId = ledgerEntry?.notifId;

    switch (type) {
      case NotificationInteractionType.opened:
        if (notifId != null) {
          await _ledger.markInteraction(notifId, 'opened');
        }
        await _cancelActiveNotification(entityId);
        await _logFatigueEvent(
          type: AnalyticsEventType.notificationOpened,
          entityId: entityId,
          entityKind: ledgerEntry?.entityKind ?? 'task',
        );

      case NotificationInteractionType.snoozed:
        if (notifId != null) {
          await _ledger.markInteraction(notifId, 'snoozed');
        }
        await _recordSnooze(entityId);

      case NotificationInteractionType.dismissed:
        if (notifId != null) {
          await _ledger.markInteraction(notifId, 'dismissed');
        }
        await _logFatigueEvent(
          type: AnalyticsEventType.notificationDismissed,
          entityId: entityId,
          entityKind: ledgerEntry?.entityKind ?? 'task',
        );

      case NotificationInteractionType.ignored:
        // Increment consecutive ignored count in the persistent ledger.
        if (ledgerEntry != null) {
          ledgerEntry
            ..ignoredCount = ledgerEntry.ignoredCount + 1
            ..updatedAtMs = _now().millisecondsSinceEpoch;
          await _ledger.upsertEntry(ledgerEntry);
        }
        await _logFatigueEvent(
          type: AnalyticsEventType.notificationIgnored,
          entityId: entityId,
          entityKind: ledgerEntry?.entityKind ?? 'task',
        );
        await _scheduleFollowUp(entityId);
    }
  }

  /// Called when a context override ends (from [ContextOverrideExpiryPoller]
  /// or manual "End" action).
  /// Re-evaluates all suppressed intents — relevant ones are re-delivered,
  /// stale ones populate the Phase B recovery review.
  Future<PostOverrideReview?> onOverrideEnded(
    ContextOverride endedOverride,
    int overrideStartedAtMs,
  ) async {
    if (_suppressedQueue.isEmpty) return null;

    final now = _now();
    final staleItems = <SuppressedItem>[];
    final toReEvaluate = Map<String, ReminderIntent>.from(_suppressedQueue);
    _suppressedQueue.clear();

    final reminders = await _reminderRepo.listAllReminders();
    final enabledTaskIds = {
      for (final r in reminders)
        if (r.enabled) r.taskId,
    };

    for (final intent in toReEvaluate.values) {
      // The reminder-config existence check only applies to task/habit
      // intents; goal and stake-invite intents (Phase 0 reroute) have no
      // ReminderConfig — their staleness is judged by age alone.
      final isTaskKind =
          intent.entityKind == ReminderEntityKinds.task ||
          intent.entityKind == ReminderEntityKinds.habit;
      final isEntityStillPending =
          !isTaskKind || enabledTaskIds.contains(intent.entityId);
      final age = now.difference(intent.proposedAt);
      final isStale = age > kSuppressedIntentStaleThreshold;

      if (!isEntityStillPending || isStale) {
        staleItems.add(
          SuppressedItem(
            entityId: intent.entityId,
            entityKind: intent.entityKind,
            entityTitle: intent.entityTitle,
            originalScheduledAtMs: intent.proposedAt.millisecondsSinceEpoch,
            suggestedAction: SuggestedAction.reschedule,
          ),
        );
        continue;
      }

      // Still relevant — re-evaluate with a fresh followUp intent.
      final followUp = intent.copyWith(
        reminderType: ReminderType.followUp,
        proposedAt: now,
        sourceReason:
            'Re-evaluated after override ended: '
            '${endedOverride.displayName}',
      );
      await evaluate(followUp);
    }

    if (staleItems.isEmpty) return null;

    return PostOverrideReview(
      overrideType: endedOverride,
      activeFromMs: overrideStartedAtMs,
      activeUntilMs: now.millisecondsSinceEpoch,
      suppressedItems: staleItems,
    );
  }

  /// Cancel the active OS notification for [entityId] (replaces 64-slot loop).
  Future<void> cancelForEntity(String entityId) async {
    await _cancelActiveNotification(entityId);
  }

  /// Cancel every pending ladder slot for an intention (done / dismissed /
  /// replan). Slot ids are deterministic, so this needs no ledger lookup to
  /// know what exists — cancelling a non-pending id is a no-op.
  Future<void> cancelIntentionSlots(
    String intentionId, {
    int slotCount = 3,
  }) async {
    for (var slot = 0; slot < slotCount; slot++) {
      final notifId = _notifications.idFromIntentionId(intentionId, slot: slot);
      try {
        await _notifications.cancel(notifId);
      } catch (e) {
        debugPrint('attention_orchestrator_service: swallowed error: $e');
      }
      await _ledger.markCancelledByNotifId(notifId);
    }
  }

  /// Re-evaluate whether a notification should be re-scheduled for [entityId].
  ///
  /// Called by [NotificationReconciliationService] when a ledger entry is
  /// found in `scheduled`/`delivered` state but is missing from the OS tray
  /// (the app was killed before the notification fired or the OS dismissed it).
  @override
  Future<void> reEvaluateIfAppropriate(String entityId) async {
    final reminders = await _reminderRepo.listAllReminders();
    final config = reminders.cast<dynamic>().firstWhere(
      (r) => (r as dynamic).taskId == entityId,
      orElse: () => null,
    );
    if (config == null) return; // task was deleted — nothing to reschedule

    final modeRefId = config.modeRefId as String? ?? 'flexible';
    final level = InterruptionLevelResolver.resolve(
      enforcementMode: modeRefId,
      escalationLevel: config.escalationLevel as int? ?? 0,
      emergencyBypass: config.emergencyBypass as bool? ?? false,
    );
    final followUp = ReminderIntent(
      id: StableId.generate('ri_reconcile'),
      entityId: entityId,
      entityKind: 'task',
      entityTitle: config.taskTitle as String? ?? entityId,
      proposedAt: _now(),
      importance: (config.blockUrgencyScore as int? ?? 50).clamp(0, 100),
      interruptionLevel: level,
      enforcementMode: modeRefId,
      escalationLevel: config.escalationLevel as int? ?? 0,
      reminderType: ReminderType.followUp,
      sourceReason: 'boot_reconciliation',
      createdAtMs: _now().millisecondsSinceEpoch,
    );
    await evaluate(followUp);
  }

  /// Called on every app foreground resume.
  /// For each reminder that is pending and has been delivered but not
  /// interacted with within [kIgnoredTimeoutMinutes], fires an
  /// [NotificationInteractionType.ignored] interaction to trigger a follow-up.
  Future<void> checkIgnoredTimeouts() async {
    final now = _now();
    final cutoffMs =
        now.millisecondsSinceEpoch - kIgnoredTimeoutMinutes * 60 * 1000;
    final reminders = await _reminderRepo.listAllReminders();

    for (final reminder in reminders) {
      if (!reminder.pendingAction) continue;
      final lastMs = reminder.lastTriggeredAtMs;
      if (lastMs == null) continue;
      // Only act if triggered before the timeout window and no interaction
      // has been recorded since (no active notification id in our map means
      // the notification was delivered but not yet interacted with).
      if (lastMs < cutoffMs) {
        await onInteractionReceived(
          reminder.taskId,
          NotificationInteractionType.ignored,
        );
      }
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _executeDecision(
    ReminderIntent intent,
    AttentionDecision decision,
  ) async {
    switch (decision.outcome) {
      case AttentionOutcome.approved:
      case AttentionOutcome.batched:
      case AttentionOutcome.delayed:
        final deliverAt = decision.deliverAt ?? _now();
        final route = resolveNotificationRoute(intent);
        final body = _buildNotificationBody(intent, decision);
        // Immediate announcements (stake invites) must bypass schedule():
        // its normalize step pushes a non-future `when` forward by a day.
        final immediate = route.immediate && !deliverAt.isAfter(_now());
        // Guard the iOS 64-pending cap BEFORE cancelling the entity's
        // existing notification: a denied budget must leave whatever the
        // user already has, not destroy it. (Immediate showNow goes to the
        // tray, not the pending queue — no budget needed.)
        if (!immediate) {
          final budgetOk = await (_budget?.canSchedule() ?? Future.value(true));
          if (!budgetOk) {
            await _logFatigueEvent(
              type: AnalyticsEventType.reminderSuppressed,
              entityId: intent.entityId,
              entityKind: intent.entityKind,
              reason: 'notification_budget_exhausted',
            );
            return;
          }
        }
        // Intentions pre-schedule a ladder of slots per entity — cancel only
        // THIS slot's previous incarnation, or scheduling slot 1 would
        // destroy slot 0. Single-slot kinds keep the entity-scoped cancel.
        if (intent.entityKind == ReminderEntityKinds.intention) {
          await _cancelByNotifId(route.notifId);
        } else {
          await _cancelActiveNotification(intent.entityId);
        }
        try {
          if (immediate) {
            await _notifications.showNow(
              id: route.notifId,
              title: intent.entityTitle,
              body: body,
              payload: route.payload,
            );
          } else {
            await _notifications.schedule(
              id: route.notifId,
              title: intent.entityTitle,
              body: body,
              when: deliverAt,
              payload: route.payload,
              darwinCategoryId: route.darwinCategoryId,
            );
          }
          // Persist scheduled state to the ledger (replaces _activeNotificationIds).
          await _ledger.upsertEntry(
            IsarNotificationLedgerEntry()
              ..notifId = route.notifId
              ..entityId = intent.entityId
              ..entityKind = intent.entityKind
              ..state = NotificationLedgerState.scheduled.name
              ..scheduledForMs = deliverAt.millisecondsSinceEpoch
              ..sourceContext = kAttentionOrchestratorSurface
              ..updatedAtMs = _now().millisecondsSinceEpoch,
          );
          if (immediate) {
            // showNow delivered to the tray already — record it so the
            // reconciliation service doesn't treat it as an undelivered ghost.
            await _ledger.markDelivered(route.notifId);
          }
          _recentDeliveries.add(
            RecentDelivery(
              entityId: intent.entityId,
              deliveredAtMs: deliverAt.millisecondsSinceEpoch,
              interruptionLevel: intent.interruptionLevel,
            ),
          );
          await _logFatigueEvent(
            type: AnalyticsEventType.notificationDelivered,
            entityId: intent.entityId,
            entityKind: intent.entityKind,
            reason: decision.priorityBoosted ? 'focus_boosted' : null,
          );
        } catch (e, st) {
          debugPrint(
            '[AttentionOrchestrator] schedule failed: ${intent.entityId} $e',
          );
          debugPrint('$st');
        }

      case AttentionOutcome.suppressed:
        if (decision.retryAllowed) {
          _suppressedQueue[intent.id] = intent;
        }
        await _logFatigueEvent(
          type: AnalyticsEventType.reminderSuppressed,
          entityId: intent.entityId,
          entityKind: intent.entityKind,
          reason: decision.suppressedReason,
        );
    }
  }

  /// Slot-scoped cancel: only the given OS notification id (and its ledger
  /// row), leaving the entity's sibling slots untouched.
  Future<void> _cancelByNotifId(int notifId) async {
    final entry = await _ledger.findByNotifId(notifId);
    if (entry != null &&
        entry.state != NotificationLedgerState.cancelled.name) {
      try {
        await _notifications.cancel(notifId);
      } catch (e) {
        debugPrint('attention_orchestrator_service: swallowed error: $e');
      }
      await _ledger.markCancelledByNotifId(notifId);
    }
  }

  Future<void> _cancelActiveNotification(String entityId) async {
    final entry = await _ledger.findByEntityId(entityId);
    if (entry != null &&
        entry.state != NotificationLedgerState.cancelled.name) {
      try {
        await _notifications.cancel(entry.notifId);
      } catch (e) {
        debugPrint('attention_orchestrator_service: swallowed error: $e');
      }
      await _ledger.markCancelled(entityId);
    }
  }

  String _buildNotificationBody(
    ReminderIntent intent,
    AttentionDecision decision,
  ) {
    if (decision.outcome == AttentionOutcome.batched &&
        decision.batchedWith.isNotEmpty) {
      final partnerIds = decision.batchedWith.join(', ');
      return 'Time to start: ${intent.entityTitle} + $partnerIds';
    }
    // Goal reminders and invites carry their own copy; tasks keep the default.
    final override = intent.bodyOverride;
    if (override != null && override.isNotEmpty) return override;
    return 'Time to start: ${intent.entityTitle}';
  }

  void _trimRecentDeliveries() {
    final cutoff = _now().subtract(const Duration(minutes: 30));
    _recentDeliveries.removeWhere((d) => d.deliveredAt.isBefore(cutoff));
  }

  Future<void> _scheduleFollowUp(String entityId) async {
    final reminders = await _reminderRepo.listAllReminders();
    final config = reminders.cast<dynamic>().firstWhere(
      (r) => (r as dynamic).taskId == entityId,
      orElse: () => null,
    );
    if (config == null) return;

    final modeRefId = config.modeRefId as String? ?? 'flexible';
    final escalation = (config.escalationLevel as int? ?? 0) + 1;
    final level = InterruptionLevelResolver.resolve(
      enforcementMode: modeRefId,
      escalationLevel: escalation,
      emergencyBypass: config.emergencyBypass as bool? ?? false,
    );
    final followUp = ReminderIntent(
      id: StableId.generate('ri_followup'),
      entityId: entityId,
      entityKind: 'task',
      entityTitle: config.taskTitle as String? ?? entityId,
      proposedAt: _now().add(const Duration(minutes: 15)),
      importance: (config.blockUrgencyScore as int? ?? 50).clamp(0, 100),
      interruptionLevel: level,
      enforcementMode: modeRefId,
      escalationLevel: escalation,
      reminderType: ReminderType.followUp,
      sourceReason: 'ignored_timeout_followup',
      createdAtMs: _now().millisecondsSinceEpoch,
    );
    await evaluate(followUp);
  }

  Future<void> _recordSnooze(String entityId) async {
    final entry = await _ledger.findByEntityId(entityId);
    if (entry != null) {
      entry
        ..snoozeCount = entry.snoozeCount + 1
        ..snoozedUntilMs = _now()
            .add(const Duration(minutes: 15))
            .millisecondsSinceEpoch
        ..state = NotificationLedgerState.snoozed.name
        ..updatedAtMs = _now().millisecondsSinceEpoch;
      await _ledger.upsertEntry(entry);

      if (entry.snoozeCount >= kSnoozePatternThreshold) {
        await _logFatigueEvent(
          type: AnalyticsEventType.repeatedSnoozePattern,
          entityId: entityId,
          reason: '${entry.snoozeCount} snoozes',
        );
      }
    }
  }

  Future<void> _logFatigueEvent({
    required AnalyticsEventType type,
    required String entityId,
    String entityKind = 'task',
    String? reason,
  }) async {
    final ts = _now();
    try {
      await _logEvent(
        type: type,
        entityId: entityId,
        entityKind: entityKind,
        sourceSurface: kAttentionOrchestratorSurface,
        idempotencyKey: StableId.generate(
          '${type.name}_${entityId}_${DateKeys.todayKey(ts)}',
        ),
        reason: reason,
      );
    } catch (e) {
      debugPrint('[AttentionOrchestrator] analytics log failed: $e');
    }
  }
}
