import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/goals_providers.dart';
import '../../domain/models/goal_categories.dart';

import '../../../../core/presentation/app_colors.dart';

/// Horizontally scrollable category filter chips.
///
/// Replaces the previous bento-grid layout with a simpler, more mobile-friendly
/// single row that doesn't consume vertical space.
class CategoryChipRow extends ConsumerWidget {
  const CategoryChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(selectedGoalCategoryFilterProvider);

    final categories = [
      (id: null, label: 'All'),
      ...GoalCategories.all.map(
        (id) => (id: id as String?, label: GoalCategories.label(id)),
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = filter == cat.id;
          return _CategoryChip(
            label: cat.label,
            selected: selected,
            onTap: () {
              ref.read(selectedGoalCategoryFilterProvider.notifier).state =
                  selected ? null : cat.id;
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.dark2A2D32),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
