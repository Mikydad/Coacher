import 'dart:convert';

import '../../../core/utils/date_keys.dart';
import 'day_summary.dart';
import 'duration_format.dart';
import 'models/activity_category_rule.dart';
import 'models/activity_event.dart';
import 'timeline_builder.dart';
import 'week_periods.dart';

/// Export of the user's own time log (Day / Week / Month) as a file they
/// can hand to another AI, a spreadsheet, or their notes. Pure Dart: the
/// caller fetches events, this file resolves the period, builds each day's
/// timeline with the same rules as the Time page, and renders.
///
/// Two formats, one truth: Markdown reads best pasted into a chat; JSON
/// suits apps. Both carry the same "how to read durations" note so a
/// reader never mistakes an inferred end for a recorded one. Internal ids
/// and sync metadata are never exported.
///
/// SidePal doesn't track your time for you. It makes it effortless for you
/// to record your time, then helps you see what you actually did with it.

enum TimeExportScope { day, week, month }

enum TimeExportFormat { markdown, json }

extension TimeExportFormatX on TimeExportFormat {
  String get extension => switch (this) {
    TimeExportFormat.markdown => 'md',
    TimeExportFormat.json => 'json',
  };

  String get mimeType => switch (this) {
    TimeExportFormat.markdown => 'text/markdown',
    TimeExportFormat.json => 'application/json',
  };
}

/// The local calendar span being exported.
class TimeExportPeriod {
  const TimeExportPeriod({
    required this.scope,
    required this.key,
    required this.startMs,
    required this.endMs,
    required this.dayKeys,
  });

  /// [anchor] is the day the user is looking at; the scope widens around it.
  factory TimeExportPeriod.around(TimeExportScope scope, DateTime anchor) {
    switch (scope) {
      case TimeExportScope.day:
        final day = DateTime(anchor.year, anchor.month, anchor.day);
        final next = DateTime(day.year, day.month, day.day + 1);
        return TimeExportPeriod(
          scope: scope,
          key: DateKeys.yyyymmdd(day),
          startMs: day.millisecondsSinceEpoch,
          endMs: next.millisecondsSinceEpoch,
          dayKeys: [DateKeys.yyyymmdd(day)],
        );
      case TimeExportScope.week:
        final w = WeekPeriods.of(anchor);
        return TimeExportPeriod(
          scope: scope,
          key: w.key,
          startMs: w.startMs,
          endMs: w.endMs,
          dayKeys: w.dayKeys,
        );
      case TimeExportScope.month:
        final m = WeekPeriods.monthOf(anchor);
        final first = DateTime.fromMillisecondsSinceEpoch(m.startMs);
        final count = DateTime(first.year, first.month + 1, 0).day;
        return TimeExportPeriod(
          scope: scope,
          key: m.key,
          startMs: m.startMs,
          endMs: m.endMs,
          dayKeys: [
            for (var i = 0; i < count; i++)
              DateKeys.yyyymmdd(DateTime(first.year, first.month, 1 + i)),
          ],
        );
    }
  }

  final TimeExportScope scope;

  /// `2026-09-08` / `2026-W37` / `2026-09` — also the file-name suffix.
  final String key;
  final int startMs;

  /// Exclusive.
  final int endMs;
  final List<String> dayKeys;

  DateTime get start => DateTime.fromMillisecondsSinceEpoch(startMs);
  DateTime get lastDay => DateKeys.parseLocalDateKey(dayKeys.last);

  /// Local midnight after the period — one extra day is fetched so the
  /// last day's open entry can be ended by the next morning's first log,
  /// exactly as the Day view does (V1.1 successor rule).
  int get fetchEndMs {
    final last = lastDay;
    return DateTime(last.year, last.month, last.day + 2).millisecondsSinceEpoch;
  }

  String get fileStem => 'sidepal_time_$key';

  /// Human label: `Monday, September 8, 2026` / `Sep 8 – Sep 14, 2026` /
  /// `September 2026`. No BuildContext, so month names are fixed English
  /// like the rest of the Time page copy.
  String get label => switch (scope) {
    TimeExportScope.day => '${_weekdayName(start)}, ${_longDate(start)}',
    TimeExportScope.week =>
      '${_shortDate(start)} – ${_shortDate(lastDay)}, ${lastDay.year}',
    TimeExportScope.month => '${_monthName(start.month)} ${start.year}',
  };
}

