import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/stable_id.dart';
import '../data/execution_repository.dart';
import '../data/timer_runtime_cache.dart';
import '../domain/models/timer_session.dart';
import '../domain/task_timer_engine.dart';

class ExecutionState {
  const ExecutionState({
    required this.taskId,
    required this.taskLabel,
    required this.phase,
    required this.elapsed,
    required this.readyToScore,
  });

  final String taskId;
  final String taskLabel;
  final ExecutionPhase phase;
  final Duration elapsed;
  final bool readyToScore;

  ExecutionState copyWith({
    String? taskId,
    String? taskLabel,
    ExecutionPhase? phase,
    Duration? elapsed,
    bool? readyToScore,
  }) {
    return ExecutionState(
      taskId: taskId ?? this.taskId,
      taskLabel: taskLabel ?? this.taskLabel,
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      readyToScore: readyToScore ?? this.readyToScore,
    );
  }
}

class ExecutionController extends StateNotifier<ExecutionState> {
  ExecutionController({
    required this.repository,
    required this.runtimeCache,
    required String initialTaskId,
    required String initialTaskLabel,
  }) : _engine = TaskTimerEngine(),
       super(
         ExecutionState(
           taskId: initialTaskId,
           taskLabel: initialTaskLabel,
           phase: ExecutionPhase.notStarted,
           elapsed: Duration.zero,
           readyToScore: false,
         ),
       ) {
    _sub = _engine.stream.listen((snapshot) {
      state = state.copyWith(phase: snapshot.phase, elapsed: snapshot.elapsed);
      unawaited(
        runtimeCache.save(
          taskId: state.taskId,
          phase: snapshot.phase,
          elapsed: snapshot.elapsed,
          runningSince: snapshot.phase == ExecutionPhase.inProgress ? DateTime.now() : null,
        ),
      );
    });
    unawaited(_restoreFromCacheIfPossible());
  }

  final ExecutionRepository repository;
  final TimerRuntimeCache runtimeCache;
  final TaskTimerEngine _engine;
  StreamSubscription<TimerSnapshot>? _sub;

  Future<void> _restoreFromCacheIfPossible() async {
    final data = await runtimeCache.load();
    if (data == null) return;
    final taskId = data['taskId'] as String?;
    if (taskId != state.taskId) return;
    final phaseName = data['phase'] as String?;
    if (phaseName == null) return;
    final phase = ExecutionPhase.values.byName(phaseName);
    final elapsed = Duration(milliseconds: (data['elapsedMs'] as int?) ?? 0);
    final runningSinceMs = data['runningSinceMs'] as int?;
    _engine.restore(
      phase: phase,
      elapsed: elapsed,
      runningSince: runningSinceMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(runningSinceMs),
    );
  }

  void setTask({required String id, required String label}) {
    state = state.copyWith(taskId: id, taskLabel: label, readyToScore: false);
    _engine.restore(phase: ExecutionPhase.notStarted, elapsed: Duration.zero);
  }

  void start() => _engine.start();
  void pause() => _engine.pause();
  void resume() => _engine.resume();

  Future<void> stopAndPersist() async {
    final snapshot = _engine.stop();
    final now = DateTime.now().millisecondsSinceEpoch;
    final session = TimerSession(
      id: StableId.generate('session'),
      taskId: state.taskId,
      startedAtMs: now - snapshot.elapsed.inMilliseconds,
      endedAtMs: now,
      elapsedSeconds: snapshot.elapsed.inSeconds,
      createdAtMs: now,
      updatedAtMs: now,
    );
    await repository.upsertSession(session);
    await runtimeCache.clear();
    state = state.copyWith(readyToScore: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
