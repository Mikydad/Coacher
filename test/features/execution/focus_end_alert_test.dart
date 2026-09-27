import 'package:sidepal/features/execution/application/execution_controller.dart';
import 'package:sidepal/features/execution/application/focus_end_alert.dart';
import 'package:sidepal/features/execution/data/execution_repository.dart';
import 'package:sidepal/features/execution/data/timer_runtime_cache.dart';
import 'package:sidepal/features/execution/domain/models/timer_session.dart';
import 'package:sidepal/features/focus/data/focus_resume_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExecutionRepository implements ExecutionRepository {
  final sessions = <TimerSession>[];

  @override
  Future<List<TimerSession>> getSessionsForBlock(String blockId) async =>
      sessions.where((s) => s.blockId == blockId).toList();

  @override
  Future<List<TimerSession>> getSessionsForTask(String taskId) async =>
      sessions.where((s) => s.taskId == taskId).toList();

  @override
  Future<void> upsertSession(TimerSession session) async {
    sessions.add(session);
  }
}

class _FakeFocusResumeStore implements FocusResumeStore {
  final Map<String, Duration> saved = {};

  @override
  Future<void> saveElapsed(String taskId, Duration elapsed) async {
    saved[taskId] = elapsed;
  }

  @override
  Future<Duration?> readElapsed(String taskId) async => saved[taskId];

  @override
  Future<void> clear(String taskId) async {
    saved.remove(taskId);
  }
}

class _FakeTimerRuntimeCache extends TimerRuntimeCache {
  _FakeTimerRuntimeCache({Map<String, dynamic>? initialData})
    : _data = initialData;

  Map<String, dynamic>? _data;

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
    _data = {
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
  Future<Map<String, dynamic>?> load() async => _data;

  @override
  Future<void> clear() async {
    _data = null;
  }
}

class _FakeEndAlert implements FocusEndAlertPort {
  final calls = <String>[];
  DateTime? armedAt;
  int? armedMinutes;
  String? armedLabel;

  @override
  Future<void> arm({
    required String taskLabel,
    required int targetMinutes,
    required DateTime at,
  }) async {
    calls.add('arm');
    armedAt = at;
    armedMinutes = targetMinutes;
    armedLabel = taskLabel;
  }

  @override
  Future<void> disarm() async => calls.add('disarm');
}

/// The "time's up" notification (2026-09-27): armed for the remaining time
/// on start/resume, disarmed on pause/stop/switch; never for open-ended.
void main() {
  late _FakeEndAlert alert;
  late ExecutionController ctrl;

  setUp(() {
    alert = _FakeEndAlert();
    ctrl = ExecutionController(
      repository: _FakeExecutionRepository(),
      runtimeCache: _FakeTimerRuntimeCache(),
      resumeStore: _FakeFocusResumeStore(),
      initialTaskId: '',
      initialTaskLabel: '',
      endAlert: alert,
    );
  });

  tearDown(() => ctrl.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('start arms at now + target; pause disarms; resume re-arms', () async {
    ctrl.setTask(id: 't1', label: 'Write', durationMinutes: 25);
    await settle();
    alert.calls.clear();

    final before = DateTime.now();
    ctrl.start();
    expect(alert.calls, ['arm']);
    expect(alert.armedLabel, 'Write');
    expect(alert.armedMinutes, 25);
    final delta = alert.armedAt!.difference(before);
    expect(delta.inSeconds, inInclusiveRange(25 * 60 - 1, 25 * 60 + 1));

    await settle();
    ctrl.pause();
    expect(alert.calls.last, 'disarm');

    await settle();
    ctrl.resume();
    expect(alert.calls.last, 'arm');

    await settle();
    await ctrl.stopAndPersist();
    expect(alert.calls.last, 'disarm');
  });

  test('a resumed task arms only for the time left', () async {
    ctrl.setTask(
      id: 't1',
      label: 'Write',
      durationMinutes: 30,
      resumeElapsed: const Duration(minutes: 10),
    );
    await settle();
    final before = DateTime.now();
    ctrl.start();
    final delta = alert.armedAt!.difference(before);
    expect(delta.inSeconds, inInclusiveRange(20 * 60 - 1, 20 * 60 + 1));
    await ctrl.stopAndPersist();
  });

  test('open-ended task (no duration) never arms', () async {
    ctrl.setTask(id: 't1', label: 'Write', durationMinutes: 0);
    await settle();
    ctrl.start();
    expect(alert.calls, isNot(contains('arm')));
    await ctrl.stopAndPersist();
  });

  test('switching to another task disarms', () async {
    ctrl.setTask(id: 't1', label: 'Write', durationMinutes: 25);
    await settle();
    alert.calls.clear();
    ctrl.setTask(id: 't2', label: 'Read', durationMinutes: 10);
    expect(alert.calls, ['disarm']);
  });
}