/// One exported day: the timeline rows and their summary.
class TimeExportDay {
  const TimeExportDay({
    required this.dateKey,
    required this.rows,
    required this.summary,
  });

  final String dateKey;
  final List<TimelineRow> rows;
  final DaySummary summary;

  bool get isEmpty => rows.isEmpty;
}

class TimeExport {
  const TimeExport({
    required this.period,
    required this.days,
    required this.exportedAt,
    required this.categoryOf,
  });

  final TimeExportPeriod period;

  /// One per [TimeExportPeriod.dayKeys], in order, empty days included.
  final List<TimeExportDay> days;
  final DateTime exportedAt;

  /// normalisedText → category (the rules at export time).
  final Map<String, String> categoryOf;

  int get daysWithEntries => days.where((d) => !d.isEmpty).length;

  Duration get logged =>
      days.fold(Duration.zero, (a, d) => a + d.summary.logged);

  Duration get untracked =>
      days.fold(Duration.zero, (a, d) => a + d.summary.untracked);

  bool get isEmpty => daysWithEntries == 0;

  /// Totals per category, descending, "Other" last. Empty when no rule
  /// applies to anything in the period.
  List<SummaryLine> get byCategory {
    final totals = <String, Duration>{};
    var any = false;
    for (final d in days) {
      for (final row in d.rows) {
        if (row is! ActivityRow) continue;
        final actual = row.actual;
        if (actual == null) continue;
        final cat = categoryOf[row.event.normalizedText];
        if (cat != null) any = true;
        final bucket = cat ?? ActivityCategories.other;
        totals[bucket] = (totals[bucket] ?? Duration.zero) + actual;
      }
    }
    if (!any) return const [];
    final ordered = totals.entries.toList()
      ..sort((a, b) {
        if (a.key == ActivityCategories.other) return 1;
        if (b.key == ActivityCategories.other) return -1;
        final t = b.value.compareTo(a.value);
        return t != 0 ? t : a.key.compareTo(b.key);
      });
    return [
      for (final e in ordered)
        SummaryLine(label: ActivityCategories.label(e.key), total: e.value),
    ];
  }

  /// Totals per activity, descending — every activity, nothing folded
  /// into "Other" (an export should not hide the long tail).
  List<SummaryLine> get byActivity {
    final totals = <String, Duration>{};
    final labels = <String, ({String label, int at})>{};
    for (final d in days) {
      for (final row in d.rows) {
        if (row is! ActivityRow) continue;
        final actual = row.actual;
        if (actual == null) continue;
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
        final t = b.value.compareTo(a.value);
        return t != 0 ? t : a.key.compareTo(b.key);
      });
    return [
      for (final e in ordered)
        SummaryLine(label: labels[e.key]!.label, total: e.value),
    ];
  }
}

/// [events]: live events from `period.startMs` up to `period.fetchEndMs`
/// (the day after the period is used only as the successor of the last
/// day). Tombstones and out-of-range events are ignored.
TimeExport buildTimeExport(
  TimeExportPeriod period,
  List<ActivityEvent> events, {
  required DateTime exportedAt,
  Map<String, String> categoryOf = const {},
}) {
  final byDay = <String, List<ActivityEvent>>{};
  for (final e in events) {
    if (!e.active) continue;
    (byDay[e.dateKey] ??= []).add(e);
  }
  final days = <TimeExportDay>[];
  for (final key in period.dayKeys) {
    final day = DateKeys.parseLocalDateKey(key);
    final nextKey = DateKeys.yyyymmdd(
      DateTime(day.year, day.month, day.day + 1),
    );
    final next = byDay[nextKey];
    int? successor;
    if (next != null && next.isNotEmpty) {
      successor = next.map((e) => e.startedAtMs).reduce((a, b) => a < b ? a : b);
    }
    final rows = buildTimeline(
      byDay[key] ?? const [],
      nextDayFirstStartMs: successor,
    );
    days.add(
      TimeExportDay(
        dateKey: key,
        rows: rows,
        summary: buildDaySummary(rows, maxLines: 1 << 20, categoryOf: categoryOf),
      ),
    );
  }
  return TimeExport(
    period: period,
    days: days,
    exportedAt: exportedAt,
    categoryOf: categoryOf,
  );
}

