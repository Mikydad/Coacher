import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/models/analytics_event.dart';
import 'kpi_engine.dart';
import 'streak_engine.dart';

class HabitFallbackSnapshot {
  const HabitFallbackSnapshot({required this.streak, required this.kpi});

  final StreakSummary streak;
  final HabitKpiSnapshot kpi;
}

final habitTaskFallbackSnapshotProvider =
    FutureProvider.family<HabitFallbackSnapshot, String>((
      ref,
      taskIdsKey,
    ) async {
      final ids = taskIdsKey
          .split('|')
          .where((e) => e.trim().isNotEmpty)
          .toSet();
      if (ids.isEmpty) {
        return HabitFallbackSnapshot(
          streak: computeStreakSummaryForEvents(const []),
          kpi: computeHabitKpisFromEvents(const []),
        );
      }

      final repo = ref.read(analyticsRepositoryProvider);
      final events = await repo.listEvents();
      final completions = events.where((e) {
        if (e.entityKind != 'task') return false;
        if (e.type != AnalyticsEventType.taskCompleted) return false;
        return ids.contains(e.entityId);
      }).toList();

      final dateKeys = <String>{};
      for (final e in completions) {
        dateKeys.add(e.dateKey);
      }

      final synthetic = <AnalyticsEvent>[];
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final key in dateKeys) {
        synthetic.add(
          AnalyticsEvent(
            id: 'habit_fallback_$key',
            type: AnalyticsEventType.habitCompleted,
            entityId: 'habit-fallback',
            entityKind: 'habit',
            dateKey: key,
            timestampLocalIso: '${key}T00:00:00.000',
            sourceSurface: 'fallback',
            idempotencyKey: 'habit_fallback_$key',
            createdAtMs: nowMs,
            updatedAtMs: nowMs,
          ),
        );
      }

      return HabitFallbackSnapshot(
        streak: computeStreakSummaryForEvents(synthetic),
        kpi: computeHabitKpisFromEvents(synthetic),
      );
    });
