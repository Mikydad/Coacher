import 'package:coach_for_life/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:coach_for_life/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:coach_for_life/features/coaching/data/coaching_style_repository.dart';
import 'package:coach_for_life/features/context_override/data/context_override_repository.dart';
import 'package:coach_for_life/features/goals/data/goals_repository.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingPlanningRepo implements PlanningRepository {
  int routineFetchCount = 0;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    routineFetchCount++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeGoalsRepo implements GoalsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeContextRepo implements ContextOverrideRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeCoachingRepo implements CoachingStyleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHistory implements AiInteractionHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('schedule slice is cached for 30s within the same session', () async {
    final planning = _CountingPlanningRepo();
    final assembler = AiPayloadAssembler(
      planningRepository: planning,
      goalsRepository: _FakeGoalsRepo(),
      contextOverrideRepository: _FakeContextRepo(),
      coachingStyleRepository: _FakeCoachingRepo(),
      historyRepository: _FakeHistory(),
    );

    await assembler.assemble('q1', 'session-cache');
    final afterFirst = planning.routineFetchCount;
    expect(afterFirst, greaterThan(0));

    await assembler.assemble('q2', 'session-cache');
    expect(planning.routineFetchCount, afterFirst);

    assembler.invalidateSessionCache('session-cache');
    await assembler.assemble('q3', 'session-cache');
    expect(planning.routineFetchCount, greaterThan(afterFirst));
  });
}
