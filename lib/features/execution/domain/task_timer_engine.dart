import 'dart:async';

enum ExecutionPhase { notStarted, inProgress, paused, finished }

class TimerSnapshot {
  const TimerSnapshot({
    required this.phase,
    required this.elapsed,
  });

  final ExecutionPhase phase;
  final Duration elapsed;
}

class TaskTimerEngine {
  TaskTimerEngine();

  Duration _elapsed = Duration.zero;
  DateTime? _runningSince;
  ExecutionPhase _phase = ExecutionPhase.notStarted;
  Timer? _ticker;
  final StreamController<TimerSnapshot> _controller = StreamController.broadcast();

  Stream<TimerSnapshot> get stream => _controller.stream;
  TimerSnapshot get current => TimerSnapshot(phase: _phase, elapsed: _currentElapsed());

  void start() {
    if (_phase == ExecutionPhase.inProgress) return;
    if (_phase == ExecutionPhase.finished) {
      _elapsed = Duration.zero;
    }
    _phase = ExecutionPhase.inProgress;
    _runningSince = DateTime.now();
    _startTicker();
    _emit();
  }

  void pause() {
    if (_phase != ExecutionPhase.inProgress) return;
    _elapsed = _currentElapsed();
    _runningSince = null;
    _phase = ExecutionPhase.paused;
    _ticker?.cancel();
    _emit();
  }

  void resume() {
    if (_phase != ExecutionPhase.paused) return;
    _phase = ExecutionPhase.inProgress;
    _runningSince = DateTime.now();
    _startTicker();
    _emit();
  }

  TimerSnapshot stop() {
    if (_phase == ExecutionPhase.inProgress) {
      _elapsed = _currentElapsed();
    }
    _runningSince = null;
    _phase = ExecutionPhase.finished;
    _ticker?.cancel();
    _emit();
    return current;
  }

  void restore({
    required ExecutionPhase phase,
    required Duration elapsed,
    DateTime? runningSince,
  }) {
    _phase = phase;
    _elapsed = elapsed;
    _runningSince = runningSince;
    if (_phase == ExecutionPhase.inProgress) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
    _emit();
  }

  Duration _currentElapsed() {
    if (_runningSince == null) return _elapsed;
    return _elapsed + DateTime.now().difference(_runningSince!);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _emit());
  }

  void _emit() => _controller.add(current);

  void dispose() {
    _ticker?.cancel();
    _controller.close();
  }
}
