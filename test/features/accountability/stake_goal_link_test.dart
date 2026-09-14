import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/accountability/application/stake_goal_check_in_bridge.dart';
import 'package:sidepal/features/accountability/application/stakes_providers.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';
import 'package:sidepal/features/goals/application/goals_providers.dart';
import 'package:sidepal/features/goals/domain/models/goal_action.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/goals/presentation/widgets/goal_card.dart';

import '../../support/no_op_goals_repository.dart';

/// A staked goal (2026-09-15): its card opens the challenge page instead of
/// the check-in sheet, the quick-add is gone, and the stake's evidence
/// mirrors into the goal's check-in so the goal's own book stays current.
void main() {
  group('liveStakeForGoalProvider', () {
    test('returns the non-terminal challenge staked on the goal', () {
      final container = ProviderContainer(
        overrides: [
          stakeChallengesStreamProvider.overrideWith(
            (ref) => Stream.value([
              _challenge(id: 'old', goalId: 'g1', status: 'completed_success'),
              _challenge(id: 'live', goalId: 'g1'),
              _challenge(id: 'other', goalId: 'g2'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Prime the stream.
      final sub = container.listen(stakeChallengesStreamProvider, (_, _) {});
      addTearDown(sub.close);
      return Future<void>.delayed(Duration.zero).then((_) {
        expect(container.read(liveStakeForGoalProvider('g1'))?.id, 'live');
        expect(container.read(liveStakeForGoalProvider('g2'))?.id, 'other');
        expect(container.read(liveStakeForGoalProvider('g3')), isNull);
      });
    });
  });

  group('StakeGoalCheckInBridge', () {
    late _GoalsRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _GoalsRepo(_goal(id: 'g1', target: 30));
      container = ProviderContainer(
        overrides: [goalsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
    });

    test('evidence lands as today\'s check-in with the same amount', () async {
      await container
          .read(stakeGoalCheckInBridgeProvider)
          .mirrorEvidence(challenge: _challenge(goalId: 'g1'), amount: 12);
      final today = repo.checkIns[DateKeys.todayKey()];
      expect(today, isNotNull);
      expect(today!.value, 12);
      expect(today.metCommitment, isFalse, reason: '12 < 30');
    });

    test('adds to what was already logged today and marks met', () async {
      final key = DateKeys.todayKey();
      repo.checkIns[key] = GoalCheckIn(
        goalId: 'g1',
        dateKey: key,
        metCommitment: false,
        updatedAtMs: 1,
        value: 20,
        note: 'keep',
      );
      await container
          .read(stakeGoalCheckInBridgeProvider)
          .mirrorEvidence(challenge: _challenge(goalId: 'g1'), amount: 10);
      final today = repo.checkIns[key]!;
      expect(today.value, 30);
      expect(today.metCommitment, isTrue);
      expect(today.note, 'keep');
    });

    test('no linked goal, paused goal, or zero amount is a no-op', () async {
      final bridge = container.read(stakeGoalCheckInBridgeProvider);
      await bridge.mirrorEvidence(
        challenge: _challenge(goalId: null),
        amount: 5,
      );
      await bridge.mirrorEvidence(
        challenge: _challenge(goalId: 'g1'),
        amount: 0,
      );
      repo.goal = _goal(id: 'g1', target: 30, status: GoalStatus.paused);
      await bridge.mirrorEvidence(
        challenge: _challenge(goalId: 'g1'),
        amount: 5,
      );
      expect(repo.checkIns, isEmpty);
    });

    test('an off-day for the goal is a no-op', () async {
      final today = DateTime.now().weekday;
      final otherDay = today == DateTime.monday ? DateTime.tuesday : today - 1;
      repo.goal = _goal(id: 'g1', target: 30, weekdays: [otherDay]);
      await container
          .read(stakeGoalCheckInBridgeProvider)
          .mirrorEvidence(challenge: _challenge(goalId: 'g1'), amount: 5);
      expect(repo.checkIns, isEmpty);
    });
  });

  group('GoalCard when staked', () {
    Widget app(_GoalsRepo repo, List<StakeChallenge> stakes, GoalCard card) {
      return ProviderScope(
        overrides: [
          goalsRepositoryProvider.overrideWithValue(repo),
          stakeChallengesStreamProvider.overrideWith(
            (ref) => Stream.value(stakes),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: card)),
      );
    }

    testWidgets('tap opens the challenge; quick-add is gone', (tester) async {
      final repo = _GoalsRepo(_goal(id: 'g1', target: 30));
      String? opened;
      await tester.pumpWidget(
        app(repo, [
          _challenge(id: 'live', goalId: 'g1'),
        ], GoalCard(goal: repo.goal, onOpenStake: (_, id) => opened = id)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Staked'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing, reason: 'no bare check-in');

      await tester.tap(find.text(repo.goal.title));
      await tester.pumpAndSettle();
      expect(opened, 'live');
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('an unstaked goal keeps its quick-add and check-in sheet', (
      tester,
    ) async {
      final repo = _GoalsRepo(_goal(id: 'g1', target: 30));
      String? opened;
      await tester.pumpWidget(
        app(
          repo,
          const [],
          GoalCard(goal: repo.goal, onOpenStake: (_, id) => opened = id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Staked'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text(repo.goal.title));
      await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}

class _GoalsRepo extends NoOpGoalsRepository {
  _GoalsRepo(this.goal);

  UserGoal goal;
  final Map<String, GoalCheckIn> checkIns = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<T> _live<T>(T Function() snapshot) async* {
    yield snapshot();
    yield* _changes.stream.map((_) => snapshot());
  }

  @override
  Future<UserGoal?> getGoal(String goalId) async =>
      goalId == goal.id ? goal : null;

  @override
  Stream<List<UserGoal>> watchGoals() => _live(() => [goal]);

  @override
  Stream<List<GoalAction>> watchActions(String goalId) => _live(() => const []);

  @override
  Stream<List<GoalCheckIn>> watchCheckIns(String goalId) =>
      _live(() => checkIns.values.toList());

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async => checkIns.values
      .where(
        (c) =>
            (startDateKey == null || c.dateKey.compareTo(startDateKey) >= 0) &&
            (endDateKey == null || c.dateKey.compareTo(endDateKey) <= 0),
      )
      .toList();

  @override
  Future<void> upsertCheckIn(GoalCheckIn checkIn) async {
    checkIns[checkIn.dateKey] = checkIn;
    _changes.add(null);
  }
}

UserGoal _goal({
  required String id,
  required double target,
  GoalStatus status = GoalStatus.active,
  List<int>? weekdays,
}) {
  final now = DateTime.now();
  return UserGoal(
    id: id,
    title: 'Read',
    categoryId: 'study',
    repeatCadence: weekdays == null
        ? GoalRepeatCadence.daily
        : GoalRepeatCadence.weekly,
    scheduledWeekdays: weekdays,
    status: status,
    measurementKind: MeasurementKind.minutes,
    targetValue: target,
    intensity: 3,
    periodStartMs: now
        .subtract(const Duration(days: 10))
        .millisecondsSinceEpoch,
    periodEndMs: now.add(const Duration(days: 20)).millisecondsSinceEpoch,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

StakeChallenge _challenge({
  String id = 'stk_1',
  required String? goalId,
  String status = 'active',
}) {
  return StakeChallenge.fromMap({
    'id': id,
    'type': 'solo_public',
    'status': status,
    'creatorUid': 'u1',
    'circleId': '',
    'participants': [
      {'uid': 'u1', 'teamId': 'u1', 'stakeKind': 'public', 'accepted': true},
    ],
    'frozenGoal': {
      'title': 'Read',
      'unitKind': 'minutes',
      'unitTarget': 30,
      'totalUnits': 30,
      'linkedGoalId': ?goalId,
    },
    'mode': 'disciplined',
    'deadlineMs': DateTime.now()
        .add(const Duration(days: 20))
        .millisecondsSinceEpoch,
    'createdAtMs': 1,
    'updatedAtMs': 2,
  });
}
