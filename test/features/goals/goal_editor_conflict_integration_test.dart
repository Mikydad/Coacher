/// Integration test: GoalBlockSyncService → TimeBlockSyncService →
/// ConflictDetectionEngine across real service wiring.
///
/// Tests the full conflict-check chain that backs
/// GoalEditorScreen._checkGoalTimeBlockConflicts without needing Flutter
/// widgets, Firebase, or Isar.
library;

import 'package:coach_for_life/features/goals/application/goal_block_sync_service.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/time_blocks/application/conflict_detection_engine.dart';
import 'package:coach_for_life/features/time_blocks/application/time_block_sync_service.dart';
import 'package:coach_for_life/features/time_blocks/data/time_block_repository.dart';
import 'package:coach_for_life/features/time_blocks/domain/models/scheduled_time_block.dart';
import 'package:coach_for_life/features/time_blocks/domain/models/time_conflict.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeRepo implements TimeBlockRepository {
  /// Blocks returned by [listOverlappingBlocks].
  List<ScheduledTimeBlock> overlapping = [];

  final List<ScheduledTimeBlock> upserted = [];
  final List<String> deleted = [];

  @override
  Future<void> upsertBlock(ScheduledTimeBlock block) async =>
      upserted.add(block);

  @override
  Future<void> deleteBlock(String id) async => deleted.add(id);

  @override
  Future<void> deleteBlockForEntity(String entityId) async =>
      deleted.add(entityId);

  @override
  Future<List<ScheduledTimeBlock>> listOverlappingBlocks(
    ScheduledTimeBlock proposed,
  ) async =>
      overlapping
          .where((b) => b.entityId != proposed.entityId)
          .toList();

  @override
  Future<List<ScheduledTimeBlock>> listBlocksForDateRange(
    DateTime start,
    DateTime end,
  ) async =>
      [];

  @override
  Future<ScheduledTimeBlock?> getBlockForEntity(String entityId) async => null;
}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _today = DateTime(2026, 5, 19);

UserGoal _makeGoal({
  String id = 'goal-1',
  int reminderMinutesFromMidnight = 600, // 10:00
  int intensity = 3,
}) {
  final now = _today.millisecondsSinceEpoch;
  return UserGoal(
    id: id,
    title: 'Test Goal',
    categoryId: 'health',
    horizon: GoalHorizon.monthly,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.count,
    targetValue: 10,
    intensity: intensity,
    periodStartMs: now,
    periodEndMs: now + const Duration(days: 30).inMilliseconds,
    reminderEnabled: true,
    reminderMinutesFromMidnight: reminderMinutesFromMidnight,
    createdAtMs: now,
    updatedAtMs: now,
  );
}

/// Builds a persisted block for an *existing* entity that overlaps 10:00.
ScheduledTimeBlock _existingBlock({
  String entityId = 'task-existing',
  String entityKind = 'task',
  int startHour = 10,
  int durationMinutes = 60,
  int importance = 60,
}) {
  final start = DateTime(_today.year, _today.month, _today.day, startHour, 0);
  return ScheduledTimeBlock(
    id: 'block-existing',
    entityId: entityId,
    entityKind: entityKind,
    startAt: start,
    expectedDurationMinutes: durationMinutes,
    computedEndAt: start.add(Duration(minutes: durationMinutes)),
    flexibilityType: FlexibilityType.flexible,
    allowOverlapOverride: false,
    importance: importance,
    createdAtMs: _today.millisecondsSinceEpoch,
    updatedAtMs: _today.millisecondsSinceEpoch,
  );
}

// ─── Service builder ─────────────────────────────────────────────────────────

