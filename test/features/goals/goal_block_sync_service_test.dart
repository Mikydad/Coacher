import 'package:sidepal/features/goals/application/goal_block_sync_service.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/time_blocks/application/conflict_detection_engine.dart';
import 'package:sidepal/features/time_blocks/application/time_block_sync_service.dart';
import 'package:sidepal/features/time_blocks/data/time_block_repository.dart';
import 'package:sidepal/features/time_blocks/domain/models/scheduled_time_block.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeRepo implements TimeBlockRepository {
  final List<ScheduledTimeBlock> upserted = [];
  final List<String> deleted = [];

  @override
  Future<void> upsertBlock(ScheduledTimeBlock block) async => upserted.add(block);

  @override
  Future<void> deleteBlock(String id) async => deleted.add(id);

  @override
  Future<void> deleteBlockForEntity(String entityId) async => deleted.add(entityId);

  @override
  Future<List<ScheduledTimeBlock>> listOverlappingBlocks(
    ScheduledTimeBlock proposed,
  ) async => [];

  @override
  Future<List<ScheduledTimeBlock>> listBlocksForDateRange(
    DateTime start,
    DateTime end,
  ) async => [];

  @override
  Future<ScheduledTimeBlock?> getBlockForEntity(String entityId) async => null;
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

UserGoal _makeGoal({
  bool reminderEnabled = true,
  int? reminderMinutesFromMidnight = 600, // 10:00
  int intensity = 3,
  GoalStatus status = GoalStatus.active,
  GoalRepeatCadence? repeatCadence,
  List<int>? scheduledWeekdays,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return UserGoal(
    id: 'goal-1',
    title: 'Test goal',
    categoryId: 'health',
    status: status,
    measurementKind: MeasurementKind.count,
    targetValue: 10,
    intensity: intensity,
    periodStartMs: now,
    periodEndMs: now + const Duration(days: 30).inMilliseconds,
    repeatCadence:
        repeatCadence ??
        (scheduledWeekdays != null
            ? GoalRepeatCadence.weekly
            : GoalRepeatCadence.daily),
    scheduledWeekdays: scheduledWeekdays,
    reminderEnabled: reminderEnabled,
    reminderMinutesFromMidnight: reminderMinutesFromMidnight,
    createdAtMs: now,
    updatedAtMs: now,
  );
}

GoalBlockSyncService _buildService(_FakeRepo repo) {
  final tb = TimeBlockSyncService(repository: repo);
  return GoalBlockSyncService(timeBlockSyncService: tb);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  final today = DateTime(2026, 5, 19);

  group('GoalBlockSyncService.syncBlockForGoal', () {
    test('no-ops and removes block when reminderEnabled = false', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      final goal = _makeGoal(reminderEnabled: false);

      await svc.syncBlockForGoal(goal, today);

      expect(repo.upserted, isEmpty);
      expect(repo.deleted, contains(goal.id));
    });

    test('no-ops and removes block when reminderMinutesFromMidnight is null', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      final goal = _makeGoal(
        reminderEnabled: true,
        reminderMinutesFromMidnight: null,
      );

      await svc.syncBlockForGoal(goal, today);

      expect(repo.upserted, isEmpty);
      expect(repo.deleted, contains(goal.id));
    });

    test('upserts a block with correct start time (10:00 → 600 min)', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      final goal = _makeGoal(reminderMinutesFromMidnight: 600);

      await svc.syncBlockForGoal(goal, today);

      expect(repo.upserted, hasLength(1));
      final block = repo.upserted.first;
      expect(block.startAt, DateTime(today.year, today.month, today.day, 10, 0));
    });

    test('upserts a block with correct start time (22:30 → 1350 min)', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      final goal = _makeGoal(reminderMinutesFromMidnight: 1350);

      await svc.syncBlockForGoal(goal, today);

      final block = repo.upserted.first;
      expect(block.startAt, DateTime(today.year, today.month, today.day, 22, 30));
    });

    test('block duration equals kGoalBlockDefaultDurationMinutes (30)', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(), today);

      expect(repo.upserted.first.expectedDurationMinutes, kGoalBlockDefaultDurationMinutes);
    });

    test('block entityKind is "goal"', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(), today);

      expect(repo.upserted.first.entityKind, 'goal');
    });

    test('importance 30 for intensity 1', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(intensity: 1), today);

      expect(repo.upserted.first.importance, 30);
    });

    test('importance 30 for intensity 2', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(intensity: 2), today);

      expect(repo.upserted.first.importance, 30);
    });

    test('importance 60 for intensity 3', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(intensity: 3), today);

      expect(repo.upserted.first.importance, 60);
    });

    test('importance 90 for intensity 4', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(intensity: 4), today);

      expect(repo.upserted.first.importance, 90);
    });

    test('importance 90 for intensity 5', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(intensity: 5), today);

      expect(repo.upserted.first.importance, 90);
    });

    test('importance matches ConflictDetectionEngine.importanceFromGoalIntensity', () async {
      for (final intensity in [1, 2, 3, 4, 5]) {
        final repo = _FakeRepo();
        final svc = _buildService(repo);

        await svc.syncBlockForGoal(_makeGoal(intensity: intensity), today);

        expect(
          repo.upserted.first.importance,
          ConflictDetectionEngine.importanceFromGoalIntensity(intensity),
          reason: 'intensity $intensity',
        );
      }
    });

    test('removes block when today is not a scheduled weekday', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      // today (2026-05-19) is a Tuesday; goal runs Mon/Wed/Fri.
      final goal = _makeGoal(
        scheduledWeekdays: const [
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ],
      );

      await svc.syncBlockForGoal(goal, today);

      expect(repo.upserted, isEmpty);
      expect(repo.deleted, contains(goal.id));
    });

    test('removes block when repeat schedule is off (passive goal)', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      final goal = _makeGoal(repeatCadence: GoalRepeatCadence.off);

      await svc.syncBlockForGoal(goal, today);

      expect(repo.upserted, isEmpty);
      expect(repo.deleted, contains(goal.id));
    });

    test('upserts block when today is a scheduled weekday', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);
      // 2026-05-19 is a Tuesday.
      final goal = _makeGoal(scheduledWeekdays: const [DateTime.tuesday]);

      await svc.syncBlockForGoal(goal, today);

      expect(repo.upserted, hasLength(1));
    });

    test('block is flexible (not rigid)', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.syncBlockForGoal(_makeGoal(), today);

      expect(repo.upserted.first.flexibilityType, FlexibilityType.flexible);
    });
  });

  group('GoalBlockSyncService.deriveBlockForGoal', () {
    test('returns null when reminderEnabled = false', () {
      final svc = _buildService(_FakeRepo());
      final block = svc.deriveBlockForGoal(_makeGoal(reminderEnabled: false), today);
      expect(block, isNull);
    });

    test('returns null when reminderMinutesFromMidnight is null', () {
      final svc = _buildService(_FakeRepo());
      final block = svc.deriveBlockForGoal(
        _makeGoal(reminderMinutesFromMidnight: null),
        today,
      );
      expect(block, isNull);
    });

    test('returns null when today is not a scheduled weekday', () {
      final svc = _buildService(_FakeRepo());
      // 2026-05-19 is a Tuesday; goal runs Monday only.
      final block = svc.deriveBlockForGoal(
        _makeGoal(scheduledWeekdays: const [DateTime.monday]),
        today,
      );
      expect(block, isNull);
    });

    test('returns non-null ScheduledTimeBlock for valid goal', () {
      final svc = _buildService(_FakeRepo());
      final block = svc.deriveBlockForGoal(_makeGoal(), today);
      expect(block, isNotNull);
    });

    test('derived block has correct importance (intensity 4 → 90)', () {
      final svc = _buildService(_FakeRepo());
      final block = svc.deriveBlockForGoal(_makeGoal(intensity: 4), today);
      expect(block!.importance, 90);
    });
  });

  group('GoalBlockSyncService.removeBlockForGoal', () {
    test('delegates to TimeBlockSyncService.removeBlockForEntity', () async {
      final repo = _FakeRepo();
      final svc = _buildService(repo);

      await svc.removeBlockForGoal('goal-42');

      expect(repo.deleted, contains('goal-42'));
    });
  });
}
