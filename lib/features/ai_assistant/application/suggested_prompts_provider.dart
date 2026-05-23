import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../planning/application/planned_task_collect.dart';
import 'entity_normaliser.dart';

const List<String> kDefaultSuggestedPrompts = [
  'Add a workout at 5AM',
  'Move my study session tomorrow',
  'Enable focus mode for 90 minutes',
];

/// Generates up to 3 context-specific suggested prompts based on the user's
/// current tasks and goals.
///
/// Falls back to [kDefaultSuggestedPrompts] on any error.
final suggestedPromptsProvider =
    FutureProvider<List<String>>((ref) async {
  try {
    final planningRepo = ref.read(planningRepositoryProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    const normaliser = EntityNormaliser();

    // Load today's tasks
    final rows = await collectTodayPlannedRows(planningRepo);
    final tasks = rows.map((r) => r.task).toList();

    final prompts = <String>[];

    // Rule 1 — Recurring fitness task → suggest scheduling it for tomorrow
    final fitnessTasks = tasks.where((t) {
      final cat = normaliser.normalise(t.category ?? t.title);
      return cat == 'fitness';
    }).toList();
    if (fitnessTasks.isNotEmpty) {
      final name = fitnessTasks.first.title;
      prompts.add('Schedule my $name for tomorrow');
    }

    // Rule 2 — Unscheduled active goal → suggest setting time for it
    final goals = goalsAsync.valueOrNull ?? [];
    final activeGoals =
        goals.where((g) => g.status.name == 'active').toList();
    if (activeGoals.isNotEmpty) {
      // Pick the goal that doesn't already have a matching task today
      for (final goal in activeGoals) {
        final hasTask = tasks.any(
          (t) => normaliser.similarityScore(goal.title, t.title) >= 0.7,
        );
        if (!hasTask) {
          prompts.add('Set time for ${goal.title}');
          break;
        }
      }
    }

    // Rule 3 — Overdue tasks (no time set + status not completed)
    final overdueCount = tasks
        .where((t) =>
            (t.reminderTimeIso == null || t.reminderTimeIso!.isEmpty) &&
            t.status.name != 'completed')
        .length;
    if (overdueCount > 0) {
      prompts.add(
        'Move ${overdueCount > 1 ? 'my unscheduled tasks' : 'my unscheduled task'} to today',
      );
    }

    if (prompts.isEmpty) return kDefaultSuggestedPrompts;

    // Cap at 3
    return prompts.take(3).toList();
  } catch (_) {
    return kDefaultSuggestedPrompts;
  }
});
