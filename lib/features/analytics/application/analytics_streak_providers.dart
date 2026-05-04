import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/models/analytics_event.dart';
import 'streak_engine.dart';

final habitStreakSummaryProvider = FutureProvider.family<StreakSummary, String>((
  ref,
  habitId,
) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final events = await repo.listEvents(entityId: habitId);
  final habitEvents = events.where((e) {
    if (e.entityKind != 'habit') return false;
    return e.type == AnalyticsEventType.habitCompleted;
  });
  return computeStreakSummaryForEvents(habitEvents);
});
