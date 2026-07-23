/// Notification action + category identifiers shared between
/// [LocalNotificationsService] (where iOS categories are registered) and
/// `handleNotificationResponse` (where action taps are handled).
///
/// iOS treats a category's action set as immutable per install: changing the
/// actions of an already-shipped category silently does nothing until the app
/// is reinstalled. New action sets therefore need a NEW category identifier —
/// hence the `.v1` suffix. Adding brand-new categories later is fine.
abstract final class NotificationActionIds {
  /// Snooze / "Later". Shares the id of the long-standing Android
  /// `AndroidNotificationAction('snooze', …)` so both platforms hit the same
  /// handler branch.
  static const String later = 'snooze';

  /// Mark the task complete straight from the notification.
  static const String done = 'done';

  /// Open the Coach sheet.
  static const String openCoach = 'open_coach';

  /// "Wrong time" feedback — records that this moment was badly chosen.
  /// Consumed by the notification ledger today; the opportunity planner
  /// (humanizing Phase 1) reads it to avoid similar moments.
  static const String wrongTime = 'wrong_time';
}

abstract final class NotificationCategoryIds {
  /// Task reminders scheduled through the AttentionOrchestrator:
  /// Done / Later / Wrong time / Open Coach.
  static const String taskReminder = 'sidepalTaskReminder.v1';

  /// Opportunity nudges for intentions (humanizing Phase 1). Same action
  /// set as task reminders but its own category so the two surfaces can
  /// diverge later without an app reinstall (see class doc above).
  static const String intentionNudge = 'sidepalIntentionNudge.v1';
}
