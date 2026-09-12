import 'day_summary.dart';
import 'models/activity_category_rule.dart';
import 'models/activity_event.dart';
import 'timeline_builder.dart';

/// Totals over several days. Built by summarising EACH DAY separately and
/// summing — the 2-hour gap cap never runs across midnight (bug trap 4).
class RangeSummary {
  const RangeSummary({
    required this.logged,
    required this.untracked,
    required this.daysWithEntries,
    required this.lines,
    required this.categoryLines,
  });

  static const empty = RangeSummary(
    logged: Duration.zero,
    untracked: Duration.zero,
    daysWithEntries: 0,
    lines: [],
    categoryLines: [],
  );

  final Duration logged;
  final Duration untracked;
  final int daysWithEntries;

  /// By activity, descending, top `maxLines` + Other.
  final List<SummaryLine> lines;

  /// By category (labels), Other last; empty when nothing is categorised.
  final List<SummaryLine> categoryLines;

  bool get isEmpty => logged == Duration.zero && untracked == Duration.zero;
  bool get hasCategories => categoryLines.isNotEmpty;
}

/// [eventsByDay]: dateKey → that day's events (any order, tombstones ok).
RangeSummary buildRangeSummary(
  Map<String, List<ActivityEvent>> eventsByDay, {
  Map<String, String> categoryOf = const {},
  int maxLines = 8,
}) {
  var logged = Duration.zero;
  var untracked = Duration.zero;
  var days = 0;
  final byText = <String, Duration>{};
  final labelFor = <String, String>{};
  final byCategory = <String, Duration>{};
  var anyCategorised = false;

  for (final entry in eventsByDay.entries) {
    final live = entry.value.where((e) => e.active).toList();
    if (live.isEmpty) continue;
    days++;
    final rows = buildTimeline(live);
    for (final row in rows) {
      switch (row) {
        case UntrackedRow():
          untracked += row.length;
        case ActivityRow():
          final actual = row.actual;
          if (actual == null) continue;
          logged += actual;
          final key = row.event.normalizedText;
          byText[key] = (byText[key] ?? Duration.zero) + actual;
          labelFor.putIfAbsent(key, () => row.event.text.trim());
          final cat = categoryOf[key];
          if (cat != null) anyCategorised = true;
          final bucket = cat ?? ActivityCategories.other;
          byCategory[bucket] = (byCategory[bucket] ?? Duration.zero) + actual;
      }
    }
  }

  final ordered = byText.entries.toList()
    ..sort((a, b) {
      final t = b.value.compareTo(a.value);
      return t != 0 ? t : a.key.compareTo(b.key);
    });
  final lines = <SummaryLine>[];
  var other = Duration.zero;
  for (var i = 0; i < ordered.length; i++) {
    if (i < maxLines) {
      lines.add(SummaryLine(label: labelFor[ordered[i].key]!, total: ordered[i].value));
    } else {
      other += ordered[i].value;
    }
  }
  if (other > Duration.zero) {
    lines.add(SummaryLine(label: kSummaryOtherLabel, total: other));
  }

  final categoryLines = <SummaryLine>[];
  if (anyCategorised) {
    final cats = byCategory.entries.toList()
      ..sort((a, b) {
        if (a.key == ActivityCategories.other) return 1;
        if (b.key == ActivityCategories.other) return -1;
        final t = b.value.compareTo(a.value);
        return t != 0 ? t : a.key.compareTo(b.key);
      });
    for (final c in cats) {
      categoryLines.add(
        SummaryLine(label: ActivityCategories.label(c.key), total: c.value),
      );
    }
  }

  return RangeSummary(
    logged: logged,
    untracked: untracked,
    daysWithEntries: days,
    lines: lines,
    categoryLines: categoryLines,
  );
}

/// Group a flat list by local dateKey.
Map<String, List<ActivityEvent>> groupEventsByDay(List<ActivityEvent> events) {
  final out = <String, List<ActivityEvent>>{};
  for (final e in events) {
    (out[e.dateKey] ??= []).add(e);
  }
  return out;
}
