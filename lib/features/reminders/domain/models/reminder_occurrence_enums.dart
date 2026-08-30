// The vocabulary of the reminder state machine (PRD §3.1 / §3.2).
//
// Each enum stores as a stable lowercase string, and every `fromStorage`
// falls back to the safest value rather than throwing: these are replicated
// fields, so a row written by a newer client must degrade, not crash.

/// Where an occurrence sits in its lifecycle.
///
/// ```
/// upcoming → due → [active] → overdue → resolved
/// ```
enum ReminderOccurrenceState {
  /// Scheduled time is still in the future.
  upcoming,

  /// Inside the reminder window — the ladder is live.
  due,

  /// The user started it (timer/focus start, or an explicit check-in).
  /// Opt-in: an occurrence may go `due → overdue` without ever being active.
  active,

  /// The window closed without resolution. A first-class *visible* state —
  /// never a silent one.
  overdue,

  /// Terminal. See [ReminderResolutionKind] for how it ended.
  resolved;

  static ReminderOccurrenceState fromStorage(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'due' => ReminderOccurrenceState.due,
        'active' => ReminderOccurrenceState.active,
        'overdue' => ReminderOccurrenceState.overdue,
        'resolved' => ReminderOccurrenceState.resolved,
        _ => ReminderOccurrenceState.upcoming,
      };

  String toStorage() => name;

  bool get isTerminal => this == ReminderOccurrenceState.resolved;
}

/// How a [ReminderOccurrenceState.resolved] occurrence ended.
enum ReminderResolutionKind {
  completed,
  skipped,

  /// Rolled to a new time; the new time is its own occurrence.
  rescheduled,

  /// The window closed and the taxonomy says it is no longer worth doing
  /// (time-sensitive), or it is a low-stakes routine miss. Recorded for
  /// analytics/streaks, never nagged about.
  expired;

  static ReminderResolutionKind? fromStorage(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'completed' => ReminderResolutionKind.completed,
        'skipped' => ReminderResolutionKind.skipped,
        'rescheduled' => ReminderResolutionKind.rescheduled,
        'expired' => ReminderResolutionKind.expired,
        _ => null,
      };

  String toStorage() => name;
}

/// How much a miss costs — decides what happens when the window closes
/// (PRD §3.2).
enum ReminderTaxonomy {
  /// Less useful or impossible later ("Join meeting 2 PM", "Take medication").
  /// Expires when the window closes; no overdue nagging.
  timeSensitive,

  /// Still worth doing later ("Study 1 hr"). Becomes overdue and surfaces at
  /// recovery moments. The default.
  flexible,

  /// Recurs; individual misses are low-stakes ("Drink water"). Rolls forward
  /// silently and aggregates into at most one daily digest line.
  routine;

  static ReminderTaxonomy fromStorage(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'timesensitive' => ReminderTaxonomy.timeSensitive,
        'routine' => ReminderTaxonomy.routine,
        _ => ReminderTaxonomy.flexible,
      };

  String toStorage() => switch (this) {
    ReminderTaxonomy.timeSensitive => 'timesensitive',
    ReminderTaxonomy.flexible => 'flexible',
    ReminderTaxonomy.routine => 'routine',
  };
}

/// Who decided the taxonomy/criticality. A [user] classification is never
/// overwritten by a heuristic or by AI (FR-R-21).
enum ClassificationSource {
  /// The local rule-based classifier (FR-R-20) — the permanent floor.
  heuristic,

  /// The user picked it in the task editor. Authoritative.
  user,

  /// Upgraded by the background classifier endpoint (FR-R-22).
  ai,

  /// Backfilled for rows that predate classification (PRD §9).
  migration;

  static ClassificationSource fromStorage(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'user' => ClassificationSource.user,
        'ai' => ClassificationSource.ai,
        'migration' => ClassificationSource.migration,
        _ => ClassificationSource.heuristic,
      };

  String toStorage() => name;

  /// Only a user override outranks everything else.
  bool get isAuthoritative => this == ClassificationSource.user;
}
