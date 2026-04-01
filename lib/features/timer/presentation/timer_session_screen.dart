import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../execution/application/execution_controller.dart';
import '../../execution/domain/task_timer_engine.dart';
import '../../execution/domain/models/timer_session.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../scoring/presentation/score_task_dialog.dart';

class TimerLaunchArgs {
  const TimerLaunchArgs({this.autoStartDelaySeconds});

  final int? autoStartDelaySeconds;
}

class TimerSessionScreen extends ConsumerStatefulWidget {
  const TimerSessionScreen({super.key, this.launchArgs});

  static const routeName = '/timer';

  final TimerLaunchArgs? launchArgs;

  @override
  ConsumerState<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends ConsumerState<TimerSessionScreen> {
  Timer? _autoStartTicker;
  int? _remainingAutoStartSeconds;
  bool _autoStartCancelled = false;

  @override
  void initState() {
    super.initState();
    final secs = widget.launchArgs?.autoStartDelaySeconds;
    if (secs != null && secs > 0) {
      _remainingAutoStartSeconds = secs;
      _autoStartTicker = Timer.periodic(const Duration(seconds: 1), (t) {
        final execState = ref.read(executionControllerProvider);
        if (_autoStartCancelled || execState.phase != ExecutionPhase.notStarted) {
          t.cancel();
          return;
        }
        final next = (_remainingAutoStartSeconds ?? 0) - 1;
        if (next <= 0) {
          t.cancel();
          _startSession(ref.read(executionControllerProvider));
          return;
        }
        if (mounted) {
          setState(() => _remainingAutoStartSeconds = next);
        }
      });
    }
  }

  @override
  void dispose() {
    _autoStartTicker?.cancel();
    super.dispose();
  }

  void _startSession(ExecutionState execState) {
    final ctrl = ref.read(executionControllerProvider.notifier);
    if (execState.phase != ExecutionPhase.notStarted) return;
    ctrl.start();
    if (execState.targetType == TimerSessionTargetType.task && execState.taskId.isNotEmpty) {
      unawaited(ref.read(reminderSyncServiceProvider).markTaskStarted(execState.taskId));
    }
    if (mounted) {
      setState(() {
        _remainingAutoStartSeconds = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionControllerProvider);
    final ctrl = ref.read(executionControllerProvider.notifier);
    final running = execState.phase == ExecutionPhase.inProgress;
    final paused = execState.phase == ExecutionPhase.paused;
    final elapsed = execState.elapsed;
    final activeLabel = execState.targetType == TimerSessionTargetType.task
        ? execState.taskLabel
        : execState.blockLabel;
    final mins = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hrs = elapsed.inHours;
    final timerText = hrs > 0 ? '${hrs.toString().padLeft(2, '0')}:$mins:$secs' : '$mins:$secs';

    final showAutoStart =
        execState.phase == ExecutionPhase.notStarted && !_autoStartCancelled && (_remainingAutoStartSeconds ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Quittr')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text('PHASE', style: TextStyle(letterSpacing: 3, color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('Deep Focus', style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0D10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF00E6FF).withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(timerText, style: const TextStyle(fontSize: 86, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2026),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(running ? 'FOCUS ACTIVE' : paused ? 'PAUSED' : 'READY'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text('Currently engaged in', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111317),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                activeLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 34, fontStyle: FontStyle.italic),
              ),
            ),
            if (showAutoStart) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2026),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Auto-starting in ${_remainingAutoStartSeconds}s',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _autoStartTicker?.cancel();
                        setState(() {
                          _autoStartCancelled = true;
                          _remainingAutoStartSeconds = null;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: running ? const Color(0xFF2B2D31) : const Color(0xFFB7FF00),
                      foregroundColor: running ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      if (running) {
                        ctrl.pause();
                      } else if (paused) {
                        ctrl.resume();
                      } else {
                        _autoStartTicker?.cancel();
                        _remainingAutoStartSeconds = null;
                        _startSession(execState);
                      }
                    },
                    icon: Icon(running ? Icons.pause_circle_outline : Icons.play_arrow_rounded),
                    label: Text(running ? 'Pause' : paused ? 'Resume' : 'Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: const Color(0xFF2B2D31),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: execState.phase == ExecutionPhase.notStarted
                        ? null
                        : () async {
                            await ctrl.stopAndPersist();
                            if (!context.mounted) return;
                            if (execState.targetType == TimerSessionTargetType.block) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Block timer session saved.')),
                              );
                              return;
                            }
                            final result = await ScoreTaskDialog.show(
                              context,
                              taskTitle: activeLabel,
                            );
                            if (!context.mounted || result == null) return;
                            await ref
                                .read(scoringControllerProvider)
                                .submit(
                                  taskId: execState.taskId,
                                  completionPercent: result.completionPercent,
                                  reason: result.reason,
                                );
                            final prev = ref.read(scoredTaskStatusesProvider);
                            ref.read(scoredTaskStatusesProvider.notifier).state = {
                              ...prev,
                              execState.taskId: result.completionPercent,
                            };
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.completionPercent == 100
                                        ? 'Task marked completed and score saved.'
                                        : 'Task marked partial (${result.completionPercent}%) and score saved.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            if (execState.readyToScore) ...[
              const SizedBox(height: 10),
              const Text(
                'Task is now marked as ready for scoring.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
