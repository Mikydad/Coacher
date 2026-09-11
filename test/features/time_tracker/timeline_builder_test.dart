import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/time_tracker/domain/day_summary.dart';
import 'package:sidepal/features/time_tracker/domain/duration_format.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/domain/recent_activities.dart';
import 'package:sidepal/features/time_tracker/domain/timeline_builder.dart';

final _day = DateTime(2026, 9, 12);

int _at(int hour, [int minute = 0]) =>
    DateTime(_day.year, _day.month, _day.day, hour, minute).millisecondsSinceEpoch;

ActivityEvent _e(
  String text,
  int startMs, {
  int? endMs,
  int? intended,
  bool active = true,
  ActivitySource source = ActivitySource.manual,
}) => ActivityEvent(
  id: 'act_${text.hashCode}_$startMs',
  text: text,
  startedAtMs: startMs,
  endedAtMs: endMs,
  intendedMinutes: intended,
  dateKey: activityDateKeyFor(startMs),
  source: source,
  active: active,
  createdAtMs: startMs,
  updatedAtMs: startMs,
);

void main() {
  group('buildTimeline', () {
    test('next event within the cap ends the previous one', () {
      final rows = buildTimeline([
        _e('Scrolling', _at(22, 3)),
        _e('Planning', _at(22, 9)),
      ]);
      expect(rows.length, 2);
      final first = rows[0] as ActivityRow;
      expect(first.endSource, EndSource.nextEvent);
      expect(first.actual, const Duration(minutes: 6));
      final last = rows[1] as ActivityRow;
      expect(last.endSource, EndSource.ongoing);
      expect(last.actual, isNull);
      expect(last.isOngoing, isTrue);
    });

    test('beyond the cap: credited nothing + an untracked row', () {
      final rows = buildTimeline([
        _e('Planning', _at(22, 9)),
        _e('Sleep', _at(2, 0) + const Duration(days: 1).inMilliseconds),
      ]);
      expect(rows.length, 3);
      final planning = rows[0] as ActivityRow;
      expect(planning.endSource, EndSource.capped);
      expect(planning.actual, isNull);
      final gap = rows[1] as UntrackedRow;
      expect(gap.length, const Duration(hours: 3, minutes: 51));
      expect((rows[2] as ActivityRow).endSource, EndSource.ongoing);
    });

    test('exactly 2 h still counts as the next event', () {
      final rows = buildTimeline([
        _e('A', _at(10)),
        _e('B', _at(12)),
      ]);
      expect((rows[0] as ActivityRow).endSource, EndSource.nextEvent);
      expect((rows[0] as ActivityRow).actual, const Duration(hours: 2));
    });

    test('explicit end beats the next event; 10-min sliver is not untracked',
        () {
      final rows = buildTimeline([
        _e('Work on SidePal', _at(19, 42), endMs: _at(20, 27)),
        _e('YouTube', _at(20, 37)),
      ]);
      expect(rows.length, 2);
      final work = rows[0] as ActivityRow;
      expect(work.endSource, EndSource.explicit);
      expect(work.actual, const Duration(minutes: 45));
    });

    test('explicit end with a 40-min sliver → untracked row', () {
      final rows = buildTimeline([
        _e('Work', _at(19, 42), endMs: _at(20, 27)),
        _e('YouTube', _at(21, 7)),
      ]);
      expect(rows.length, 3);
      expect((rows[1] as UntrackedRow).length, const Duration(minutes: 40));
    });

    test('explicit end past the next start is clamped to the next start', () {
      final rows = buildTimeline([
        _e('Timer', _at(19, 0), endMs: _at(21, 0)),
        _e('Logged sooner', _at(20, 0)),
      ]);
      final timer = rows[0] as ActivityRow;
      expect(timer.endSource, EndSource.explicit);
      expect(timer.actual, const Duration(hours: 1));
      expect(rows.length, 2);
    });

    test('explicit end on the last event is ended, not ongoing', () {
      final rows = buildTimeline([
        _e('Focus', _at(19, 42), endMs: _at(20, 27)),
      ]);
      final row = rows.single as ActivityRow;
      expect(row.endSource, EndSource.explicit);
      expect(row.isOngoing, isFalse);
    });

    test('intended never changes actual', () {
      final rows = buildTimeline([
        _e('Study Flutter', _at(19, 42), intended: 30),
        _e('YouTube', _at(20, 27)),
      ]);
      final study = rows[0] as ActivityRow;
      expect(study.intended, const Duration(minutes: 30));
      expect(study.actual, const Duration(minutes: 45));
    });

    test('sorts by start and drops tombstones', () {
      final rows = buildTimeline([
        _e('Later', _at(11)),
        _e('Deleted', _at(10, 30), active: false),
        _e('Earlier', _at(10)),
      ]);
      expect(rows.length, 2);
      expect((rows[0] as ActivityRow).event.text, 'Earlier');
      expect((rows[0] as ActivityRow).actual, const Duration(hours: 1));
    });

    test('the full PRD day renders with one untracked stretch', () {
      final rows = buildTimeline([
        _e('Woke up', _at(10, 0)),
        _e('Scrolling', _at(10, 3)),
        _e('Planning', _at(10, 9)),
        _e('Bathroom', _at(10, 26)),
        _e('Cleaning house', _at(10, 50)),
        _e('Playing game', _at(11, 55)),
        _e('Eating', _at(19, 0)),
      ]);
      final untracked = rows.whereType<UntrackedRow>().toList();
      expect(untracked.length, 1);
      expect(untracked.single.length, const Duration(hours: 7, minutes: 5));
      final cleaning = rows.whereType<ActivityRow>().firstWhere(
        (r) => r.event.text == 'Cleaning house',
      );
      expect(cleaning.actual, const Duration(hours: 1, minutes: 5));
    });
  });

  group('buildDaySummary', () {
    test('counts only known durations, groups by normalised text', () {
      final rows = buildTimeline([
        _e('Gym', _at(7, 0)),
        _e('SidePal', _at(8, 10)),
        _e('gym ', _at(10, 10)),
        _e('Gaming', _at(10, 40)),
        _e('Sleep', _at(2, 0) + const Duration(days: 1).inMilliseconds),
      ]);
      final s = buildDaySummary(rows);
      // Gym 1h10 + SidePal 2h + gym 30m; Gaming capped → 0; Sleep ongoing.
      expect(s.logged, const Duration(hours: 3, minutes: 40));
      expect(s.untracked, const Duration(hours: 15, minutes: 20));
      expect(s.lines[0].label, 'SidePal');
      expect(s.lines[0].total, const Duration(hours: 2));
      expect(s.lines[1].label, 'gym'); // most recent spelling
      expect(s.lines[1].total, const Duration(hours: 1, minutes: 40));
      expect(s.lines.length, 2);
    });

    test('folds beyond maxLines into Other', () {
      final events = <ActivityEvent>[];
      for (var i = 0; i < 8; i++) {
        events.add(_e('A$i', _at(8 + i)));
      }
      events.add(_e('End', _at(16), endMs: _at(16, 30)));
      final s = buildDaySummary(buildTimeline(events), maxLines: 6);
      expect(s.lines.length, 7);
      expect(s.lines.last.label, kSummaryOtherLabel);
      // A6 + A7 (1 h each) + End (30 m).
      expect(s.lines.last.total, const Duration(hours: 2, minutes: 30));
    });

    test('empty day', () {
      expect(buildDaySummary(const []).isEmpty, isTrue);
    });
  });

  group('recentActivityChips', () {
    test('distinct by normalised text, newest spelling, capped', () {
      final chips = recentActivityChips([
        _e('gym', _at(7)),
        _e('Gym', _at(9)),
        _e('Scrolling', _at(8)),
        _e('Deleted', _at(10), active: false),
        _e('Flutter', _at(6)),
      ], max: 2);
      expect(chips, ['Gym', 'Scrolling']);
    });

    test('empty input → no chips', () {
      expect(recentActivityChips(const []), isEmpty);
    });
  });

  group('formatActivityDuration', () {
    test('formats', () {
      expect(formatActivityDuration(const Duration(minutes: 6)), '6m');
      expect(formatActivityDuration(const Duration(minutes: 45)), '45m');
      expect(formatActivityDuration(const Duration(hours: 1, minutes: 5)), '1h 05m');
      expect(formatActivityDuration(const Duration(hours: 3, minutes: 51)), '3h 51m');
      expect(formatActivityDuration(const Duration(seconds: 40)), '0m');
    });
  });
}
