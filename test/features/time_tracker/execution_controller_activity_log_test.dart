import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/execution/application/execution_controller.dart';
import 'package:sidepal/features/execution/data/execution_repository.dart';
import 'package:sidepal/features/execution/data/timer_runtime_cache.dart';
import 'package:sidepal/features/execution/domain/models/timer_session.dart';
import 'package:sidepal/features/focus/data/focus_resume_store.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';

/// Decision 14 + F1: a focus session auto-logs a timer-sourced activity
/// event on a FRESH start (never on resume) and writes the explicit end on
/// stop; the id survives a crash-restore through the runtime cache.

class _FakeExecutionRepository implements ExecutionRepository {
  final sessions = <TimerSession>[];
  @override
  Future<List<TimerSession>> getSessionsForBlock(String blockId) async => [];
  @override
  Future<List<TimerSession>> getSessionsForTask(String taskId) async => [];
  @override
  Future<void> upsertSession(TimerSession session) async =>
      sessions.add(session);
}

class _FakeFocusResumeStore implements FocusResumeStore {
  @override
  Future<void> saveElapsed(String taskId, Duration elapsed) async {}
  @override
  Future<Duration?> readElapsed(String taskId) async => null;
  @override
  Future<void> clear(String taskId) async {}
}

class _FakeTimerRuntimeCache extends TimerRuntimeCache {
  _FakeTimerRuntimeCache({Map<String, dynamic>? initialData}) : data = initialData;
  Map<String, dynamic>? data;

  @override
  Future<void> save({
    required TimerSessionTargetType targetType,
    required String taskId,
    required String blockId,
    required String label,
    required phase,
    required Duration elapsed,
    DateTime? runningSince,
    int? targetDurationMinutes,
    String? activityEventId,
  }) async {
    data = {
      'targetType': targetType.storageValue,
      'taskId': taskId,
      'blockId': blockId,
      'label': label,
      'phase': phase.name,
      'elapsedMs': elapsed.inMilliseconds,
      'runningSinceMs': runningSince?.millisecondsSinceEpoch,
      'targetDurationMinutes': targetDurationMinutes,
      'activityEventId': ?activityEventId,
    };
  }

  @override
  Future<Map<String, dynamic>?> load() async => data;

  @override
  Future<void> clear() async => data = null;
}

class _MemoryActivityRepo extends ActivityEventRepository {
  final Map<String, ActivityEvent> rows = {};
  final List<String> ends = [];

  @override
  Future<ActivityEvent> upsert(ActivityEvent event) async {
    rows[event.id] = event;
    return event;
  }

  @override
  Future<ActivityEvent?> setEnd(String id, int endedAtMs) async {
    ends.add(id);
    final c = rows[id];
    if (c == null) return null;
    final e = c.copyWith(endedAtMs: endedAtMs);
    rows[id] = e;
    return e;
  }
}

ExecutionController _controller(
  _MemoryActivityRepo repo, {
  _FakeTimerRuntimeCache? cache,
  ActivityEventRepository? override,
}) => ExecutionController(
  repository: _FakeExecutionRepository(),
  runtimeCache: cache ?? _FakeTimerRuntimeCache(),
  resumeStore: _FakeFocusResumeStore(),
  initialTaskId: 'task_1',
  initialTaskLabel: 'Work on SidePal',
  activityEvents: override ?? repo,
);

void main() {
  test('fresh start logs a timer-sourced event with the task title', () {
    fakeAsync((async) {
      final repo = _MemoryActivityRepo();
      final cache = _FakeTimerRuntimeCache();
      final c = _controller(repo, cache: cache);
      async.flushMicrotasks();
      c.setTask(id: 'task_1', label: 'Work on SidePal', durationMinutes: 45);
      c.start();
      async.flushMicrotasks();

      expect(repo.rows.length, 1);
      final e = repo.rows.values.single;
      expect(e.text, 'Work on SidePal');
      expect(e.source, ActivitySource.timer);
      expect(e.sourceEntityId, 'task_1');
      expect(e.intendedMinutes, 45);
      expect(c.activityEventIdForTests, e.id);
      expect(cache.data?['activityEventId'], e.id);

      // Pause + resume must NOT log a second event.
      async.elapse(const Duration(seconds: 5));
      c.pause();
      async.flushMicrotasks();
      c.resume();
      async.flushMicrotasks();
      expect(repo.rows.length, 1);

      // Stop writes the explicit end and clears the id.
      async.elapse(const Duration(minutes: 1));
      c.stopAndPersist();
      async.flushMicrotasks();
      expect(repo.ends, [e.id]);
      expect(repo.rows[e.id]!.endedAtMs, isNotNull);
      expect(c.activityEventIdForTests, isNull);
      c.dispose();
    });
  });

  test('a zero target duration does not become an intended duration', () {
    fakeAsync((async) {
      final repo = _MemoryActivityRepo();
      final c = _controller(repo);
      async.flushMicrotasks();
      c.setTask(id: 'task_1', label: 'Quick', durationMinutes: 0);
      c.start();
      async.flushMicrotasks();
      expect(repo.rows.values.single.intendedMinutes, isNull);
      c.dispose();
    });
  });

  test('crash-restore keeps the id so stop still ends the right event', () {
    fakeAsync((async) {
      final repo = _MemoryActivityRepo();
      final seeded = ActivityEvent.create(
        text: 'Work on SidePal',
        startedAtMs: DateTime.now().millisecondsSinceEpoch - 60000,
        nowMs: 1,
        source: ActivitySource.timer,
        sourceEntityId: 'task_1',
      );
      repo.rows[seeded.id] = seeded;
      final cache = _FakeTimerRuntimeCache(
        initialData: {
          'targetType': TimerSessionTargetType.task.storageValue,
          'taskId': 'task_1',
          'blockId': '',
          'label': 'Work on SidePal',
          'phase': 'inProgress',
          'elapsedMs': 60000,
          'runningSinceMs': DateTime.now().millisecondsSinceEpoch - 60000,
          'targetDurationMinutes': null,
          'activityEventId': seeded.id,
        },
      );
      final c = _controller(repo, cache: cache);
      async.flushMicrotasks();
      expect(c.activityEventIdForTests, seeded.id);
      // Restored session is in progress → start() is not a fresh start.
      c.stopAndPersist();
      async.flushMicrotasks();
      expect(repo.ends, [seeded.id]);
      expect(repo.rows.length, 1, reason: 'no second event was logged');
      c.dispose();
    });
  });

  test('without a repository the controller is unchanged', () {
    fakeAsync((async) {
      final c = ExecutionController(
        repository: _FakeExecutionRepository(),
        runtimeCache: _FakeTimerRuntimeCache(),
        resumeStore: _FakeFocusResumeStore(),
        initialTaskId: 'task_1',
        initialTaskLabel: 'Work',
      );
      async.flushMicrotasks();
      c.start();
      async.flushMicrotasks();
      expect(c.activityEventIdForTests, isNull);
      c.stopAndPersist();
      async.flushMicrotasks();
      c.dispose();
    });
  });
}
