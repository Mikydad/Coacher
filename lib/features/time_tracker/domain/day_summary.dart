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

  bool get isEmpty => logged == Duration.zero && untracked == Duration.zero;
}

const String kSummaryOtherLabel = 'Other';

DaySummary buildDaySummary(List<TimelineRow> rows, {int maxLines = 6}) {
  var logged = Duration.zero;
  var untracked = Duration.zero;
  final totals = <String, Duration>{};
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

  return DaySummary(logged: logged, untracked: untracked, lines: lines);
}

/// Convenience for callers holding events rather than rows.
DaySummary summarizeDay(List<ActivityEvent> events, {int maxLines = 6}) =>
    buildDaySummary(buildTimeline(events), maxLines: maxLines);
