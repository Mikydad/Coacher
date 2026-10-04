import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/context_override/domain/models/interruption_level.dart';
import 'package:sidepal/features/reminders/application/notification_route_resolver.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_intent.dart';
import 'package:sidepal/features/time_tracker/application/activity_reminder_service.dart';
import 'package:sidepal/features/time_tracker/application/time_tracker_actions.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';

final _now = DateTime(2026, 9, 12, 19, 42);

ActivityEvent _event({
  String text = 'Study Flutter',
  int? intended,
  int? endMs,
  ActivitySource source = ActivitySource.manual,
  int? startMs,
  bool active = true,
}) => ActivityEvent.create(
  text: text,
  startedAtMs: startMs ?? _now.millisecondsSinceEpoch,
  nowMs: 1,
  intendedMinutes: intended,
  endedAtMs: endMs,
  source: source,
).copyWith(active: active);

class _Recorder {
  final List<ReminderIntent> scheduled = [];
  final List<String> cancelled = [];

  ActivityReminderService service({DateTime? now}) => ActivityReminderService(
    evaluate: (i) async => scheduled.add(i),
    cancel: (id) async => cancelled.add(id),
    now: () => now ?? _now,
  );
}

class _MemoryRepo extends ActivityEventRepository {
  final Map<String, ActivityEvent> rows = {};
  int clock = 100;

  @override
  Future<ActivityEvent?> fetchLatestOnce() async {
    final live = rows.values.where((e) => e.active).toList()
      ..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return live.isEmpty ? null : live.first;
  }

  @override
  Future<ActivityEvent?> getById(String id) async => rows[id];

  @override
  Future<ActivityEvent> upsert(ActivityEvent event) async {
    final stamped = event.copyWith(updatedAtMs: clock++);
    rows[stamped.id] = stamped;
    return stamped;
  }

  @override
  Future<void> softDelete(String id) async {
    final c = rows[id];
    if (c == null || !c.active) return;
    await upsert(c.copyWith(active: false));
  }

  @override
  Future<ActivityEvent?> setEnd(String id, int endedAtMs) async {
    final c = rows[id];
    if (c == null || !c.active || endedAtMs <= c.startedAtMs) return c;
    return upsert(c.copyWith(endedAtMs: endedAtMs));
  }
}

void main() {
  group('ActivityReminderService', () {
    test('schedules one low-interruption reminder at start + intended', () async {
      final r = _Recorder();
      final ok = await r.service().scheduleFor(_event(intended: 30));
      expect(ok, isTrue);
      final i = r.scheduled.single;
      expect(i.entityKind, ReminderEntityKinds.activity);
      expect(i.proposedAt, _now.add(const Duration(minutes: 30)));
      expect(i.bodyOverride, '30m are up. What are you doing now?');
      expect(i.importance, ActivityReminderService.importance);
      expect(i.enforcementMode, 'flexible');
    });

    test('hour copy', () {
      expect(
        ActivityReminderService.bodyFor(_event(intended: 60)),
        '1h are up. What are you doing now?',
      );
      expect(
        ActivityReminderService.bodyFor(_event(intended: 90)),
        '90m are up. What are you doing now?',
      );
    });

    test('skips: no intended, timer-sourced, explicit end, backdated past',
        () async {
      final r = _Recorder();
      final s = r.service();
      expect(await s.scheduleFor(_event()), isFalse);
      expect(
        await s.scheduleFor(_event(intended: 30, source: ActivitySource.timer)),
        isFalse,
      );
      expect(
        await s.scheduleFor(
          _event(intended: 30, endMs: _now.millisecondsSinceEpoch + 60000),
        ),
        isFalse,
      );
      expect(
        await s.scheduleFor(
          _event(
            intended: 30,
            startMs: _now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          ),
        ),
        isFalse,
      );
      expect(r.scheduled, isEmpty);
    });

    test('the activity route is stable per event and tap-routed', () {
      final intent = ReminderIntent(
        id: 'ri',
        entityId: 'act_1',
        entityKind: ReminderEntityKinds.activity,
        entityTitle: 'Study',
        proposedAt: _now,
        importance: 45,
        interruptionLevel: InterruptionLevel.low,
        enforcementMode: 'flexible',
        createdAtMs: 1,
      );
      final a = resolveNotificationRoute(intent);
      final b = resolveNotificationRoute(intent);
      expect(a.notifId, b.notifId);
      expect(a.payload, 'activity:act_1');
      expect(a.immediate, isFalse);
    });
  });

  group('TimeTrackerActions', () {
    test('log cancels the previous ongoing reminder and arms the new one',
        () async {
      final repo = _MemoryRepo();
      final r = _Recorder();
      final actions = TimeTrackerActions(repository: repo, reminders: r.service());

      final first = await actions.log(_event(text: 'Study', intended: 30));
      expect(r.scheduled.map((i) => i.entityId), [first.id]);
      expect(r.cancelled, isEmpty);

      final second = await actions.log(
        _event(
          text: 'YouTube',
          startMs: _now.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
        ),
      );
      expect(r.cancelled, [first.id]);
      // No intended duration on the second → nothing new armed.
      expect(r.scheduled.map((i) => i.entityId), [first.id]);
      expect(repo.rows.length, 2);
      expect(second.active, isTrue);
    });

    test('update cancels then re-arms; delete and end cancel', () async {
      final repo = _MemoryRepo();
      final r = _Recorder();
      final actions = TimeTrackerActions(repository: repo, reminders: r.service());
      final e = await actions.log(_event(intended: 30));
      r.scheduled.clear();

      await actions.update(e.copyWith(intendedMinutes: 45));
      expect(r.cancelled, [e.id]);
      expect(r.scheduled.single.proposedAt,
          _now.add(const Duration(minutes: 45)));

      r.cancelled.clear();
      await actions.end(e.id, _now.millisecondsSinceEpoch + 60000);
      expect(r.cancelled, [e.id]);
      expect(repo.rows[e.id]!.endedAtMs, isNotNull);

      r.cancelled.clear();
      await actions.delete(e.id);
      expect(r.cancelled, [e.id]);
      expect(repo.rows[e.id]!.active, isFalse);
    });
  });

  group('log ends the running previous entry (2026-09-24)', () {
    test('the previous open entry gets an explicit end at the new start',
        () async {
      final repo = _MemoryRepo();
      final rec = _Recorder();
      final actions = TimeTrackerActions(
        repository: repo,
        reminders: rec.service(),
      );
      final a = await actions.log(
        _event(text: 'A', startMs: _now.millisecondsSinceEpoch),
      );
      final bStart = _now.add(const Duration(minutes: 20)).millisecondsSinceEpoch;
      await actions.log(_event(text: 'B', startMs: bStart));
      expect(repo.rows[a.id]!.endedAtMs, bStart);
    });

    test('a backfilled entry that starts earlier leaves the running one open',
        () async {
      final repo = _MemoryRepo();
      final rec = _Recorder();
      final actions = TimeTrackerActions(
        repository: repo,
        reminders: rec.service(),
      );
      final a = await actions.log(
        _event(text: 'A', startMs: _now.millisecondsSinceEpoch),
      );
      final earlier = _now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch;
      await actions.log(
        _event(
          text: 'Earlier',
          startMs: earlier,
          endMs: _now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
        ),
      );
      expect(repo.rows[a.id]!.endedAtMs, isNull);
    });
  });
}

