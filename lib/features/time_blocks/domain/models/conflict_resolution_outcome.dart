/// Result of [SchedulingConflictSheet] or inline conflict resolution.
enum ConflictResolutionKind {
  /// User may proceed with save (optionally after allowing overlap).
  proceedToSave,

  /// User stays on the parent form (cancel, move proposed, or dismiss).
  stayOnForm,

  /// Parent should apply adjusted schedule before re-saving.
  proposedScheduleAdjusted,
}

class ConflictResolutionOutcome {
  const ConflictResolutionOutcome({
    required this.kind,
    this.overlapOverridden = false,
    this.adjustedStart,
    this.adjustedDurationMinutes,
  });

  final ConflictResolutionKind kind;
  final bool overlapOverridden;
  final DateTime? adjustedStart;
  final int? adjustedDurationMinutes;

  static const stayOnForm = ConflictResolutionOutcome(
    kind: ConflictResolutionKind.stayOnForm,
  );

  static ConflictResolutionOutcome proceed({bool overlapOverridden = false}) {
    return ConflictResolutionOutcome(
      kind: ConflictResolutionKind.proceedToSave,
      overlapOverridden: overlapOverridden,
    );
  }

  static ConflictResolutionOutcome adjusted({
    DateTime? adjustedStart,
    int? adjustedDurationMinutes,
  }) {
    return ConflictResolutionOutcome(
      kind: ConflictResolutionKind.proposedScheduleAdjusted,
      adjustedStart: adjustedStart,
      adjustedDurationMinutes: adjustedDurationMinutes,
    );
  }
}
