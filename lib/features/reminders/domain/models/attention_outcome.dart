enum AttentionOutcome {
  /// Intent passes all checks and is scheduled for OS delivery.
  approved,

  /// Intent is delayed past its proposedAt due to a collision gap.
  delayed,

  /// Intent is merged into a grouped notification with another intent.
  batched,

  /// Intent is held back due to an active context override.
  suppressed;

  static AttentionOutcome fromStorage(String? value) {
    for (final v in AttentionOutcome.values) {
      if (v.name == value) return v;
    }
    return AttentionOutcome.approved;
  }

  String toStorage() => name;
}
