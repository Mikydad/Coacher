import '../../../core/notifications/notification_action_ids.dart';
import '../../analytics/application/coaching_insight_notification_policy.dart'
    show kCoachingInsightNotificationId;
import '../domain/models/reminder_intent.dart';

/// Entity kinds the orchestrator can deliver notifications for.
/// [ReminderIntent.entityKind] is a free string — these constants keep
/// producers and the resolver in agreement.
abstract final class ReminderEntityKinds {
  static const String task = 'task';
  static const String habit = 'habit';
  static const String goal = 'goal';
  static const String stakeInvite = 'stake_invite';

  /// "Your result card is ready" — a public commitment reached a terminal
  /// status (OQ-1, tasks/prd-public-commitment-cards.md). Announced once
  /// per challenge when sync lands the outcome.
  static const String stakeCard = 'stake_card';
  static const String intention = 'intention';

  /// Layer-4 "coach insight ready" push (V-01): routed through the
  /// orchestrator so politeness (overrides, quiet hours, collision gap)
  /// and the ledger apply — its own 3/day + 4h producer budget still
  /// gates upstream.
  static const String coachInsight = 'coach_insight';

  /// The aggregated recovery summary (FR-R-53). One notification standing in
  /// for every overdue item, never one per item.
  static const String recovery = 'recovery';
}

/// Where an intent's notification goes: deterministic OS id, tap payload,
/// iOS action category, and whether it is an immediate announcement
/// (delivered via `showNow`) rather than a scheduled reminder.
class NotificationRoute {
  const NotificationRoute({
    required this.notifId,
    required this.payload,
    this.darwinCategoryId,
    this.immediate = false,
  });

  final int notifId;
  final String payload;
  final String? darwinCategoryId;

  /// Immediate announcements must NOT go through `schedule()`: its
  /// normalize step pushes any non-future `when` forward by a full day.
  final bool immediate;
}

/// Pure mapping from a [ReminderIntent] to its OS notification routing.
///
/// This is the single source of truth for id/payload/category per entity
/// kind — `AttentionOrchestratorService._executeDecision` must never
/// hardcode them (it used to hardcode the task shape, which would have
/// routed goal and invite taps into the task/focus flow).
NotificationRoute resolveNotificationRoute(ReminderIntent intent) {
  final encoded = Uri.encodeComponent(intent.entityId);
  switch (intent.entityKind) {
    case ReminderEntityKinds.goal:
      return NotificationRoute(
        // Mirrors LocalNotificationsService.idFromGoalId — kept in sync by
        // notification_route_resolver_test. Slot 0 keeps the historic
        // derivation so an already-armed goal notification stays cancellable
        // across the upgrade; slot 1 is FR-R-14's second armed occurrence.
        notifId: intent.slot == 0
            ? (intent.entityId.hashCode ^ 0x474f414c).abs() % 2147483647
            : ('goal:${intent.entityId}:${intent.slot}').hashCode.abs() %
                  2147483647,
        payload: 'goal:$encoded',
      );
    case ReminderEntityKinds.stakeInvite:
      return NotificationRoute(
        // Legacy invite id scheme (stable per challenge so a re-emit can't
        // stack duplicates) — pre-migration invites cancel under the same id.
        notifId: intent.entityId.hashCode & 0x7fffffff,
        payload: 'stake:$encoded',
        immediate: true,
      );
    case ReminderEntityKinds.stakeCard:
      return NotificationRoute(
        // Stable per challenge (one outcome, one announcement) and a
        // distinct id space from the invite scheme for the same challenge.
        notifId: ('stake_card:${intent.entityId}').hashCode.abs() % 2147483647,
        // Same tap route as invites: land on Accountability, where the
        // challenge's card CTA is waiting.
        payload: 'stake:$encoded',
        immediate: true,
      );
    case ReminderEntityKinds.coachInsight:
      return NotificationRoute(
        // Fixed slot — every coach-insight push replaces the previous one
        // (same contract the direct dispatch had). Payload matches the
        // existing `layer4:` tap route; the insight id is used raw, as
        // the tap handler splits on `::` without percent-decoding.
        notifId: kCoachingInsightNotificationId,
        payload: 'layer4:${intent.entityId}',
      );
    case ReminderEntityKinds.recovery:
      return NotificationRoute(
        // Slot-aware so the day's two summaries (D6) can coexist and be
        // cancelled independently. The entityId is the day key, which makes
        // the ids naturally unique per day.
        notifId:
            ('recovery:${intent.entityId}:${intent.slot}').hashCode.abs() %
            2147483647,
        // No entity to open — the tap lands on Home, where the card lives.
        payload: 'recovery:$encoded',
      );
    case ReminderEntityKinds.intention:
      return NotificationRoute(
        // Slot-aware ladder ids (0 = primary, 1 = deadline-eve, 2 =
        // fallback) so siblings can be cancelled individually. Mirrors
        // LocalNotificationsService.idFromIntentionId.
        notifId:
            ('intention:${intent.entityId}:${intent.slot}').hashCode.abs() %
            2147483647,
        payload: 'intention:$encoded',
        darwinCategoryId: NotificationCategoryIds.intentionNudge,
      );
    default: // task / habit
      return NotificationRoute(
        // Mirrors LocalNotificationsService.idFromTaskId — slot-aware since
        // FR-R-30, because a task's ladder pre-schedules several moments and
        // each must be cancellable on its own. Slot 0 keeps the historic id,
        // so a notification armed by an older build stays cancellable.
        notifId:
            ('task:${intent.entityId}:${intent.slot}').hashCode.abs() %
            2147483647,
        payload: 'task:$encoded',
        darwinCategoryId: NotificationCategoryIds.taskReminder,
      );
  }
}
