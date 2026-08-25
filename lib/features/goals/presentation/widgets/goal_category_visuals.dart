import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../domain/models/goal_categories.dart';
import '../../domain/models/user_goal.dart';

/// The three-level color recipe for a goal: its category's hand-tuned tone,
/// or one derived from the goal's own `colorHex` when it carries a custom
/// color (a raw hex would only give us one of the three levels).
GoalTone goalTone(UserGoal goal) {
  final hex = goal.colorHex;
  if (hex != null && hex.length == 6) {
    try {
      return GoalTone.fromSeed(
        Color(int.parse('FF$hex', radix: 16)),
        light: AppColors.isLight,
      );
    } catch (e) {
      debugPrint('goal_category_visuals: swallowed error: $e');
    }
  }
  return goalCategoryTone(goal.categoryId);
}

GoalTone goalCategoryTone(String categoryId) => switch (categoryId) {
  GoalCategories.study => AppColors.toneStudy,
  GoalCategories.fitness => AppColors.toneFitness,
  GoalCategories.productivity => AppColors.toneProductivity,
  GoalCategories.focus => AppColors.toneFocus,
  GoalCategories.habits => AppColors.toneHabits,
  GoalCategories.mentalClarity => AppColors.toneMentalClarity,
  _ => _derivedCategoryTone(categoryId),
};

/// Custom categories hash their own name to a stable hue (2026-08-25) —
/// they all used to wear the Study tone, indistinguishable at a glance.
/// Same recipe as the tasks hub's derived accents.
GoalTone _derivedCategoryTone(String categoryId) {
  final hue = categoryId.trim().toLowerCase().codeUnits.fold<int>(
        0,
        (acc, c) => (acc * 31 + c) & 0x7fffffff,
      ) %
      360;
  return GoalTone.fromSeed(
    HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.60).toColor(),
    light: AppColors.isLight,
  );
}

/// One glyph per category — goals carry no icon of their own, so the
/// category is what the disc can show.
IconData goalCategoryIcon(String categoryId) => switch (categoryId) {
  GoalCategories.study => CupertinoIcons.book_fill,
  GoalCategories.fitness => CupertinoIcons.flame_fill,
  GoalCategories.productivity => CupertinoIcons.bolt_fill,
  GoalCategories.focus => CupertinoIcons.scope,
  GoalCategories.habits => Icons.spa_rounded,
  GoalCategories.mentalClarity => CupertinoIcons.lightbulb_fill,
  _ => CupertinoIcons.sparkles,
};

/// The disc behind the glyph, sized for the list card (44) or the sheet (56).
///
/// Completion lights the disc up — it takes the tone's brightest level and
/// the glyph drops to the card color. That's the "done" signal now that the
/// card no longer flips its text to black.
class GoalIconDisc extends StatelessWidget {
  const GoalIconDisc({
    super.key,
    required this.tone,
    required this.icon,
    this.size = 44,
    this.done = false,
  });

  final GoalTone tone;
  final IconData icon;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: done ? tone.icon : tone.circle,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.45, color: done ? tone.card : tone.icon),
    );
  }
}