/// The one sentence both formats carry so a reader (human or model) never
/// treats an inferred end as a recorded one.
const String kTimeExportDurationsNote =
    'Each entry is a timestamped note of what the user was doing. Durations '
    'are derived, never typed: an explicit end when one was recorded, '
    'otherwise the next entry\'s start if it came within 2 hours; beyond '
    'that the duration is unknown and the gap is listed as untracked. '
    '"Intended" is a planned length, not what happened. Times are local.';

String renderTimeExport(TimeExport export, TimeExportFormat format) =>
    switch (format) {
      TimeExportFormat.markdown => renderTimeExportMarkdown(export),
      TimeExportFormat.json => renderTimeExportJson(export),
    };

// ─── Markdown ─────────────────────────────────────────────────────────────────

String renderTimeExportMarkdown(TimeExport export) {
  final p = export.period;
  final b = StringBuffer();
  b.writeln('# SidePal time log · ${p.label}');
  b.writeln();
  b.writeln('- Scope: ${p.scope.name} `${p.key}`');
  b.writeln(
    '- Exported: ${_localIso(export.exportedAt)} '
    '(${export.exportedAt.timeZoneName})',
  );
  b.writeln();
  b.writeln('> $kTimeExportDurationsNote');
  b.writeln();

  b.writeln('## Totals');
  b.writeln();
  if (export.isEmpty) {
    b.writeln('Nothing logged in this period.');
    b.writeln();
    return b.toString();
  }
  b.writeln(
    '- Logged: ${formatActivityDuration(export.logged)} across '
    '${export.daysWithEntries} of ${export.days.length} '
    '${export.days.length == 1 ? 'day' : 'days'}',
  );
  b.writeln('- Untracked: ${formatActivityDuration(export.untracked)}');
  b.writeln();
  final cats = export.byCategory;
  if (cats.isNotEmpty) {
    b.writeln('### By category');
    b.writeln();
    b.writeln('| Category | Time |');
    b.writeln('| --- | --- |');
    for (final c in cats) {
      b.writeln('| ${_cell(c.label)} | ${formatActivityDuration(c.total)} |');
    }
    b.writeln();
  }
  b.writeln('### By activity');
  b.writeln();
  b.writeln('| Activity | Time |');
  b.writeln('| --- | --- |');
  for (final a in export.byActivity) {
    b.writeln('| ${_cell(a.label)} | ${formatActivityDuration(a.total)} |');
  }
  b.writeln();

  b.writeln('## Timeline');
  b.writeln();
  for (final d in export.days) {
    if (d.isEmpty) continue;
    final day = DateKeys.parseLocalDateKey(d.dateKey);
    b.writeln('### ${d.dateKey} · ${_weekdayName(day)}');
    b.writeln();
    final s = d.summary;
    final tail = StringBuffer('Logged ${formatActivityDuration(s.logged)}');
    if (s.untracked > Duration.zero) {
      tail.write(' · untracked ${formatActivityDuration(s.untracked)}');
    }
    b.writeln(tail);
    b.writeln();
    b.writeln('| Start | End | Activity | Duration | Category | Notes |');
    b.writeln('| --- | --- | --- | --- | --- | --- |');
    for (final row in d.rows) {
      switch (row) {
        case ActivityRow():
          final e = row.event;
          final end = row.endMs;
          final actual = row.actual;
          final cat = export.categoryOf[e.normalizedText];
          final notes = <String>[];
          if (row.isOngoing) notes.add('ongoing');
          if (row.endSource == EndSource.capped) notes.add('end unknown');
          final intended = row.intended;
          if (intended != null) {
            notes.add('intended ${formatActivityDuration(intended)}');
          }
          if (e.isTimerSourced) notes.add('focus timer');
          b.writeln(
            '| ${_hhmm(e.startedAtMs)} '
            '| ${end == null ? '' : _hhmm(end)} '
            '| ${_cell(e.text)} '
            '| ${actual == null ? '' : formatActivityDuration(actual)} '
            '| ${cat == null ? '' : ActivityCategories.label(cat)} '
            '| ${notes.join('; ')} |',
          );
        case UntrackedRow():
          b.writeln(
            '| ${_hhmm(row.fromMs)} | ${_hhmm(row.toMs)} | *untracked* '
            '| ${formatActivityDuration(row.length)} | | |',
          );
      }
    }
    b.writeln();
  }
  return b.toString();
}

