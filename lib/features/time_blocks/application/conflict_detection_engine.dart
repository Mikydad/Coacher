import '../domain/models/scheduled_time_block.dart';
import '../domain/models/time_conflict.dart';

/// Pure Dart engine — no I/O, no Riverpod, no Flutter.
/// All inputs are plain lists; all outputs are plain objects.
/// Fully unit-testable in isolation.
abstract final class ConflictDetectionEngine {
  // ─── Public API ────────────────────────────────────────────────────────────

  /// Detect scheduling conflicts between [proposed] and [existing] blocks.
  ///
  /// A conflict exists if EITHER:
  ///   - Absolute overlap ≥ 5 minutes, OR
  ///   - Overlap ≥ 15% of the shorter block's duration.
  ///
  /// The proposed entity's own existing block is automatically excluded via
  /// the repository query, but pass [excludeEntityId] as a safety net.
  static List<TimeConflict> detect({
    required ScheduledTimeBlock proposed,
    required List<ScheduledTimeBlock> existing,
    Map<String, String> entityTitles = const {},
  }) {
    final results = <TimeConflict>[];
    for (final other in existing) {
      // Skip the entity's own block.
      if (other.entityId == proposed.entityId) continue;

      final overlapMinutes = _computeOverlapMinutes(proposed, other);
      if (overlapMinutes <= 0) continue;

      final shorterDuration =
          proposed.expectedDurationMinutes < other.expectedDurationMinutes
          ? proposed.expectedDurationMinutes
          : other.expectedDurationMinutes;

      if (!_meetsThreshold(overlapMinutes, shorterDuration)) continue;

      final severity = _computeSeverity(proposed, other, overlapMinutes);
      final severityLabel = _classifySeverity(severity);
      final conflictType = _classifyConflictType(proposed, other);
      final title =
          entityTitles[other.entityId] ?? fallbackConflictEntityTitle(other);

      results.add(
        TimeConflict(
          conflictingEntityId: other.entityId,
          conflictingEntityKind: other.entityKind,
          conflictingEntityTitle: title,
          overlapMinutes: overlapMinutes,
          severity: severity,
          severityLabel: severityLabel,
          conflictType: conflictType,
        ),
      );
    }
    // Sort worst-first for consistent UI ordering.
    results.sort((a, b) => b.severity.compareTo(a.severity));
    return results;
  }

  /// Build a [ConflictCheckResult] from a raw detect output.
  static ConflictCheckResult buildResult(List<TimeConflict> conflicts) {
    if (conflicts.isEmpty) return ConflictCheckResult.none;
    final worst = conflicts
        .map((c) => c.severityLabel)
        .reduce((a, b) => _worseSeverity(a, b));
    return ConflictCheckResult(
      hasConflicts: true,
      conflicts: conflicts,
      worstSeverity: worst,
    );
  }

  // ─── Overlap calculation ──────────────────────────────────────────────────

  static int _computeOverlapMinutes(
    ScheduledTimeBlock a,
    ScheduledTimeBlock b,
  ) {
    final overlapStart = a.startAt.isAfter(b.startAt) ? a.startAt : b.startAt;
    final overlapEnd = a.computedEndAt.isBefore(b.computedEndAt)
        ? a.computedEndAt
        : b.computedEndAt;
    if (!overlapEnd.isAfter(overlapStart)) return 0;
    return overlapEnd.difference(overlapStart).inMinutes;
  }

  // ─── Threshold check ──────────────────────────────────────────────────────

  /// A conflict exists if overlap ≥ 5 min OR overlap ≥ 15% of shorter block.
  static bool _meetsThreshold(int overlapMinutes, int shorterDurationMinutes) {
    if (overlapMinutes >= 5) return true;
    if (shorterDurationMinutes > 0) {
      final ratio = overlapMinutes / shorterDurationMinutes;
      if (ratio >= 0.15) return true;
    }
    return false;
  }

