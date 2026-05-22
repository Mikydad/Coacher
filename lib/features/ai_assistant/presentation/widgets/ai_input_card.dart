import 'package:flutter/material.dart';

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
        color: const Color(0xFF262626),
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
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText: 'Plan a workout tomorrow…',
              hintStyle: TextStyle(
                color: Color(0xFFADAAAA),
                fontSize: 15,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            cursorColor: const Color(0xFF00E3FD),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mic button placeholder (wired in Epic 8 after speech_to_text added)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  size: 20,
                  color: Color(0xFFADAAAA),
                ),
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
                            ? const Color(0xFFBEFC00)
                            : const Color(0xFF3A3A3A),
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
                                  ? const Color(0xFF445D00)
                                  : const Color(0xFF666666),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: canSend
                                ? const Color(0xFF445D00)
                                : const Color(0xFF666666),
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
