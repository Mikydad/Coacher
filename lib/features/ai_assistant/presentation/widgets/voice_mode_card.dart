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
    this.onExpand,
  });

  final VoiceModeController controller;
  final VoidCallback onExit;

  /// Re-enters the immersive full-screen stage (voice keeps running).
  final VoidCallback? onExpand;

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
                  if (onExpand != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onExpand,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.open_in_full_rounded,
                          size: 16,
                          color: AppColors.fg70,
                        ),
                      ),
                    ),
                  if (onExpand != null) const SizedBox(width: 8),
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

  String _statusLabel(VoiceModePhase phase) => _voicePhaseLabel(phase);

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

String _voicePhaseLabel(VoiceModePhase phase) => switch (phase) {
  VoiceModePhase.listening => 'LISTENING',
  VoiceModePhase.thinking => 'THINKING…',
  VoiceModePhase.speaking => 'SPEAKING — TAP TO INTERRUPT',
  VoiceModePhase.idle => 'VOICE MODE — PAUSED',
};

/// The full-screen Voice Mode stage (ChatGPT-voice-style, our design):
/// the whole Coach sheet at full extent shows only the breathing orb and a
/// status line — no transcript, no thread. Swipe down (or the chevron) to
/// minimize into the compact [VoiceModeCard] with the conversation visible;
/// the voice loop keeps running. X ends Voice Mode and returns to the
/// typed composer. Still the one Coach surface — this is a presentation of
/// the sheet's full stage, not a new screen.
class VoiceImmersiveStage extends StatelessWidget {
  const VoiceImmersiveStage({
    super.key,
    required this.controller,
    required this.onMinimize,
    required this.onExit,
    required this.onExitToType,
    this.sheetScrollController,
  });

  final VoiceModeController controller;

  /// Collapse to the compact card — voice keeps running.
  final VoidCallback onMinimize;

  /// End Voice Mode entirely (back to the typed composer).
  final VoidCallback onExit;

  /// End Voice Mode and focus the text input ("type instead").
  final VoidCallback onExitToType;

  /// The DraggableScrollableSheet-provided controller (sheet mode).
  ///
  /// MUST be attached to a scrollable inside the sheet's child tree:
  /// `DraggableScrollableController.isAttached` requires the sheet's inner
  /// scroll controller to have clients, so replacing the thread with a
  /// scrollable-free stage froze the sheet mid-animation and made every
  /// controller call throw "not attached". Hosting the stage in a
  /// viewport-filling scrollable also gives swipe-down-to-minimize the
  /// sheet's NATIVE drag mechanics for free.
  final ScrollController? sheetScrollController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final phase = controller.phase;
        final idleHint = phase == VoiceModePhase.idle
            ? (controller.statusMessage ?? 'Tap the orb to talk.')
            : null;
        final content = Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 16),
                  _RoundIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: 'Minimize',
                    onTap: onMinimize,
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.onOrbTap,
                child: _VoiceOrb(phase: phase, size: 220),
              ),
              const SizedBox(height: 32),
              Text(
                _voicePhaseLabel(phase),
                style: TextStyle(
                  color: AppColors.fg54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: idleHint == null
                    ? const SizedBox(height: 24)
                    : Padding(
                        key: ValueKey(idleHint),
                        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                        child: Text(
                          idleHint,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundIconButton(
                      icon: Icons.keyboard_alt_outlined,
                      tooltip: 'Type instead',
                      onTap: onExitToType,
                    ),
                    _RoundIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'End voice mode',
                      onTap: onExit,
                      prominent: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        final scroll = sheetScrollController;
        if (scroll == null) return content;
        // Viewport-filling, zero-overflow scrollable: keeps the sheet
        // controller attached and lets a downward drag anywhere on the
        // stage resize the sheet (which is how "swipe down to minimize"
        // reaches the extent listener in the screen state).
        return LayoutBuilder(
          // The floor keeps the stage from overflow-striping while the
          // sheet animates through short extents; the scrollable absorbs
          // the difference until full height is reached.
          builder: (context, constraints) => SingleChildScrollView(
            controller: scroll,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight.clamp(460.0, double.infinity),
              width: constraints.maxWidth,
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.prominent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final size = prominent ? 56.0 : 44.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: prominent ? AppColors.fg : AppColors.inkElevated,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: prominent ? 26 : 22,
              color: prominent ? AppColors.ink : AppColors.fg70,
            ),
          ),
        ),
      ),
    );
  }
}

/// Phase-colored breathing orb. Pulses while listening (mic open) and
/// speaking (audio out); still while thinking or paused.
class _VoiceOrb extends StatefulWidget {
  const _VoiceOrb({required this.phase, this.size = 88});

  final VoiceModePhase phase;

  /// Outer diameter — the card uses the default; the immersive stage
  /// renders it hero-sized. All internals scale proportionally.
  final double size;

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
    // Everything scales off the outer diameter so the card (88) and the
    // immersive stage (220) share one orb.
    final scale = widget.size / 88.0;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulse.value);
        final halo = (8.0 + 10.0 * t) * scale;
        return Container(
          width: widget.size,
          height: widget.size,
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
            width: (68 + 6 * t) * scale,
            height: (68 + 6 * t) * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.16),
              border: Border.all(color: _color.withValues(alpha: 0.75)),
            ),
            child: Icon(_icon, size: 28 * scale, color: _color),
          ),
        );
      },
    );
  }
}
