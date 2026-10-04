import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/app/siri_log_activity.dart';
import 'package:sidepal/features/time_tracker/application/activity_reminder_service.dart';
import 'package:sidepal/features/time_tracker/application/time_tracker_actions.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';

class _MemoryRepo extends ActivityEventRepository {
  final List<ActivityEvent> saved = [];
  @override
  Future<ActivityEvent?> fetchLatestOnce() async =>
      saved.isEmpty ? null : saved.last;
  @override
  Future<ActivityEvent> upsert(ActivityEvent event) async {
    saved.add(event);
    return event;
  }
}

/// The test clock — shared by the logged event AND the reminder service.
/// The service refuses to arm a reminder whose fire time is already past
/// against ITS clock; left on the wall clock, this test passed on the
/// evening it was written (2026-09-12) and failed forever after.
final _now = DateTime(2026, 9, 12, 19, 42);

TimeTrackerActions _actions(_MemoryRepo repo, List<String> reminders) =>
    TimeTrackerActions(
      repository: repo,
      reminders: ActivityReminderService(
        evaluate: (i) async => reminders.add('schedule:${i.entityId}'),
        cancel: (id) async => reminders.add('cancel:$id'),
        now: () => _now,
      ),
    );

void main() {
  final now = _now;

  test('logs the text at now with a manual source', () async {
    final repo = _MemoryRepo();
    final reminders = <String>[];
    ActivityEvent? announced;
    final saved = await SiriLogActivity.handlePayload(
      {'text': '  Gym '},
      actions: _actions(repo, reminders),
      now: now,
      onLogged: (e) => announced = e,
    );
    expect(saved, isNotNull);
    expect(saved!.text, 'Gym');
    expect(saved.startedAtMs, now.millisecondsSinceEpoch);
    expect(saved.source, ActivitySource.manual);
    expect(saved.intendedMinutes, isNull);
    expect(announced?.id, saved.id);
    expect(reminders, isEmpty);
  });

  test('minutes become an intended duration and arm a reminder', () async {
    final repo = _MemoryRepo();
    final reminders = <String>[];
    final saved = await SiriLogActivity.handlePayload(
      {'text': 'Study Flutter', 'minutes': 30},
      actions: _actions(repo, reminders),
      now: now,
    );
    expect(saved!.intendedMinutes, 30);
    expect(reminders, ['schedule:${saved.id}']);
  });

  test('out-of-range minutes are ignored, not rejected', () async {
    final repo = _MemoryRepo();
    final saved = await SiriLogActivity.handlePayload(
      {'text': 'Nap', 'minutes': 5000},
      actions: _actions(repo, []),
      now: now,
    );
    expect(saved!.intendedMinutes, isNull);
  });

  test('empty text never logs — the sheet opens instead', () async {
    final repo = _MemoryRepo();
    var sheetOpened = false;
    final saved = await SiriLogActivity.handlePayload(
      {'text': '   '},
      actions: _actions(repo, []),
      now: now,
      onNeedsText: () => sheetOpened = true,
    );
    expect(saved, isNull);
    expect(repo.saved, isEmpty);
    expect(sheetOpened, isTrue);
  });

  test('over-long text is capped at 80 chars', () async {
    final repo = _MemoryRepo();
    final saved = await SiriLogActivity.handlePayload(
      {'text': 'a' * 120},
      actions: _actions(repo, []),
      now: now,
    );
    expect(saved!.text.length, kActivityTextMaxChars);
  });
}
