import 'package:sidepal/features/ai_assistant/application/ai_entity_resolver.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// AiEntityResolver (fix-wave Phase 1, the §8 E1/E2 keystone): targeting
/// actions resolve to concrete ids BEFORE the preview card; zero/multiple
/// matches ask a LOCAL question; matching is targeting-grade (no category
/// tier — "call mom" must never resolve to "Call with investors").

class _FakePlanningRepo implements PlanningRepository {
  _FakePlanningRepo(this.tasksByDate);

  /// dateKey → tasks on that day.
  final Map<String, List<PlannedTask>> tasksByDate;
  String? _servingDate;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    _servingDate = dateKey;
    if ((tasksByDate[dateKey] ?? const []).isEmpty) return const [];
    return [
      Routine(
        id: 'r-$dateKey',
        title: 'Day',
        dateKey: dateKey,
        orderIndex: 0,
        createdAtMs: 0,
        updatedAtMs: 0,
      ),
    ];
  }

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => [
    TaskBlock(
      id: 'b-$routineId',
      routineId: routineId,
      title: 'Block',
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  ];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async => tasksByDate[_servingDate] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeGoalsRepo implements GoalsRepository {
  _FakeGoalsRepo(this.goals);
  final List<UserGoal> goals;

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => goals;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

PlannedTask _task(String id, String title, String dateKey) => PlannedTask(
  id: id,
  routineId: 'r-$dateKey',
  blockId: 'b-r-$dateKey',
  title: title,
  durationMinutes: 30,
  priority: 3,
  orderIndex: 0,
  reminderEnabled: false,
  reminderTimeIso: null,
  status: TaskStatus.notStarted,
  createdAtMs: 0,
  updatedAtMs: 0,
  planDateKey: dateKey,
);

UserGoal _goal(String id, String title) => UserGoal(
  id: id,
  title: title,
  categoryId: 'study',
  status: GoalStatus.active,
  measurementKind: MeasurementKind.count,
  targetValue: 1,
  intensity: 3,
  periodStartMs: 0,
  periodEndMs: 1,
  createdAtMs: 0,
  updatedAtMs: 0,
);

AiAction _delete(String title, {String? date}) => AiAction(
  actionType: ActionType.deleteTask,
  parameters: {'taskTitle': title, 'date': ?date},
);

void main() {
  final today = DateKeys.todayKey();
  final tomorrow = DateKeys.tomorrowKey();

  AiEntityResolver resolver(Map<String, List<PlannedTask>> tasks,
          [List<UserGoal> goals = const []]) =>
      AiEntityResolver(
        planningRepository: _FakePlanningRepo(tasks),
        goalsRepository: _FakeGoalsRepo(goals),
      );

  group('matchScore is targeting-grade', () {
    test('exact, containment, and all-words tiers resolve', () {
      expect(AiEntityResolver.matchScore('gym', 'Gym'), 1.0);
      expect(AiEntityResolver.matchScore('gym', 'Gym session'), 0.85);
      expect(
        AiEntityResolver.matchScore(
          'flutter list',
          'Create Flutter to-do list',
        ),
        0.8,
      );
    });

    test('shared-category titles do NOT match (unlike similarityScore)', () {
      // Both are 'work'-category via the dictionary — a 0.9 there, but a
      // deletion target must never resolve across entities like this.
      expect(
        AiEntityResolver.matchScore('call mom', 'Call with investors'),
        lessThan(0.8),
      );
    });
  });

  test('a unique match resolves silently and stamps the real entity',
      () async {
    final r = resolver({
      today: [_task('t1', 'Gym session', today)],
    });
    final result = await r.resolve([_delete('gym')]);

    expect(result, isA<EntityResolutionOk>());
    final action = (result as EntityResolutionOk).actions.single;
    expect(action.parameters['_resolvedTaskId'], 't1');
    expect(action.parameters['_resolvedDateKey'], today);
    // The card must show what was matched, not the model's guess.
    expect(action.parameters['taskTitle'], 'Gym session');
  });

  test('nearest day wins: today\'s workout beats tomorrow\'s', () async {
    final r = resolver({
      today: [_task('t-today', 'Workout', today)],
      tomorrow: [_task('t-tomorrow', 'Workout', tomorrow)],
    });
    final result = await r.resolve([_delete('workout')]);

    expect(result, isA<EntityResolutionOk>());
    expect(
      (result as EntityResolutionOk)
          .actions
          .single
          .parameters['_resolvedTaskId'],
      't-today',
    );
  });

  test('ambiguity within a day asks a local question naming candidates',
      () async {
    final r = resolver({
      today: [
        _task('t1', 'Gym session', today),
        _task('t2', 'Gym stretch', today),
      ],
    });
    final result = await r.resolve([_delete('gym')]);

    expect(result, isA<EntityResolutionQuestion>());
    final q = (result as EntityResolutionQuestion).question;
    expect(q, contains('Gym session'));
    expect(q, contains('Gym stretch'));
  });

  test('no match asks instead of guessing', () async {
    final r = resolver({
      today: [_task('t1', 'Study', today)],
    });
    final result = await r.resolve([_delete('dentist')]);

    expect(result, isA<EntityResolutionQuestion>());
    expect(
      (result as EntityResolutionQuestion).question,
      contains('"dentist"'),
    );
  });

  test('an explicit date scopes the search first', () async {
    final r = resolver({
      today: [_task('t-today', 'Workout', today)],
      tomorrow: [_task('t-tomorrow', 'Workout', tomorrow)],
    });
    final result = await r.resolve([_delete('workout', date: 'tomorrow')]);

    expect(result, isA<EntityResolutionOk>());
    expect(
      (result as EntityResolutionOk)
          .actions
          .single
          .parameters['_resolvedTaskId'],
      't-tomorrow',
    );
  });

  test('goals resolve by title with the same ask-on-ambiguity contract',
      () async {
    final r = resolver({}, [
      _goal('g1', 'Read books'),
      _goal('g2', 'Read papers'),
    ]);

    final unique = await r.resolve([
      const AiAction(
        actionType: ActionType.deleteGoal,
        parameters: {'goalTitle': 'read books'},
      ),
    ]);
    expect(unique, isA<EntityResolutionOk>());
    expect(
      (unique as EntityResolutionOk)
          .actions
          .single
          .parameters['_resolvedGoalId'],
      'g1',
    );

    final ambiguous = await r.resolve([
      const AiAction(
        actionType: ActionType.deleteGoal,
        parameters: {'goalTitle': 'read'},
      ),
    ]);
    expect(ambiguous, isA<EntityResolutionQuestion>());
  });

  test('non-targeting actions pass through untouched', () async {
    final r = resolver({});
    const create = AiAction(
      actionType: ActionType.createTask,
      parameters: {'title': 'Study', 'time': '14:00'},
    );
    final result = await r.resolve([create]);
    expect(result, isA<EntityResolutionOk>());
    expect((result as EntityResolutionOk).actions.single, same(create));
  });
}
