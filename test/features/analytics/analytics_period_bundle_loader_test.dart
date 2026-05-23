import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/analytics/application/analytics_period_bundle_loader.dart';
import 'package:coach_for_life/features/analytics/application/daily_analytics_engine.dart';
import 'package:coach_for_life/features/analytics/data/analytics_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryAnalyticsRepository implements AnalyticsRepository {
  _InMemoryAnalyticsRepository(this.stats);

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
  }) async =>
      const [];

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async {
    return stats.where((s) {
      if (scopeType != null && s.scopeType != scopeType) return false;
      if (scopeId != null && s.scopeId != scopeId) return false;
      if (dateKey != null && s.dateKey != dateKey) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {}
}

void main() {
  test('loadCachedAnalyticsPeriodBundle returns null without today caches', () async {
    final container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(
          _InMemoryAnalyticsRepository(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final bundle = await container.read(
      Provider((ref) => loadCachedAnalyticsPeriodBundle(ref)),
    );
    expect(bundle, isNull);
  });

  test('loadCachedAnalyticsPeriodBundle returns bundle when today is cached', () async {
    final todayKey = DateKeys.todayKey();

    AnalyticsStatsCache cacheFor(String scope) {
      final snap = DailyAnalyticsSnapshot(
        dateKey: todayKey,
        createdCount: 2,
        completedCount: 1,
        weightedCreated: 2,
        weightedCompleted: 1,
        completionRate: 0.5,
        weightedCompletionRate: 0.5,
        schemaVersion: 2,
      );
      return AnalyticsStatsCache(
        id: 'analytics::$scope::$todayKey',
        scopeType: scope,
        scopeId: 'global',
        dateKey: todayKey,
        payload: snap.toPayload(),
        createdAtMs: 0,
        updatedAtMs: 0,
        schemaVersion: 2,
      );
    }

    final container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(
          _InMemoryAnalyticsRepository([
            cacheFor(goalHabitDailyScope),
            cacheFor(taskDailyScope),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final bundle = await container.read(
      Provider((ref) => loadCachedAnalyticsPeriodBundle(ref)),
    );
    expect(bundle, isNotNull);
    expect(bundle!.goalHabitDay.dateKey, todayKey);
    expect(bundle.taskDay.dateKey, todayKey);
  });
}
