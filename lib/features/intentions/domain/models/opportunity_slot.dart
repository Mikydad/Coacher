/// Why the planner chose a slot — powers the nudge's "why now" line.
/// Mirrors the FocusReason pattern: an enum kind + prerendered human text.
enum OpportunityReasonKind {
  /// A free window big enough for the estimated duration.
  freeWindow,

  /// The user's historical best time block for similar activity.
  bestTimeBlock,

  /// The deadline window is nearly over — safety slot.
  deadlinePressure,

  /// User pinned an exact time; smart timing is bypassed.
  pinned,
}

OpportunityReasonKind opportunityReasonKindFromStorage(String? raw) {
  for (final v in OpportunityReasonKind.values) {
    if (v.name == raw) return v;
  }
  return OpportunityReasonKind.freeWindow;
}

/// One planned delivery moment for an intention.
///
/// slot 0 = primary (best score), slot 1 = deadline-eve safety,
/// slot 2 = optional fallback (budget permitting).
class OpportunitySlot {
  const OpportunitySlot({
    required this.slot,
    required this.deliverAtMs,
    required this.reasonKind,
    required this.reasonText,
    required this.body,
  });

  final int slot;
  final int deliverAtMs;
  final OpportunityReasonKind reasonKind;

  /// Human "why now" line, e.g. "20 free minutes before Dinner".
  final String reasonText;

  /// Prerendered notification body (suggestion-as-question voice). Rendered
  /// at planning time so the delivery path is 100% network- and token-free.
  final String body;

  Map<String, dynamic> toMap() => {
    'slot': slot,
    'deliverAtMs': deliverAtMs,
    'reasonKind': reasonKind.name,
    'reasonText': reasonText,
    'body': body,
  };

  static OpportunitySlot fromMap(Map<String, dynamic> map) {
    return OpportunitySlot(
      slot: (map['slot'] as num?)?.toInt() ?? 0,
      deliverAtMs: (map['deliverAtMs'] as num?)?.toInt() ?? 0,
      reasonKind: opportunityReasonKindFromStorage(
        map['reasonKind'] as String?,
      ),
      reasonText: map['reasonText'] as String? ?? '',
      body: map['body'] as String? ?? '',
    );
  }
}
