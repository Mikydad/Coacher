import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/time_block_repository.dart';
import '../domain/models/scheduled_time_block.dart';
import '../domain/models/time_conflict.dart';
import 'reclaimed_time_service.dart';
import 'time_block_sync_service.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final timeBlockRepositoryProvider = Provider<TimeBlockRepository>(
  (ref) => IsarTimeBlockRepository(),
);

// ─── Sync service ─────────────────────────────────────────────────────────────

final timeBlockSyncServiceProvider = Provider<TimeBlockSyncService>((ref) {
  return TimeBlockSyncService(
    repository: ref.read(timeBlockRepositoryProvider),
  );
});

// ─── Conflict check ───────────────────────────────────────────────────────────

/// Runs a conflict check for a [ScheduledTimeBlock].
///
/// Usage:
/// ```dart
/// final result = await ref.read(conflictCheckProvider(block).future);
/// ```
///
/// Invalidate after save so stale conflict state doesn't persist:
/// ```dart
/// ref.invalidate(conflictCheckProvider);
/// ```
final conflictCheckProvider = FutureProvider.family<ConflictCheckResult,
    ScheduledTimeBlock>((ref, proposed) async {
  final service = ref.read(timeBlockSyncServiceProvider);
  return service.checkConflicts(proposed);
});

// ─── Reclaimed time service ───────────────────────────────────────────────────

final reclaimedTimeServiceProvider = Provider<ReclaimedTimeService>((ref) {
  return ReclaimedTimeService(
    repository: ref.read(timeBlockRepositoryProvider),
  );
});
