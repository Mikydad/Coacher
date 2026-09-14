import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_category_rule.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/domain/time_export.dart';

ActivityEvent _ev(
  String text,
  DateTime start, {
  DateTime? end,
  int? intended,
  ActivitySource source = ActivitySource.manual,
  bool active = true,
}) => ActivityEvent.create(
  text: text,
  startedAtMs: start.millisecondsSinceEpoch,
  endedAtMs: end?.millisecondsSinceEpoch,
  intendedMinutes: intended,
  nowMs: 1,
  source: source,
).copyWith(active: active);

void main() {
  // Tuesday 8 Sep 2026 → ISO week 37 (Mon 7 – Sun 13). September has 30 days.
  final anchor = DateTime(2026, 9, 8, 15, 30);

  group('TimeExportPeriod.around', () {
    test('day is the local calendar day', () {
      final p = TimeExportPeriod.around(TimeExportScope.day, anchor);
      expect(p.key, '2026-09-08');
      expect(p.dayKeys, ['2026-09-08']);
      expect(p.start, DateTime(2026, 9, 8));
      expect(p.endMs, DateTime(2026, 9, 9).millisecondsSinceEpoch);
      expect(p.fetchEndMs, DateTime(2026, 9, 10).millisecondsSinceEpoch);
      expect(p.label, 'Tuesday, September 8, 2026');
      expect(p.fileStem, 'sidepal_time_2026-09-08');
    });

    test('week is the ISO week, Monday first', () {
      final p = TimeExportPeriod.around(TimeExportScope.week, anchor);
      expect(p.key, '2026-W37');
      expect(p.dayKeys.first, '2026-09-07');
      expect(p.dayKeys.last, '2026-09-13');
      expect(p.dayKeys.length, 7);
      expect(p.label, 'Sep 7 – Sep 13, 2026');
      expect(p.fetchEndMs, DateTime(2026, 9, 15).millisecondsSinceEpoch);
    });

    test('month covers every day of the month', () {
      final p = TimeExportPeriod.around(TimeExportScope.month, anchor);
      expect(p.key, '2026-09');
      expect(p.dayKeys.length, 30);
      expect(p.dayKeys.first, '2026-09-01');
      expect(p.dayKeys.last, '2026-09-30');
      expect(p.label, 'September 2026');
      expect(p.endMs, DateTime(2026, 10, 1).millisecondsSinceEpoch);
    });

    test('February in a leap year has 29 days', () {
      final p = TimeExportPeriod.around(
        TimeExportScope.month,
        DateTime(2028, 2, 10),
      );
      expect(p.dayKeys.length, 29);
    });
  });

  group('buildTimeExport', () {
    final exportedAt = DateTime(2026, 9, 15, 10, 0);

    test('one day per period key, empty days kept, tombstones ignored', () {
      final p = TimeExportPeriod.around(TimeExportScope.week, anchor);
      final events = [
        _ev('Gym', DateTime(2026, 9, 8, 7), end: DateTime(2026, 9, 8, 8)),
        _ev('Deleted', DateTime(2026, 9, 9, 7), active: false),
      ];
      final x = buildTimeExport(p, events, exportedAt: exportedAt);
      expect(x.days.length, 7);
      expect(x.daysWithEntries, 1);
      expect(x.logged, const Duration(hours: 1));
      expect(x.isEmpty, isFalse);
    });

    test('the day after the period ends the last open entry (successor)', () {
      final p = TimeExportPeriod.around(TimeExportScope.day, anchor);
      final events = [
        _ev('Reading', DateTime(2026, 9, 8, 23, 0)),
        // Next morning's first log, 60 min later: within the 2h cap.
        _ev('Sleep', DateTime(2026, 9, 9, 0, 0)),
      ];
      final x = buildTimeExport(p, events, exportedAt: exportedAt);
      expect(x.days.single.summary.logged, const Duration(hours: 1));
      // The successor itself is not part of the exported day.
      expect(x.days.single.rows.length, 1);
    });

    test('byActivity keeps the long tail; byCategory only with rules', () {
      final p = TimeExportPeriod.around(TimeExportScope.day, anchor);
      final events = [
        for (var i = 0; i < 12; i++)
          _ev(
            'Task $i',
            DateTime(2026, 9, 8, 8, 10 * i),
            end: DateTime(2026, 9, 8, 8, 10 * i + 5),
          ),
      ];
      final noRules = buildTimeExport(p, events, exportedAt: exportedAt);
      expect(noRules.byActivity.length, 12);
      expect(noRules.byActivity.any((l) => l.label == 'Other'), isFalse);
      expect(noRules.byCategory, isEmpty);

      final withRules = buildTimeExport(
        p,
        events,
        exportedAt: exportedAt,
        categoryOf: {'task 0': ActivityCategories.work},
      );
      expect(withRules.byCategory.first.label, 'Work');
      expect(withRules.byCategory.last.label, 'Other');
    });
  });

  group('renderers', () {
    final exportedAt = DateTime(2026, 9, 15, 10, 0);
    final period = TimeExportPeriod.around(TimeExportScope.day, anchor);
    final events = [
      _ev(
        'Deep | work',
        DateTime(2026, 9, 8, 9, 0),
        end: DateTime(2026, 9, 8, 10, 30),
        intended: 120,
        source: ActivitySource.timer,
      ),
      _ev('Lunch', DateTime(2026, 9, 8, 12, 0)),
      // 10:30–12:00 is a 90 min gap after an explicit end → untracked.
      // Walk is 3h after Lunch: beyond the cap → Lunch has no end, 3h untracked.
      _ev('Walk', DateTime(2026, 9, 8, 15, 0)),
    ];
    final export = buildTimeExport(
      period,
      events,
      exportedAt: exportedAt,
      categoryOf: {'deep | work': ActivityCategories.work},
    );

    test('markdown carries the note, totals, and a per-day table', () {
      final md = renderTimeExportMarkdown(export);
      expect(md, startsWith('# SidePal time log · Tuesday, September 8, 2026'));
      expect(md, contains(kTimeExportDurationsNote));
      expect(md, contains('- Logged: 1h 30m across 1 of 1 day'));
      expect(md, contains('- Untracked: 4h 30m'));
      expect(md, contains('| Work | 1h 30m |'));
      expect(md, contains('### 2026-09-08 · Tuesday'));
      // Pipes in activity text are escaped so the table survives.
      expect(
        md,
        contains(
          '| 09:00 | 10:30 | Deep \\| work | 1h 30m | Work '
          '| intended 2h 00m; focus timer |',
        ),
      );
      expect(md, contains('| 10:30 | 12:00 | *untracked* | 1h 30m | | |'));
      expect(md, contains('| 12:00 |  | Lunch |  |  | end unknown |'));
      expect(md, contains('| 12:00 | 15:00 | *untracked* | 3h 00m | | |'));
      expect(md, contains('| 15:00 |  | Walk |  |  | ongoing |'));
      // No ids or sync metadata leak.
      expect(md, isNot(contains('act_')));
      expect(md, isNot(contains('updatedAt')));
    });

    test('markdown for an empty period says so and stops', () {
      final empty = buildTimeExport(period, const [], exportedAt: exportedAt);
      final md = renderTimeExportMarkdown(empty);
      expect(md, contains('Nothing logged in this period.'));
      expect(md, isNot(contains('## Timeline')));
    });

    test('json is well-formed, local times, no ids', () {
      final raw = renderTimeExportJson(export);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      expect(map['app'], 'SidePal');
      expect(map['kind'], 'time_log_export');
      expect(map['scope'], 'day');
      expect(map['periodKey'], '2026-09-08');
      expect(map['exportedAt'], '2026-09-15T10:00');
      expect(map['durationsNote'], kTimeExportDurationsNote);

      final totals = map['totals'] as Map<String, dynamic>;
      expect(totals['loggedMinutes'], 90);
      expect(totals['untrackedMinutes'], 270);
      expect(totals['daysWithEntries'], 1);
      expect((totals['byCategory'] as List).first, {
        'category': 'Work',
        'minutes': 90,
      });

      final days = map['days'] as List;
      expect(days.length, 1);
      final entries = (days.first as Map)['entries'] as List;
      expect(entries.length, 5);
      final first = entries.first as Map<String, dynamic>;
      expect(first['type'], 'activity');
      expect(first['activity'], 'Deep | work');
      expect(first['start'], '2026-09-08T09:00');
      expect(first['end'], '2026-09-08T10:30');
      expect(first['endSource'], 'explicit');
      expect(first['durationMinutes'], 90);
      expect(first['intendedMinutes'], 120);
      expect(first['category'], 'work');
      expect(first['source'], 'focus_timer');
      expect(first.containsKey('id'), isFalse);

      final firstGap = entries[1] as Map<String, dynamic>;
      expect(firstGap['type'], 'untracked');
      expect(firstGap['durationMinutes'], 90);

      final lunch = entries[2] as Map<String, dynamic>;
      expect(lunch['end'], isNull);
      expect(lunch['endSource'], 'capped');
      expect(lunch['durationMinutes'], isNull);

      final gap = entries[3] as Map<String, dynamic>;
      expect(gap['type'], 'untracked');
      expect(gap['durationMinutes'], 180);

      final walk = entries[4] as Map<String, dynamic>;
      expect(walk['endSource'], 'ongoing');
      expect(raw, isNot(contains('act_')));
    });

    test('format metadata', () {
      expect(TimeExportFormat.markdown.extension, 'md');
      expect(TimeExportFormat.json.extension, 'json');
      expect(TimeExportFormat.markdown.mimeType, 'text/markdown');
      expect(TimeExportFormat.json.mimeType, 'application/json');
    });
  });
}
