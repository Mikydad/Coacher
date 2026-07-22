import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/features/analytics/application/analytics_streak_providers.dart';
import 'package:sidepal/features/analytics/data/analytics_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnalyticsRepository implements AnalyticsRepository {
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
    return [
      AnalyticsEvent(
        id: '1',
        type: AnalyticsEventType.habitCompleted,
        entityId: entityId ?? 'habit-1',
        entityKind: 'habit',
        dateKey: '2026-05-01',
        timestampLocalIso: '2026-05-01T08:00:00.000',
        sourceSurface: 'home',
        idempotencyKey: 'k1',
        createdAtMs: 1,
        updatedAtMs: 1,
      ),
      AnalyticsEvent(
        id: '2',
        type: AnalyticsEventType.habitCompleted,
        entityId: entityId ?? 'habit-1',
        entityKind: 'habit',
        dateKey: '2026-05-02',
        timestampLocalIso: '2026-05-02T08:00:00.000',
        sourceSurface: 'home',
        idempotencyKey: 'k2',
        createdAtMs: 1,
        updatedAtMs: 1,
      ),
    ];
  }

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async {
    return const [];
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {}
}

class _NoOpReminderRepository implements ReminderRepository {
  @override
  Future<List<ReminderConfig>> listAllReminders() async => const [];
  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async => const [];
  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}
  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

void main() {
  test('habitStreakSummaryProvider computes streak summary for habit id', () async {
    final container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(_FakeAnalyticsRepository()),
        reminderRepositoryProvider.overrideWithValue(_NoOpReminderRepository()),
      ],
    );
    addTearDown(container.dispose);
    final summary = await container.read(habitStreakSummaryProvider('habit-1').future);
    expect(summary.longestStreak, 2);
    expect(summary.completedDateKeys, ['2026-05-01', '2026-05-02']);
  });
}
