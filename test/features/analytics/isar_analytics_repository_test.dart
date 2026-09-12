import 'dart:io';

import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/analytics/data/analytics_range_reads.dart';
import 'package:sidepal/features/analytics/data/analytics_repository.dart';
import 'package:sidepal/features/analytics/data/isar_analytics_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

class _MemoryRemoteAnalyticsRepository implements AnalyticsRepository {
  _MemoryRemoteAnalyticsRepository({
    this.events = const [],
    this.stats = const [],
  });

  final List<AnalyticsEvent> events;
  final List<AnalyticsStatsCache> stats;

  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {}

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {}

  @override
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  }) async {
    return events;
  }

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async {
    return stats;
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {}
}

AnalyticsEvent _event({
  required String id,
  required String key,
  required int updatedAtMs,
}) {
  return AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.habitCompleted,
    entityId: 'habit-1',
    entityKind: 'habit',
    dateKey: '2026-05-02',
    timestampLocalIso: '2026-05-02T07:30:00.000',
    sourceSurface: 'home',
    idempotencyKey: key,
    createdAtMs: 1,
    updatedAtMs: updatedAtMs,
  );
}

void main() {
  Isar? isar;
  Directory? dir;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    SyncService.debugSkipQueuePersistenceForTests = true;
    SyncService.instance.debugResetQueueInMemoryOnly();
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    SyncService.debugSkipQueuePersistenceForTests = false;
    SyncService.instance.debugResetQueueInMemoryOnly();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('logEvent dedupes by idempotency key and keeps newer', () async {
    final repo = IsarAnalyticsRepository(_MemoryRemoteAnalyticsRepository());
    await repo.logEvent(_event(id: 'evt-1', key: 'dup-key', updatedAtMs: 10));
    await repo.logEvent(_event(id: 'evt-2', key: 'dup-key', updatedAtMs: 5));
    await repo.logEvent(_event(id: 'evt-3', key: 'dup-key', updatedAtMs: 50));
    final all = await repo.listEvents();
    expect(all.length, 1);
    expect(all.single.id, 'evt-3');
    expect(all.single.updatedAtMs, 50);
  });

  test('hydrateRemoteStatsCache merges by updatedAtMs', () async {
    final repo = IsarAnalyticsRepository(
      _MemoryRemoteAnalyticsRepository(
        stats: [
          const AnalyticsStatsCache(
            id: 'stats-habit-1',
            scopeType: 'habit',
            scopeId: 'habit-1',
            dateKey: '2026-05-02',
            payload: {'currentStreak': 4},
            createdAtMs: 1,
            updatedAtMs: 100,
            schemaVersion: 1,
          ),
        ],
      ),
    );
    await repo.upsertStatsCache(
      const AnalyticsStatsCache(
        id: 'stats-habit-1',
        scopeType: 'habit',
        scopeId: 'habit-1',
        dateKey: '2026-05-02',
        payload: {'currentStreak': 2},
        createdAtMs: 1,
        updatedAtMs: 50,
        schemaVersion: 1,
      ),
    );
    await repo.hydrateRemoteStatsCache();
    final all = await repo.listStatsCache(scopeId: 'habit-1');
    expect(all.length, 1);
    expect(all.single.updatedAtMs, 100);
    expect(all.single.payload['currentStreak'], 4);
  });

  test('hydrateRemoteEvents merges by updatedAtMs', () async {
    final repo = IsarAnalyticsRepository(
      _MemoryRemoteAnalyticsRepository(
        events: [
          _event(id: 'evt-remote', key: 'remote-key', updatedAtMs: 100),
        ],
      ),
    );
    await repo.logEvent(_event(id: 'evt-local', key: 'remote-key', updatedAtMs: 50));
    await repo.hydrateRemoteEvents();
    final all = await repo.listEvents();
    expect(all.length, 1);
    expect(all.single.id, 'evt-remote');
    expect(all.single.updatedAtMs, 100);
  });

  AnalyticsStatsCache _daily(String scope, String dateKey, {String scopeId = 'global'}) {
    return AnalyticsStatsCache(
      id: 'analytics::$scope::$dateKey::$scopeId',
      scopeType: scope,
      scopeId: scopeId,
      dateKey: dateKey,
      payload: const {'createdCount': 1},
      createdAtMs: 1,
      updatedAtMs: 1,
      schemaVersion: 3,
    );
  }

  test('listStatsCacheRange honours bounds, scope and global scope id', () async {
    final repo = IsarAnalyticsRepository(_MemoryRemoteAnalyticsRepository());
    for (final k in ['2026-08-31', '2026-09-01', '2026-09-15', '2026-09-30', '2026-10-01']) {
      await repo.upsertStatsCache(_daily('goal_habit_daily', k));
      await repo.upsertStatsCache(_daily('task_daily', k));
    }
    await repo.upsertStatsCache(_daily('goal_habit_daily', '2026-09-10', scopeId: 'habit-1'));

    final rows = await readStatsCacheRange(
      repo,
      scopeType: 'goal_habit_daily',
      fromDateKey: '2026-09-01',
      toDateKey: '2026-09-30',
    );
    expect(rows.map((r) => r.dateKey).toList()..sort(), [
      '2026-09-01',
      '2026-09-15',
      '2026-09-30',
    ]);
    expect(rows.every((r) => r.scopeType == 'goal_habit_daily'), isTrue);
    expect(rows.every((r) => r.scopeId == 'global'), isTrue);

    expect(await readEarliestStatsDateKey(repo, scopeType: 'task_daily'), '2026-08-31');
    expect(await readEarliestStatsDateKey(repo, scopeType: 'nothing'), isNull);
  });

  test('readStatsCacheRange falls back to listStatsCache for other repositories', () async {
    final remote = _MemoryRemoteAnalyticsRepository(
      stats: [
        _daily('task_daily', '2026-09-01'),
        _daily('task_daily', '2026-09-20'),
        _daily('task_daily', '2026-10-01'),
      ],
    );
    final rows = await readStatsCacheRange(
      remote,
      scopeType: 'task_daily',
      fromDateKey: '2026-09-01',
      toDateKey: '2026-09-30',
    );
    expect(rows.map((r) => r.dateKey).toList(), ['2026-09-01', '2026-09-20']);
    expect(await readEarliestStatsDateKey(remote, scopeType: 'task_daily'), '2026-09-01');
  });
}
