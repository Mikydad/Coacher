enum ReminderType {
  scheduled,
  followUp,
  escalation;

  static ReminderType fromStorage(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'followup':
        return ReminderType.followUp;
      case 'escalation':
        return ReminderType.escalation;
      default:
        return ReminderType.scheduled;
    }
  }

  String toStorage() => switch (this) {
    ReminderType.scheduled => 'scheduled',
    ReminderType.followUp => 'followup',
    ReminderType.escalation => 'escalation',
  };
}
