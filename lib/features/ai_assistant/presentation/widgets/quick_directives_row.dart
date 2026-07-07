import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/quick_directives_provider.dart';

import '../../../../core/presentation/app_colors.dart';

class QuickDirective {
  const QuickDirective({required this.label, required this.startingText});

  final String label;
  final String startingText;
}

const List<QuickDirective> kDefaultDirectives = [
  QuickDirective(label: 'Add task', startingText: 'Add a task '),
  QuickDirective(label: 'Create goal', startingText: 'Create a goal '),
  QuickDirective(label: 'Move schedule', startingText: 'Move my '),
  QuickDirective(label: 'Focus mode', startingText: 'Enable focus mode '),
];

class QuickDirectivesRow extends ConsumerWidget {
  const QuickDirectivesRow({super.key, required this.onSelected});

  final void Function(String startingText) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDirectives = ref.watch(quickDirectivesProvider);

    final directives = asyncDirectives.when(
      data: (list) => list,
      loading: () => null, // show shimmer
      error: (err, stack) => kDefaultDirectives,
    );

    return SizedBox(
      height: 36,
      child: directives == null
          ? _ShimmerRow()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: directives.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = directives[i];
                return _DirectiveChip(
                  label: d.label,
                  onTap: () => onSelected(d.startingText),
                );
              },
            ),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────

class _ShimmerRow extends StatefulWidget {
  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) {
        final alpha = (0.08 + 0.10 * _anim.value);
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          separatorBuilder: (c, i) => const SizedBox(width: 8),
          itemBuilder: (c, i) => Container(
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      },
    );
  }
}

// ─── Chip widget ──────────────────────────────────────────────────────────────

class _DirectiveChip extends StatelessWidget {
  const _DirectiveChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSoft,
          ),
        ),
      ),
    );
  }
}
