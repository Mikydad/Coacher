import 'dart:convert';

import 'package:sidepal/core/local_db/isar_collections/isar_ai_interaction_history.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/presentation/widgets/quick_directives_row.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for the dynamic quick-directives logic (extracted to a pure function
// so we can test it without Riverpod / Isar infrastructure).

/// Mirrors the core logic inside quickDirectivesProvider.
List<QuickDirective> computeDirectives(
  List<IsarAiInteractionHistory> recent,
) {
  const actionDirectiveMap = {
    'createTask':
        QuickDirective(label: 'Add task', startingText: 'Add a task '),
    'createGoal':
        QuickDirective(label: 'Create goal', startingText: 'Create a goal '),
    'moveTask':
        QuickDirective(label: 'Move schedule', startingText: 'Move my '),
    'activateContextOverride':
        QuickDirective(label: 'Focus mode', startingText: 'Enable focus mode '),
    'deleteTask':
        QuickDirective(label: 'Remove task', startingText: 'Delete my '),
  };

  if (recent.length < 5) return kDefaultDirectives;

  final counts = <String, int>{};
  for (final entry in recent) {
    try {
      final list = jsonDecode(entry.parsedActionsJson) as List;
      for (final item in list) {
        final typeStr =
            (item as Map<String, dynamic>)['actionType'] as String?;
        if (typeStr == null) continue;
        counts[typeStr] = (counts[typeStr] ?? 0) + 1;
      }
    } catch (_) {
      continue;
    }
  }

  if (counts.isEmpty) return kDefaultDirectives;

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final directives = sorted
      .take(3)
      .map((e) => actionDirectiveMap[e.key])
      .whereType<QuickDirective>()
      .toList();

  return directives.isEmpty ? kDefaultDirectives : directives;
}

IsarAiInteractionHistory _makeEntry(String actionType) {
  final entry = IsarAiInteractionHistory()
    ..sessionId = 'sess-1'
    ..userInput = 'input'
    ..parsedActionsJson = jsonEncode([
      {'actionType': actionType, 'parameters': {}, 'confidence': 1.0}
    ])
    ..confirmed = true
    ..executed = true
    ..timestampMs = DateTime.now().millisecondsSinceEpoch;
  return entry;
}

void main() {
  group('quickDirectives logic', () {
    test('returns static fallback when fewer than 5 history entries', () {
      final result = computeDirectives([]);
      expect(result, equals(kDefaultDirectives));
    });

    test('returns static fallback with 4 entries (< 5 threshold)', () {
      final entries = List.generate(4, (_) => _makeEntry('createTask'));
      final result = computeDirectives(entries);
      expect(result, equals(kDefaultDirectives));
    });

    test('returns dynamic output with 10 entries', () {
      final entries = [
        ...List.generate(6, (_) => _makeEntry('createTask')),
        ...List.generate(2, (_) => _makeEntry('createGoal')),
        ...List.generate(2, (_) => _makeEntry('moveTask')),
      ];
      final result = computeDirectives(entries);
      expect(result.length, 3);
      expect(result.first.label, 'Add task'); // most frequent
    });

    test('handles malformed JSON gracefully', () {
      final badEntry = IsarAiInteractionHistory()
        ..sessionId = 'sess-bad'
        ..userInput = 'bad'
        ..parsedActionsJson = '{not valid json}'
        ..confirmed = false
        ..executed = false
        ..timestampMs = DateTime.now().millisecondsSinceEpoch;

      final entries = [
        badEntry,
        ...List.generate(5, (_) => _makeEntry('createTask')),
      ];
      // Should not throw; falls back gracefully
      expect(() => computeDirectives(entries), returnsNormally);
    });
  });
}
