import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../analytics/application/delivery_providers.dart';
import '../domain/models/user_goal.dart';
import 'goals_providers.dart';

/// Confirmation dialog + full goal delete (reminders, coaching caches, time
/// block). Shared by the detail-screen menu and the goal-card swipe action
/// so the two paths can't drift in side effects. Returns true when deleted.
Future<bool> confirmDeleteGoal(
  BuildContext context,
  WidgetRef ref,
  UserGoal goal,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete goal?'),
      content: Text(
        'Remove “${goal.title}” and all its actions, milestones, and '
        'check-ins?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  await ref.read(goalReminderSyncServiceProvider).cancelForGoal(goal.id);
  await ref.read(goalsRepositoryProvider).deleteGoal(goal.id);
  await clearEntityCoachingCachesForGoal(ref, goal.id);
  await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(goal.id);
  invalidateGoals(ref, goalId: goal.id);
  return true;
}
