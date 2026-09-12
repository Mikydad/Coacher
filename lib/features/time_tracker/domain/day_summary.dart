import 'models/activity_category_rule.dart';
import 'models/activity_event.dart';
import 'timeline_builder.dart';

/// Per-day totals for the tail of the Time page (decision 16). V1 groups
/// by activity text because categories are still empty; the shape is the
/// same once a category exists.
///
/// Only KNOWN durations count: ongoing and capped rows contribute nothing,
/// and untracked time is reported separately, never inside "logged".
class SummaryLine {
  const SummaryLine({required this.label, required this.total});

  /// Most recent spelling the user used for this activity.
  final String label;
  final Duration total;
}

class DaySummary {
  const DaySummary({
    required this.logged,
    required this.untracked,
    required this.lines,
    this.categoryLines = const [],
  });

  static const empty = DaySummary(
    logged: Duration.zero,
    untracked: Duration.zero,
    lines: [],
  );

  final Duration logged;
  final Duration untracked;

  /// Descending by total; at most `maxLines` + an "Other" line.
  final List<SummaryLine> lines;

  /// V1.2: totals per category (labels from [ActivityCategories]) when at
  /// least one activity that day has a rule; texts without a rule land in
  /// "Other". Empty when nothing is categorised.
  final List<SummaryLine> categoryLines;

  bool get hasCategories => categoryLines.isNotEmpty;

  bool get isEmpty => logged == Duration.zero && untracked == Duration.zero;
}

const String kSummaryOtherLabel = 'Other';

DaySummary buildDaySummary(
  List<TimelineRow> rows, {
  int maxLines = 6,

  /// normalisedText → category (from the rules). Empty = no category block.
  Map<String, String> categoryOf = const {},
}) {
  var logged = Duration.zero;
  var untracked = Duration.zero;
  final totals = <String, Duration>{};
  final categoryTotals = <String, Duration>{};
  var anyCategorised = false;
  final labels = <String, ({String label, int at})>{};

  for (final row in rows) {
    switch (row) {
      case UntrackedRow():
        untracked += row.length;
      case ActivityRow():
        final actual = row.actual;
        if (actual == null) continue;
        logged += actual;
        final key = row.event.normalizedText;
        totals[key] = (totals[key] ?? Duration.zero) + actual;
        final cat = categoryOf[key];
        if (cat != null) anyCategorised = true;
        final bucket = cat ?? ActivityCategories.other;
        categoryTotals[bucket] = (categoryTotals[bucket] ?? Duration.zero) + actual;
        final seen = labels[key];
        if (seen == null || row.event.startedAtMs > seen.at) {
          labels[key] = (label: row.event.text.trim(), at: row.event.startedAtMs);
        }
    }
  }

  final ordered = totals.entries.toList()
    ..sort((a, b) {
      final byTotal = b.value.compareTo(a.value);
      if (byTotal != 0) return byTotal;
      return a.key.compareTo(b.key);
    });

  final lines = <SummaryLine>[];
  var other = Duration.zero;
  for (var i = 0; i < ordered.length; i++) {
    final entry = ordered[i];
    if (i < maxLines) {
      lines.add(SummaryLine(label: labels[entry.key]!.label, total: entry.value));
    } else {
      other += entry.value;
    }
  }
  if (other > Duration.zero) {
    lines.add(SummaryLine(label: kSummaryOtherLabel, total: other));
  }

  final categoryLines = <SummaryLine>[];
  if (anyCategorised) {
    final ordered = categoryTotals.entries.toList()
      ..sort((a, b) {
        // "Other" always last; the rest by total desc, then name.
        if (a.key == ActivityCategories.other) return 1;
        if (b.key == ActivityCategories.other) return -1;
        final byTotal = b.value.compareTo(a.value);
        return byTotal != 0 ? byTotal : a.key.compareTo(b.key);
      });
    for (final e in ordered) {
      categoryLines.add(
        SummaryLine(label: ActivityCategories.label(e.key), total: e.value),
      );
    }
  }

  return DaySummary(
    logged: logged,
    untracked: untracked,
    lines: lines,
    categoryLines: categoryLines,
  );
}

/// Convenience for callers holding events rather than rows.
DaySummary summarizeDay(
  List<ActivityEvent> events, {
  int maxLines = 6,
  Map<String, String> categoryOf = const {},
}) => buildDaySummary(
  buildTimeline(events),
  maxLines: maxLines,
  categoryOf: categoryOf,
);
