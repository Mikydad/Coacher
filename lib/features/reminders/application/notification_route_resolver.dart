import '../../../core/notifications/notification_action_ids.dart';
import '../domain/models/reminder_intent.dart';

/// Entity kinds the orchestrator can deliver notifications for.
/// [ReminderIntent.entityKind] is a free string — these constants keep
/// producers and the resolver in agreement.
abstract final class ReminderEntityKinds {
  static const String task = 'task';
  static const String habit = 'habit';
  static const String goal = 'goal';
  static const String stakeInvite = 'stake_invite';
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
        // notification_route_resolver_test.
        notifId: (intent.entityId.hashCode ^ 0x474f414c).abs() % 2147483647,
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
    default: // task / habit
      return NotificationRoute(
        // Mirrors LocalNotificationsService.idFromTaskId(slot: 0).
        notifId: ('task:${intent.entityId}:0').hashCode.abs() % 2147483647,
        payload: 'task:$encoded',
        darwinCategoryId: NotificationCategoryIds.taskReminder,
      );
  }
}
