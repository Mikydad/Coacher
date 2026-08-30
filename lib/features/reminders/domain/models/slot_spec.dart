/// One compiled notification slot: an exact moment, already decided.
///
/// [SlotSpec] is the output of the ladder compiler and the input to
/// `zonedSchedule`. By the time one exists, every question — should this fire,
/// when, past which boundary, under what budget — has been answered by pure
/// local code. Delivery composes nothing and decides nothing (FR-R-34).
class SlotSpec {
  const SlotSpec({
    required this.slot,
    required this.offsetMinutes,
    required this.fireAt,
    required this.entityId,
    required this.entityKind,
    required this.criticality,
    required this.title,
    required this.body,
    this.modeRefId,
  });

  /// Ladder position: 0 is the reminder itself, 1+ are follow-ups.
  final int slot;

  /// Minutes after the occurrence's scheduled time.
  final int offsetMinutes;

  final DateTime fireAt;
  final String entityId;
  final String entityKind;
  final int criticality;

  /// Written at compile time, used verbatim at delivery (FR-R-34). A slot
  /// compiled at 9 a.m. for 9 p.m. already knows what it will say.
  final String title;
  final String body;

  final String? modeRefId;

  bool get isFirst => slot == 0;

  @override
  String toString() => 'SlotSpec(slot $slot, T+$offsetMinutes, $fireAt)';
}

/// Why a slot the mode called for did not survive compilation.
///
/// FR-R-33 requires every drop to be logged: a ladder that silently
/// truncates is indistinguishable from one that was never configured, which
/// is how "SidePal reminded me once" became impossible to diagnose.
enum SlotDropReason {
  /// At or after the next scheduled item's start (minus the buffer) — the
  /// interruption boundary.
  boundary,

  /// At or after the reminder window's close.
  window,

  /// Inside a focus block or the sleep window.
  shield,

  /// Already in the past; nothing can be scheduled there.
  past,

  /// Not today, so only the first slot is armed until it becomes today.
  notToday,

  /// Pre-empted by the user's own snooze: they asked for quiet until a
  /// moment after this slot would have fired (FR-R-35).
  snoozed,

  /// The OS pending queue had no room.
  budget,
}

class SlotDrop {
  const SlotDrop({
    required this.slot,
    required this.offsetMinutes,
    required this.reason,
  });

  final int slot;
  final int offsetMinutes;
  final SlotDropReason reason;

  @override
  String toString() => 'SlotDrop(slot $slot, T+$offsetMinutes, ${reason.name})';
}

/// The compiled ladder for one occurrence, plus what it had to give up.
class LadderPlan {
  const LadderPlan({
    this.slots = const [],
    this.drops = const [],
    this.boundary,
    this.effectiveEnd,
  });

  final List<SlotSpec> slots;
  final List<SlotDrop> drops;

  /// The next scheduled item's start minus the buffer, if there is one.
  final DateTime? boundary;

  /// Where the ladder actually stops: the earlier of the window's close and
  /// the boundary.
  final DateTime? effectiveEnd;

  bool get isEmpty => slots.isEmpty;
  bool get isNotEmpty => slots.isNotEmpty;

  /// True when the boundary — not the window — is what ended the ladder.
  /// The recovery system owns everything after this point.
  bool get endedAtBoundary =>
      drops.any((d) => d.reason == SlotDropReason.boundary);
}
