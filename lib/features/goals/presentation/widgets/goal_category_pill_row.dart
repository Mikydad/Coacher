import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../add_task/presentation/add_task_custom_category_dialog.dart';
import '../../domain/models/goal_categories.dart';
import 'goal_editor_widgets.dart';

/// One horizontal row of category pills (Miko, 2026-09-24): "+ New" first,
/// then [categories]. Used by the New-goal picker (categories not already
/// on the mosaic, plus the user's own) and by the goal editor (all of
/// them), so picking a category looks the same in both places.
class GoalCategoryPillRow extends StatelessWidget {
  const GoalCategoryPillRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onCreated,
  });

  final List<String> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// A freshly typed custom category name (trimmed, non-empty).
  final ValueChanged<String> onCreated;

  Future<void> _create(BuildContext context) async {
    final name = await showCustomCategoryDialog(context);
    if (name == null || name.trim().isEmpty) return;
    onCreated(name.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          GoalCategoryPill(
            key: const ValueKey('goal_category_new'),
            label: 'New',
            icon: Icons.add,
            selected: false,
            onTap: () => _create(context),
          ),
          for (final id in categories) ...[
            const SizedBox(width: 8),
            GoalCategoryPill(
              key: ValueKey('goal_category_$id'),
              label: GoalCategories.label(id),
              selected: selectedId == id,
              onTap: () => onSelected(id),
            ),
          ],
        ],
      ),
    );
  }
}

/// The editor's sector-chip look, made public for the row.
class GoalCategoryPill extends StatelessWidget {
  const GoalCategoryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? GoalEditorColors.lime : GoalEditorColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: selected ? null : Border.all(color: GoalEditorColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: Colors.black),
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.fg70),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : AppColors.fg70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
