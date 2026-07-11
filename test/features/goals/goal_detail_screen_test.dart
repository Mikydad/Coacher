import 'package:coach_for_life/core/di/providers.dart';
import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/analytics/application/feature_builder_recompute_service.dart';
import 'package:coach_for_life/features/analytics/data/analytics_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:coach_for_life/features/goals/application/goals_providers.dart';
import 'package:coach_for_life/features/goals/data/goals_repository.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_action.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_check_in.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_milestone.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/goals/presentation/goal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryGoalsRepository implements GoalsRepository {
  _MemoryGoalsRepository(this.goal, {List<GoalCheckIn> checkIns = const []})
      : checkIns = {for (final c in checkIns) c.dateKey: c};

  UserGoal goal;
  final Map<String, GoalCheckIn> checkIns;
  final List<GoalAction> actions = [];
  final List<GoalMilestone> milestones = [];

  @override
  Stream<List<UserGoal>> watchGoals() => Stream.value([goal]);

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => [goal];

  @override
  Future<UserGoal?> getGoal(String goalId) async =>
      goalId == goal.id ? goal : null;

  @override
  Future<void> upsertGoal(UserGoal g) async => goal = g;

  @override
  Future<void> deleteGoal(String goalId) async {}

  @override
  Future<List<GoalAction>> getActions(String goalId) async => actions;

  @override
  Future<void> upsertAction(GoalAction action) async {
    actions.removeWhere((a) => a.id == action.id);
    actions.add(action);
  }

  @override
  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {}

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) async => milestones;

  @override
  Future<void> upsertMilestone(GoalMilestone milestone) async {
    milestones.removeWhere((m) => m.id == milestone.id);
    milestones.add(milestone);
  }

  @override
  Future<void> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    milestones.removeWhere((m) => m.id == milestoneId);
  }

  @override
  Future<void> upsertCheckIn(GoalCheckIn checkIn) async {
    checkIns[checkIn.dateKey] = checkIn;
  }

  @override
  Future<GoalCheckIn?> getTodayCheckIn(String goalId, String dateKey) async =>
      checkIns[dateKey];

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async =>
      checkIns.values.toList();
}

class _NoOpAnalyticsRepository implements AnalyticsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) async {
    final name = invocation.memberName.toString();
    if (name.contains('logEvent')) return null;
    return super.noSuchMethod(invocation);
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}
}

/// The real service's provider chain reaches Firestore-backed repositories,
/// which cannot exist in widget tests. Only [onAnalyticsEventLogged] is hit
/// by this screen's flows.
class _NoOpRecomputeService implements FeatureBuilderRecomputeService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

UserGoal _goal() {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 2));
  final end = now.add(const Duration(days: 4));
  return UserGoal(
    id: 'g1',
    title: 'Study 10 Minutes',
    categoryId: 'study',
    repeatCadence: GoalRepeatCadence.weekly,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.minutes,
    targetValue: 30,
    intensity: 3,
    periodStartMs: start.millisecondsSinceEpoch,
    periodEndMs: end.millisecondsSinceEpoch,
    createdAtMs: start.millisecondsSinceEpoch,
    updatedAtMs: start.millisecondsSinceEpoch,
  );
}

Widget _app(_MemoryGoalsRepository repo) {
  return ProviderScope(
    overrides: [
      goalsRepositoryProvider.overrideWithValue(repo),
      analyticsRepositoryProvider.overrideWithValue(_NoOpAnalyticsRepository()),
      featureBuilderRecomputeServiceProvider
          .overrideWithValue(_NoOpRecomputeService()),
    ],
    child: const MaterialApp(home: GoalDetailScreen(goalId: 'g1')),
  );
}

void main() {
  testWidgets('shows commit CTA when today is not done; tapping marks it done',
      (tester) async {
    final repo = _MemoryGoalsRepository(_goal());
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('I DID IT TODAY'), findsOneWidget);
    await tester.tap(find.text('I DID IT TODAY'));
    await tester.pumpAndSettle();

    final todayKey = DateKeys.todayKey();
    expect(repo.checkIns[todayKey]?.metCommitment, isTrue);
    expect(find.text('Mission Accomplished.'), findsOneWidget);
    expect(find.text('UNDO TODAY'), findsOneWidget);
  });

  testWidgets('UNDO TODAY unmarks today and returns to the commit CTA',
      (tester) async {
    final todayKey = DateKeys.todayKey();
    final repo = _MemoryGoalsRepository(
      _goal(),
      checkIns: [
        GoalCheckIn(
          goalId: 'g1',
          dateKey: todayKey,
          metCommitment: true,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
    );
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Mission Accomplished.'), findsOneWidget);
    await tester.tap(find.text('UNDO TODAY'));
    await tester.pumpAndSettle();

    expect(repo.checkIns[todayKey]?.metCommitment, isFalse);
    expect(find.text('I DID IT TODAY'), findsOneWidget);
    expect(find.text('Mission Accomplished.'), findsNothing);
  });
}
