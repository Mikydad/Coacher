import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
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
              'Sessions under a minute are not recorded. Leave anyway?'),
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
    await ref.read(stakesRepositoryProvider).addEvidence(
          challengeId: widget.challenge.id,
          unitIndex: widget.challenge.todayUnitIndex,
          amount: minutes,
          source: 'timer',
          recordedAtMs: _startedAt!.millisecondsSinceEpoch,
        );
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
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const PageTitle('Focus'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: AppColors.fg12,
                      color:
                          metMercy ? AppColors.statusGreen : AppColors.accent,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _format(_elapsed),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            'of $target min · counts from $mercy',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                widget.challenge.frozenGoal.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : _running
                              ? _pause
                              : _start,
                      child: Text(_running
                          ? 'Pause'
                          : _elapsed == Duration.zero
                              ? 'Start'
                              : 'Resume'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _saving || _elapsed == Duration.zero ? null : _stopAndSave,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Finish & record'),
                    ),
                  ),
                ],
              ),
            ],
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
