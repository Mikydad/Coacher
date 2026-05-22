import 'package:coach_for_life/features/time_blocks/application/time_block_sync_service.dart';
import 'package:coach_for_life/features/time_blocks/data/time_block_repository.dart';
import 'package:coach_for_life/features/time_blocks/domain/models/scheduled_time_block.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeTimeBlockRepository implements TimeBlockRepository {
  final List<ScheduledTimeBlock> blocks = [];

  @override
  Future<void> upsertBlock(ScheduledTimeBlock block) async {
    blocks.removeWhere((b) => b.entityId == block.entityId);
    blocks.add(block);
  }

  @override
  Future<void> deleteBlock(String id) async {
    blocks.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteBlockForEntity(String entityId) async {
    blocks.removeWhere((b) => b.entityId == entityId);
  }

  @override
  Future<List<ScheduledTimeBlock>> listBlocksForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return blocks.where((b) {
      return b.startAt.isBefore(end) && b.computedEndAt.isAfter(start);
    }).toList();
  }

  @override
  Future<List<ScheduledTimeBlock>> listOverlappingBlocks(
    ScheduledTimeBlock proposed,
  ) async {
    return blocks.where((b) {
      if (b.entityId == proposed.entityId) return false;
      return b.startAt.isBefore(proposed.computedEndAt) &&
          b.computedEndAt.isAfter(proposed.startAt);
    }).toList();
  }

  @override
  Future<ScheduledTimeBlock?> getBlockForEntity(String entityId) async {
    final matches = blocks.where((b) => b.entityId == entityId);
    return matches.isEmpty ? null : matches.first;
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeTimeBlockRepository repo;
  late TimeBlockSyncService service;
  final fixedNow = DateTime(2026, 5, 18, 9, 0);

  setUp(() {
    repo = _FakeTimeBlockRepository();
    service = TimeBlockSyncService(
      repository: repo,
      now: () => fixedNow,
    );
  });

  group('TimeBlockSyncService.deriveBlock', () {
    test('returns null when startAt is null', () {
      final block = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: null,
        durationMinutes: 30,
      );
      expect(block, isNull);
    });

    test('returns null when durationMinutes is null', () {
      final block = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: null,
      );
      expect(block, isNull);
    });

    test('derives block with correct computedEndAt', () {
      final block = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
      );
      expect(block, isNotNull);
      expect(
        block!.computedEndAt,
        fixedNow.add(const Duration(minutes: 30)),
      );
    });

    test('rigid flag sets FlexibilityType.rigid', () {
      final block = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
        isRigid: true,
      );
      expect(block?.flexibilityType, FlexibilityType.rigid);
    });

    test('importance derived from modeRefId', () {
      final extreme = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
        modeRefId: 'extreme',
      );
      expect(extreme?.importance, 90);
    });
  });

  group('TimeBlockSyncService.syncBlock', () {
    test('upserts block into repository', () async {
      final block = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
      )!;
      await service.syncBlock(block);
      expect(repo.blocks, hasLength(1));
      expect(repo.blocks.first.entityId, 'a');
    });

    test('replaces existing block for same entity', () async {
      final block1 = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
      )!;
      await service.syncBlock(block1);

      final block2 = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow.add(const Duration(hours: 1)),
        durationMinutes: 45,
      )!;
      await service.syncBlock(block2);

      expect(repo.blocks, hasLength(1));
      expect(repo.blocks.first.expectedDurationMinutes, 45);
    });
  });

  group('TimeBlockSyncService.checkConflicts', () {
    test('returns no conflicts when no overlap exists', () async {
      final existing = service.deriveBlock(
        entityId: 'b',
        entityKind: 'task',
        startAt: fixedNow.add(const Duration(hours: 2)),
        durationMinutes: 30,
      )!;
      await service.syncBlock(existing);

      final proposed = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
      )!;
      final result = await service.checkConflicts(proposed);
      expect(result.hasConflicts, isFalse);
    });

    test('returns conflict when blocks overlap sufficiently', () async {
      final existing = service.deriveBlock(
        entityId: 'b',
        entityKind: 'task',
        startAt: fixedNow.add(const Duration(minutes: 20)),
        durationMinutes: 30,
      )!;
      await service.syncBlock(existing);

      final proposed = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
      )!;
      final result = await service.checkConflicts(proposed);
      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.first.conflictingEntityId, 'b');
    });
  });

  group('TimeBlockSyncService.removeBlockForEntity', () {
    test('removes block from repository', () async {
      final block = service.deriveBlock(
        entityId: 'a',
        entityKind: 'task',
        startAt: fixedNow,
        durationMinutes: 30,
      )!;
      await service.syncBlock(block);
      expect(repo.blocks, hasLength(1));

      await service.removeBlockForEntity('a');
      expect(repo.blocks, isEmpty);
    });
  });
}
