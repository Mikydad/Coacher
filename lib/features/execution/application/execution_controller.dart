import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/stable_id.dart';
import '../data/execution_repository.dart';
import '../data/timer_runtime_cache.dart';
import '../domain/models/timer_session.dart';
import '../domain/task_timer_engine.dart';

class ExecutionState {
  const ExecutionState({
    required this.targetType,
    required this.taskId,
    required this.blockId,
    required this.taskLabel,
    required this.blockLabel,
    required this.phase,
    required this.elapsed,
    required this.readyToScore,
  });

  final TimerSessionTargetType targetType;
  final String taskId;
  final String blockId;
  final String taskLabel;
  final String blockLabel;
  final ExecutionPhase phase;
  final Duration elapsed;
  final bool readyToScore;

  ExecutionState copyWith({
    TimerSessionTargetType? targetType,
    String? taskId,
    String? blockId,
    String? taskLabel,
    String? blockLabel,
    ExecutionPhase? phase,
    Duration? elapsed,
    bool? readyToScore,
  }) {
    return ExecutionState(
      targetType: targetType ?? this.targetType,
      taskId: taskId ?? this.taskId,
      blockId: blockId ?? this.blockId,
      taskLabel: taskLabel ?? this.taskLabel,
      blockLabel: blockLabel ?? this.blockLabel,
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
           targetType: TimerSessionTargetType.task,
           taskId: initialTaskId,
           blockId: '',
           taskLabel: initialTaskLabel,
           blockLabel: '',
           phase: ExecutionPhase.notStarted,
           elapsed: Duration.zero,
           readyToScore: false,
         ),
       ) {
    _sub = _engine.stream.listen((snapshot) {
      state = state.copyWith(phase: snapshot.phase, elapsed: snapshot.elapsed);
      unawaited(
        runtimeCache.save(
          targetType: state.targetType,
          taskId: state.taskId,
          blockId: state.blockId,
          label: state.targetType == TimerSessionTargetType.task
              ? state.taskLabel
              : state.blockLabel,
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
    final targetType = TimerSessionTargetTypeStorage.fromStorage(
      data['targetType'] as String?,
    );
    final taskId = data['taskId'] as String?;
    final blockId = data['blockId'] as String?;
    if (targetType == TimerSessionTargetType.task && taskId != state.taskId) return;
    if (targetType == TimerSessionTargetType.block && blockId != state.blockId) return;
    final phaseName = data['phase'] as String?;
    if (phaseName == null) return;
    final phase = ExecutionPhase.values.byName(phaseName);
    final elapsed = Duration(milliseconds: (data['elapsedMs'] as int?) ?? 0);
    final runningSinceMs = data['runningSinceMs'] as int?;
    state = state.copyWith(
      targetType: targetType,
      taskId: taskId ?? state.taskId,
      blockId: blockId ?? state.blockId,
      taskLabel: targetType == TimerSessionTargetType.task
          ? (data['label'] as String? ?? state.taskLabel)
          : state.taskLabel,
      blockLabel: targetType == TimerSessionTargetType.block
          ? (data['label'] as String? ?? state.blockLabel)
          : state.blockLabel,
    );
    _engine.restore(
      phase: phase,
      elapsed: elapsed,
      runningSince: runningSinceMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(runningSinceMs),
    );
  }

  void setTask({required String id, required String label}) {
    state = state.copyWith(
      targetType: TimerSessionTargetType.task,
      taskId: id,
      taskLabel: label,
      readyToScore: false,
    );
    _engine.restore(phase: ExecutionPhase.notStarted, elapsed: Duration.zero);
  }

  void setBlock({required String id, required String label}) {
    state = state.copyWith(
      targetType: TimerSessionTargetType.block,
      blockId: id,
      blockLabel: label,
      readyToScore: false,
    );
    _engine.restore(phase: ExecutionPhase.notStarted, elapsed: Duration.zero);
  }

  void start() => _engine.start();
  void pause() => _engine.pause();
  void resume() => _engine.resume();

  Future<void> stopAndPersist() async {
    final snapshot = _engine.stop();
    final now = DateTime.now().millisecondsSinceEpoch;
    final session = switch (state.targetType) {
      TimerSessionTargetType.task => TimerSession(
        id: StableId.generate('session'),
        targetType: TimerSessionTargetType.task,
        taskId: state.taskId,
        startedAtMs: now - snapshot.elapsed.inMilliseconds,
        endedAtMs: now,
        elapsedSeconds: snapshot.elapsed.inSeconds,
        createdAtMs: now,
        updatedAtMs: now,
      ),
      TimerSessionTargetType.block => TimerSession(
        id: StableId.generate('session'),
        targetType: TimerSessionTargetType.block,
        blockId: state.blockId,
        startedAtMs: now - snapshot.elapsed.inMilliseconds,
        endedAtMs: now,
        elapsedSeconds: snapshot.elapsed.inSeconds,
        createdAtMs: now,
        updatedAtMs: now,
      ),
    };
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
