/// Classification of how interruptive a notification is.
/// Used by [OverrideAttentionPolicy] to decide whether delivery is suppressed.
enum InterruptionLevel {
  /// Coaching tips, passive suggestions. Lowest priority.
  low,

  /// Standard task/habit reminders.
  medium,

  /// Urgent: imminent streak risk, critical overdue items.
  high,

  /// Emergency bypass — extreme mode at max escalation. Nothing suppresses
  /// this except [ContextOverride.doNotDisturb].
  critical,
}

InterruptionLevel interruptionLevelFromStorage(String? raw) {
  for (final v in InterruptionLevel.values) {
    if (v.name == raw) return v;
  }
  return InterruptionLevel.medium;
}
