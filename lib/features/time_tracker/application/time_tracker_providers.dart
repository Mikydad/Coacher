import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../reminders/application/attention_orchestrator_providers.dart';
import '../data/activity_event_repository.dart';
import '../domain/day_summary.dart';
import '../domain/models/activity_event.dart';
import '../domain/recent_activities.dart';
import '../domain/timeline_builder.dart';
import 'activity_reminder_service.dart';
import 'time_tracker_actions.dart';

/// Time Tracker providers. Everything derives from Isar watch streams;
/// the local write IS the update (no invalidate-and-refetch).
///
/// SidePal doesn't track your time for you. It makes it effortless for you
/// to record your time, then helps you see what you actually did with it.

final activityEventRepositoryProvider = Provider<ActivityEventRepository>(
  (ref) => ActivityEventRepository(),
);

/// Intended-duration reminders ride the attention orchestrator (decision 13).
final activityReminderServiceProvider = Provider<ActivityReminderService>((
  ref,
) {
  final orchestrator = ref.read(attentionOrchestratorServiceProvider);
  return ActivityReminderService(
    evaluate: (intent) => orchestrator.evaluate(intent),
    cancel: (entityId) => orchestrator.cancelForEntity(entityId, slotCount: 1),
  );
});

/// Write-side use cases for the sheet and the page.
final timeTrackerActionsProvider = Provider<TimeTrackerActions>(
  (ref) => TimeTrackerActions(
    repository: ref.read(activityEventRepositoryProvider),
    reminders: ref.read(activityReminderServiceProvider),
  ),
);

/// The day shown on the Time page. Defaults to today; the page resets it
/// on open. Per-user UI state → registered in `invalidateUserScopedProviders`.
final timelineDayKeyProvider = StateProvider<String>(
  (ref) => DateKeys.todayKey(),
);

/// One day's live events, sorted by start.
final dayEventsProvider = StreamProvider.family<List<ActivityEvent>, String>((
  ref,
  dateKey,
) {
  return ref.watch(activityEventRepositoryProvider).watchDay(dateKey);
});

/// The day's timeline rows (activities + untracked gaps).
final timelineRowsProvider = Provider.family<List<TimelineRow>, String>((
  ref,
  dateKey,
) {
  final events = ref.watch(dayEventsProvider(dateKey)).valueOrNull ?? const [];
  return buildTimeline(events);
});

/// The day's summary (tail of the Time page).
final daySummaryProvider = Provider.family<DaySummary, String>((ref, dateKey) {
  return buildDaySummary(ref.watch(timelineRowsProvider(dateKey)));
});

/// Live events from the last 30 days, newest first (chips source).
final recentActivityEventsProvider = StreamProvider<List<ActivityEvent>>((ref) {
  final since = DateTime.now().subtract(kRecentActivityWindow);
  return ref
      .watch(activityEventRepositoryProvider)
      .watchRecentSince(since.millisecondsSinceEpoch);
});

/// The user's own recent distinct activities for the capture sheet.
final recentActivityChipsProvider = Provider<List<String>>((ref) {
  final events =
      ref.watch(recentActivityEventsProvider).valueOrNull ?? const [];
  return recentActivityChips(events);
});

/// The most recently started live event, any day.
final latestActivityEventProvider = StreamProvider<ActivityEvent?>((ref) {
  return ref.watch(activityEventRepositoryProvider).watchLatest();
});

/// What the user is doing "now" for the Home pill: the latest event when
/// it has no explicit end and started within the gap cap. Older than that
/// the pill goes back to its neutral copy — the timeline still says
/// "Ongoing" (decision 3); the pill just shouldn't claim "since 10:03 PM"
/// at noon the next day.
final ongoingActivityProvider = Provider<ActivityEvent?>((ref) {
  final latest = ref.watch(latestActivityEventProvider).valueOrNull;
  if (latest == null || latest.hasExplicitEnd) return null;
  final age = DateTime.now().millisecondsSinceEpoch - latest.startedAtMs;
  if (age > kActivityGapCap.inMilliseconds) return null;
  return latest;
});
