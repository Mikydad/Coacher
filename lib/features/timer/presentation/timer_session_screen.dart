import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../execution/domain/task_timer_engine.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../scoring/presentation/score_task_dialog.dart';

class TimerSessionScreen extends ConsumerWidget {
  const TimerSessionScreen({super.key});

  static const routeName = '/timer';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionControllerProvider);
    final ctrl = ref.read(executionControllerProvider.notifier);
    final running = execState.phase == ExecutionPhase.inProgress;
    final paused = execState.phase == ExecutionPhase.paused;
    final elapsed = execState.elapsed;
    final mins = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hrs = elapsed.inHours;
    final timerText = hrs > 0 ? '${hrs.toString().padLeft(2, '0')}:$mins:$secs' : '$mins:$secs';

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
                execState.taskLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 34, fontStyle: FontStyle.italic),
              ),
            ),
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
                        ctrl.start();
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
                            final result = await ScoreTaskDialog.show(
                              context,
                              taskTitle: execState.taskLabel,
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
