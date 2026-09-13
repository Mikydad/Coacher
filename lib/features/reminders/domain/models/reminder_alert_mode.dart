/// How a reminder reaches the user when its moment arrives.
///
/// A `notification` is the mode ladder as it has always been: one
/// notification per compiled slot, pruned by the interruption boundary, the
/// Focus Shield and the sleep window. An `alarm` adds a **ring ladder** on
/// top: a bounded burst of loud, Time-Sensitive notifications with the
/// bundled alarm sound that ignores every shield — because an alarm that is
/// quietly withheld is a broken alarm, not a polite one.
///
/// Stored as a lowercase string so a row written by a newer client degrades
/// to `notification` instead of throwing on read.
enum ReminderAlertMode {
  notification,
  alarm;

  static ReminderAlertMode fromStorage(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'alarm' => ReminderAlertMode.alarm,
        _ => ReminderAlertMode.notification,
      };

  String toStorage() => name;

  bool get isAlarm => this == ReminderAlertMode.alarm;
}
