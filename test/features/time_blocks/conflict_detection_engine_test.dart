import 'package:coach_for_life/features/time_blocks/application/conflict_detection_engine.dart';
import 'package:coach_for_life/features/time_blocks/domain/models/scheduled_time_block.dart';
import 'package:coach_for_life/features/time_blocks/domain/models/time_conflict.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConflictDetectionEngine', () {
    // Helper — builds a minimal ScheduledTimeBlock.
    ScheduledTimeBlock makeBlock({
      required String entityId,
      required DateTime startAt,
      required int durationMinutes,
      FlexibilityType flexibilityType = FlexibilityType.flexible,
      int importance = 30,
    }) {
      return ScheduledTimeBlock(
        id: 'tb_$entityId',
        entityId: entityId,
        entityKind: 'task',
        startAt: startAt,
        expectedDurationMinutes: durationMinutes,
        computedEndAt: startAt.add(Duration(minutes: durationMinutes)),
        flexibilityType: flexibilityType,
        allowOverlapOverride: false,
        importance: importance,
        createdAtMs: 0,
        updatedAtMs: 0,
      );
    }

    // ─── Threshold tests ─────────────────────────────────────────────────

    test('no conflict when overlap is 0', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed = makeBlock(entityId: 'a', startAt: now, durationMinutes: 60);
      final other = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(hours: 1)),
        durationMinutes: 30,
      );
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isEmpty);
    });

    test('no conflict for 2-min overlap on 60-min blocks (< 5 min AND < 15%)', () {
      // 2 min overlap on 60 min blocks → 3.3% < 15% and 2 < 5 min.
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed = makeBlock(entityId: 'a', startAt: now, durationMinutes: 60);
      final other = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(minutes: 58)),
        durationMinutes: 60,
      );
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isEmpty);
    });

    test('conflict for 6-min overlap on 20-min block (> 5 min)', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed =
          makeBlock(entityId: 'a', startAt: now, durationMinutes: 20);
      final other = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(minutes: 14)),
        durationMinutes: 20,
      );
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isNotEmpty);
      expect(conflicts.first.overlapMinutes, 6);
    });

    test('conflict for 3-min overlap on 10-min block (≥ 15% of shorter)', () {
      // 3 min on 10 min = 30% ≥ 15%.
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed =
          makeBlock(entityId: 'a', startAt: now, durationMinutes: 10);
      final other = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(minutes: 7)),
        durationMinutes: 10,
      );
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isNotEmpty);
    });

    // ─── Severity classification ──────────────────────────────────────────

    test('rigid block raises severity to moderate or severe', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed = makeBlock(
        entityId: 'a',
        startAt: now,
        durationMinutes: 30,
        flexibilityType: FlexibilityType.rigid,
        importance: 90,
      );
      final other =
          makeBlock(entityId: 'b', startAt: now, durationMinutes: 30);
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isNotEmpty);
      expect(
        conflicts.first.severityLabel,
        anyOf(ConflictSeverity.moderate, ConflictSeverity.severe),
      );
    });

    test('minor classification for small overlap with low importance', () {
      // 6-min overlap on 30-min blocks, both flexible, both low importance.
      // overlapRatio = 6/30 = 0.2, hardness = 0.0, importance = 10/100*0.2 = 0.02
      // total = 0.22 → minor.
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed = makeBlock(
        entityId: 'a',
        startAt: now,
        durationMinutes: 30,
        importance: 10,
      );
      final other = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(minutes: 24)),
        durationMinutes: 30,
        importance: 10,
      );
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isNotEmpty);
      expect(conflicts.first.severityLabel, ConflictSeverity.minor);
    });

    // ─── Conflict type ────────────────────────────────────────────────────

    test('contained conflict type when one block is inside another', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final outer =
          makeBlock(entityId: 'a', startAt: now, durationMinutes: 120);
      final inner = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(minutes: 30)),
        durationMinutes: 30,
      );
      final conflicts = ConflictDetectionEngine.detect(
        proposed: outer,
        existing: [inner],
      );
      expect(conflicts, isNotEmpty);
      expect(conflicts.first.conflictType, ConflictType.contained);
    });

    test('partial overlap conflict type for edge overlap', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed =
          makeBlock(entityId: 'a', startAt: now, durationMinutes: 60);
      final other = makeBlock(
        entityId: 'b',
        startAt: now.add(const Duration(minutes: 45)),
        durationMinutes: 60,
      );
      final conflicts =
          ConflictDetectionEngine.detect(proposed: proposed, existing: [other]);
      expect(conflicts, isNotEmpty);
      expect(conflicts.first.conflictType, ConflictType.partialOverlap);
    });

    // ─── buildResult ──────────────────────────────────────────────────────

    test('buildResult returns none when no conflicts', () {
      final result = ConflictDetectionEngine.buildResult([]);
      expect(result.hasConflicts, isFalse);
      expect(result.conflicts, isEmpty);
      expect(result.worstSeverity, isNull);
    });

    test('buildResult returns worst severity across multiple conflicts', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed = makeBlock(
        entityId: 'a',
        startAt: now,
        durationMinutes: 60,
        importance: 90,
        flexibilityType: FlexibilityType.rigid,
      );
      final blocks = [
        makeBlock(
          entityId: 'b',
          startAt: now.add(const Duration(minutes: 50)),
          durationMinutes: 60,
          importance: 10,
        ),
        makeBlock(
          entityId: 'c',
          startAt: now,
          durationMinutes: 60,
          importance: 90,
          flexibilityType: FlexibilityType.rigid,
        ),
      ];
      final conflicts = ConflictDetectionEngine.detect(
        proposed: proposed,
        existing: blocks,
      );
      final result = ConflictDetectionEngine.buildResult(conflicts);
      expect(result.hasConflicts, isTrue);
      expect(result.worstSeverity, ConflictSeverity.severe);
    });

    // ─── importanceFromModeRefId ──────────────────────────────────────────

    test('importanceFromModeRefId maps correctly', () {
      expect(ConflictDetectionEngine.importanceFromModeRefId('extreme'), 90);
      expect(
          ConflictDetectionEngine.importanceFromModeRefId('disciplined'), 60);
      expect(ConflictDetectionEngine.importanceFromModeRefId('flexible'), 30);
      expect(ConflictDetectionEngine.importanceFromModeRefId(null), 30);
      expect(ConflictDetectionEngine.importanceFromModeRefId('unknown'), 30);
    });

    // ─── Own block exclusion ──────────────────────────────────────────────

    test('own entity block is excluded from conflicts', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      final proposed =
          makeBlock(entityId: 'a', startAt: now, durationMinutes: 60);
      final ownExisting =
          makeBlock(entityId: 'a', startAt: now, durationMinutes: 60);
      final conflicts = ConflictDetectionEngine.detect(
        proposed: proposed,
        existing: [ownExisting],
      );
      expect(conflicts, isEmpty);
    });
  });
}
