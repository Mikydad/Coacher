import '../../time_blocks/application/conflict_detection_engine.dart';
import '../../time_blocks/application/time_block_sync_service.dart';
import '../../time_blocks/domain/models/scheduled_time_block.dart';
import '../domain/models/user_goal.dart';

/// Manages [ScheduledTimeBlock] records for goals.
///
/// Goals do not have an explicit `durationMinutes` field, so
/// [kGoalBlockDefaultDurationMinutes] is used. The start time is derived from
/// [UserGoal.reminderMinutesFromMidnight] anchored to the provided [today].
///
/// This service is the only place that should write/delete goal time blocks.
/// All conflict detection is still handled by [TimeBlockSyncService].
class GoalBlockSyncService {
  GoalBlockSyncService({required TimeBlockSyncService timeBlockSyncService})
    : _tb = timeBlockSyncService;

  final TimeBlockSyncService _tb;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Derives and persists a time block for [goal] anchored to [today].
  ///
  /// No-ops silently when:
  ///   - [goal.reminderEnabled] is false, OR
  ///   - [goal.reminderMinutesFromMidnight] is null, OR
  ///   - [today] is not a planned action day (repeat off or off-day).
  ///
  /// In those cases the existing block (if any) is removed so stale rows do
  /// not participate in future conflict checks.
  Future<void> syncBlockForGoal(UserGoal goal, DateTime today) async {
    if (!goal.reminderEnabled ||
        goal.reminderMinutesFromMidnight == null ||
        !goal.isActionDay(today)) {
      await _tb.removeBlockForEntity(goal.id);
      return;
    }

    final startAt = _startAtFromMinutes(
      goal.reminderMinutesFromMidnight!,
      today,
    );
    final block = _tb.deriveBlock(
      entityId: goal.id,
      entityKind: 'goal',
      startAt: startAt,
      durationMinutes: kGoalBlockDefaultDurationMinutes,
      isRigid: false,
      allowOverlapOverride: false,
    );
    if (block == null) return;

    // Override importance using goal intensity (not modeRefId).
    final withImportance = block.copyWith(
      importance: ConflictDetectionEngine.importanceFromGoalIntensity(
        goal.intensity,
      ),
    );
    await _tb.syncBlock(withImportance);
  }

  /// Derives a proposed [ScheduledTimeBlock] for [goal] **without persisting**
  /// it. Used by [GoalEditorScreen] to run a conflict check before committing.
  ///
  /// Returns null if the goal has no reminder, no time set, or [today] is
  /// not a planned action day.
  ScheduledTimeBlock? deriveBlockForGoal(UserGoal goal, DateTime today) {
    if (!goal.reminderEnabled ||
        goal.reminderMinutesFromMidnight == null ||
        !goal.isActionDay(today)) {
      return null;
    }
    final startAt = _startAtFromMinutes(
      goal.reminderMinutesFromMidnight!,
      today,
    );
    final block = _tb.deriveBlock(
      entityId: goal.id,
      entityKind: 'goal',
      startAt: startAt,
      durationMinutes: kGoalBlockDefaultDurationMinutes,
      isRigid: false,
    );
    if (block == null) return null;
    return block.copyWith(
      importance: ConflictDetectionEngine.importanceFromGoalIntensity(
        goal.intensity,
      ),
    );
  }

  /// Removes the time block for the given [goalId].
  ///
  /// Call this when a goal is archived, completed, or deleted.
  Future<void> removeBlockForGoal(String goalId) async {
    await _tb.removeBlockForEntity(goalId);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Converts [minutesFromMidnight] to an absolute [DateTime] on [today].
  static DateTime _startAtFromMinutes(int minutesFromMidnight, DateTime today) {
    return DateTime(
      today.year,
      today.month,
      today.day,
      minutesFromMidnight ~/ 60,
      minutesFromMidnight % 60,
    );
  }
}
