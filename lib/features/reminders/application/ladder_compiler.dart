import '../../../core/utils/date_keys.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import '../domain/models/slot_spec.dart';
import 'adaptive_reminder_policy.dart';
import 'reminder_copy_bank.dart';

/// A span during which reminders are withheld: a scheduled focus block, or
/// the configured sleep window.
class ShieldWindow {
  const ShieldWindow({
    required this.start,
    required this.end,
    required this.reason,
  });

  final DateTime start;
  final DateTime end;
  final String reason;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

/// Everything outside the occurrence that the ladder has to respect.
///
/// Passed in rather than fetched so the compiler stays pure: the plan, the
/// shields and the remaining budget are all resolved by the caller, which is
/// what makes every rule below unit-testable against fixed inputs.
class LadderContext {
  const LadderContext({
    this.upcomingStarts = const [],
    this.shields = const [],
    this.budgetRemaining = 64,
  });

  /// Start times of the user's other scheduled items. Only those strictly
  /// after the occurrence matter; the compiler filters.
  final List<DateTime> upcomingStarts;

  final List<ShieldWindow> shields;

  /// Room left in the OS pending queue.
  final int budgetRemaining;
}

/// Compiles a mode's ladder into concrete moments (FR-R-30…33) — **pure**.
///
/// This is where the audit's C1 and C2 die. Escalation used to begin only if
/// the user tapped "Later", and the per-mode repeat plans were tested policy
/// math with no execution path at all. The fix cannot be a runtime
/// decision-maker, because iOS gives no callback when a notification fires and
/// the app is usually not running: every slot has to be a real
/// `zonedSchedule` call, decided in advance.
///
/// The interruption boundary is what keeps that from becoming spam. Task A's
/// ladder stops before task B begins — computed here, at scheduling time,
/// from the plan. That single rule is why pre-scheduling the whole ladder is
/// safe rather than a bombardment.
abstract final class LadderCompiler {
  /// D1: how long before the next scheduled item the ladder must fall silent.
  static const int boundaryBufferMinutes = 20;

  /// Only criticality 3 pierces the boundary, the shields and the sleep
  /// window (D5). It still stops hard at the window's close.
  static const int piercingCriticality = 3;

