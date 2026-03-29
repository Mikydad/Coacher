import 'package:coach_for_life/features/execution/application/execution_controller.dart';
import 'package:coach_for_life/features/execution/data/execution_repository.dart';
import 'package:coach_for_life/features/execution/data/timer_runtime_cache.dart';
import 'package:coach_for_life/features/execution/domain/models/timer_session.dart';
import 'package:coach_for_life/features/execution/domain/task_timer_engine.dart';
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

class _FakeTimerRuntimeCache extends TimerRuntimeCache {
  _FakeTimerRuntimeCache({Map<String, dynamic>? initialData}) : _data = initialData;

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
  }) async {
    _data = {
      'targetType': targetType.storageValue,
      'taskId': taskId,
      'blockId': blockId,
      'label': label,
      'phase': phase.name,
      'elapsedMs': elapsed.inMilliseconds,
      'runningSinceMs': runningSince?.millisecondsSinceEpoch,
    };
  }

  @override
  Future<Map<String, dynamic>?> load() async => _data;

  @override
  Future<void> clear() async {
    _data = null;
  }
}

void main() {
  test('setBlock + stopAndPersist writes block-target timer session', () async {
    final repo = _FakeExecutionRepository();
    final cache = _FakeTimerRuntimeCache();
    final ctrl = ExecutionController(
      repository: repo,
      runtimeCache: cache,
      initialTaskId: 'task1',
      initialTaskLabel: 'Task 1',
    );

    ctrl.setBlock(id: 'blockA', label: 'Morning Block');
    ctrl.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await ctrl.stopAndPersist();

    expect(repo.sessions, hasLength(1));
    final saved = repo.sessions.first;
    expect(saved.targetType, TimerSessionTargetType.block);
    expect(saved.blockId, 'blockA');
    expect(saved.taskId, isNull);
    expect(ctrl.state.readyToScore, isTrue);

    ctrl.dispose();
  });

  test('restores in-progress state from runtime cache on init', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cache = _FakeTimerRuntimeCache(
      initialData: {
        'targetType': TimerSessionTargetType.task.storageValue,
        'taskId': 'task1',
        'blockId': '',
        'label': 'Task 1',
        'phase': ExecutionPhase.inProgress.name,
        'elapsedMs': 60000,
        'runningSinceMs': now - 3000,
      },
    );
    final ctrl = ExecutionController(
      repository: _FakeExecutionRepository(),
      runtimeCache: cache,
      initialTaskId: 'task1',
      initialTaskLabel: 'Task 1',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ctrl.state.phase, ExecutionPhase.inProgress);
    expect(ctrl.state.elapsed.inMilliseconds, greaterThanOrEqualTo(60000));
    ctrl.dispose();
  });
}
