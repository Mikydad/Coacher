import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/time_tracker/domain/activity_overlap.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';

/// One thing at a time (2026-09-24): the sheet asks before an entry cuts
/// another one short.
final _nine = DateTime(2026, 9, 24, 9);
int _at(int minutes) =>
    _nine.add(Duration(minutes: minutes)).millisecondsSinceEpoch;

ActivityEvent _e(
  String text,
  int startMin, {
  int? endMin,
  bool active = true,
}) => ActivityEvent.create(
  text: text,
  startedAtMs: _at(startMin),
  nowMs: 1,
  endedAtMs: endMin == null ? null : _at(endMin),
).copyWith(active: active);

void main() {
  test('a running entry clashes with a new one at the same start', () {
    final running = _e('Deep work', 0);
    final clashes = overlappingActivities(
      [running],
      startMs: _at(0),
      nowMs: _at(40),
    );
    expect(clashes.map((e) => e.text), ['Deep work']);
  });

  test('closed entries clash only when the ranges cross', () {
    final a = _e('A', 0, endMin: 30);
    expect(
      overlappingActivities(
        [a],
        startMs: _at(30),
        endMs: _at(45),
        nowMs: _at(60),
      ),
      isEmpty,
      reason: 'touching ends do not overlap',
    );
    expect(
      overlappingActivities(
        [a],
        startMs: _at(15),
        endMs: _at(45),
        nowMs: _at(60),
      ),
      hasLength(1),
    );
  });

  test('deleted rows and the entry being edited are ignored', () {
    final a = _e('A', 0, endMin: 30);
    final gone = _e('Gone', 0, endMin: 30, active: false);
    expect(
      overlappingActivities(
        [a, gone],
        startMs: _at(10),
        endMs: _at(20),
        nowMs: _at(60),
        excludeId: a.id,
      ),
      isEmpty,
    );
  });

  test('the notice names the clash and where the cut lands', () {
    final running = _e('Deep work', 0);
    final n = overlapNotice(
      existing: running,
      newText: 'Reading',
      startMs: _at(15),
      formatTime: (ms) =>
          '${DateTime.fromMillisecondsSinceEpoch(ms).hour}:'
          '${DateTime.fromMillisecondsSinceEpoch(ms).minute.toString().padLeft(2, '0')}',
    );
    expect(n.title, "Already logging 'Deep work'");
    expect(n.body, contains('from 9:00'));
    expect(n.body, contains("'Reading' will end it at 9:15"));
  });
}