({GoalBlockSyncService goalSvc, TimeBlockSyncService tbSvc, _FakeRepo repo})
    _build() {
  final repo = _FakeRepo();
  final tbSvc = TimeBlockSyncService(repository: repo);
  final goalSvc = GoalBlockSyncService(timeBlockSyncService: tbSvc);
  return (goalSvc: goalSvc, tbSvc: tbSvc, repo: repo);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Goal-block conflict integration (goal → conflict engine)', () {
    // ── No conflict ───────────────────────────────────────────────────────────

    test('no conflicts when block store is empty', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      final goal = _makeGoal();
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(result.hasConflicts, isFalse);
    });

    test('no conflicts when existing block does not overlap', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      // Existing block: 13:00–14:00 (no overlap with goal at 10:00–10:30).
      repo.overlapping = [_existingBlock(startHour: 13)];
      final goal = _makeGoal();
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(result.hasConflicts, isFalse);
    });

    // ── Conflict detected ─────────────────────────────────────────────────────

    test('detects conflict when task block overlaps goal block', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      // Existing task: 10:00–11:00 overlaps goal at 10:00–10:30 by 30 min.
      repo.overlapping = [_existingBlock(startHour: 10, durationMinutes: 60)];
      final goal = _makeGoal();
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts, hasLength(1));
    });

    test('detects conflict when goal block overlaps another goal block', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      // Existing goal: 10:00–10:30 — direct overlap.
      repo.overlapping = [
        _existingBlock(
          entityId: 'goal-other',
          entityKind: 'goal',
          startHour: 10,
          durationMinutes: 30,
        ),
      ];
      final goal = _makeGoal();
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.first.conflictingEntityKind, 'goal');
    });

    // ── Severity pipeline ─────────────────────────────────────────────────────

    test('30-min full overlap with intensity-3 goal → moderate or severe', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      repo.overlapping = [_existingBlock(startHour: 10, durationMinutes: 30)];
      final goal = _makeGoal(intensity: 3);
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(
        result.worstSeverity,
        anyOf(ConflictSeverity.moderate, ConflictSeverity.severe),
      );
    });

    test('brief 2-min fringe overlap → no conflict (below threshold)', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      // Existing block: 10:28–11:28. Goal at 10:00–10:30 → 2 min overlap.
      // 2 min < 5 min threshold AND 2/30 = 6.7% < 15% → no conflict.
      final start = DateTime(_today.year, _today.month, _today.day, 10, 28);
      repo.overlapping = [
        ScheduledTimeBlock(
          id: 'block-fringe',
          entityId: 'task-fringe',
          entityKind: 'task',
          startAt: start,
          expectedDurationMinutes: 60,
          computedEndAt: start.add(const Duration(minutes: 60)),
          flexibilityType: FlexibilityType.flexible,
          allowOverlapOverride: false,
          importance: 30,
          createdAtMs: _today.millisecondsSinceEpoch,
          updatedAtMs: _today.millisecondsSinceEpoch,
        ),
      ];
      final goal = _makeGoal(reminderMinutesFromMidnight: 600); // 10:00–10:30
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(result.hasConflicts, isFalse);
    });

    // ── Title map wiring ──────────────────────────────────────────────────────

    test('entity title map populates conflictingEntityTitle', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      repo.overlapping = [
        _existingBlock(entityId: 'task-abc', entityKind: 'task'),
      ];
      final goal = _makeGoal();
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(
        proposed,
        entityTitles: {'task-abc': 'Deep Work Session'},
      );

      expect(result.hasConflicts, isTrue);
      expect(
        result.conflicts.first.conflictingEntityTitle,
        'Deep Work Session',
      );
    });

    test('falls back to kind label when title map has no entry', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      repo.overlapping = [
        _existingBlock(entityId: 'task-xyz', entityKind: 'task'),
      ];
      final goal = _makeGoal();
      final proposed = goalSvc.deriveBlockForGoal(goal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      expect(
        result.conflicts.first.conflictingEntityTitle,
        'Another scheduled task',
      );
    });

    // ── Goal intensity → importance → severity ────────────────────────────────

    test('high-intensity goal (5) raises importance to 90', () {
      final proposed = GoalBlockSyncService(
        timeBlockSyncService: TimeBlockSyncService(repository: _FakeRepo()),
      ).deriveBlockForGoal(_makeGoal(intensity: 5), _today)!;

      expect(proposed.importance, 90);
    });

    test('low-intensity goal (1) keeps importance at 30', () {
      final proposed = GoalBlockSyncService(
        timeBlockSyncService: TimeBlockSyncService(repository: _FakeRepo()),
      ).deriveBlockForGoal(_makeGoal(intensity: 1), _today)!;

      expect(proposed.importance, 30);
    });

    test('severity is higher when both goal and task have high importance', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      // Existing block with importance = 90 (extreme task).
      repo.overlapping = [
        _existingBlock(
          startHour: 10,
          durationMinutes: 30,
          importance: 90,
        ),
      ];
      final highIntensityGoal = _makeGoal(intensity: 5);
      final proposed = goalSvc.deriveBlockForGoal(highIntensityGoal, _today)!;

      final result = await tbSvc.checkConflicts(proposed);

      // Both importance 90 → importanceWeight = 0.18; full overlap ratio = 1.0
      // → total ≥ 1.0 → clamped to 1.0 → severe.
      expect(result.worstSeverity, ConflictSeverity.severe);
    });

    // ── syncBlockForGoal correctly upserts ────────────────────────────────────

    test('syncBlockForGoal upserts block with correct metadata', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      final goal = _makeGoal(reminderMinutesFromMidnight: 540, intensity: 4); // 09:00

      await goalSvc.syncBlockForGoal(goal, _today);

      expect(repo.upserted, hasLength(1));
      final b = repo.upserted.first;
      expect(b.entityId, goal.id);
      expect(b.entityKind, 'goal');
      expect(b.startAt, DateTime(_today.year, _today.month, _today.day, 9, 0));
      expect(b.expectedDurationMinutes, kGoalBlockDefaultDurationMinutes);
      expect(b.importance, ConflictDetectionEngine.importanceFromGoalIntensity(4));
      expect(b.flexibilityType, FlexibilityType.flexible);
    });

    // ── goal vs goal conflict check ───────────────────────────────────────────

    test('goal vs goal: same time → conflict detected', () async {
      final (:goalSvc, :tbSvc, :repo) = _build();
      // Both goals at 10:00 for 30 min.
      repo.overlapping = [
        _existingBlock(
          entityId: 'goal-B',
          entityKind: 'goal',
          startHour: 10,
          durationMinutes: 30,
          importance: 60,
        ),
      ];
      final goalA = _makeGoal(id: 'goal-A');
      final proposed = goalSvc.deriveBlockForGoal(goalA, _today)!;

      final result = await tbSvc.checkConflicts(
        proposed,
        entityTitles: {'goal-B': 'Exercise'},
      );

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.first.conflictingEntityKind, 'goal');
      expect(result.conflicts.first.conflictingEntityTitle, 'Exercise');
    });
  });
}
