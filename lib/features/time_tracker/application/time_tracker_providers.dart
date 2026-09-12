import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../analytics/application/insight_generation_providers.dart';
import '../../analytics/data/insight_cache_repository.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../reminders/application/attention_orchestrator_providers.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../time_blocks/domain/models/scheduled_time_block.dart';
import '../data/activity_category_rule_repository.dart';
import '../data/activity_event_repository.dart';
import '../domain/models/activity_category_rule.dart';
import '../domain/day_summary.dart';
import '../domain/models/activity_event.dart';
import '../domain/recent_activities.dart';
import '../domain/timeline_builder.dart';
import '../domain/week_periods.dart';
import '../domain/week_summary.dart';
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

/// V1.2 category rules ("every 'gym' is Exercise").
final activityCategoryRuleRepositoryProvider =
    Provider<ActivityCategoryRuleRepository>(
      (ref) => ActivityCategoryRuleRepository(),
    );

final activityCategoryRulesProvider =
    StreamProvider<List<ActivityCategoryRule>>((ref) {
      return ref.watch(activityCategoryRuleRepositoryProvider).watchAll();
    });

/// normalisedText → category, for summaries.
final activityCategoryMapProvider = Provider<Map<String, String>>((ref) {
  final rules =
      ref.watch(activityCategoryRulesProvider).valueOrNull ?? const [];
  return {for (final r in rules) r.normalizedText: r.category};
});

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

/// Day | Week toggle on the Time page (V1.2 decision 7).
enum TimelineMode { day, week }

final timelineModeProvider = StateProvider<TimelineMode>(
  (ref) => TimelineMode.day,
);

/// The ISO week shown in Week view. Defaults to the current week.
final timelineWeekKeyProvider = StateProvider<String>(
  (ref) => WeekPeriods.of(DateTime.now()).key,
);

/// Week key → its period (bounds + day keys).
WeekPeriod weekPeriodForKey(String weekKey) {
  // Walk from the current week until the key matches (keys are ISO, and
  // the pager only moves ±1, so this stays cheap).
  var w = WeekPeriods.of(DateTime.now());
  for (var i = 0; i < 520 && w.key != weekKey; i++) {
    w = w.key.compareTo(weekKey) > 0 ? WeekPeriods.previous(w) : WeekPeriods.next(w);
  }
  return w;
}

/// A week's live events (flat, sorted by start).
final weekEventsProvider = StreamProvider.family<List<ActivityEvent>, String>((
  ref,
  weekKey,
) {
  final w = weekPeriodForKey(weekKey);
  return ref.watch(activityEventRepositoryProvider).watchRange(w.startMs, w.endMs);
});

/// A week's totals, built per day then summed (gap cap never crosses midnight).
final weekSummaryProvider = Provider.family<RangeSummary, String>((ref, weekKey) {
  final events = ref.watch(weekEventsProvider(weekKey)).valueOrNull ?? const [];
  return buildRangeSummary(
    groupEventsByDay(events),
    categoryOf: ref.watch(activityCategoryMapProvider),
  );
});

/// Planned-vs-actual (V1.2 decision 8): the scheduled block for a
/// TIMER-sourced event's task, if any. Manual entries never match.
final plannedBlockForEntityProvider =
    FutureProvider.family<ScheduledTimeBlock?, String>((ref, entityId) {
      if (entityId.isEmpty) return Future.value(null);
      return ref.read(timeBlockRepositoryProvider).getBlockForEntity(entityId);
    });

/// Time observations live in the insight cache under `time:<scope>:<key>`
/// (entity scope). They never appear on Home — the radar reads only the
/// reflection scope.
String timeObservationScopeId(String scope, String key) => 'time:$scope:$key';

final timeObservationProvider = Provider.family<GeneratedInsight?, String>((
  ref,
  scopeId,
) {
  final insights =
      ref.watch(layer3EntityInsightsProvider(scopeId)).valueOrNull ?? const [];
  for (final i in insights) {
    if (i.insightType == InsightType.reflectionObservation) return i;
  }
  return null;
});

/// Dismissing an observation clears its scope — it does not come back.
Future<void> dismissTimeObservation(
  InsightCacheRepository cache,
  String scopeId,
) => cache.replaceScopeInsights(
  scopeType: InsightScopeType.entity,
  scopeId: scopeId,
  insights: const [],
);

/// One day's live events, sorted by start.
final dayEventsProvider = StreamProvider.family<List<ActivityEvent>, String>((
  ref,
  dateKey,
) {
  return ref.watch(activityEventRepositoryProvider).watchDay(dateKey);
});

/// The following day's first event start (V1.1 cross-midnight successor).
final nextDayFirstStartProvider = Provider.family<int?, String>((ref, dateKey) {
  final day = DateKeys.parseLocalDateKey(dateKey);
  final nextKey = DateKeys.yyyymmdd(DateTime(day.year, day.month, day.day + 1));
  final events = ref.watch(dayEventsProvider(nextKey)).valueOrNull ?? const [];
  if (events.isEmpty) return null;
  return events.map((e) => e.startedAtMs).reduce((a, b) => a < b ? a : b);
});

/// The day's timeline rows (activities + untracked gaps).
final timelineRowsProvider = Provider.family<List<TimelineRow>, String>((
  ref,
  dateKey,
) {
  final events = ref.watch(dayEventsProvider(dateKey)).valueOrNull ?? const [];
  return buildTimeline(
    events,
    nextDayFirstStartMs: ref.watch(nextDayFirstStartProvider(dateKey)),
  );
});

/// The day's summary (tail of the Time page).
final daySummaryProvider = Provider.family<DaySummary, String>((ref, dateKey) {
  return buildDaySummary(
    ref.watch(timelineRowsProvider(dateKey)),
    categoryOf: ref.watch(activityCategoryMapProvider),
  );
});

/// Live events from the last 30 days, newest first (chips source).
final recentActivityEventsProvider = StreamProvider<List<ActivityEvent>>((ref) {
  final since = DateTime.now().subtract(kRecentActivityWindow);
  return ref
      .watch(activityEventRepositoryProvider)
      .watchRecentSince(since.millisecondsSinceEpoch);
});

/// Ranked suggestions for the sheet (repeats first, then recency); the
/// sheet filters by what is typed. Unfiltered here.
final recentActivitySuggestionsProvider =
    Provider<List<RecentActivitySuggestion>>((ref) {
      final events =
          ref.watch(recentActivityEventsProvider).valueOrNull ?? const [];
      return recentActivitySuggestions(events, max: 200);
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
