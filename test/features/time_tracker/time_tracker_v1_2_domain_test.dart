import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/thinking/application/reflection_parser.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_category_rule.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/domain/observation_tone.dart';
import 'package:sidepal/features/time_tracker/domain/reflection_activity_snapshot.dart';
import 'package:sidepal/features/time_tracker/domain/week_periods.dart';
import 'package:sidepal/features/time_tracker/domain/week_summary.dart';

ActivityEvent _e(String text, DateTime at, {int? endMinutes, ActivitySource source = ActivitySource.manual}) {
  final ms = at.millisecondsSinceEpoch;
  return ActivityEvent(
    id: 'act_$ms',
    text: text,
    startedAtMs: ms,
    endedAtMs: endMinutes == null ? null : ms + endMinutes * 60000,
    dateKey: activityDateKeyFor(ms),
    source: source,
    createdAtMs: 1,
    updatedAtMs: ms,
  );
}

void main() {
  group('WeekPeriods', () {
    test('Monday-start ISO weeks, contiguous, keyed', () {
      final w = WeekPeriods.of(DateTime(2026, 9, 12, 22)); // Saturday
      expect(w.start, DateTime(2026, 9, 7));
      expect(w.lastDay, DateTime(2026, 9, 13));
      expect(w.dayKeys.first, '2026-09-07');
      expect(w.dayKeys.last, '2026-09-13');
      expect(w.dayKeys.length, 7);
      expect(w.key, '2026-W37');
      final prev = WeekPeriods.previous(w);
      expect(prev.endMs, w.startMs);
      expect(WeekPeriods.next(prev).key, w.key);
      expect(w.contains(DateTime(2026, 9, 13, 23, 59)), isTrue);
      expect(w.contains(DateTime(2026, 9, 14)), isFalse);
    });

    test('monthOf', () {
      final m = WeekPeriods.monthOf(DateTime(2026, 9, 12));
      expect(m.key, '2026-09');
      expect(m.label, 'September');
      expect(m.endMs, DateTime(2026, 10, 1).millisecondsSinceEpoch);
    });
  });

  group('buildRangeSummary', () {
    test('sums per day; the gap cap never crosses midnight', () {
      final d1 = DateTime(2026, 9, 7);
      final d2 = DateTime(2026, 9, 8);
      final byDay = groupEventsByDay([
        _e('Gym', d1.add(const Duration(hours: 7))),
        _e('Work', d1.add(const Duration(hours: 8))),
        _e('Lunch', d1.add(const Duration(hours: 10))), // Work = 2h, Lunch ongoing (day 1 last)
        _e('Work', d2.add(const Duration(hours: 9))),
        _e('Done', d2.add(const Duration(hours: 10, minutes: 30))),
      ]);
      final s = buildRangeSummary(byDay, categoryOf: {'work': ActivityCategories.work});
      expect(s.daysWithEntries, 2);
      expect(s.logged, const Duration(hours: 4, minutes: 30));
      expect(s.lines.first.label, 'Work');
      expect(s.lines.first.total, const Duration(hours: 3, minutes: 30));
      expect(s.categoryLines.first.label, 'Work');
      expect(s.categoryLines.last.label, 'Other');
      expect(s.untracked, Duration.zero);
    });

    test('empty', () {
      expect(buildRangeSummary(const {}).isEmpty, isTrue);
    });
  });

  group('violatesObservationTone', () {
    test('catches the banned list, word-boundary, any case', () {
      for (final bad in [
        'You wasted two hours.',
        'You should sleep earlier',
        'That was a bad day',
        'You need to focus',
        'You spent too much time gaming',
        'Not enough exercise this week',
        'You ought to try harder',
        'Only 20 minutes of reading',
        'You were unproductive after lunch',
        'Stop procrastinating',
      ]) {
        expect(violatesObservationTone(bad), isTrue, reason: bad);
      }
    });

    test('lets observational sentences through', () {
      for (final ok in [
        'Most of your focused work happened after 9 PM.',
        'You logged 4 gym sessions this week, all in the evening.',
        'Your SidePal work was concentrated in late-night sessions.',
        'Scrolling showed up on 5 of 7 days, usually right after waking.',
      ]) {
        expect(violatesObservationTone(ok), isFalse, reason: ok);
      }
    });
  });

  group('buildActivitySnapshot', () {
    final today = DateTime(2026, 9, 12);
    test('today rows, aggregates, uncategorised texts, ids', () {
      final todayEvents = [
        _e('Gym', today.add(const Duration(hours: 7))),
        _e('SidePal', today.add(const Duration(hours: 8)), endMinutes: 90),
      ];
      final yesterday = today.subtract(const Duration(days: 1));
      final recent = {
        '2026-09-11': [
          _e('Scrolling', yesterday.add(const Duration(hours: 22))),
          _e('Sleep', yesterday.add(const Duration(hours: 23))),
        ],
      };
      final rules = [
        ActivityCategoryRule.forText('gym', category: ActivityCategories.exercise, source: CategoryRuleSource.ai, nowMs: 1),
        ActivityCategoryRule.forText('scrolling', category: ActivityCategories.entertainment, source: CategoryRuleSource.user, nowMs: 1),
      ];
      final snap = buildActivitySnapshot(
        todayKey: '2026-09-12',
        todayEvents: todayEvents,
        last7Days: recent,
        rules: rules,
      );
      final rows = snap['today'] as List;
      expect(rows.length, 2);
      expect((rows[0] as Map)['category'], ActivityCategories.exercise);
      expect((rows[0] as Map)['minutes'], 60);
      expect((rows[1] as Map)['minutes'], 90);
      expect(snap['todayLogged'], '2h 30m');
      final week = snap['last7Days'] as Map;
      expect(week['daysWithEntries'], 1);
      expect(week['loggedMinutes'], 60);
      expect(snap['uncategorizedTexts'], ['SidePal', 'Sleep']);
      expect(snap.containsKey('weekBoundary'), isFalse);
      final ids = activitySnapshotIds(snap);
      expect(ids, contains(todayEvents.first.id));
      expect(ids, contains('activity:day:2026-09-12'));
      expect(ids, contains('activity:week:last7'));
    });

    test('month boundary carries direction texts', () {
      final snap = buildActivitySnapshot(
        todayKey: '2026-10-01',
        todayEvents: const [],
        last7Days: const {},
        rules: const [],
        monthBoundary: (
          key: '2026-09',
          label: 'September',
          eventsByDay: {
            '2026-09-20': [_e('SidePal', DateTime(2026, 9, 20, 21), endMinutes: 120)],
          },
          directionTexts: ['month: Launch SidePal'],
        ),
      );
      final m = snap['monthBoundary'] as Map;
      expect(m['direction'], ['month: Launch SidePal']);
      expect(m['loggedMinutes'], 120);
      expect(activitySnapshotIds(snap), contains('activity:month:2026-09'));
    });
  });

  group('ReflectionParser time sections', () {
    const ids = {'act_1', 'activity:day:2026-09-12', 'activity:month:2026-09'};
    ParsedReflection parse(String json) => ReflectionParser.parse(
      json,
      knownIds: const {},
      openIntentionIds: const {},
      existingTitleKeys: const {},
      activityIds: ids,
      uncategorizedTexts: const {'Gym', 'SidePal'},
    );

    test('accepts one per scope, grounded, tone-clean', () {
      final p = parse('''{
        "timeObservations": [
          {"scope": "day", "message": "Most of your focused work happened after 9 PM.", "basedOn": ["act_1"]},
          {"scope": "day", "message": "A second day observation that is long enough.", "basedOn": ["act_1"]},
          {"scope": "month", "message": "Your focus was launching SidePal; SidePal work clustered late at night.", "basedOn": ["activity:month:2026-09"]},
          {"scope": "week", "message": "You wasted the weekend on gaming.", "basedOn": ["activity:day:2026-09-12"]},
          {"scope": "week", "message": "Ungrounded observation about nothing at all.", "basedOn": ["nope"]},
          {"scope": "year", "message": "Unknown scope observation, long enough.", "basedOn": ["act_1"]}
        ],
        "activityCategories": [
          {"text": "Gym", "category": "exercise"},
          {"text": "Gym", "category": "rest"},
          {"text": "Unknown", "category": "work"},
          {"text": "SidePal", "category": "nonsense"}
        ]
      }''');
      expect(p.timeObservations.map((o) => o.scope), ['day', 'month']);
      expect(p.timeObservations.first.message, startsWith('Most of'));
      expect(p.activityCategories.length, 1);
      expect(p.activityCategories.single.text, 'Gym');
      expect(p.activityCategories.single.category, 'exercise');
      expect(p.isEmpty, isFalse);
    });

    test('ignored entirely when no activity ids were sent', () {
      final p = ReflectionParser.parse(
        '{"timeObservations":[{"scope":"day","message":"Long enough message here.","basedOn":["act_1"]}]}',
        knownIds: const {},
        openIntentionIds: const {},
        existingTitleKeys: const {},
      );
      expect(p.timeObservations, isEmpty);
    });
  });
}
