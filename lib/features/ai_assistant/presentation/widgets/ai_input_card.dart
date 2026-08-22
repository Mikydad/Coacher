import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/presentation/keyboard_dismiss.dart';

import '../../../../core/presentation/app_colors.dart';

class AiInputCard extends StatelessWidget {
  const AiInputCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isLoading,
    this.onVoiceModeRequested,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isLoading;

  /// Long-press on the mic enters Voice Mode (humanizing Phase 3);
  /// plain tap stays one-shot dictation. Null hides the affordance.
  final VoidCallback? onVoiceModeRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.inkElevated,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 4,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            onTapOutside: (_) => dismissKeyboard(context),
            style: TextStyle(fontSize: 15, color: AppColors.fg),
            decoration: InputDecoration(
              hintText: 'Ask about your schedule or tell me what to plan…',
              hintStyle: TextStyle(color: AppColors.textSoft, fontSize: 15),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            cursorColor: AppColors.cyan,
          ),
          const SizedBox(height: 10),
          // TextFieldTapRegion: the TextField's onTapOutside fires on
          // pointer-DOWN, so without this a press on the mic (or Send)
          // collapsed the keyboard instantly and yanked the whole composer
          // out from under the finger mid-hold (2026-08-22 bug batch).
          TextFieldTapRegion(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _VoiceInputButton(
                  controller: controller,
                  enabled: !isLoading,
                  onVoiceModeRequested: onVoiceModeRequested,
                ),
                // Send button
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context2, value, child2) {
                    final canSend = value.text.trim().isNotEmpty && !isLoading;
                    return GestureDetector(
                      onTap: canSend ? onSend : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: canSend
                              ? AppColors.accentBright
                              : AppColors.gray3A,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SEND',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: canSend
                                    ? AppColors.accentDeep
                                    : AppColors.textFaint,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: canSend
                                  ? AppColors.accentDeep
                                  : AppColors.textFaint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap-to-dictate mic button. Streams recognised words into [controller] so
/// the user can review the text before sending. Long-press enters Voice
/// Mode when [onVoiceModeRequested] is provided.
class _VoiceInputButton extends StatefulWidget {
  const _VoiceInputButton({
    required this.controller,
    required this.enabled,
    this.onVoiceModeRequested,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onVoiceModeRequested;

  @override
  State<_VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<_VoiceInputButton> {
  final SpeechToText _speech = SpeechToText();
  bool _initialised = false;
  bool _available = false;
  bool _listening = false;
  String _baseText = '';

  @override
  void dispose() {
    _holdTimer?.cancel();
    if (_listening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_initialised) {
      _available = await _speech.initialize(
        onStatus: _onStatus,
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      _initialised = true;
    }

    if (!_available) {
      if (mounted) {
        _showMessage(
          'Voice input is unavailable. Check microphone and speech '
          'permissions in Settings.',
        );
      }
      return;
    }

    _baseText = widget.controller.text;
    await _speech.listen(
      onResult: (result) {
        final recognised = result.recognizedWords;
        final needsSpace = _baseText.isNotEmpty && !_baseText.endsWith(' ');
        final combined = '$_baseText${needsSpace ? ' ' : ''}$recognised';
        widget.controller.value = TextEditingValue(
          text: combined,
          selection: TextSelection.collapsed(offset: combined.length),
        );
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
    if (mounted) setState(() => _listening = true);
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.inkCard),
    );
  }

  /// Hold-to-enter-Voice-Mode, hand-rolled instead of onLongPress so the
  /// press acknowledges INSTANTLY (glow + haptic on finger-down, stronger
  /// haptic at trigger) and fires faster than the stock 500ms — the old
  /// silent hold read as "nothing is happening" while the layout shifted
  /// (2026-08-22 bug batch).
  static const _kVoiceHold = Duration(milliseconds: 350);

  Timer? _holdTimer;
  bool _pressed = false;
  bool _voiceHoldFired = false;

  void _onPressDown() {
    _voiceHoldFired = false;
    setState(() => _pressed = true);
    HapticFeedback.selectionClick();
    if (widget.onVoiceModeRequested == null) return;
    _holdTimer = Timer(_kVoiceHold, () async {
      if (!mounted) return;
      _voiceHoldFired = true;
      setState(() => _pressed = false);
      HapticFeedback.mediumImpact();
      // Never enter Voice Mode with the dictation mic still open.
      if (_listening) {
        await _speech.stop();
        if (mounted) setState(() => _listening = false);
      }
      widget.onVoiceModeRequested!();
    });
  }

  void _onPressEnd({required bool wasTap}) {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_pressed && mounted) setState(() => _pressed = false);
    // A quick release is the dictation tap; after the hold fired, the
    // release is just the finger leaving.
    if (wasTap && !_voiceHoldFired) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.cyan;
    final active = _listening || _pressed;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _onPressDown() : null,
      onTap: widget.enabled ? () => _onPressEnd(wasTap: true) : null,
      onTapCancel: widget.enabled ? () => _onPressEnd(wasTap: false) : null,
      child: AnimatedScale(
        scale: _pressed ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.8)
                  : AppColors.fg.withValues(alpha: 0.12),
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: Icon(
            _listening || _pressed ? Icons.mic_rounded : Icons.mic_none_rounded,
            size: 20,
            color: active ? accent : AppColors.textSoft,
          ),
        ),
      ),
    );
  }
}
