import '../domain/models/scheduled_time_block.dart';
import '../domain/models/time_conflict.dart';

/// Narrow port for [SchedulingConflictSheet] (testable).
abstract class ConflictResolutionPort {
  Future<ConflictCheckResult> recheckProposedBlock(
    ScheduledTimeBlock proposed, {
    Map<String, String> entityTitles = const {},
  });

  Future<List<ScheduledTimeBlock>> blocksForPlanDay(DateTime planDay);

  Future<ScheduledTimeBlock?> blockForEntity(String entityId);

  Future<String> moveConflictingEntity({
    required TimeConflict conflict,
    required DateTime newStart,
    required DateTime planDay,
    int? durationMinutes,
  });
}
