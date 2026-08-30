import '../../../core/utils/date_keys.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';

/// How insistently one row asks to be dealt with — the mode's real difference
/// (FR-R-40…42), resolved once here so the widget never re-derives it.
enum RecoveryInsistence {
  /// Flexible: wave it away and it stops mentioning itself today.
  dismissible,

  /// Disciplined: asks for an explicit disposition and re-appears at every
  /// recovery moment until it gets one — but never blocks.
  persistent,

  /// Extreme: non-dismissible. Do it, or reschedule it with a reason.
  demanding;

  static RecoveryInsistence forMode(String? modeRefId) =>
      switch ((modeRefId ?? '').trim().toLowerCase()) {
        'extreme' => RecoveryInsistence.demanding,
        'disciplined' => RecoveryInsistence.persistent,
        _ => RecoveryInsistence.dismissible,
      };

  bool get canDismiss => this == RecoveryInsistence.dismissible;
}

/// One row on the Recovery Card.
class RecoveryRow {
  const RecoveryRow({required this.occurrence, required this.insistence});

  final ReminderOccurrence occurrence;
  final RecoveryInsistence insistence;

  String get title => occurrence.entityTitle ?? 'Untitled';
  bool get isCritical => occurrence.criticality >= 3;
}

/// Everything the Recovery Card renders: the rows that want attention, plus
/// one digest line for the routine misses that deliberately do not.
class RecoveryView {
  const RecoveryView({this.rows = const [], this.routineMisses = const []});

  final List<RecoveryRow> rows;

  /// Titles of today's routine-class misses. These are NOT rows: an
  /// individual missed day of a recurring low-stakes thing gets one quiet
  /// line, never a row demanding disposition (FR-R-52).
  final List<String> routineMisses;

  bool get isEmpty => rows.isEmpty && routineMisses.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// "Missed today: Water, Stretch" / "…and 2 more".
  ///
  /// The PRD's example is "Water: 3 of 6 today", which assumes a task can
  /// recur several times within one day. This app has no intra-day
  /// recurrence — occurrences are one per entity per day — so the honest
  /// digest names the routines missed instead of counting repeats.
  String? get routineDigestLine {
    if (routineMisses.isEmpty) return null;
    if (routineMisses.length <= 2) {
      return 'Missed today: ${routineMisses.join(', ')}';
    }
    final shown = routineMisses.take(2).join(', ');
    return 'Missed today: $shown and ${routineMisses.length - 2} more';
  }
}

/// Builds the Recovery Card's content from raw occurrences — **pure**.
///
/// Keeping this out of the widget means the ordering contract (FR-R-50) and
/// the dismissal rules are unit-testable against a fixed clock, rather than
/// only observable by pumping a widget tree.
abstract final class RecoveryViewBuilder {
  /// Rows shown at once before the card starts counting the rest.
  static const int maxRows = 5;

  static RecoveryView build(
    Iterable<ReminderOccurrence> occurrences, {
    required DateTime now,
  }) {
    final todayKey = DateKeys.todayKey(now);
    final rows = <RecoveryRow>[];
    final routineMisses = <String>[];

    for (final o in occurrences) {
      // Routine misses expire rather than going overdue, so they arrive here
      // already resolved. Today's are worth one line; older ones are gone.
      if (o.taxonomy == ReminderTaxonomy.routine) {
        if (o.resolutionKind == ReminderResolutionKind.expired &&
            o.dateKey == todayKey) {
          routineMisses.add(o.entityTitle ?? 'Untitled');
        }
        continue;
      }

      if (!o.isOverdue) continue;

      final insistence = RecoveryInsistence.forMode(o.modeRefId);
      // Only Flexible can be waved away, and only for the day it was waved.
      // A Disciplined or Extreme row ignores a stale dismissal outright —
      // the contract is the mode's, not the row's history.
      if (insistence.canDismiss && o.isDismissedOn(todayKey)) continue;

      rows.add(RecoveryRow(occurrence: o, insistence: insistence));
    }

    // FR-R-50: criticality descending, then longest-overdue first. Ties fall
    // back to the title so the order never jitters between rebuilds.
    rows.sort((a, b) {
      final byCriticality = b.occurrence.criticality.compareTo(
        a.occurrence.criticality,
      );
      if (byCriticality != 0) return byCriticality;
      final aSince = a.occurrence.overdueSinceMs ?? a.occurrence.scheduledAtMs;
      final bSince = b.occurrence.overdueSinceMs ?? b.occurrence.scheduledAtMs;
      final bySince = aSince.compareTo(bSince);
      if (bySince != 0) return bySince;
      return a.title.compareTo(b.title);
    });

    routineMisses.sort();
    return RecoveryView(rows: rows, routineMisses: routineMisses);
  }
}
