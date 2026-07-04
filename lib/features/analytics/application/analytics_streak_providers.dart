import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../coaching/domain/models/enforcement_mode.dart';
import '../../context_override/application/context_override_providers.dart';
import '../domain/models/analytics_event.dart';
import 'streak_engine.dart';

final habitStreakSummaryProvider = FutureProvider.family<StreakSummary, String>((
  ref,
  habitId,
) async {
  // Rebuild on account switch so cached values never leak across users.
  ref.watch(authUidProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final events = await repo.listEvents(entityId: habitId);
  final habitEvents = events.where((e) {
    if (e.entityKind != 'habit') return false;
    return e.type == AnalyticsEventType.habitCompleted;
  });

  // Resolve per-entity EnforcementMode from the reminder config modeRefId.
  final reminders = await ref.read(reminderRepositoryProvider).getRemindersForTasks([habitId]);
  final modeRefId = reminders.isEmpty ? null : reminders.first.modeRefId;
  final enforcementMode = EnforcementMode.fromModeRefId(modeRefId);

  // Inject vacation state so missed days during vacation don't break streaks.
  final vacationState = ref.read(attentionStateProvider).valueOrNull;
  return computeStreakSummaryWithVacationProtection(
    habitEvents,
    vacationState: vacationState,
    enforcementMode: enforcementMode,
  );
});
