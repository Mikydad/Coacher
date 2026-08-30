import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';

/// The reminder state machine (FR-R-11 / FR-R-12) — **pure**.
///
/// Every function here is a total function of `(occurrence, now)` with no
/// I/O, no repository, no clock of its own. That is deliberate: the PRD's one
/// architecture rule keeps AI and the network out of the delivery path, and
/// the state spine is where that rule is easiest to violate by accident. A
/// pure module is also the unit-test surface for every "was it overdue?"
/// question, against an injected clock.
///
/// ## Retroactive by construction
///
/// Transitions compare `now` against the occurrence's own `windowEnd`, so the
/// app never has to have been *alive* at the moment a window closed. Opening
/// the app at 6 PM correctly concludes "windowEnd was 3:10 PM, therefore
/// overdue since 3:10 PM" — and stamps 3:10, not 6:00. Anything else would
/// make overdue-ness depend on when the user happened to look at their phone.
abstract final class ReminderStateMachine {
  /// Recompute [o]'s state as of [now].
  ///
  /// Returns [o] unchanged when nothing moved, so callers can write only what
  /// actually transitioned.
  static ReminderOccurrence advance(
    ReminderOccurrence o, {
    required DateTime now,
  }) {
    // Resolved is terminal. Nothing — not a clock change, not a re-sync,
    // not a late-arriving remote row — reopens it.
    if (o.state.isTerminal) return o;

    final nowMs = now.millisecondsSinceEpoch;

    if (nowMs < o.scheduledAtMs) {
      return _to(o, ReminderOccurrenceState.upcoming, now);
    }

    if (nowMs < o.windowEndMs) {
      // Inside the window. `active` is an opt-in signal the user sets by
      // starting a timer or checking in; it must survive a recompute, so it
      // is preserved rather than overwritten with `due`.
      if (o.state == ReminderOccurrenceState.active) return o;
      return _to(o, ReminderOccurrenceState.due, now);
    }

    // The window has closed. What that means is the taxonomy's whole job
    // (PRD §3.2).
    switch (o.taxonomy) {
      case ReminderTaxonomy.timeSensitive:
        // Less useful or impossible later. Recorded as missed for analytics
        // and streaks, then never mentioned again — no overdue nagging.
        return _expire(o, now);

      case ReminderTaxonomy.routine:
        // Individual misses are low-stakes. It expires the same way, and the
        // digest (FR-R-52) counts these rather than listing them.
        return _expire(o, now);

      case ReminderTaxonomy.flexible:
        // Still worth doing. Becomes overdue — a visible state, surfaced at
        // the next recovery moment.
        if (o.state == ReminderOccurrenceState.overdue) return o;
        return o.copyWith(
          state: ReminderOccurrenceState.overdue,
          // Stamped to windowEnd, NOT to now: an occurrence missed at 3:10 PM
          // and noticed at 6 PM has been overdue for nearly three hours, and
          // the Recovery Card orders by exactly this field.
          overdueSinceMs: o.overdueSinceMs ?? o.windowEndMs,
          updatedAtMs: now.millisecondsSinceEpoch,
        );
    }
  }

  /// [advance] applied to a batch, returning **only** the occurrences whose
  /// state actually changed — the write set for an [L-ALIVE] pass.
  static List<ReminderOccurrence> advanceAll(
    Iterable<ReminderOccurrence> occurrences, {
    required DateTime now,
  }) {
    final changed = <ReminderOccurrence>[];
    for (final o in occurrences) {
      final next = advance(o, now: now);
      if (!identical(next, o)) changed.add(next);
    }
    return changed;
  }

  /// The user started this occurrence (timer/focus start, or an explicit
  /// check-in). Never applies to an already-resolved occurrence.
  static ReminderOccurrence markActive(
    ReminderOccurrence o, {
    required DateTime now,
  }) {
    if (o.state.isTerminal) return o;
    if (o.state == ReminderOccurrenceState.active) return o;
    return _to(o, ReminderOccurrenceState.active, now);
  }

  /// Resolve an occurrence (FR-R-13). Terminal and idempotent.
  ///
  /// `resolvedAtMs` is the real resolution moment — unlike `overdueSinceMs`,
  /// which is retroactive — because "when did you actually deal with it" is
  /// what the 24-hour resolution metric measures.
  ///
  /// This function is deliberately permissive about [reason]: the rule that
  /// Extreme mode demands one for a reschedule is a *contract with the user*,
  /// enforced at the surface that offers the choice (FR-R-42, task 9.4).
  /// Ask [requiresResolutionReason] there rather than having the state
  /// machine silently refuse a write.
  static ReminderOccurrence resolve(
    ReminderOccurrence o, {
    required ReminderResolutionKind kind,
    String? reason,
    required DateTime now,
  }) {
    if (o.state.isTerminal) return o;
    final trimmed = reason?.trim();
    return o.copyWith(
      state: ReminderOccurrenceState.resolved,
      resolutionKind: kind,
      resolutionReason: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      resolvedAtMs: now.millisecondsSinceEpoch,
      updatedAtMs: now.millisecondsSinceEpoch,
    );
  }

  /// Whether the user must give a reason to resolve [o] this way.
  ///
  /// Extreme is a resolution contract, not just a louder ladder: rescheduling
  /// or skipping costs an explicit sentence, logged to the accountability log
  /// (FR-R-42). Flexible and Disciplined never require one (FR-R-40/41).
  static bool requiresResolutionReason(
    ReminderOccurrence o,
    ReminderResolutionKind kind,
  ) {
    if (kind == ReminderResolutionKind.completed) return false;
    if (kind == ReminderResolutionKind.expired) return false;
    return (o.modeRefId ?? '').trim().toLowerCase() == 'extreme';
  }

  /// Advance the ladder position — the counter the copy bank and the
  /// interruption-level resolver read.
  static ReminderOccurrence advanceLadder(
    ReminderOccurrence o, {
    required DateTime now,
  }) {
    if (o.state.isTerminal) return o;
    return o.copyWith(
      ladderPosition: o.ladderPosition + 1,
      updatedAtMs: now.millisecondsSinceEpoch,
    );
  }

  // ── internals ─────────────────────────────────────────────────────────────

  static ReminderOccurrence _to(
    ReminderOccurrence o,
    ReminderOccurrenceState state,
    DateTime now,
  ) {
    if (o.state == state) return o;
    return o.copyWith(state: state, updatedAtMs: now.millisecondsSinceEpoch);
  }

  /// Time-sensitive and routine misses both end here: honestly logged, never
  /// nagged about.
  static ReminderOccurrence _expire(ReminderOccurrence o, DateTime now) {
    return o.copyWith(
      state: ReminderOccurrenceState.resolved,
      resolutionKind: ReminderResolutionKind.expired,
      // The window's close is when it expired, whenever we noticed.
      resolvedAtMs: o.resolvedAtMs ?? o.windowEndMs,
      updatedAtMs: now.millisecondsSinceEpoch,
    );
  }
}