  // ─── Severity formula ─────────────────────────────────────────────────────

  /// Continuous severity score 0.0–1.0:
  ///   severity = overlapRatio + hardnessMultiplier + importanceWeight
  ///
  ///   overlapRatio       = overlapMinutes / shorterDuration  (clamped 0–1)
  ///   hardnessMultiplier = 0.3 if either block is rigid, else 0.0
  ///   importanceWeight   = max(a.importance, b.importance) / 100 × 0.2
  static double _computeSeverity(
    ScheduledTimeBlock proposed,
    ScheduledTimeBlock other,
    int overlapMinutes,
  ) {
    final shorter =
        proposed.expectedDurationMinutes < other.expectedDurationMinutes
        ? proposed.expectedDurationMinutes
        : other.expectedDurationMinutes;

    final overlapRatio = shorter > 0
        ? (overlapMinutes / shorter).clamp(0.0, 1.0)
        : 1.0;

    final hardnessMultiplier = (proposed.isRigid || other.isRigid) ? 0.3 : 0.0;

    final maxImportance = proposed.importance > other.importance
        ? proposed.importance
        : other.importance;
    final importanceWeight = (maxImportance / 100.0) * 0.2;

    return (overlapRatio + hardnessMultiplier + importanceWeight).clamp(
      0.0,
      1.0,
    );
  }

  // ─── Severity classification ──────────────────────────────────────────────

  static ConflictSeverity _classifySeverity(double score) {
    if (score <= 0.35) return ConflictSeverity.minor;
    if (score <= 0.65) return ConflictSeverity.moderate;
    return ConflictSeverity.severe;
  }

  // ─── Conflict type classification ─────────────────────────────────────────

  static ConflictType _classifyConflictType(
    ScheduledTimeBlock proposed,
    ScheduledTimeBlock other,
  ) {
    final aStart = proposed.startAt;
    final aEnd = proposed.computedEndAt;
    final bStart = other.startAt;
    final bEnd = other.computedEndAt;

    // Contained: one block is fully inside the other.
    final aInsideB = !aStart.isBefore(bStart) && !aEnd.isAfter(bEnd);
    final bInsideA = !bStart.isBefore(aStart) && !bEnd.isAfter(aEnd);
    if (aInsideB || bInsideA) return ConflictType.contained;

    // Full overlap: starts and ends are within 5 minutes of each other.
    final startDiff = aStart.difference(bStart).inMinutes.abs();
    final endDiff = aEnd.difference(bEnd).inMinutes.abs();
    if (startDiff <= 5 && endDiff <= 5) return ConflictType.fullOverlap;

    return ConflictType.partialOverlap;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static ConflictSeverity _worseSeverity(
    ConflictSeverity a,
    ConflictSeverity b,
  ) {
    return a.index > b.index ? a : b;
  }

  /// Human-readable label when [entityTitles] has no entry for [block].
  static String fallbackConflictEntityTitle(ScheduledTimeBlock block) {
    switch (block.entityKind) {
      case 'goal':
        return 'Another goal';
      case 'habit':
        return 'A scheduled habit';
      case 'task':
        return 'Another scheduled task';
      default:
        return 'Another scheduled item';
    }
  }

  /// Derive importance from enforcement mode string.
  /// extreme = 90, disciplined = 60, flexible (default) = 30.
  static int importanceFromModeRefId(String? modeRefId) {
    final mode = modeRefId?.trim().toLowerCase();
    if (mode == 'extreme') return 90;
    if (mode == 'disciplined') return 60;
    return 30;
  }

  /// Derive importance from goal intensity (1–5).
  /// intensity 4–5 → 90, intensity 3 → 60, intensity 1–2 → 30.
  static int importanceFromGoalIntensity(int intensity) {
    if (intensity >= 4) return 90;
    if (intensity == 3) return 60;
    return 30;
  }
}
