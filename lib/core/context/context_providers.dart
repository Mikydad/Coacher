import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/context_override/application/context_override_providers.dart';
import '../../features/context_override/application/sleep_window_util.dart';
import '../../features/context_override/domain/models/context_override.dart';
import '../../features/intentions/application/intention_nudge_sync_service.dart';
import '../../features/planning/application/planned_task_collect.dart';
import '../di/providers.dart';
import '../utils/date_keys.dart';
import 'activity_signal.dart';
import 'calendar_signal.dart';
import 'context_snapshot_service.dart';

/// Riverpod wiring for the Context Engine (humanizing Phase 4b, PRD §9).
/// The services themselves are plugin-/framework-free; this file is the
/// only place that binds them to repositories and platform channels.

final calendarSignalServiceProvider = Provider<CalendarSignalService>(
  (ref) => CalendarSignalService(),
);

/// The user's remembered calendar decision — UI reads this to decide
/// whether the one-time ask card or the Profile toggle state shows.
/// Invalidate after [CalendarSignalService.enable]/[decline].
final calendarSignalChoiceProvider = FutureProvider<CalendarSignalChoice>(
  (ref) => ref.watch(calendarSignalServiceProvider).getChoice(),
);

final activitySignalServiceProvider = Provider<ActivitySignalService>(
  (ref) => ActivitySignalService(),
);

/// The user's remembered motion decision (Tier 2, Phase 6a) — same
/// tri-state contract as the calendar choice above.
final activitySignalChoiceProvider = FutureProvider<ActivitySignalChoice>(
  (ref) => ref.watch(activitySignalServiceProvider).getChoice(),
);

final contextSnapshotServiceProvider = Provider<ContextSnapshotService>((ref) {
  return ContextSnapshotService(
    scheduleMapsForDay: (day) async {
      final rows = await collectTasksForDateKey(
        ref.read(planningRepositoryProvider),
        DateKeys.yyyymmdd(day),
      );
      return scheduleMapsFromPlannedRows(rows);
    },
    overrideMode: () async {
      final state = await ref
          .read(contextOverrideRepositoryProvider)
          .getAttentionState();
      if (state == null) return null;
      final override = effectiveOverride(state, DateTime.now());
      return override == ContextOverride.none ? null : override.name;
    },
    isOnline: () async {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    },
    calendarSignal: ref.read(calendarSignalServiceProvider),
    activitySignal: ref.read(activitySignalServiceProvider),
  );
});
