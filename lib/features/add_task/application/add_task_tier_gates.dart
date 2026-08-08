import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tier/tier_providers.dart';
import '../../../core/tier/tier_usage.dart';
import '../../../core/tier/upgrade_prompt.dart';

/// Free-tier creation gates (no-ops while enforcement is off / on Pro).
/// Returns true to proceed with the save. [onBlocked] runs BEFORE the tier
/// sheet is shown so the caller can re-enable its save button first —
/// preserving the original ordering.
Future<bool> checkAddTaskTierGates(
  BuildContext context,
  WidgetRef ref, {
  required bool isEdit,
  required String planDateKey,
  required bool addingHabitAnchor,
  required VoidCallback onBlocked,
}) async {
  final tierGate = ref.read(tierGateProvider);
  if (tierGate.isBypassed) return true;

  if (!isEdit) {
    final dayCount = await TierUsage.tasksPlannedForDay(planDateKey);
    if (!tierGate.canCreateTaskForDay(dayCount)) {
      onBlocked();
      if (context.mounted) {
        await showTierLimitSheet(
          context,
          title: 'Daily task limit reached',
          message:
              'The free plan includes ${tierGate.limits.freeTasksPerDay} '
              'tasks per day. SidePal Pro removes the limit.',
        );
      }
      return false;
    }
  }
  if (addingHabitAnchor) {
    final anchorCount = await TierUsage.habitAnchorsForDay(planDateKey);
    if (!tierGate.canAddHabitAnchorForDay(anchorCount)) {
      onBlocked();
      if (context.mounted) {
        await showTierLimitSheet(
          context,
          title: 'Habit limit reached',
          message:
              'The free plan includes '
              '${tierGate.limits.freeHabitAnchorsPerDay} active habits '
              'per day. SidePal Pro removes the limit.',
        );
      }
      return false;
    }
  }
  return true;
}
