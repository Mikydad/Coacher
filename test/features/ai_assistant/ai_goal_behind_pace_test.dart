import 'package:sidepal/features/ai_assistant/application/entity_normaliser.dart';
import 'package:sidepal/features/ai_assistant/application/proactive_suggestion_engine.dart';
import 'package:sidepal/features/ai_assistant/application/schedule_optimisation_service.dart';
import 'package:sidepal/features/ai_assistant/data/dismissed_suggestion_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/proactive_suggestion.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:sidepal/features/time_blocks/data/time_block_repository.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goal-behind-pace honesty (fix-wave Phase 0, AUDIT.md §8 H7):
///
/// `_estimateGoalProgress` used to hardcode 0, so every active goal was
/// accused of being "~elapsed% behind the expected pace" — a fully on-track
/// goal at day 27/30 read "~90% behind", daily, contradicting the Goals
/// surfaces which compute real progress from the same synced check-ins.
/// These tests pin the rule to real check-in data.

class _FakeGoalsRepo implements GoalsRepository {
  _FakeGoalsRepo({required this.goals, required this.checkIns});

  final List<UserGoal> goals;
  final List<GoalCheckIn> checkIns;

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => goals;

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async => checkIns
      .where(
        (c) =>
            c.goalId == goalId &&
            (startDateKey == null || c.dateKey.compareTo(startDateKey) >= 0) &&
            (endDateKey == null || c.dateKey.compareTo(endDateKey) <= 0),
      )
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

// The other rules are exercised elsewhere; here they must simply stay out
// of the way. Each rule body is wrapped in its own try/catch, so throwing
// fakes make them return empty lists.
class _ThrowingFake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakePlanningRepo extends _ThrowingFake implements PlanningRepository {}

class _FakeTimeBlockRepo extends _ThrowingFake implements TimeBlockRepository {}

class _FakeOptimisation extends _ThrowingFake
    implements ScheduleOptimisationService {}

class _FakeDismissedRepo extends _ThrowingFake
    implements DismissedSuggestionRepository {
  @override
  Future<Set<ProactiveSuggestionType>> suppressedTypes() async => {};

  @override
  Future<Set<ProactiveSuggestionType>> typesDismissedToday() async => {};
}

UserGoal _goal({double targetValue = 10}) {
  final now = DateTime.now();
  // A 30-day one-time goal, 15 days in → expected progress ≈ 0.5.
  final start = now.subtract(const Duration(days: 15));
  final end = now.add(const Duration(days: 15));
  return UserGoal(
    id: 'g1',
    title: 'Read books',
    categoryId: 'study',
    status: GoalStatus.active,
    measurementKind: MeasurementKind.count,
    targetValue: targetValue,
    intensity: 3,
    periodStartMs: start.millisecondsSinceEpoch,
    periodEndMs: end.millisecondsSinceEpoch,
    createdAtMs: start.millisecondsSinceEpoch,
    updatedAtMs: start.millisecondsSinceEpoch,
  );
}

GoalCheckIn _checkIn(int daysAgo, double value) {
  final day = DateTime.now().subtract(Duration(days: daysAgo));
  return GoalCheckIn(
    goalId: 'g1',
    dateKey: DateKeys.yyyymmdd(day),
    metCommitment: true,
    updatedAtMs: day.millisecondsSinceEpoch,
    value: value,
  );
}

ProactiveSuggestionEngine _engine({
  required List<UserGoal> goals,
  required List<GoalCheckIn> checkIns,
}) => ProactiveSuggestionEngine(
  planningRepository: _FakePlanningRepo(),
  goalsRepository: _FakeGoalsRepo(goals: goals, checkIns: checkIns),
  timeBlockRepository: _FakeTimeBlockRepo(),
  dismissedRepo: _FakeDismissedRepo(),
  normaliser: const EntityNormaliser(),
  optimisationService: _FakeOptimisation(),
);

void main() {
  test('an on-track goal never emits a behind-pace card', () async {
    // 15 of 30 days elapsed, 5/10 logged → exactly on pace.
    final suggestions = await _engine(
      goals: [_goal()],
      checkIns: [_checkIn(1, 2), _checkIn(3, 2), _checkIn(6, 1)],
    ).generateForToday();

    expect(
      suggestions.where(
        (s) => s.type == ProactiveSuggestionType.goalBehindPace,
      ),
      isEmpty,
    );
  });

  test('a genuinely behind goal fires with the REAL gap percentage',
      () async {
    // 15 of 30 days elapsed (expected ~50%), 1/10 logged (actual 10%)
    // → gap ~40%, and the copy must reflect it.
    final suggestions = await _engine(
      goals: [_goal()],
      checkIns: [_checkIn(2, 1)],
    ).generateForToday();

    final card = suggestions.singleWhere(
      (s) => s.type == ProactiveSuggestionType.goalBehindPace,
    );
    final pct = RegExp(r'~(\d+)%').firstMatch(card.description)!.group(1)!;
    final gap = int.parse(pct);
    expect(gap, inInclusiveRange(35, 45));
  });

  test('a goal with an unreadable target stays silent instead of guessing',
      () async {
    final suggestions = await _engine(
      goals: [_goal(targetValue: 0)],
      checkIns: const [],
    ).generateForToday();

    expect(
      suggestions.where(
        (s) => s.type == ProactiveSuggestionType.goalBehindPace,
      ),
      isEmpty,
    );
  });

  test('an ahead-of-pace goal stays silent', () async {
    // 15 of 30 days elapsed, 9/10 already logged.
    final suggestions = await _engine(
      goals: [_goal()],
      checkIns: [_checkIn(1, 5), _checkIn(4, 4)],
    ).generateForToday();

    expect(
      suggestions.where(
        (s) => s.type == ProactiveSuggestionType.goalBehindPace,
      ),
      isEmpty,
    );
  });
}
