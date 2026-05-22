import 'package:flutter/material.dart';

const List<String> kDefaultSuggestedPrompts = [
  'Add a workout at 5AM',
  'Move my study session tomorrow',
];

class SuggestedPromptsSection extends StatelessWidget {
  const SuggestedPromptsSection({
    super.key,
    required this.onSelected,
    this.prompts = kDefaultSuggestedPrompts,
  });

  final void Function(String prompt) onSelected;
  final List<String> prompts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUGGESTED PROMPTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.10 * 11,
              color: Color(0xFFADAAAA),
            ),
          ),
          const SizedBox(height: 10),
          ...prompts.map((p) => _PromptCard(prompt: p, onTap: () => onSelected(p))),
        ],
      ),
    );
  }
}

class _PromptCard extends StatefulWidget {
  const _PromptCard({required this.prompt, required this.onTap});

  final String prompt;
  final VoidCallback onTap;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapCancel: () => _controller.forward(),
        onTap: () {
          _controller.forward();
          widget.onTap();
        },
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF201F1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '"${widget.prompt}"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                ),
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: Color(0xFFADAAAA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
