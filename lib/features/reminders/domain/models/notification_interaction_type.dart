enum NotificationInteractionType {
  opened,
  snoozed,
  dismissed,
  ignored;

  static NotificationInteractionType fromStorage(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'opened':
        return NotificationInteractionType.opened;
      case 'snoozed':
        return NotificationInteractionType.snoozed;
      case 'dismissed':
        return NotificationInteractionType.dismissed;
      default:
        return NotificationInteractionType.ignored;
    }
  }

  String toStorage() => name;
}
