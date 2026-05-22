import 'package:isar/isar.dart';

import '../../../core/local_db/isar_collections/isar_scheduled_time_block.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/scheduled_time_block.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class TimeBlockRepository {
  Future<void> upsertBlock(ScheduledTimeBlock block);

  Future<void> deleteBlock(String id);

  Future<void> deleteBlockForEntity(String entityId);

  /// Returns all blocks whose time window intersects [start, end].
  Future<List<ScheduledTimeBlock>> listBlocksForDateRange(
    DateTime start,
    DateTime end,
  );

  /// Returns all existing blocks that geometrically overlap with [proposed].
  /// Candidates are fetched by time range; the threshold filter
  /// (≥ 5 min OR ≥ 15% of shorter block) is applied by the caller
  /// (ConflictDetectionEngine). This method returns raw geometric overlaps.
  Future<List<ScheduledTimeBlock>> listOverlappingBlocks(
    ScheduledTimeBlock proposed,
  );

  /// Returns the block for a specific entity, or null if none exists.
  Future<ScheduledTimeBlock?> getBlockForEntity(String entityId);
}

// ─── Isar implementation ──────────────────────────────────────────────────────

class IsarTimeBlockRepository implements TimeBlockRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> upsertBlock(ScheduledTimeBlock block) async {
    block.validate();
    await _isar.writeTxn(() async {
      await _isar.isarScheduledTimeBlocks.putByBlockId(
        IsarScheduledTimeBlock.fromDomain(block),
      );
    });
  }

  @override
  Future<void> deleteBlock(String id) async {
    await _isar.writeTxn(() async {
      await _isar.isarScheduledTimeBlocks
          .filter()
          .blockIdEqualTo(id)
          .deleteAll();
    });
  }

  @override
  Future<void> deleteBlockForEntity(String entityId) async {
    await _isar.writeTxn(() async {
      await _isar.isarScheduledTimeBlocks
          .filter()
          .entityIdEqualTo(entityId)
          .deleteAll();
    });
  }

  @override
  Future<List<ScheduledTimeBlock>> listBlocksForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;
    // A block intersects [start, end] if startAt < end AND computedEndAt > start.
    final rows = await _isar.isarScheduledTimeBlocks
        .filter()
        .startAtMsLessThan(endMs)
        .and()
        .computedEndAtMsGreaterThan(startMs)
        .findAll();
    return rows.map((r) => r.toDomain()).toList(growable: false);
  }

  @override
  Future<List<ScheduledTimeBlock>> listOverlappingBlocks(
    ScheduledTimeBlock proposed,
  ) async {
    final proposedStartMs = proposed.startAt.millisecondsSinceEpoch;
    final proposedEndMs = proposed.computedEndAt.millisecondsSinceEpoch;
    // Fetch all blocks that geometrically overlap the proposed window,
    // excluding the proposed entity's own block (if it already exists).
    final rows = await _isar.isarScheduledTimeBlocks
        .filter()
        .startAtMsLessThan(proposedEndMs)
        .and()
        .computedEndAtMsGreaterThan(proposedStartMs)
        .not()
        .entityIdEqualTo(proposed.entityId)
        .findAll();
    return rows.map((r) => r.toDomain()).toList(growable: false);
  }

  @override
  Future<ScheduledTimeBlock?> getBlockForEntity(String entityId) async {
    final row = await _isar.isarScheduledTimeBlocks
        .filter()
        .entityIdEqualTo(entityId)
        .findFirst();
    return row?.toDomain();
  }
}
