import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/domain/sleep_task.dart';

/// Stripe + checkbox color for one task — the Tasks page rows and Home's
/// Up next bar (shared since 2026-09-27, so a task keeps one color).
///
/// The six built-in categories hold a fixed hue so the list reads by kind.
/// A custom category derives a stable hue from its own name; an
/// uncategorized task derives one from its title and wears it desaturated —
/// enough to give the list rhythm without pretending to mean something a
/// categorized row's color does.
Color taskAccentColor(PlannedTask t) {
  final category = t.category?.trim();
  if (category == null || category.isEmpty) {
    return _derivedAccent(t.title, saturation: 0.20, lightness: 0.52);
  }
  return switch (category) {
    'Study' => AppColors.categoryBlue,
    'Fitness' => AppColors.coral,
    'Work' => AppColors.orange,
    'Personal' => AppColors.violetSoft,
    'Plan' || 'Planning' => AppColors.success,
    kSleepTaskCategory => AppColors.periwinkle,
    _ => _derivedAccent(category, saturation: 0.45, lightness: 0.60),
  };
}

/// Same text → same hue, every launch: [String.hashCode] is stable within a
/// run and the value only ever drives decoration.
Color _derivedAccent(
  String seed, {
  required double saturation,
  required double lightness,
}) {
  final hue = (seed.hashCode.abs() % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
}
