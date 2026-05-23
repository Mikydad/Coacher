import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/models/ai_action.dart';
import '../presentation/widgets/quick_directives_row.dart';

// ─── Label map ────────────────────────────────────────────────────────────────

const Map<ActionType, QuickDirective> _kActionDirectiveMap = {
  ActionType.createTask: QuickDirective(
    label: 'Add task',
    startingText: 'Add a task ',
  ),
  ActionType.createGoal: QuickDirective(
    label: 'Create goal',
    startingText: 'Create a goal ',
  ),
  ActionType.moveTask: QuickDirective(
    label: 'Move schedule',
    startingText: 'Move my ',
  ),
  ActionType.activateContextOverride: QuickDirective(
    label: 'Focus mode',
    startingText: 'Enable focus mode ',
  ),
  ActionType.deleteTask: QuickDirective(
    label: 'Remove task',
    startingText: 'Delete my ',
  ),
  ActionType.addReminder: QuickDirective(
    label: 'Add reminder',
    startingText: 'Remind me to ',
  ),
  ActionType.editTask: QuickDirective(
    label: 'Edit task',
    startingText: 'Edit my ',
  ),
};

/// Computes the 3 most-used directive types from AI interaction history.
///
/// Falls back to [kDefaultDirectives] when fewer than 5 history entries exist.
final quickDirectivesProvider =
    FutureProvider<List<QuickDirective>>((ref) async {
  try {
    final historyRepo = ref.read(aiInteractionHistoryRepositoryProvider);
    final recent = await historyRepo.getRecent(limit: 100);

    if (recent.length < 5) return kDefaultDirectives;

    // Count actionType occurrences across all stored interactions
    final counts = <ActionType, int>{};
    for (final entry in recent) {
      try {
        final list = jsonDecode(entry.parsedActionsJson) as List;
        for (final item in list) {
          final typeStr = (item as Map<String, dynamic>)['actionType'] as String?;
          if (typeStr == null) continue;
          final type = ActionType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => ActionType.createTask,
          );
          counts[type] = (counts[type] ?? 0) + 1;
        }
      } catch (_) {
        continue;
      }
    }

    if (counts.isEmpty) return kDefaultDirectives;

    // Sort by frequency, take top 3, map to directives
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final directives = sorted
        .take(3)
        .map((e) => _kActionDirectiveMap[e.key])
        .whereType<QuickDirective>()
        .toList();

    if (directives.isEmpty) return kDefaultDirectives;

    return directives;
  } catch (_) {
    return kDefaultDirectives;
  }
});
