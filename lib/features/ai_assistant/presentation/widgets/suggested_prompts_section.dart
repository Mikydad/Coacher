import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/suggested_prompts_provider.dart';

import '../../../../core/presentation/app_colors.dart';

export '../../application/suggested_prompts_provider.dart'
    show kDefaultSuggestedPrompts;

class SuggestedPromptsSection extends ConsumerWidget {
  const SuggestedPromptsSection({
    super.key,
    required this.onSelected,
  });

  final void Function(String prompt) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrompts = ref.watch(suggestedPromptsProvider);

    final prompts = asyncPrompts.when(
      data: (list) => list,
      loading: () => null,
      error: (err, stack) => kDefaultSuggestedPrompts,
    );

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
              color: AppColors.textSoft,
            ),
          ),
          const SizedBox(height: 10),
          if (prompts == null)
            _ShimmerPrompts()
          else
            ...prompts.map(
              (p) => _PromptCard(prompt: p, onTap: () => onSelected(p)),
            ),
        ],
      ),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────

class _ShimmerPrompts extends StatefulWidget {
  @override
  State<_ShimmerPrompts> createState() => _ShimmerPromptsState();
}

class _ShimmerPromptsState extends State<_ShimmerPrompts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final alpha = 0.06 + 0.08 * _ctrl.value;
        return Column(
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Prompt card ──────────────────────────────────────────────────────────────

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
              color: AppColors.inkWarm,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '"${widget.prompt}"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grayBright,
                    ),
                  ),
                ),
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: AppColors.textSoft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
