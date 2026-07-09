import 'dart:io';

import 'package:coach_for_life/core/local_db/isar_collections/isar_ai_action_batch.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_action_batch_repository.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_action_batch_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;
  late AiActionBatchRepository repo;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    repo = AiActionBatchRepository(isar!);
  });

  tearDown(() async => closeTempIsar(isar!, dir!));

  // ── helpers ──────────────────────────────────────────────────────────────────

  IsarAiActionBatch _batch({
    required String batchId,
    AiActionBatchState state = AiActionBatchState.pending,
    int? createdAtMs,
  }) {
    final now = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;
    return IsarAiActionBatch()
      ..batchId = batchId
      ..state = state.name
      ..actionsJson = '[]'
      ..snapshotJson = '{}'
      ..succeededActionIds = []
      ..failedActionIds = []
      ..createdAtMs = now
      ..updatedAtMs = now;
  }

  // ── tests ────────────────────────────────────────────────────────────────────

  group('AiActionBatchRepository', () {
    test('createBatch + findByBatchId returns the created batch', () async {
      await repo.createBatch(_batch(batchId: 'uuid-1'));

      final found = await repo.findByBatchId('uuid-1');
      expect(found, isNotNull);
      expect(found!.batchId, equals('uuid-1'));
      expect(found.state, equals(AiActionBatchState.pending.name));
    });

    test('findMostRecent returns the newest batch by createdAtMs', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.createBatch(_batch(batchId: 'old', createdAtMs: now - 5000));
      await repo.createBatch(_batch(batchId: 'new', createdAtMs: now));

      final most = await repo.findMostRecent();
      expect(most!.batchId, equals('new'));
    });

    test('updateState transitions state and updates succeeded/failed lists',
        () async {
      await repo.createBatch(_batch(batchId: 'uuid-2'));

      await repo.updateState(
        'uuid-2',
        AiActionBatchState.completed,
        succeeded: ['action-a', 'action-b'],
        failed: [],
      );

      final updated = await repo.findByBatchId('uuid-2');
      expect(updated!.state, equals(AiActionBatchState.completed.name));
      expect(updated.succeededActionIds, containsAll(['action-a', 'action-b']));
      expect(updated.failedActionIds, isEmpty);
    });

    test('updateState sets undoneAtMs on rollback', () async {
      await repo.createBatch(
        _batch(batchId: 'uuid-3', state: AiActionBatchState.completed),
      );

      final undoneAt = DateTime.now().millisecondsSinceEpoch;
      await repo.updateState(
        'uuid-3',
        AiActionBatchState.rolledBack,
        undoneAtMs: undoneAt,
      );

      final updated = await repo.findByBatchId('uuid-3');
      expect(updated!.state, equals(AiActionBatchState.rolledBack.name));
      expect(updated.undoneAtMs, equals(undoneAt));
    });

    test('listRecent returns up to [limit] batches newest first', () async {
      final base = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < 7; i++) {
        await repo.createBatch(
          _batch(batchId: 'batch-$i', createdAtMs: base + i * 1000),
        );
      }

      final recent = await repo.listRecent(limit: 5);
      expect(recent.length, equals(5));
      expect(recent.first.batchId, equals('batch-6')); // newest first
    });

    test('pruneOld respects 7-day limit', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final old = now - const Duration(days: 8).inMilliseconds;
      await repo.createBatch(_batch(batchId: 'old-batch', createdAtMs: old));
      await repo.createBatch(_batch(batchId: 'fresh-batch', createdAtMs: now));

      await repo.pruneOld();

      expect(await repo.findByBatchId('old-batch'), isNull);
      expect(await repo.findByBatchId('fresh-batch'), isNotNull);
    });

    test('pruneOld enforces 20-batch count limit', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < 25; i++) {
        await repo.createBatch(
          _batch(batchId: 'b-$i', createdAtMs: now + i * 1000),
        );
      }

      await repo.pruneOld();

      final remaining = await repo.listRecent(limit: 100);
      expect(remaining.length, equals(20));
      // Oldest (b-0 … b-4) should have been pruned.
      for (var i = 0; i < 5; i++) {
        expect(await repo.findByBatchId('b-$i'), isNull);
      }
    });
  });
}
