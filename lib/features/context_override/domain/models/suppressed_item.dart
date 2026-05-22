/// Action the user can take on a suppressed item in the recovery review.
enum SuggestedAction {
  startNow,
  reschedule,
  shorten,
  skipIntentionally,
  dismiss,
}

SuggestedAction suggestedActionFromStorage(String? raw) {
  for (final v in SuggestedAction.values) {
    if (v.name == raw) return v;
  }
  return SuggestedAction.dismiss;
}

extension SuggestedActionLabel on SuggestedAction {
  String get label {
    switch (this) {
      case SuggestedAction.startNow:
        return 'Start now';
      case SuggestedAction.reschedule:
        return 'Reschedule';
      case SuggestedAction.shorten:
        return 'Shorten';
      case SuggestedAction.skipIntentionally:
        return 'Skip';
      case SuggestedAction.dismiss:
        return 'Dismiss';
    }
  }
}

/// An item that was held back (suppressed) during an active override window.
class SuppressedItem {
  const SuppressedItem({
    required this.entityId,
    required this.entityKind,
    required this.entityTitle,
    required this.originalScheduledAtMs,
    required this.suggestedAction,
  });

  final String entityId;

  /// `"task"` or `"habit"`.
  final String entityKind;

  final String entityTitle;

  /// Epoch ms when this item was originally due.
  final int originalScheduledAtMs;

  /// Recommended next action for this item in the recovery review.
  final SuggestedAction suggestedAction;

  Map<String, dynamic> toMap() => {
    'entityId': entityId,
    'entityKind': entityKind,
    'entityTitle': entityTitle,
    'originalScheduledAtMs': originalScheduledAtMs,
    'suggestedAction': suggestedAction.name,
  };

  static SuppressedItem fromMap(Map<String, dynamic> map) {
    return SuppressedItem(
      entityId: map['entityId'] as String? ?? '',
      entityKind: map['entityKind'] as String? ?? 'task',
      entityTitle: map['entityTitle'] as String? ?? 'Unknown',
      originalScheduledAtMs:
          (map['originalScheduledAtMs'] as num?)?.toInt() ?? 0,
      suggestedAction:
          suggestedActionFromStorage(map['suggestedAction'] as String?),
    );
  }
}
