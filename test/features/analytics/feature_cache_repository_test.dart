import 'dart:convert';
import 'dart:io';

import 'package:sidepal/core/local_db/isar_collections/isar_behavior_feature_cache.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/features/analytics/data/feature_cache_repository.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/behavior_time_metrics_fixture.dart';
import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('upsert and query by entity kind/date window', () async {
    final repo = IsarFeatureCacheRepository();
    final now = DateTime(2026, 5, 6).millisecondsSinceEpoch;
    await repo.upsertFeatures([
      _feature(
        id: 'task-1',
        kind: BehaviorEntityKind.task,
        computedAtMs: now,
        start: '2026-05-01',
        end: '2026-05-06',
      ),
      _feature(
        id: 'goal-1',
        kind: BehaviorEntityKind.goal,
        computedAtMs: now + 1,
        start: '2026-05-01',
        end: '2026-05-06',
      ),
    ]);

    final taskOnly = await repo.listByEntityKind(BehaviorEntityKind.task);
    expect(taskOnly.length, 1);
    expect(taskOnly.single.entityId, 'task-1');

    final scoped = await repo.listByKindAndDateWindow(
      kind: BehaviorEntityKind.goal,
      startDateKey: '2026-05-05',
      endDateKey: '2026-05-06',
    );
    expect(scoped.length, 1);
    expect(scoped.single.entityId, 'goal-1');

    final all = await repo.listAll();
    expect(all.length, 2);
  });

  test('deleteByEntityId removes row', () async {
    final repo = IsarFeatureCacheRepository();
    final now = DateTime(2026, 5, 6).millisecondsSinceEpoch;
    await repo.upsertFeatures([
      _feature(
        id: 'goal-done',
        kind: BehaviorEntityKind.goal,
        computedAtMs: now,
        start: '2026-05-01',
        end: '2026-05-06',
      ),
    ]);
    expect(await repo.getByEntityId('goal-done'), isNotNull);
    await repo.deleteByEntityId('goal-done');
    expect(await repo.getByEntityId('goal-done'), isNull);
    expect(await repo.listAll(), isEmpty);
  });

  test('reads newer schema rows with compatibility fallback', () async {
    final localIsar = isar!;
    await localIsar.writeTxn(() async {
      await localIsar.isarBehaviorFeatureCaches.put(
        IsarBehaviorFeatureCache()
          ..entityId = 'future-row'
          ..entityKind = 'task'
          ..updatedAtMs = 123
          ..payloadJson = jsonEncode({
            'entityId': 'future-row',
            'entityKind': 'task',
            'computedAtMs': 123,
            'schemaVersion': 99,
          })
          ..createdAtMs = 123
          ..schemaVersion = 99,
      );
    });

    final repo = IsarFeatureCacheRepository();
    final out = await repo.getByEntityId('future-row');
    expect(out, isNotNull);
    expect(out!.schemaVersion, kBehaviorFeatureSchemaVersion);
    expect(out.timeMetrics.completionRate7d, 0);
  });
}

BehaviorFeatureObject _feature({
  required String id,
  required BehaviorEntityKind kind,
  required int computedAtMs,
  required String start,
  required String end,
}) {
  return BehaviorFeatureObject(
    entityId: id,
    entityKind: kind,
    timeMetrics: testBehaviorTimeMetrics(
      scheduledOccurrences7d: 7,
      scheduledOccurrences30d: 30,
      completionRate7d: 1,
      completionRate30d: 1,
    ),
    streakMetrics: const BehaviorStreakMetrics(
      currentStreak: 1,
      longestStreak: 1,
      missedLast2Days: false,
      missedCount7d: 0,
    ),
    effortMetrics: const BehaviorEffortMetrics(
      avgSnoozeCount: 0,
      avgSessionDuration: 25,
      plannedVsActualRatio: 1,
    ),
    goalMetrics: const BehaviorGoalMetrics(
      progress: 1,
      expectedProgress: 1,
      gap: 0,
    ),
    contextFeatures: const BehaviorContextFeatures(
      bestTimeBlock: 'morning',
      isHabitAnchor: false,
      priority: 2,
    ),
    computedAtMs: computedAtMs,
    windowStartDateKey: start,
    windowEndDateKey: end,
  );
}
