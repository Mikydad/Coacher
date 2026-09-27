import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timer/presentation/focus_stage.dart';
import '../application/stake_goal_check_in_bridge.dart';
import '../application/stakes_providers.dart';
import '../domain/models/stake_challenge.dart';

/// The stake focus timer (M-5 'timer' evidence source).
///
/// Deliberately minimal: start → run → stop. Stopping (or completing the
/// target) records the elapsed minutes as evidence — Isar first, outbox in
/// the background, fully offline-capable. The user's own pledge ("why") sits
/// on screen the whole session (PSY-2: hard to cheat past your own words).
class StakeTimerScreen extends ConsumerStatefulWidget {
  const StakeTimerScreen({super.key, required this.challenge});

  final StakeChallenge challenge;

  @override
  ConsumerState<StakeTimerScreen> createState() => _StakeTimerScreenState();
}

class _StakeTimerScreenState extends ConsumerState<StakeTimerScreen> {
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _saving = false;

  bool get _running => _ticker != null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _startedAt = DateTime.now().subtract(_elapsed);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(_startedAt!));
    });
    setState(() {});
  }

  void _pause() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {});
  }

  Future<void> _stopAndSave() async {
    _pause();
    final minutes = _elapsed.inMinutes;
    if (minutes < 1) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Under a minute'),
          content: const Text(
            'Sessions under a minute are not recorded. Leave anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep going'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave == true && mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    await ref
        .read(stakesRepositoryProvider)
        .addEvidence(
          challengeId: widget.challenge.id,
          unitIndex: widget.challenge.todayUnitIndex,
          amount: minutes,
          source: 'timer',
          recordedAtMs: _startedAt!.millisecondsSinceEpoch,
        );
    await ref
        .read(stakeGoalCheckInBridgeProvider)
        .mirrorEvidence(challenge: widget.challenge, amount: minutes);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.challenge.frozenGoal.unitTarget;
    final mercy = widget.challenge.mercyUnitTarget;
    final minutes = _elapsed.inMinutes;
    final progress = (minutes / target).clamp(0.0, 1.0);
    final metMercy = minutes >= mercy;

    return PopScope(
      canPop: !_running && _elapsed == Duration.zero,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopAndSave();
      },
      child: FocusStageScaffold(
        title: 'Focus',
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 8),
                  FocusRing(
                    size: focusRingSize(constraints),
                    progress: progress,
                    timeText: _format(_elapsed),
                    statusLabel: _running
                        ? 'Focus'
                        : _elapsed == Duration.zero
                        ? 'Ready'
                        : 'Paused',
                    statusIcon: !_running && _elapsed > Duration.zero
                        ? Icons.pause_rounded
                        : Icons.track_changes_rounded,
                    chipLabel: 'of $target min · counts from $mercy',
                    color: metMercy ? FocusColors.success : null,
                    dimmed: !_running && _elapsed > Duration.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: FocusControls(
                      primary: FocusRoundButton(
                        primary: true,
                        icon: _running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        label: _running
                            ? 'Pause'
                            : _elapsed == Duration.zero
                            ? 'Start'
                            : 'Resume',
                        onPressed: _saving
                            ? null
                            : _running
                            ? _pause
                            : _start,
                      ),
                      secondary: FocusRoundButton(
                        icon: Icons.check_rounded,
                        label: 'Finish & record',
                        busy: _saving,
                        onPressed: _saving || _elapsed == Duration.zero
                            ? null
                            : _stopAndSave,
                      ),
                    ),
                  ),
                  FocusWorkingOnCard(
                    title: widget.challenge.frozenGoal.title,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
