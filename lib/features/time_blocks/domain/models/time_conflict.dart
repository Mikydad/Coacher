// ─── ConflictSeverity ─────────────────────────────────────────────────────────

/// Display tier for a detected scheduling conflict.
/// Derived from the continuous 0–1 severity score.
enum ConflictSeverity {
  /// Score 0.0–0.35. Show inline warning banner only.
  minor,

  /// Score 0.36–0.65. Show conflict bottom sheet.
  moderate,

  /// Score 0.66–1.0. Show conflict bottom sheet with red accent.
  severe,
}

ConflictSeverity conflictSeverityFromStorage(String? raw) {
  for (final v in ConflictSeverity.values) {
    if (v.name == raw) return v;
  }
  return ConflictSeverity.minor;
}

// ─── ConflictType ─────────────────────────────────────────────────────────────

/// Structural relationship between two overlapping time blocks.
enum ConflictType {
  /// The two blocks overlap partially at their start or end edges.
  partialOverlap,

  /// The blocks start and end at nearly the same time.
  fullOverlap,

  /// One block is fully contained within the other.
  contained,
}

ConflictType conflictTypeFromStorage(String? raw) {
  for (final v in ConflictType.values) {
    if (v.name == raw) return v;
  }
  return ConflictType.partialOverlap;
}

// ─── TimeConflict ─────────────────────────────────────────────────────────────

/// A single scheduling conflict between the proposed block and an existing one.
class TimeConflict {
  const TimeConflict({
    required this.conflictingEntityId,
    required this.conflictingEntityKind,
    required this.conflictingEntityTitle,
    required this.overlapMinutes,
    required this.severity,
    required this.severityLabel,
    required this.conflictType,
  });

  final String conflictingEntityId;

  /// `"task"` or `"habit"`.
  final String conflictingEntityKind;

  /// Display title of the conflicting entity (for UI).
  final String conflictingEntityTitle;

  /// Duration of the overlap in minutes.
  final int overlapMinutes;

  /// Continuous 0–1 severity score.
  final double severity;

  /// Severity tier derived from the score.
  final ConflictSeverity severityLabel;

  final ConflictType conflictType;
}

// ─── ConflictCheckResult ──────────────────────────────────────────────────────

/// Result of a full conflict check for a proposed time block.
class ConflictCheckResult {
  const ConflictCheckResult({
    required this.hasConflicts,
    required this.conflicts,
    this.worstSeverity,
  });

  final bool hasConflicts;
  final List<TimeConflict> conflicts;

  /// The highest severity among all detected conflicts. Null if no conflicts.
  final ConflictSeverity? worstSeverity;

  /// Convenience: no conflicts detected.
  static const ConflictCheckResult none = ConflictCheckResult(
    hasConflicts: false,
    conflicts: [],
  );
}
