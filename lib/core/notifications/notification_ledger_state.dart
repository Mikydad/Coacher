/// Lifecycle states for a notification entry in the [NotificationLedger].
enum NotificationLedgerState {
  /// Notification has been scheduled with the OS but not yet confirmed delivered.
  scheduled,

  /// OS has confirmed the notification appeared in the tray (via callback).
  delivered,

  /// Notification was explicitly cancelled — either by the app or during
  /// boot reconciliation when it was no longer found in the OS tray.
  cancelled,

  /// User snoozed the notification; re-delivery is pending.
  snoozed,

  /// User dismissed the notification without acting on it.
  ignored,

  /// Notification time has passed and it was never interacted with.
  expired,
}