  static LadderPlan compile({
    required ReminderOccurrence occurrence,
    required LadderContext context,
    required DateTime now,
  }) {
    // A resolved occurrence has nothing left to say.
    if (occurrence.isResolved) return const LadderPlan();

    final scheduledAt = occurrence.scheduledAt;
    final windowEnd = occurrence.windowEnd;
    final pierces = occurrence.criticality >= piercingCriticality;

    final boundary = _boundaryFor(scheduledAt, context.upcomingStarts);
    // The ladder ends at whichever comes first — except for criticality 3,
    // which ignores the boundary but never the window.
    final effectiveEnd = (boundary != null && !pierces && boundary.isBefore(windowEnd))
        ? boundary
        : windowEnd;

    // §3.2 / AUDIT A4: routine never escalates — whatever the mode says, a
    // routine item speaks once. This is shape selection, not pruning, so no
    // drop is logged: the ladder a routine item is entitled to IS one slot.
    // (A routine occurrence that is already overdue compiles to nothing at
    // all — it expires into the digest rather than going overdue, so an
    // overdue routine row is legacy data, not a delivery obligation.)
    final baseOffsets = AdaptiveReminderPolicy.ladderOffsetsFor(
      occurrence.modeRefId,
    );
    final offsets = occurrence.taxonomy == ReminderTaxonomy.routine
        ? baseOffsets.take(1).toList(growable: false)
        : baseOffsets;

    // FR-R-33: a day that has not arrived gets its first slot only. Full
    // ladders for every future day at once would exhaust the 64-slot queue on
    // the tasks furthest from mattering.
    final isToday = occurrence.dateKey == DateKeys.todayKey(now);

    final slots = <SlotSpec>[];
    final drops = <SlotDrop>[];

    for (var i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final fireAt = scheduledAt.add(Duration(minutes: offset));

      if (!isToday && i > 0) {
        drops.add(SlotDrop(slot: i, offsetMinutes: offset, reason: SlotDropReason.notToday));
        continue;
      }
      if (!fireAt.isAfter(now)) {
        drops.add(SlotDrop(slot: i, offsetMinutes: offset, reason: SlotDropReason.past));
        continue;
      }
      // FR-R-35 / AUDIT A2: "Later" re-plans the remaining ladder. A slot
      // the snooze pre-empts must not fire anyway — that would make snoozing
      // produce MORE notifications than ignoring. Slots after the snooze
      // survive: deferring the ladder is not resigning from it.
      final snoozedUntilMs = occurrence.snoozedUntilMs;
      if (snoozedUntilMs != null &&
          !fireAt.isAfter(
            DateTime.fromMillisecondsSinceEpoch(snoozedUntilMs),
          )) {
        drops.add(
          SlotDrop(slot: i, offsetMinutes: offset, reason: SlotDropReason.snoozed),
        );
        continue;
      }
      if (!fireAt.isBefore(effectiveEnd)) {
        // Attribute it honestly: the boundary cut it short, or the window did.
        final endedByBoundary = boundary != null &&
            !pierces &&
            !fireAt.isBefore(boundary) &&
            boundary.isBefore(windowEnd);
        drops.add(
          SlotDrop(
            slot: i,
            offsetMinutes: offset,
            reason: endedByBoundary
                ? SlotDropReason.boundary
                : SlotDropReason.window,
          ),
        );
        continue;
      }
      if (!pierces && _isShielded(fireAt, context.shields)) {
        drops.add(SlotDrop(slot: i, offsetMinutes: offset, reason: SlotDropReason.shield));
        continue;
      }

      // The string is written HERE, not at delivery (FR-R-34): by the time
      // the OS fires this slot the app may not be running at all.
      final copy = ReminderCopyBank.forSlot(
        entityTitle: occurrence.entityTitle ?? '',
        entityKind: occurrence.entityKind,
        modeRefId: occurrence.modeRefId,
        taxonomy: occurrence.taxonomy,
        ladderPosition: i,
        criticality: occurrence.criticality,
      );
      slots.add(
        SlotSpec(
          slot: i,
          offsetMinutes: offset,
          fireAt: fireAt,
          entityId: occurrence.entityId,
          entityKind: occurrence.entityKind,
          criticality: occurrence.criticality,
          title: copy.title,
          body: copy.body,
          modeRefId: occurrence.modeRefId,
        ),
      );
    }

    // Budget last, and from the deepest slot inward: if only some of the
    // ladder fits, the earliest slots are the ones worth keeping.
    if (slots.length > context.budgetRemaining) {
      final keep = context.budgetRemaining.clamp(0, slots.length);
      for (final dropped in slots.sublist(keep)) {
        drops.add(
          SlotDrop(
            slot: dropped.slot,
            offsetMinutes: dropped.offsetMinutes,
            reason: SlotDropReason.budget,
          ),
        );
      }
      slots.removeRange(keep, slots.length);
    }

    return LadderPlan(
      slots: slots,
      drops: drops,
      boundary: boundary,
      effectiveEnd: effectiveEnd,
    );
  }

  /// The next scheduled item's start after [scheduledAt], minus the buffer.
  ///
  /// Null when nothing else is scheduled — then only the window ends the
  /// ladder. A boundary at or before the occurrence itself is ignored: the
  /// user's next item cannot be one that already started.
  static DateTime? _boundaryFor(
    DateTime scheduledAt,
    List<DateTime> upcomingStarts,
  ) {
    DateTime? earliest;
    for (final start in upcomingStarts) {
      if (!start.isAfter(scheduledAt)) continue;
      if (earliest == null || start.isBefore(earliest)) earliest = start;
    }
    if (earliest == null) return null;
    return earliest.subtract(const Duration(minutes: boundaryBufferMinutes));
  }

  static bool _isShielded(DateTime at, List<ShieldWindow> shields) {
    for (final shield in shields) {
      if (shield.contains(at)) return true;
    }
    return false;
  }
}
