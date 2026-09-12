import 'day_summary.dart';
import 'duration_format.dart';
import 'timeline_builder.dart';

/// Plain-text rendering of a day's timeline for the AI readers (Coach
/// payload, reflection snapshot). No BuildContext, 24-hour clock, one line
/// per row, newest rows kept when capped. Recorded truth only — the caller's
/// prompt says how to treat it (describe, never judge).
List<String> renderTimelineLines(
  List<TimelineRow> rows, {
  int maxRows = 25,
  DaySummary? summary,
}) {
  final lines = <String>[];
  for (final row in rows) {
    switch (row) {
      case ActivityRow():
        final start = _hhmm(row.event.startedAtMs);
        final end = row.endMs;
        final actual = row.actual;
        final buffer = StringBuffer();
        if (end != null && actual != null) {
          buffer.write('$start–${_hhmm(end)} ${row.event.text} · '
              '${formatActivityDuration(actual)}');
        } else if (row.isOngoing) {
          buffer.write('$start ${row.event.text} · ongoing');
        } else {
          buffer.write('$start ${row.event.text}');
        }
        final intended = row.intended;
        if (intended != null) {
          buffer.write(' (intended ${formatActivityDuration(intended)})');
        }
        if (row.event.isTimerSourced) buffer.write(' [focus timer]');
        lines.add(buffer.toString());
      case UntrackedRow():
        lines.add('? · ${formatActivityDuration(row.length)} untracked');
    }
  }
  final kept = lines.length > maxRows
      ? lines.sublist(lines.length - maxRows)
      : lines;
  final out = [...kept];
  if (summary != null && !summary.isEmpty) {
    final tail = StringBuffer('Logged ${formatActivityDuration(summary.logged)}');
    if (summary.untracked > Duration.zero) {
      tail.write(' · untracked ${formatActivityDuration(summary.untracked)}');
    }
    out.add(tail.toString());
  }
  return out;
}

String _hhmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
