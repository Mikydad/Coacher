import 'package:flutter/material.dart';
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isLoading;

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
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText: 'Ask about your schedule or tell me what to plan…',
              hintStyle: TextStyle(
                color: AppColors.textSoft,
                fontSize: 15,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            cursorColor: AppColors.cyan,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _VoiceInputButton(
                controller: controller,
                enabled: !isLoading,
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
        ],
      ),
    );
  }
}

/// Tap-to-dictate mic button. Streams recognised words into [controller] so
/// the user can review the text before sending.
class _VoiceInputButton extends StatefulWidget {
  const _VoiceInputButton({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

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
        final needsSpace =
            _baseText.isNotEmpty && !_baseText.endsWith(' ');
        final combined =
            '$_baseText${needsSpace ? ' ' : ''}$recognised';
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
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.inkCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.cyan;
    return GestureDetector(
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
                : Colors.white.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          size: 20,
          color: _listening ? accent : AppColors.textSoft,
        ),
      ),
    );
  }
}
