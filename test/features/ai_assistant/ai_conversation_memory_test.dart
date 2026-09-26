import 'package:sidepal/core/local_db/isar_collections/isar_ai_interaction_history.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/coaching/data/coaching_style_repository.dart';
import 'package:sidepal/features/context_override/data/context_override_repository.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';

class _FakeHistoryRepo implements AiInteractionHistoryRepository {
  @override
  Future<int?> saveTurn({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
    bool executed = false,
  }) async {
    await save(
      sessionId: sessionId,
      userInput: userInput,
      parsedActions: parsedActions,
      resolvedCategory: resolvedCategory,
      assistantSummary: assistantSummary,
      responseType: responseType,
    );
    return null;
  }

  _FakeHistoryRepo(this._entries);

  final List<IsarAiInteractionHistory> _entries;

  @override
  Future<List<IsarAiInteractionHistory>> getRecentForSession(
    String sessionId, {
    int limit = 10,
  }) async {
    return _entries
        .where((e) => e.sessionId == sessionId)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePlanningRepo implements PlanningRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeGoalsRepo implements GoalsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeContextRepo implements ContextOverrideRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeCoachingRepo implements CoachingStyleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('buildConversationHistory includes prior informational assistant turn', () async {
    const sessionId = 'session-memory';
    final entry = IsarAiInteractionHistory()
      ..sessionId = sessionId
      ..userInput = 'What is my plan for tomorrow?'
      ..parsedActionsJson = '[]'
      ..confirmed = false
      ..executed = false
      ..assistantSummary = 'Tomorrow you have Study at 9:00.'
      ..responseType = 'informational'
      ..timestampMs = 1;

    final assembler = AiPayloadAssembler(
      planningRepository: _FakePlanningRepo(),
      goalsRepository: _FakeGoalsRepo(),
      contextOverrideRepository: _FakeContextRepo(),
      coachingStyleRepository: _FakeCoachingRepo(),
      historyRepository: _FakeHistoryRepo([entry]),
    );

    final conversation = await assembler.buildConversationHistory(sessionId);

    expect(conversation, hasLength(2));
    expect(conversation[0], {'role': 'user', 'content': 'What is my plan for tomorrow?'});
    expect(conversation[1], {
      'role': 'assistant',
      'content': 'Tomorrow you have Study at 9:00.',
    });
  });
}
