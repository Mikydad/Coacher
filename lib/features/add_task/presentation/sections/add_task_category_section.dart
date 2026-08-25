import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/presentation/bento_category_card.dart';
import '../../../planning/domain/sleep_task.dart';
import '../add_task_custom_category_dialog.dart';

// 'Plan' superseded 'Planning' (2026-07-15); older tasks may still carry
// the long value, so the icon/color maps keep a legacy alias.
const _categoryOptions = [
  'Study',
  'Fitness',
  'Work',
  'Personal',
  'Plan',
  kSleepTaskCategory,
];

/// Inline category picker (replaces the old full-screen category step):
/// a single horizontally scrolling line of mini bento cards, shown under
/// Notes. Tapping the selected card clears it — no category is a valid
/// choice — and a trailing Custom card opens the name dialog (showing the
/// chosen custom name once set). Selection flows back through
/// [onCategorySelected] (null = cleared) so the owning State's `setState`
/// stays the single write path.
class AddTaskCategorySection extends StatelessWidget {
  const AddTaskCategorySection({
    super.key,
    required this.category,
    required this.onCategorySelected,
  });

  final String? category;
  final ValueChanged<String?> onCategorySelected;

  /// Ink-drawn glyphs for the bento cards — the reference design uses clean
  /// line icons, not emoji.
  static IconData _categoryIcon(String label) => switch (label) {
    'Study' => CupertinoIcons.book_fill,
    'Fitness' => CupertinoIcons.flame_fill,
    'Work' => CupertinoIcons.briefcase_fill,
    'Personal' => CupertinoIcons.heart_fill,
    'Plan' || 'Planning' => CupertinoIcons.calendar,
    kSleepTaskCategory => CupertinoIcons.moon_fill,
    _ => CupertinoIcons.tag_fill,
  };

  /// Fixed bento color per category — bright in both themes, matching the
  /// mosaic these mini cards replace. Custom / unknown labels fall back to a
  /// soft neutral so the dark ink text stays readable.
  static Color _categoryColor(String label) => switch (label) {
    'Study' => BentoPalette.yellow,
    'Work' => BentoPalette.orange,
    'Plan' || 'Planning' => BentoPalette.green,
    'Fitness' => BentoPalette.purple,
    'Personal' => BentoPalette.blue,
    kSleepTaskCategory => BentoPalette.teal,
    _ => const Color(0xFFDADDE2),
  };

  Future<void> _promptCustomCategory(BuildContext context) async {
    final name = await showCustomCategoryDialog(context);
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    onCategorySelected(name.trim());
  }

  @override
  Widget build(BuildContext context) {
    final customActive =
        category != null && !_categoryOptions.contains(category);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final label in _categoryOptions) ...[
            _CategoryMiniCard(
              label,
              color: _categoryColor(label),
              icon: _categoryIcon(label),
              selected: category == label,
              onTap: () => onCategorySelected(category == label ? null : label),
            ),
            const SizedBox(width: 10),
          ],
          _CategoryMiniCard(
            customActive ? category! : 'Custom',
            color: _categoryColor(customActive ? category! : 'Custom'),
            icon: CupertinoIcons.tag_fill,
            selected: customActive,
            onTap: () => _promptCustomCategory(context),
          ),
        ],
      ),
    );
  }
}

/// One fixed-size mini bento chip for the inline category row: icon +
/// uppercase label on a single centered line (the row is too short for the
/// stacked bento layout). Selection is ADDITIVE, never an inversion
/// (2026-08-25): the old dark-ink flip vanished into the dark sheet, so a
/// picked category read as an empty gap. The chip keeps its vivid color
/// and gains three redundant cues — the icon becomes a check, an ink ring
/// draws inside the edge, and the chip glows in its own color.
class _CategoryMiniCard extends StatelessWidget {
  const _CategoryMiniCard(
    this.label, {
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const fg = BentoPalette.ink;
    return SizedBox(
      width: 73,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? fg : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? Icons.check_rounded : icon,
                    size: selected ? 14 : 13, color: fg),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: fg,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
