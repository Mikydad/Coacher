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
import '../domain/models/reminder_config.dart';
import '../domain/models/reminder_intent.dart';
import '../domain/models/reminder_type.dart';
import 'attention_orchestrator.dart';
import 'interruption_level_resolver.dart';
import 'notification_route_resolver.dart';
import 'reminder_copy_bank.dart';

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

    /// Liveness check for non-task suppressed intents (goal/stake) before
    /// they are re-delivered on override end — a goal deleted or completed
    /// during an override must not nudge afterwards. Null means always live.
    Future<bool> Function(String entityId, String entityKind)? isEntityLive,
    DateTime Function()? now,
  }) : _getCoachingStyle = getCoachingStyle ?? (() => CoachingStyle.balanced),
       _overrideRepo = contextOverrideRepository,
       _focusRepo = focusRepository,
       _reminderRepo = reminderRepository,
       _notifications = notifications,
       _ledger = ledger,
       _logEvent = logEvent,
       _budget = budget,
       _isEntityLive = isEntityLive,
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
  final Future<bool> Function(String entityId, String entityKind)?
  _isEntityLive;
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
  ///
  /// Pass [notifId] when the OS response carries it (P2-01): entities with
  /// several pending notifications (intention ladders) need the feedback
  /// to land on the TAPPED slot's ledger row — the entityId lookup always
  /// resolves to the most recently updated sibling.
  Future<void> onInteractionReceived(
    String entityId,
    NotificationInteractionType type, {
    int? notifId,
  }) async {
    final ledgerEntry = notifId != null
        ? await _ledger.findByNotifId(notifId)
        : await _ledger.findByEntityId(entityId);
    final resolvedNotifId = ledgerEntry?.notifId;

    switch (type) {
      case NotificationInteractionType.opened:
        if (resolvedNotifId != null) {
          await _ledger.markInteraction(resolvedNotifId, 'opened');
          await _cancelByNotifId(resolvedNotifId);
        } else {
          await _cancelActiveNotification(entityId);
        }
        await _logFatigueEvent(
          type: AnalyticsEventType.notificationOpened,
          entityId: entityId,
          entityKind: ledgerEntry?.entityKind ?? 'task',
        );

      case NotificationInteractionType.snoozed:
        if (resolvedNotifId != null) {
          await _ledger.markInteraction(resolvedNotifId, 'snoozed');
        }
        await _recordSnooze(entityId);

      case NotificationInteractionType.dismissed:
        if (resolvedNotifId != null) {
          await _ledger.markInteraction(resolvedNotifId, 'dismissed');
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
      // Task/habit liveness = an enabled ReminderConfig still exists; other
      // kinds (goal/stake) consult the injected liveness callback so an
      // entity deleted or completed during the override is not re-delivered.
      final isTaskKind =
          intent.entityKind == ReminderEntityKinds.task ||
          intent.entityKind == ReminderEntityKinds.habit;
      final bool isEntityStillPending;
      if (isTaskKind) {
        isEntityStillPending = enabledTaskIds.contains(intent.entityId);
      } else {
        isEntityStillPending =
            await (_isEntityLive?.call(intent.entityId, intent.entityKind) ??
                Future.value(true));
      }
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

  /// Cancel every armed notification for [entityId].
  ///
  /// Tasks now pre-schedule a ladder (FR-R-30), so an entity-scoped cancel
  /// has to sweep each slot: completing a task at T+2 must silence T+10 and
  /// T+25 too, or the ladder outlives the thing it was reminding about
  /// (FR-R-13). Slot ids are deterministic, so cancelling one that was never
  /// armed is a harmless no-op.
  Future<void> cancelForEntity(String entityId, {int slotCount = 4}) async {
    for (var slot = 0; slot < slotCount; slot++) {
      final notifId = _notifications.idFromTaskId(entityId, slot: slot);
      try {
        await _notifications.cancel(notifId);
      } catch (e) {
        debugPrint('attention_orchestrator_service: swallowed error: $e');
      }
      await _ledger.markCancelledByNotifId(notifId);
    }
    // Non-task kinds (and any legacy row) still resolve through the ledger.
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

  /// Re-arm a reminder the OS lost, at its **original** time.
  ///
  /// Called by [NotificationReconciliationService] when a ledger entry in
  /// `scheduled`/`delivered` state is missing from BOTH OS queues.
  ///
  /// This path is deliberately conservative (FR-R-01/FR-R-02). It re-arms only
  /// when all three hold: the config still exists, the user still has the
  /// reminder `enabled`, and the target time is still in the future. It never
  /// proposes `now` — that is what made every cold start deliver the evening's
  /// reminders at breakfast (AUDIT §10 T1).
  ///
  /// The restored intent is [ReminderType.scheduled], not a follow-up: it IS
  /// the user's original first delivery, so the CoachingStyle back-off that
  /// guards against over-eager follow-ups must not suppress it.
  @override
  Future<void> reEvaluateIfAppropriate(
    String entityId, {
    DateTime? scheduledFor,
  }) async {
    final config = await _findConfig(entityId);
    if (config == null) return; // task was deleted — nothing to reschedule

    // A reminder the user switched off stays off, whatever the OS queue says.
    if (!config.enabled) return;

    // Prefer the caller's time (the ledger row's own scheduledFor); fall back
    // to the config's stored time. Anything non-future is not ours to deliver.
    final storedIso = config.scheduledAtIso;
    final deliverAt =
        scheduledFor ??
        (storedIso == null ? null : DateTime.tryParse(storedIso));
    if (deliverAt == null || !deliverAt.isAfter(_now())) return;

    final modeRefId = config.modeRefId ?? 'flexible';
    final level = InterruptionLevelResolver.resolve(
      enforcementMode: modeRefId,
      escalationLevel: config.escalationLevel,
      emergencyBypass: config.emergencyBypass,
    );
    final restored = ReminderIntent(
      id: StableId.generate('ri_reconcile'),
      entityId: entityId,
      entityKind: 'task',
      entityTitle: config.taskTitle ?? entityId,
      proposedAt: deliverAt,
      importance: config.blockUrgencyScore.clamp(0, 100),
      interruptionLevel: level,
      enforcementMode: modeRefId,
      escalationLevel: config.escalationLevel,
      reminderType: ReminderType.scheduled,
      sourceReason: 'boot_reconciliation',
      createdAtMs: _now().millisecondsSinceEpoch,
    );
    await evaluate(restored);
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
        // Anything due NOW must bypass schedule(): its normalize step pushes
        // a non-future `when` forward by a full day — which would silently
        // defer immediate announcements (stake invites), override-end
        // re-deliveries, and boot-reconciliation follow-ups to tomorrow.
        final immediate = !deliverAt.isAfter(_now());
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
        // Multi-slot kinds pre-schedule several delivery moments per entity —
        // cancel only THIS slot's previous incarnation, or arming slot 1
        // would destroy slot 0. Intentions have always done this; goals join
        // them under FR-R-14, which keeps two occurrences armed so a missed
        // app-open cannot silence a daily goal. Single-slot kinds keep the
        // entity-scoped cancel.
        if (_isMultiSlotKind(intent.entityKind)) {
          await _cancelByNotifId(route.notifId);
        } else {
          await _cancelActiveNotification(intent.entityId);
        }
        try {
          // FR-R-44 / M1: the level the policy computed finally reaches the
          // OS. `decision.silent` is honoured here too — it was computed by
          // the focus-silence path and then never read, so "silent"
          // deliveries were delivered loud.
          // The policy may upgrade the level on a focus boost; the decision
          // records that it happened but not the resulting level, so it is
          // reconstructed here rather than widening the serialized model.
          final level = decision.priorityBoosted
              ? InterruptionLevelResolver.upgrade(intent.interruptionLevel)
              : intent.interruptionLevel;
          final silent = decision.outcome == AttentionOutcome.approved &&
              decision.silent;
          if (immediate) {
            await _notifications.showNow(
              id: route.notifId,
              title: intent.entityTitle,
              body: body,
              payload: route.payload,
              darwinCategoryId: route.darwinCategoryId,
              level: level,
              silent: silent,
            );
          } else {
            await _notifications.schedule(
              id: route.notifId,
              title: intent.entityTitle,
              body: body,
              when: deliverAt,
              payload: route.payload,
              darwinCategoryId: route.darwinCategoryId,
              level: level,
              silent: silent,
            );
          }
          // Persist scheduled state to the ledger. notifId is a UNIQUE
          // non-replacing index, so a reschedule must reuse the existing
          // row's Isar id — a fresh row would throw (and previously did,
          // silently, inside this try). Reusing the row also keeps the
          // slot's behavioral memory (deliveredAtMs, ignore/snooze counts)
          // which the daily caps and back-off logic read.
          final priorEntry = await _ledger.findByNotifId(route.notifId);
          final entry = priorEntry ?? IsarNotificationLedgerEntry();
          entry
            ..notifId = route.notifId
            ..entityId = intent.entityId
            ..entityKind = intent.entityKind
            ..state = NotificationLedgerState.scheduled.name
            ..scheduledForMs = deliverAt.millisecondsSinceEpoch
            ..sourceContext = kAttentionOrchestratorSurface
            ..updatedAtMs = _now().millisecondsSinceEpoch;
          await _ledger.upsertEntry(entry);
          if (immediate) {
            // showNow delivered to the tray already — record it so the
            // reconciliation service doesn't treat it as an undelivered ghost.
            await _ledger.markDelivered(route.notifId);
          }
          // Purge the entity's superseded entry first: a re-arm REPLACES
          // the previous slot, and a stale phantom time would delay other
          // entities' intents against a notification that no longer exists.
          _recentDeliveries
            ..removeWhere((d) => d.entityId == intent.entityId)
            ..add(
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

  /// Kinds that arm more than one notification per entity, and therefore need
  /// slot-scoped rather than entity-scoped cancels.
  static bool _isMultiSlotKind(String entityKind) =>
      entityKind == ReminderEntityKinds.intention ||
      entityKind == ReminderEntityKinds.goal ||
      entityKind == ReminderEntityKinds.task ||
      entityKind == ReminderEntityKinds.habit;

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
      // AUDIT §10 M4: this used to join `batchedWith`, which carries intent
      // ids (`ri_…` StableIds), so the one artifact batching could produce
      // was a notification showing the user internal identifiers.
      return ReminderCopyBank.batchedBody(
        intent.entityTitle,
        decision.batchedWith.length,
      );
    }
    // Ladder slots, goal reminders and invites all arrive pre-written
    // (FR-R-34); this fallback is for the paths that have not adopted the
    // copy bank yet.
    final override = intent.bodyOverride;
    if (override != null && override.isNotEmpty) return override;
    return ReminderCopyBank.forSlot(
      entityTitle: intent.entityTitle,
      entityKind: intent.entityKind,
      modeRefId: intent.enforcementMode,
      ladderPosition: intent.escalationLevel,
    ).body;
  }

  void _trimRecentDeliveries() {
    final cutoff = _now().subtract(const Duration(minutes: 30));
    _recentDeliveries.removeWhere((d) => d.deliveredAt.isBefore(cutoff));
  }

  Future<void> _scheduleFollowUp(String entityId) async {
    final config = await _findConfig(entityId);
    if (config == null) return;

    final modeRefId = config.modeRefId ?? 'flexible';
    final escalation = config.escalationLevel + 1;
    final nowMs = _now().millisecondsSinceEpoch;

    // Persist the climb AND stamp the ignore before anything else
    // (FR-R-04 / FR-R-05).
    //
    // M2: the incremented level used to live only on the intent and was
    // never written back, so the ladder never climbed through ignores —
    // extreme's tail phase and the whole escalation copy bank were
    // unreachable except via an explicit snooze.
    //
    // C7: without advancing lastTriggeredAtMs, checkIgnoredTimeouts counts
    // the SAME un-acted-on notification again on every foreground resume
    // past the 15-minute window. ignoredCount climbs once per app-open with
    // no new delivery behind it, and under CoachingStyle.supportive the
    // back-off trips at two — silencing the task permanently. Stamping now
    // bounds it to at most one ignore per window.
    await _reminderRepo.upsertReminder(
      config.copyWith(
        escalationLevel: escalation,
        lastTriggeredAtMs: nowMs,
        updatedAtMs: nowMs,
      ),
    );

    final level = InterruptionLevelResolver.resolve(
      enforcementMode: modeRefId,
      escalationLevel: escalation,
      emergencyBypass: config.emergencyBypass,
    );
    final followUp = ReminderIntent(
      id: StableId.generate('ri_followup'),
      entityId: entityId,
      entityKind: 'task',
      entityTitle: config.taskTitle ?? entityId,
      proposedAt: _now().add(const Duration(minutes: 15)),
      importance: config.blockUrgencyScore.clamp(0, 100),
      interruptionLevel: level,
      enforcementMode: modeRefId,
      escalationLevel: escalation,
      reminderType: ReminderType.followUp,
      sourceReason: 'ignored_timeout_followup',
      createdAtMs: nowMs,
    );
    await evaluate(followUp);
  }

  /// Typed lookup of the reminder config for [entityId], or null.
  Future<ReminderConfig?> _findConfig(String entityId) async {
    final reminders = await _reminderRepo.listAllReminders();
    final index = reminders.indexWhere((r) => r.taskId == entityId);
    return index < 0 ? null : reminders[index];
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
