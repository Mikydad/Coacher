import '../data/time_block_repository.dart';
import '../domain/models/scheduled_time_block.dart';

/// Detects early task completion and computes the freed time window.
///
/// The [AvailableTimeWindow] is in-memory only — not persisted to Isar.
/// UI shows a passive snackbar suggestion when reclaimed time ≥ 10 minutes.
class ReclaimedTimeService {
  ReclaimedTimeService({
    required TimeBlockRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final TimeBlockRepository _repository;
  final DateTime Function() _now;

  /// Check whether a task completed before its expected duration.
  ///
  /// Returns an [AvailableTimeWindow] when reclaimed minutes ≥ 1.
  /// Returns null when:
  ///   - No [ScheduledTimeBlock] exists for the entity.
  ///   - The task completed at or after the expected end time.
  Future<AvailableTimeWindow?> checkEarlyCompletion({
    required String entityId,
    DateTime? completedAt,
  }) async {
    final block = await _repository.getBlockForEntity(entityId);
    if (block == null) return null;

    final finishedAt = completedAt ?? _now();
    if (!finishedAt.isBefore(block.computedEndAt)) return null;

    final reclaimedMinutes = block.computedEndAt
        .difference(finishedAt)
        .inMinutes;
    if (reclaimedMinutes < 1) return null;

    return AvailableTimeWindow(
      entityId: entityId,
      windowStartAt: finishedAt,
      windowEndAt: block.computedEndAt,
      durationMinutes: reclaimedMinutes,
      createdAtMs: _now().millisecondsSinceEpoch,
    );
  }
}
