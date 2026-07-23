import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../application/voice_mode_controller.dart';

/// The immersive Voice Mode state of the Coach sheet (humanizing Phase 3):
/// replaces the input card with a large phase-colored orb, a live
/// transcript, and a status line. The chat thread stays visible above —
/// one-surface rule, no new chat screen.
///
/// Orb tap is contextual (interrupt speech / finalize utterance / wake);
/// the X exits back to the typed input.
class VoiceModeCard extends StatelessWidget {
  const VoiceModeCard({
    super.key,
    required this.controller,
    required this.onExit,
  });

  final VoiceModeController controller;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final phase = controller.phase;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.inkElevated,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _statusLabel(phase),
                      style: TextStyle(
                        color: AppColors.fg54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onExit,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.fg70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: controller.onOrbTap,
                child: _VoiceOrb(phase: phase),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _bodyText(),
                  key: ValueKey(_bodyText()),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: controller.transcript.isEmpty
                        ? AppColors.textSoft
                        : AppColors.fg,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(VoiceModePhase phase) => switch (phase) {
    VoiceModePhase.listening => 'LISTENING',
    VoiceModePhase.thinking => 'THINKING…',
    VoiceModePhase.speaking => 'SPEAKING — TAP TO INTERRUPT',
    VoiceModePhase.idle => 'VOICE MODE — PAUSED',
  };

  String _bodyText() {
    final transcript = controller.transcript.trim();
    if (transcript.isNotEmpty) return transcript;
    return switch (controller.phase) {
      VoiceModePhase.listening => 'Say something…',
      VoiceModePhase.thinking => ' ',
      VoiceModePhase.speaking => ' ',
      VoiceModePhase.idle =>
        controller.statusMessage ?? 'Tap the orb to talk.',
    };
  }
}

/// Phase-colored breathing orb. Pulses while listening (mic open) and
/// speaking (audio out); still while thinking or paused.
class _VoiceOrb extends StatefulWidget {
  const _VoiceOrb({required this.phase});

  final VoiceModePhase phase;

  @override
  State<_VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<_VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _syncAnimation();
  }

  void _syncAnimation() {
    final animate =
        widget.phase == VoiceModePhase.listening ||
        widget.phase == VoiceModePhase.speaking;
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.phase) {
    VoiceModePhase.listening => AppColors.cyan,
    VoiceModePhase.thinking => AppColors.amber,
    VoiceModePhase.speaking => AppColors.accentBright,
    VoiceModePhase.idle => AppColors.fg54,
  };

  IconData get _icon => switch (widget.phase) {
    VoiceModePhase.listening => Icons.mic_rounded,
    VoiceModePhase.thinking => Icons.more_horiz_rounded,
    VoiceModePhase.speaking => Icons.graphic_eq_rounded,
    VoiceModePhase.idle => Icons.mic_none_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final halo = 8.0 + 10.0 * t;
        return Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.14 + 0.10 * t),
                blurRadius: halo * 2,
                spreadRadius: halo * 0.5,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 68 + 6 * t,
            height: 68 + 6 * t,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.16),
              border: Border.all(color: _color.withValues(alpha: 0.75)),
            ),
            child: Icon(_icon, size: 28, color: _color),
          ),
        );
      },
    );
  }
}
