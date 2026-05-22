import '../../../core/utils/stable_id.dart';
import '../data/time_block_repository.dart';
import '../domain/models/scheduled_time_block.dart';
import '../domain/models/time_conflict.dart';
import 'conflict_detection_engine.dart';

/// Default duration (minutes) used when creating a time block for a goal.
/// Goals have no explicit duration field; 30 min matches the habit-anchor
/// path (`goalHabitAnchorDefaultMinutes` in habit_anchor_aggregator.dart).
const int kGoalBlockDefaultDurationMinutes = 30;

/// Derives [ScheduledTimeBlock] records from task/habit entities,
/// persists them, and runs conflict checks.
///
/// This is the only service that should write to [TimeBlockRepository].
/// Widgets and providers interact with blocks through this service.
class TimeBlockSyncService {
  TimeBlockSyncService({
    required TimeBlockRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final TimeBlockRepository _repository;
  final DateTime Function() _now;

  // ─── Block derivation ────────────────────────────────────────────────────

  /// Derive a [ScheduledTimeBlock] from task/habit fields.
  ///
  /// Returns null if [startAt] or [durationMinutes] is not provided,
  /// since blocks require both to be meaningful.
  ScheduledTimeBlock? deriveBlock({
    required String entityId,
    required String entityKind,
    required DateTime? startAt,
    required int? durationMinutes,
    String? modeRefId,
    bool isRigid = false,
    bool allowOverlapOverride = false,
  }) {
    if (startAt == null || durationMinutes == null || durationMinutes < 1) {
      return null;
    }
    final computedEndAt = startAt.add(Duration(minutes: durationMinutes));
    final importance = ConflictDetectionEngine.importanceFromModeRefId(modeRefId);
    final nowMs = _now().millisecondsSinceEpoch;
    return ScheduledTimeBlock(
      id: StableId.generate('tb'),
      entityId: entityId,
      entityKind: entityKind,
      startAt: startAt,
      expectedDurationMinutes: durationMinutes,
      computedEndAt: computedEndAt,
      flexibilityType:
          isRigid ? FlexibilityType.rigid : FlexibilityType.flexible,
      allowOverlapOverride: allowOverlapOverride,
      importance: importance,
      createdAtMs: nowMs,
      updatedAtMs: nowMs,
    );
  }

  // ─── Persistence ─────────────────────────────────────────────────────────

  /// Upsert a block. Existing block for the same [entityId] is replaced.
  Future<void> syncBlock(ScheduledTimeBlock block) async {
    await _repository.upsertBlock(block);
  }

  /// Delete the block for an entity (on task deletion or schedule cleared).
  Future<void> removeBlockForEntity(String entityId) async {
    await _repository.deleteBlockForEntity(entityId);
  }

  // ─── Conflict check ──────────────────────────────────────────────────────

  /// Run a full conflict check for a proposed block.
  ///
  /// Fetches geometrically overlapping blocks from the repository,
  /// applies the threshold filter via [ConflictDetectionEngine], and
  /// returns a [ConflictCheckResult].
  ///
  /// [entityTitles] is an optional map of entityId → display title used to
  /// populate [TimeConflict.conflictingEntityTitle] for UI display.
  Future<ConflictCheckResult> checkConflicts(
    ScheduledTimeBlock proposed, {
    Map<String, String> entityTitles = const {},
  }) async {
    final existing = await _repository.listOverlappingBlocks(proposed);
    if (existing.isEmpty) return ConflictCheckResult.none;
    final conflicts = ConflictDetectionEngine.detect(
      proposed: proposed,
      existing: existing,
      entityTitles: entityTitles,
    );
    return ConflictDetectionEngine.buildResult(conflicts);
  }

  // ─── Convenience: derive + check in one call ─────────────────────────────

  /// Derive a block from entity fields and immediately check for conflicts.
  ///
  /// Returns `(block: null, result: none)` if the entity has no scheduled
  /// time or duration.
  Future<({ScheduledTimeBlock? block, ConflictCheckResult result})>
  deriveAndCheck({
    required String entityId,
    required String entityKind,
    required DateTime? startAt,
    required int? durationMinutes,
    String? modeRefId,
    bool isRigid = false,
    Map<String, String> entityTitles = const {},
  }) async {
    final block = deriveBlock(
      entityId: entityId,
      entityKind: entityKind,
      startAt: startAt,
      durationMinutes: durationMinutes,
      modeRefId: modeRefId,
      isRigid: isRigid,
    );
    if (block == null) {
      return (block: null, result: ConflictCheckResult.none);
    }
    final result = await checkConflicts(block, entityTitles: entityTitles);
    return (block: block, result: result);
  }
}
