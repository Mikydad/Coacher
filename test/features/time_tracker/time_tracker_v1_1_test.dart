import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/time_tracker/domain/day_summary.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/domain/timeline_builder.dart';
import 'package:sidepal/features/time_tracker/domain/timeline_text.dart';

final _day = DateTime(2026, 9, 12);
int _at(int h, [int m = 0]) =>
    DateTime(_day.year, _day.month, _day.day, h, m).millisecondsSinceEpoch;
int _nextDayAt(int h, [int m = 0]) =>
    DateTime(_day.year, _day.month, _day.day + 1, h, m).millisecondsSinceEpoch;

ActivityEvent _e(String text, int startMs,
        {int? endMs, int? intended, ActivitySource source = ActivitySource.manual}) =>
    ActivityEvent(
      id: 'act_$startMs',
      text: text,
      startedAtMs: startMs,
      endedAtMs: endMs,
      intendedMinutes: intended,
      dateKey: activityDateKeyFor(startMs),
      source: source,
      createdAtMs: 1,
      updatedAtMs: 1,
    );

void main() {
  group('cross-midnight successor (A2)', () {
    test('next day first event within the cap ends the last event', () {
      final rows = buildTimeline(
        [_e('Reading', _at(23, 30))],
        nextDayFirstStartMs: _nextDayAt(0, 45),
      );
      final r = rows.single as ActivityRow;
      expect(r.endSource, EndSource.nextEvent);
      expect(r.actual, const Duration(hours: 1, minutes: 15));
    });

    test('beyond the cap → capped, and NO untracked row across midnight', () {
      final rows = buildTimeline(
        [_e('Reading', _at(21, 0))],
        nextDayFirstStartMs: _nextDayAt(8, 0),
      );
      expect(rows.length, 1);
      expect((rows.single as ActivityRow).endSource, EndSource.capped);
    });

    test('no next-day event → still ongoing', () {
      final rows = buildTimeline([_e('Reading', _at(23, 30))]);
      expect((rows.single as ActivityRow).isOngoing, isTrue);
    });

    test('an explicit end ignores the next-day hint', () {
      final rows = buildTimeline(
        [_e('Focus', _at(23, 0), endMs: _at(23, 40))],
        nextDayFirstStartMs: _nextDayAt(0, 10),
      );
      final r = rows.single as ActivityRow;
      expect(r.endSource, EndSource.explicit);
      expect(r.actual, const Duration(minutes: 40));
    });
  });

  group('renderTimelineLines (A3)', () {
    test('renders rows, gaps, intended, timer glyph, and the totals tail', () {
      final rows = buildTimeline([
        _e('Scrolling', _at(10, 3)),
        _e('Planning', _at(10, 9), intended: 30),
        _e('Sleep', _nextDayAt(2, 0)),
        _e('Focus', _at(19, 42), endMs: _at(20, 27), source: ActivitySource.timer),
      ]);
      // Order: Scrolling, Planning (capped → untracked to Focus), Focus, Sleep.
      final lines = renderTimelineLines(rows, summary: buildDaySummary(rows));
      expect(lines.first, '10:03–10:09 Scrolling · 6m');
      expect(lines[1], '10:09 Planning (intended 30m)');
      expect(lines[2], startsWith('? · '));
      expect(lines[2], endsWith(' untracked'));
      expect(lines[3], '19:42–20:27 Focus · 45m [focus timer]');
      // Explicit end → the 5h 33m to Sleep is untracked (≥ 15 min sliver).
      expect(lines[4], '? · 5h 33m untracked');
      expect(lines[5], '02:00 Sleep · ongoing');
      expect(lines.last, 'Logged 51m · untracked 15h 06m');
    });

    test('caps rows, keeping the newest', () {
      final rows = buildTimeline([
        for (var i = 0; i < 30; i++) _e('A$i', _at(0, i)),
      ]);
      final lines = renderTimelineLines(rows, maxRows: 5);
      expect(lines.length, 5);
      expect(lines.last, contains('A29'));
    });

    test('empty → empty', () {
      expect(renderTimelineLines(const []), isEmpty);
    });
  });

  group('Coach payload (A3/A4)', () {
    test('todayActivityLog serialises only when set and renders in the prompt',
        () {
      expect(
        AiOperatingLayerPayload(userInput: 'hi').toJson().containsKey('todayActivityLog'),
        isFalse,
      );
      final payload = AiOperatingLayerPayload(
        userInput: 'what did I do today?',
        todayActivityLog: const ['10:03–10:09 Scrolling · 6m', 'Logged 6m'],
      );
      expect(payload.toJson()['todayActivityLog'], hasLength(2));
      final messages = buildConversationalStreamMessages(payload);
      final user = messages.lastWhere((m) => m['role'] == 'user')['content'] as String;
      expect(user, contains("Today's timeline"));
      expect(user, contains('  - 10:03–10:09 Scrolling · 6m'));
      expect(user, contains('never judge it'));
    });

    test('logActivity is a low-risk action type with a card description', () {
      final action = AiAction.fromJson({
        'actionType': 'logActivity',
        'parameters': {'text': 'Gym', 'time': '19:42'},
      });
      expect(action.actionType, ActionType.logActivity);
      expect(action.riskLevel, AiActionRiskLevel.low);
    });
  });
}
