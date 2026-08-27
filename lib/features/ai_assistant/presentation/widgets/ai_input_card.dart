import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../application/shared_speech_callbacks.dart';

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

  /// Opens conversational Voice Mode (humanizing Phase 3). Shown as its
  /// own labeled waveform button — dictation and conversation are two
  /// different acts and get two different buttons (2026-08-25; the old
  /// hidden long-press-on-the-mic entry was undiscoverable). Null hides
  /// the affordance.
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
            textCapitalization: TextCapitalization.sentences,
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
              children: [
                _DictationButton(controller: controller, enabled: !isLoading),
                if (onVoiceModeRequested != null) ...[
                  const SizedBox(width: 8),
                  _VoiceModeButton(
                    enabled: !isLoading,
                    onPressed: onVoiceModeRequested!,
                  ),
                ],
                const Spacer(),
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

/// Enters conversational Voice Mode with one tap. A waveform, not a mic —
/// the mic next door types for you; this one talks with you.
class _VoiceModeButton extends StatelessWidget {
  const _VoiceModeButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.cyan;
    return Tooltip(
      message: 'Voice conversation',
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed();
              }
            : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(Icons.graphic_eq_rounded, size: 20, color: accent),
        ),
      ),
    );
  }
}

/// Tap-to-dictate mic button. Streams recognised words into [controller] so
/// the user can review the text before sending. Dictation ONLY — Voice Mode
/// lives on the waveform button beside it.
class _DictationButton extends StatefulWidget {
  const _DictationButton({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  State<_DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<_DictationButton> {
  final SpeechToText _speech = SpeechToText();
  bool _initialised = false;
  bool _available = false;
  bool _listening = false;
  String _baseText = '';

  @override
  void dispose() {
    if (_listening) {
      _speech.stop();
    }
    SharedSpeechCallbacks.release(this);
    super.dispose();
  }

  void _onError() {
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    // Claim the singleton's callbacks (fix-wave Phase 4, §8 V1): after a
    // Voice Mode session the plugin's initialize() refused to re-register
    // them, so this button's lit state never reset on 'done'.
    SharedSpeechCallbacks.claim(
      this,
      speech: _speech,
      onStatus: _onStatus,
      onError: _onError,
    );
    if (!_initialised) {
      _available = await _speech.initialize(
        onStatus: SharedSpeechCallbacks.dispatchStatus,
        onError: SharedSpeechCallbacks.dispatchError,
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

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.cyan;
    return Tooltip(
      message: 'Dictate into the text box',
      child: GestureDetector(
        onTap: widget.enabled ? _toggle : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _listening
                ? accent.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: _listening
                  ? accent.withValues(alpha: 0.8)
                  : AppColors.fg.withValues(alpha: 0.12),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
            size: 20,
            color: _listening ? accent : AppColors.textSoft,
          ),
        ),
      ),
    );
  }
}
