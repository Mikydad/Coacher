import 'day_summary.dart';
import 'duration_format.dart';
import 'models/activity_category_rule.dart';
import 'models/activity_event.dart';
import 'timeline_builder.dart';
import 'timeline_text.dart';
import 'week_summary.dart';

/// Synthetic grounding id for observations that rest on aggregates rather
/// than one event (the parser accepts it in `basedOn`).
String activityAggregateId(String scope, String key) => 'activity:$scope:$key';

/// The `activity` block of the reflection snapshot (PRD V1.2 §5 D3).
/// Recorded truth only, compact, capped; the prompt says how to read it.
///
/// [todayEvents] / [last7Days] are live events; [weekBoundary] and
/// [monthBoundary] are passed only on the first reflect after a boundary
/// (the PREVIOUS week / month's events, plus that month's Direction texts
/// from history — never the current period's).
Map<String, dynamic> buildActivitySnapshot({
  required String todayKey,
  required List<ActivityEvent> todayEvents,
  required Map<String, List<ActivityEvent>> last7Days,
  required List<ActivityCategoryRule> rules,
  ({String key, Map<String, List<ActivityEvent>> eventsByDay})? weekBoundary,
  ({
    String key,
    String label,
    Map<String, List<ActivityEvent>> eventsByDay,
    List<String> directionTexts,
  })?
  monthBoundary,
}) {
  final categoryOf = {for (final r in rules) r.normalizedText: r.category};
  final userSet = {
    for (final r in rules)
      if (r.isUserSet) r.normalizedText,
  };

  final todayRows = buildTimeline(todayEvents);
  final todaySummary = buildDaySummary(todayRows, categoryOf: categoryOf);
  final today = <Map<String, dynamic>>[
    for (final row in todayRows)
      if (row is ActivityRow)
        {
          'id': row.event.id,
          'text': row.event.text,
          'start': _hhmm(row.event.startedAtMs),
          'minutes': row.actual?.inMinutes,
          if (row.event.intendedMinutes != null)
            'intendedMinutes': row.event.intendedMinutes,
          'source': row.event.source.name,
          if (categoryOf[row.event.normalizedText] != null)
            'category': categoryOf[row.event.normalizedText],
        },
  ];

  Map<String, dynamic> aggregate(
    Map<String, List<ActivityEvent>> byDay, {
    int maxActivities = 10,
  }) {
    final s = buildRangeSummary(byDay, categoryOf: categoryOf, maxLines: maxActivities);
    final bands = <String, int>{'morning': 0, 'afternoon': 0, 'evening': 0, 'night': 0};
    for (final events in byDay.values) {
      for (final row in buildTimeline(events)) {
        if (row is! ActivityRow) continue;
        final actual = row.actual;
        if (actual == null) continue;
        final h = DateTime.fromMillisecondsSinceEpoch(row.event.startedAtMs).hour;
        final band = h < 6
            ? 'night'
            : h < 12
            ? 'morning'
            : h < 18
            ? 'afternoon'
            : h < 22
            ? 'evening'
            : 'night';
        bands[band] = bands[band]! + actual.inMinutes;
      }
    }
    return {
      'loggedMinutes': s.logged.inMinutes,
      'untrackedMinutes': s.untracked.inMinutes,
      'daysWithEntries': s.daysWithEntries,
      'byActivity': [
        for (final l in s.lines) {'text': l.label, 'minutes': l.total.inMinutes},
      ],
      if (s.hasCategories)
        'byCategory': {
          for (final l in s.categoryLines) l.label: l.total.inMinutes,
        },
      'byHourBandMinutes': bands,
    };
  }

  // Distinct texts (last 7 days) with no rule at all — never ones the user
  // set, so an override is never re-proposed.
  final uncategorized = <String>[];
  final seen = <String>{};
  final allRecent = [for (final l in last7Days.values) ...l, ...todayEvents];
  allRecent.sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
  for (final e in allRecent) {
    if (!e.active) continue;
    final k = e.normalizedText;
    if (k.isEmpty || seen.contains(k)) continue;
    seen.add(k);
    if (categoryOf.containsKey(k) || userSet.contains(k)) continue;
    uncategorized.add(e.text.trim());
    if (uncategorized.length >= 20) break;
  }

  return {
    'todayKey': todayKey,
    'today': today,
    'todayLogged': formatActivityDuration(todaySummary.logged),
    'todayUntracked': formatActivityDuration(todaySummary.untracked),
    'todayId': activityAggregateId('day', todayKey),
    'last7Days': {
      'id': activityAggregateId('week', 'last7'),
      ...aggregate(last7Days),
    },
    if (weekBoundary != null)
      'weekBoundary': {
        'id': activityAggregateId('week', weekBoundary.key),
        'week': weekBoundary.key,
        ...aggregate(weekBoundary.eventsByDay),
      },
    if (monthBoundary != null)
      'monthBoundary': {
        'id': activityAggregateId('month', monthBoundary.key),
        'month': monthBoundary.label,
        if (monthBoundary.directionTexts.isNotEmpty)
          'direction': monthBoundary.directionTexts,
        ...aggregate(monthBoundary.eventsByDay, maxActivities: 12),
      },
    if (uncategorized.isNotEmpty) 'uncategorizedTexts': uncategorized,
    'categories': ActivityCategories.all,
  };
}

/// Every id the parser may accept in `basedOn` for time observations.
Set<String> activitySnapshotIds(Map<String, dynamic> activity) {
  final ids = <String>{};
  for (final row in (activity['today'] as List? ?? const [])) {
    if (row is Map && row['id'] is String) ids.add(row['id'] as String);
  }
  for (final k in ['todayId']) {
    if (activity[k] is String) ids.add(activity[k] as String);
  }
  for (final k in ['last7Days', 'weekBoundary', 'monthBoundary']) {
    final block = activity[k];
    if (block is Map && block['id'] is String) ids.add(block['id'] as String);
  }
  return ids;
}

/// Durable inputs for the reflection hash: ids + stamps only.
List<String> activityHashParts(
  List<ActivityEvent> events,
  List<ActivityCategoryRule> rules,
) => [
  for (final e in events) 'a:${e.id}:${e.updatedAtMs}',
  for (final r in rules) 'c:${r.id}:${r.updatedAtMs}',
];

String _hhmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Keep the text renderer referenced for callers that want the plain-text
/// form of today's rows in prompts.
List<String> todayTimelineText(List<ActivityEvent> todayEvents) =>
    renderTimelineLines(buildTimeline(todayEvents));