// ─── JSON ─────────────────────────────────────────────────────────────────────

Map<String, dynamic> timeExportToMap(TimeExport export) {
  final p = export.period;
  return {
    'app': 'SidePal',
    'kind': 'time_log_export',
    'schemaVersion': 1,
    'exportedAt': _localIso(export.exportedAt),
    'timeZone': export.exportedAt.timeZoneName,
    'utcOffsetMinutes': export.exportedAt.timeZoneOffset.inMinutes,
    'durationsNote': kTimeExportDurationsNote,
    'scope': p.scope.name,
    'periodKey': p.key,
    'label': p.label,
    'firstDay': p.dayKeys.first,
    'lastDay': p.dayKeys.last,
    'totals': {
      'loggedMinutes': export.logged.inMinutes,
      'untrackedMinutes': export.untracked.inMinutes,
      'daysWithEntries': export.daysWithEntries,
      'daysInPeriod': export.days.length,
      'byCategory': [
        for (final c in export.byCategory)
          {'category': c.label, 'minutes': c.total.inMinutes},
      ],
      'byActivity': [
        for (final a in export.byActivity)
          {'activity': a.label, 'minutes': a.total.inMinutes},
      ],
    },
    'days': [
      for (final d in export.days)
        if (!d.isEmpty)
          {
            'date': d.dateKey,
            'weekday': _weekdayName(DateKeys.parseLocalDateKey(d.dateKey)),
            'loggedMinutes': d.summary.logged.inMinutes,
            'untrackedMinutes': d.summary.untracked.inMinutes,
            'entries': [
              for (final row in d.rows) _rowToMap(row, export.categoryOf),
            ],
          },
    ],
  };
}

Map<String, dynamic> _rowToMap(TimelineRow row, Map<String, String> categoryOf) {
  switch (row) {
    case ActivityRow():
      final e = row.event;
      final end = row.endMs;
      final cat = categoryOf[e.normalizedText];
      return {
        'type': 'activity',
        'activity': e.text,
        'start': _localIso(DateTime.fromMillisecondsSinceEpoch(e.startedAtMs)),
        'end': end == null
            ? null
            : _localIso(DateTime.fromMillisecondsSinceEpoch(end)),
        'endSource': row.endSource.name,
        'durationMinutes': row.actual?.inMinutes,
        'intendedMinutes': e.intendedMinutes,
        'category': cat,
        'categoryLabel': cat == null ? null : ActivityCategories.label(cat),
        'source': e.isTimerSourced ? 'focus_timer' : 'manual',
      };
    case UntrackedRow():
      return {
        'type': 'untracked',
        'start': _localIso(DateTime.fromMillisecondsSinceEpoch(row.fromMs)),
        'end': _localIso(DateTime.fromMillisecondsSinceEpoch(row.toMs)),
        'durationMinutes': row.length.inMinutes,
      };
  }
}

String renderTimeExportJson(TimeExport export) =>
    const JsonEncoder.withIndent('  ').convert(timeExportToMap(export));

// ─── Formatting helpers (no BuildContext, fixed English) ──────────────────────

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _monthName(int month) => _months[month - 1];
String _weekdayName(DateTime d) => _weekdays[d.weekday - 1];

String _longDate(DateTime d) => '${_monthName(d.month)} ${d.day}, ${d.year}';

String _shortDate(DateTime d) => '${_monthName(d.month).substring(0, 3)} ${d.day}';

String _two(int n) => n.toString().padLeft(2, '0');

String _hhmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${_two(d.hour)}:${_two(d.minute)}';
}

/// `2026-09-08T09:00` — local wall time, no offset (the header carries the
/// zone once so entries stay readable).
String _localIso(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)}T${_two(d.hour)}:${_two(d.minute)}';

/// Markdown table cells cannot contain pipes or line breaks.
String _cell(String s) =>
    s.replaceAll('|', '\\|').replaceAll(RegExp(r'\s*\n\s*'), ' ');
