import 'package:flutter/material.dart';

// ─── User bubble ─────────────────────────────────────────────────────────────

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF262B33),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Assistant bubble ─────────────────────────────────────────────────────────

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFADAAAA),
          ),
        ),
      ),
    );
  }
}

// ─── Loading indicator (thinking dots) ───────────────────────────────────────

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final begin = i * 0.2;
            final end = begin + 0.4;
            return AnimatedBuilder(
              animation: _controller,
              builder: (ctx, child) {
                final t = _controller.value;
                double opacity;
                if (t < begin) {
                  opacity = 0.3;
                } else if (t < end) {
                  opacity = 0.3 + 0.7 * ((t - begin) / 0.4);
                } else {
                  opacity = 1.0 - 0.7 * ((t - end) / (1.0 - end).clamp(0.01, 1.0));
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E3FD).withValues(alpha: opacity.clamp(0.3, 1.0)),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
