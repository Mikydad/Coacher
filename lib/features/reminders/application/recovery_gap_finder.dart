import 'ladder_compiler.dart';

/// Finds a genuinely free moment to place ONE recovery summary (FR-R-53).
///
/// The aggregated recovery notification is the only push the recovery system
/// gets, and it exists to say "2 tasks need your attention" once — never N
/// individual reminders for N overdue items. Placing it badly would undo the
/// whole point: a summary that lands 30 seconds before a meeting is just
/// another interruption.
///
/// So it takes the same constraints the ladder does. A qualifying gap is:
/// far enough ahead to not feel instant, before the day winds down, clear of
/// the interruption boundary around every scheduled item, and outside every
/// shield.
///
/// Callers should pass scheduled blocks as BOTH — their start times for the
/// run-up buffer, and their full spans as shields. Start times alone would
/// let a summary land in the middle of a two-hour block, since a start says
/// nothing about when the thing ends.
///
/// Pure — the caller resolves the plan, so every rule here is testable
/// against fixed inputs.
abstract final class RecoveryGapFinder {
  /// How far ahead the first candidate sits. A summary that arrives the
  /// instant you close the app reads as a reaction to closing it.
  static const Duration lead = Duration(minutes: 20);

  /// Candidate spacing. Coarse on purpose: a recovery nudge does not need
  /// minute precision, and coarse steps keep the search cheap.
  static const Duration step = Duration(minutes: 15);

  /// The summary must land at least this long before the day ends, or it is
  /// arriving too late to act on (§3.6).
  static const Duration minBeforeDayEnd = Duration(minutes: 15);

  /// The first qualifying moment, or null when the day has no room left —
  /// which is a perfectly good answer. A day packed wall to wall does not get
  /// a recovery nudge wedged into it.
  static DateTime? find({
    required DateTime now,
    required DateTime dayEnd,
    List<DateTime> upcomingStarts = const [],
    List<ShieldWindow> shields = const [],
  }) {
    final latest = dayEnd.subtract(minBeforeDayEnd);
    var candidate = _ceilToStep(now.add(lead));

    // Bounded by construction: the loop advances by `step` and stops at
    // `latest`, so a pathological plan cannot spin it.
    while (!candidate.isAfter(latest)) {
      if (_isFree(candidate, upcomingStarts, shields)) return candidate;
      candidate = candidate.add(step);
    }
    return null;
  }

  static bool _isFree(
    DateTime at,
    List<DateTime> upcomingStarts,
    List<ShieldWindow> shields,
  ) {
    for (final shield in shields) {
      if (shield.contains(at)) return false;
    }
    for (final start in upcomingStarts) {
      // The same buffer the ladder respects: nothing may speak inside the
      // run-up to a scheduled item — and the start moment itself is part of
      // that. A summary landing exactly as a meeting begins is the
      // interruption this whole rule exists to prevent.
      final quietFrom = start.subtract(
        const Duration(minutes: LadderCompiler.boundaryBufferMinutes),
      );
      if (!at.isBefore(quietFrom) && !at.isAfter(start)) return false;
    }
    return true;
  }

  /// Rounds up to the next [step] boundary so summaries land on tidy times
  /// (2:15, 2:30) rather than at whatever second the sweep happened to run.
  static DateTime _ceilToStep(DateTime t) {
    final stepMinutes = step.inMinutes;
    final remainder = t.minute % stepMinutes;
    final base = DateTime(t.year, t.month, t.day, t.hour, t.minute);
    if (remainder == 0 && t.second == 0) return base;
    return base.add(Duration(minutes: stepMinutes - remainder));
  }
}
