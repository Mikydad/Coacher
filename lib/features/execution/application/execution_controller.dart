import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/stable_id.dart';
import '../../focus/data/focus_resume_store.dart';
import '../../time_tracker/data/activity_event_repository.dart';
import '../../time_tracker/domain/models/activity_event.dart';
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
    required this.targetDurationMinutes,
  });

  final TimerSessionTargetType targetType;
  final String taskId;
  final String blockId;
  final String taskLabel;
  final String blockLabel;
  final ExecutionPhase phase;
  final Duration elapsed;
  final bool readyToScore;
  final int? targetDurationMinutes;

  /// True while a task focus session is running or paused. Watch this via
  /// `select()` — `elapsed` changes every second, so watching the whole state
  /// rebuilds the subscriber once per tick for the entire session.
  bool get hasActiveFocusTask =>
      targetType == TimerSessionTargetType.task &&
      taskId.isNotEmpty &&
      (phase == ExecutionPhase.inProgress || phase == ExecutionPhase.paused);

  ExecutionState copyWith({
    TimerSessionTargetType? targetType,
    String? taskId,
    String? blockId,
    String? taskLabel,
    String? blockLabel,
    ExecutionPhase? phase,
    Duration? elapsed,
    bool? readyToScore,
    int? targetDurationMinutes,
    bool clearTargetDurationMinutes = false,
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
      targetDurationMinutes: clearTargetDurationMinutes
          ? null
          : targetDurationMinutes ?? this.targetDurationMinutes,
    );
  }
}

class ExecutionController extends StateNotifier<ExecutionState> {
  ExecutionController({
    required this.repository,
    required this.runtimeCache,
    required this.resumeStore,
    required String initialTaskId,
    required String initialTaskLabel,

    /// Time Tracker (decision 14): a focus session auto-logs a timer-sourced
    /// activity event on start and writes its explicit end on stop. Null
    /// keeps the controller byte-identical for tests and the no-op harness.
    this.activityEvents,
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
           targetDurationMinutes: null,
         ),
       ) {
    _sub = _engine.stream.listen((snapshot) {
      state = state.copyWith(phase: snapshot.phase, elapsed: snapshot.elapsed);
      _persistIfSessionShapeChanged(snapshot);
    });
    unawaited(_restoreFromCacheIfPossible());
  }

