import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/firebase/firestore_paths.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';
import 'package:sidepal/features/goals/application/goal_actions.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';

/// Acting on a goal with a LIVE stake is honest (delete 2026-08-25,
/// complete 2026-09-15): the dialog says the stake does not end, and
/// offers the priced surrender only where the server allows one.
void main() {
  /// Opens the dialog and hands back the pending answer WITHOUT awaiting
  /// it (awaiting would wait for the dialog itself and deadlock).
  Future<_Opened> open(
    WidgetTester tester, {
    required StakeChallenge stake,
    required StakedGoalAction action,
  }) async {
    final opened = _Opened();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                opened.answer = showStakedGoalActionDialog(
                  context,
                  _goal(),
                  stake,
                  action: action,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('complete on a solo money stake: warns, keep or surrender', (
    tester,
  ) async {
    final opened = await open(
      tester,
      stake: _challenge(type: 'solo_money', stakeKind: 'money', cents: 2500),
      action: StakedGoalAction.complete,
    );

    expect(find.text('Mark complete?'), findsOneWidget);
    expect(find.textContaining('does NOT end it'), findsOneWidget);
    expect(find.textContaining("can't be won early"), findsOneWidget);
    expect(find.textContaining('\$25 is donated'), findsOneWidget);
    expect(find.text('Complete & surrender stake'), findsOneWidget);
    expect(find.text('Complete, keep stake'), findsOneWidget);

    await tester.tap(find.text('Complete, keep stake'));
    await tester.pumpAndSettle();
    expect(await opened.answer, isFalse);
  });

  testWidgets('surrender returns true; cancel returns null', (tester) async {
    var opened = await open(
      tester,
      stake: _challenge(type: 'solo_public', stakeKind: 'public'),
      action: StakedGoalAction.complete,
    );
    await tester.tap(find.text('Complete & surrender stake'));
    await tester.pumpAndSettle();
    expect(await opened.answer, isTrue);

    opened = await open(
      tester,
      stake: _challenge(type: 'solo_public', stakeKind: 'public'),
      action: StakedGoalAction.complete,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await opened.answer, isNull);
  });

  testWidgets('a multi-party stake can never be surrendered', (tester) async {
    await open(
      tester,
      stake: _challenge(type: 'h2h_points', stakeKind: 'points'),
      action: StakedGoalAction.complete,
    );
    expect(find.textContaining('Others are in this challenge'), findsOneWidget);
    expect(find.text('Complete & surrender stake'), findsNothing);
    expect(find.text('Complete, keep stake'), findsOneWidget);
  });

  testWidgets('delete keeps its own wording', (tester) async {
    await open(
      tester,
      stake: _challenge(type: 'solo_public', stakeKind: 'public'),
      action: StakedGoalAction.delete,
    );
    expect(find.text('Delete goal?'), findsOneWidget);
    expect(
      find.textContaining('Deleting the goal does NOT end it'),
      findsOneWidget,
    );
    expect(find.text('Delete & surrender stake'), findsOneWidget);
    expect(find.text('Delete, keep stake'), findsOneWidget);
  });
}

class _Opened {
  Future<bool?>? answer;
}

UserGoal _goal() => UserGoal(
  id: 'g1',
  title: 'Read',
  categoryId: 'study',
  repeatCadence: GoalRepeatCadence.daily,
  status: GoalStatus.active,
  measurementKind: MeasurementKind.minutes,
  targetValue: 30,
  intensity: 3,
  periodStartMs: 0,
  periodEndMs: 1,
  createdAtMs: 0,
  updatedAtMs: 0,
);

/// Participant uid matches the test-time active uid (no Firebase → the
/// local user id), so the dialog sees "me" in the challenge.
StakeChallenge _challenge({
  required String type,
  required String stakeKind,
  int? cents,
}) {
  final uid = _localUid();
  return StakeChallenge.fromMap({
    'id': 'stk_1',
    'type': type,
    'status': 'active',
    'creatorUid': uid,
    'circleId': '',
    'participants': [
      {
        'uid': uid,
        'teamId': uid,
        'stakeKind': stakeKind,
        'accepted': true,
        'stakeAmount': ?cents,
      },
      if (type.startsWith('h2h'))
        {'uid': 'u2', 'teamId': 'u2', 'stakeKind': stakeKind, 'accepted': true},
    ],
    'frozenGoal': {
      'title': 'Read',
      'unitKind': 'minutes',
      'unitTarget': 30,
      'totalUnits': 30,
      'linkedGoalId': 'g1',
    },
    'mode': 'disciplined',
    'deadlineMs': 1_000_000,
    'createdAtMs': 1,
    'updatedAtMs': 2,
  });
}

String _localUid() => FirestorePaths.activeUid;