  /// Persists resume state only when the session "shape" changes (target,
  /// phase, label, duration) — never on per-second `elapsed` ticks. Elapsed
  /// is intentionally excluded from the signature: while running it is
  /// derivable at restore time from the saved `runningSince` timestamp, so
  /// writing it every tick bought no durability at the cost of continuous
  /// disk I/O for the whole session.
  void _persistIfSessionShapeChanged(TimerSnapshot snapshot) {
    final signature = [
      state.targetType.name,
      state.taskId,
      state.blockId,
      state.taskLabel,
      state.blockLabel,
      snapshot.phase.name,
      state.targetDurationMinutes,
      _activityEventId,
    ].join('|');
    if (signature == _lastSavedSignature) return;
    _lastSavedSignature = signature;
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
        runningSince: snapshot.phase == ExecutionPhase.inProgress
            ? DateTime.now()
            : null,
        targetDurationMinutes: state.targetDurationMinutes,
        activityEventId: _activityEventId,
      ),
    );
  }

  final ExecutionRepository repository;
  final TimerRuntimeCache runtimeCache;
  final FocusResumeStore resumeStore;
  final ActivityEventRepository? activityEvents;
  final TaskTimerEngine _engine;

  /// The activity event opened by [start] for this session (Time Tracker).
  String? _activityEventId;
  String? get activityEventIdForTests => _activityEventId;
  StreamSubscription<TimerSnapshot>? _sub;
  String? _lastSavedSignature;

  Future<void> _restoreFromCacheIfPossible() async {
    final data = await runtimeCache.load();
    if (data == null) return;
    final targetType = TimerSessionTargetTypeStorage.fromStorage(
      data['targetType'] as String?,
    );
    final taskId = data['taskId'] as String?;
    final blockId = data['blockId'] as String?;
    final phaseName = data['phase'] as String?;
    if (phaseName == null) return;
    final phase = ExecutionPhase.values.byName(phaseName);
    final elapsed = Duration(milliseconds: (data['elapsedMs'] as int?) ?? 0);
    final runningSinceMs = data['runningSinceMs'] as int?;
    _activityEventId = data['activityEventId'] as String?;
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
      targetDurationMinutes: (data['targetDurationMinutes'] as num?)?.toInt(),
    );
    _engine.restore(
      phase: phase,
      elapsed: elapsed,
      runningSince: runningSinceMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(runningSinceMs),
    );
  }

  void setTask({
    required String id,
    required String label,
    int? durationMinutes,
    Duration resumeElapsed = Duration.zero,
  }) {
    final sameRunningTask =
        state.targetType == TimerSessionTargetType.task &&
        state.taskId == id &&
        (state.phase == ExecutionPhase.inProgress ||
            state.phase == ExecutionPhase.paused);
    if (sameRunningTask) {
      state = state.copyWith(
        taskLabel: label,
        targetDurationMinutes: durationMinutes,
      );
      return;
    }
    state = state.copyWith(
      targetType: TimerSessionTargetType.task,
      taskId: id,
      taskLabel: label,
      readyToScore: false,
      targetDurationMinutes: durationMinutes,
    );
    _engine.restore(phase: ExecutionPhase.notStarted, elapsed: resumeElapsed);
  }

  void setBlock({required String id, required String label}) {
    state = state.copyWith(
      targetType: TimerSessionTargetType.block,
      blockId: id,
      blockLabel: label,
      readyToScore: false,
      clearTargetDurationMinutes: true,
    );
    _engine.restore(phase: ExecutionPhase.notStarted, elapsed: Duration.zero);
  }

  void start() {
    final fresh = state.phase == ExecutionPhase.notStarted;
    _engine.start();
    // A fresh start (not a resume) is a real "I'm doing this now" moment —
    // log it. Isar write, milliseconds; the timer UI never waits on it.
    if (fresh) unawaited(_logActivityStart());
  }

  Future<void> _logActivityStart() async {
    final repo = activityEvents;
    if (repo == null) return;
    final isTask = state.targetType == TimerSessionTargetType.task;
    final label = isTask ? state.taskLabel : state.blockLabel;
    if (label.trim().isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final target = state.targetDurationMinutes;
    try {
      final saved = await repo.upsert(
        ActivityEvent.create(
          text: label.trim().length > kActivityTextMaxChars
              ? label.trim().substring(0, kActivityTextMaxChars)
              : label,
          startedAtMs: now,
          nowMs: now,
          intendedMinutes: target != null && target > 0 ? target : null,
          source: ActivitySource.timer,
          sourceEntityId: isTask ? state.taskId : state.blockId,
        ),
      );
      _activityEventId = saved.id;
      // Re-persist the runtime cache with the id (shape changed).
      _lastSavedSignature = null;
      _persistIfSessionShapeChanged(
        TimerSnapshot(phase: state.phase, elapsed: state.elapsed),
      );
    } catch (e) {
      debugPrint('[ExecutionController] activity log failed: $e');
    }
  }

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
    // Time Tracker: the timer's exact end becomes the event's explicit end.
    final activityId = _activityEventId;
    _activityEventId = null;
    if (activityId != null) {
      unawaited(
        activityEvents?.setEnd(activityId, now).catchError((Object e) {
          debugPrint('[ExecutionController] activity end failed: $e');
          return null;
        }),
      );
    }
    if (state.targetType == TimerSessionTargetType.task &&
        state.taskId.isNotEmpty) {
      await resumeStore.saveElapsed(state.taskId, snapshot.elapsed);
    }
    await runtimeCache.clear();
    state = state.copyWith(readyToScore: true);
  }

  /// Clears the locally stored resume point for [taskId] (e.g. on full
  /// completion so a later re-add starts fresh).
  Future<void> clearResumePoint(String taskId) => resumeStore.clear(taskId);

  @override
  void dispose() {
    _sub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
