/// Coach AI regression scenarios (AI chat fix plan Phase 0.2).
///
/// Each scenario replays a real multi-turn sequence through the real
/// pipeline (see `test/support/ai_scenario_harness.dart`) and asserts the
/// resulting RECORDS. Scenarios that describe behaviour the plan has not
/// shipped yet are `skip`ped with the phase that flips them on — the
/// assertion is already the contract, so a fix is done when the skip goes.
///
/// Sources: documentation/AI_CHAT_AUDIT_REVIEW_2026-09-26.md §7,
/// documentation/AI_CHAT_FIX_PLAN.md.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_router.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_intent_kind.dart';
import 'package:sidepal/features/goals/domain/models/goal_categories.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';

import '../../../support/ai_scenario_harness.dart';

void main() {
  final today = DateKeys.todayKey();
  final tomorrow = DateKeys.tomorrowKey();

  /// A two-item evening suggestion for tomorrow, as the model proposes it.
  List<Map<String, dynamic>> eveningPlan() => [
    ScriptedProxy.createTask(
      title: 'Music practice',
      time: '19:00',
      duration: 25,
      date: 'tomorrow',
    ),
    ScriptedProxy.createTask(
      title: 'Workout',
      time: '18:00',
      duration: 30,
      date: 'tomorrow',
    ),
  ];

  /// Drives: "plan my evening" → suggestion card → Apply → Confirm.
  Future<AiScenario> suggestApplyConfirm() async {
    final s = await AiScenario.start(
      script: [
        ScriptedProxy.propose(
          presentation: 'suggestion',
          content: "Tomorrow evening is open — I'd add music at 19:00 and a "
              'workout at 18:00.',
          actions: eveningPlan(),
        ),
      ],
    );
    await s.service.sendMessage('help me plan tomorrow evening');
    final draft = s.latestDraft;
    expect(draft, isNotNull, reason: 'suggest turn must park a draft');
    s.service.applySuggestedPlan(draft!.id);
    expect(s.service.hasPendingPlan, isTrue);
    final card = s.latestCard;
    expect(card, isNotNull, reason: 'Apply must promote the draft to a card');
    await s.service.confirmPlan(card!.plannedChanges, card.id);
    return s;
  }

  group('ships today', () {
    test('suggest → apply → confirm creates the tasks exactly once, '
        'marks the card executed, and records the history row', () async {
      final s = await suggestApplyConfirm();
      addTearDown(s.dispose);

      expect(s.titlesOn(tomorrow), unorderedEquals(['Music practice', 'Workout']));
      expect(s.titlesOn(today), isEmpty);
      expect(s.service.hasPendingPlan, isFalse);
      expect(s.anyLiveCard, isFalse, reason: 'an executed card is inert');
      expect(s.latestCard!.isExecuted, isTrue);
      expect(s.history.rows.where((r) => r.executed), hasLength(1));
      final batch = await s.batches.findMostRecent();
      expect(batch?.state, 'completed');
    });

    test('cancel makes the card inert and clears the pending plan', () async {
      final s = await AiScenario.start(
        script: [
          ScriptedProxy.propose(
            presentation: 'preview',
            content: 'Adding your workout — confirm below.',
            actions: [
              ScriptedProxy.createTask(title: 'Workout', time: '06:00'),
            ],
          ),
        ],
      );
      addTearDown(s.dispose);

      await s.service.sendMessage('add workout at 6am');
      expect(s.service.hasPendingPlan, isTrue);
      expect(s.anyLiveCard, isTrue);

      s.service.cancelPlan();

      expect(s.service.hasPendingPlan, isFalse);
      expect(s.anyLiveCard, isFalse);
      expect(s.latestCard!.isCancelled, isTrue);
      expect(s.titlesOn(today), isEmpty);
    });

    test('a bare "yes" with no plan pending never executes anything', () async {
      final s = await AiScenario.start(
        script: [ScriptedProxy.text('Nothing pending — what would you like?')],
      );
      addTearDown(s.dispose);

      await s.service.sendMessage('yes');

      expect(s.titlesOn(today), isEmpty);
      expect(s.titlesOn(tomorrow), isEmpty);
      final batch = await s.batches.findMostRecent();
      expect(batch, isNull);
    });
  });

  group('contract, pending fix', () {
    test(
      'after confirm, the next question carries no "previous plan" '
      'and produces no card',
      () async {
        final s = await suggestApplyConfirm();
        addTearDown(s.dispose);
        s.proxy.enqueue(
          ScriptedProxy.text('Tomorrow you have Workout at 18:00 and Music at 19:00.'),
        );

        await s.service.sendMessage('What do i have');

        final prompt = s.proxy.lastUserPrompt();
        expect(prompt, isNot(contains('Previous plan (user is refining this)')));
        expect(prompt, isNot(contains('Pending plan:')));
        expect(s.anyLiveCard, isFalse);
        expect(s.titlesOn(tomorrow), hasLength(2), reason: 'no duplicates');
      },
      skip: 'Phase 1.2 — stale pending clarification (review §1.1 #1)',
    );

    test(
      'ordinary questions never route as change requests',
      () {
        const questions = [
          'What do i have',
          'How fast can Answer',
          'Should i workout?',
          'Another',
          'What do I have later this week',
        ];
        for (final q in questions) {
          expect(
            AiIntentRouter.classify(q).kind,
            isNot(AiIntentKind.mutate),
            reason: '"$q" must not default to mutate',
          );
        }
      },
      skip: 'Phase 1.3 — router mutate default (review §1.1 #2)',
    );

    test(
      'an unknown verb from the model is rejected, not turned into a task',
      () async {
        final s = await AiScenario.start(
          script: [
            ScriptedProxy.propose(
              presentation: 'preview',
              content: 'Updating your workout.',
              actions: [
                {
                  'actionType': 'updateTask',
                  'parameters': {
                    'title': 'Workout',
                    'time': '07:00',
                    'duration': 30,
                    'date': 'today',
                  },
                },
              ],
            ),
            // The tool-error repair round: the model gives up politely.
            ScriptedProxy.text("I couldn't map that — could you say it again?"),
          ],
        );
        addTearDown(s.dispose);

        await s.service.sendMessage('update my workout to 7am');

        final card = s.latestCard;
        final createdTask = card?.plannedChanges?.actions.any(
          (a) => a.actionType == ActionType.createTask,
        );
        expect(createdTask ?? false, isFalse);
        expect(s.titlesOn(today), isEmpty);
      },
      skip: 'Phase 1.4 — AiAction.fromJson coerces unknown verbs (review §2 #2)',
    );

    test(
      'a task already on tomorrow is not proposed again for tomorrow',
      () async {
        final s = await AiScenario.start(
          script: [
            ScriptedProxy.propose(
              presentation: 'preview',
              content: 'Adding your workout tomorrow at 18:00.',
              actions: [
                ScriptedProxy.createTask(
                  title: 'Workout',
                  time: '18:00',
                  date: 'tomorrow',
                ),
              ],
            ),
          ],
        );
        addTearDown(s.dispose);
        s.planning.seed(title: 'Workout', dateKey: tomorrow, time: '18:00');

        await s.service.sendMessage('add workout tomorrow at 6pm');

        final card = s.latestCard;
        final flagged = card == null ||
            card.plannedChanges!.actions.isEmpty ||
            card.plannedChanges!.conflicts.isNotEmpty;
        expect(flagged, isTrue, reason: 'existing tomorrow task must be flagged');
      },
      skip: 'Phase 2.2 — dedup is today-only (review §1.1 #3)',
    );

    test(
      'confirming the same card twice creates the records once',
      () async {
        final s = await suggestApplyConfirm();
        addTearDown(s.dispose);
        final card = s.latestCard!;

        await s.service.confirmPlan(card.plannedChanges, card.id);

        expect(s.titlesOn(tomorrow), hasLength(2));
      },
      skip: 'Phase 2.1 — no idempotency key at execution (review §1.1 #3)',
    );

    test(
      'a history failure after the actions applied never claims '
      '"nothing was lost"',
      () async {
        final s = await AiScenario.start(
          script: [
            ScriptedProxy.propose(
              presentation: 'preview',
              content: 'Adding your workout — confirm below.',
              actions: [
                ScriptedProxy.createTask(title: 'Workout', time: '06:00'),
              ],
            ),
          ],
        );
        addTearDown(s.dispose);
        await s.service.sendMessage('add workout at 6am');
        s.history.failNextMarkExecuted = StateError('isar closed');
        final card = s.latestCard!;

        await s.service.confirmPlan(card.plannedChanges, card.id);

        expect(s.titlesOn(today), ['Workout']);
        expect(
          s.messages.any((m) => m.content.contains('nothing was lost')),
          isFalse,
        );
        expect(s.latestCard!.isExecuted, isTrue);
      },
      skip: 'Phase 2.3 — confirmPlan catch wraps post-execution writes '
          '(review §1.1 #3)',
    );

    test(
      'plan pending → unrelated question → model error → "yes" executes nothing',
      () async {
        final s = await AiScenario.start(
          script: [
            ScriptedProxy.propose(
              presentation: 'preview',
              content: 'Adding your workout — confirm below.',
              actions: [
                ScriptedProxy.createTask(title: 'Workout', time: '06:00'),
              ],
            ),
            // No reply queued for the next round → the model call fails.
          ],
        );
        addTearDown(s.dispose);
        await s.service.sendMessage('add workout at 6am');
        expect(s.anyLiveCard, isTrue);

        await s.service.sendMessage("what's the weather like");
        expect(s.anyLiveCard, isFalse, reason: 'the card was demoted');
        expect(s.lastAssistant.isError, isTrue);

        s.proxy.enqueue(ScriptedProxy.text('Nothing pending.'));
        await s.service.sendMessage('yes');

        expect(s.titlesOn(today), isEmpty);
      },
      skip: 'Phase 1.2 — _pendingPlan survives its demoted card (review §2.1 #3)',
    );

    test(
      'goal progress reaches the model in the goal\'s own units',
      () async {
        final s = await AiScenario.start(
          script: [ScriptedProxy.text("You're at 10 of 25 minutes today.")],
        );
        addTearDown(s.dispose);
        final now = DateTime.now();
        s.goals.goals.add(
          UserGoal(
            id: 'g-music',
            title: 'Music',
            categoryId: GoalCategories.productivity,
            status: GoalStatus.active,
            measurementKind: MeasurementKind.minutes,
            targetValue: 25,
            intensity: 3,
            periodStartMs: now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
            periodEndMs: now.add(const Duration(days: 27)).millisecondsSinceEpoch,
            repeatCadence: GoalRepeatCadence.daily,
            createdAtMs: 1,
            updatedAtMs: 1,
          ),
        );
        s.goals.checkIns.add(
          GoalCheckIn(
            goalId: 'g-music',
            dateKey: today,
            metCommitment: false,
            updatedAtMs: 1,
            value: 10,
          ),
        );

        await s.service.sendMessage('How am I doing on my goals?');

        final prompt = s.proxy.lastUserPrompt();
        expect(prompt, contains('10/25'));
        expect(prompt, isNot(contains('0/25 minutes')));
      },
      skip: 'Phase 3.1 — daysMet printed against a value target (review §1.1 #6)',
    );

    test(
      'a reminder-only task leaves its slot free',
      () async {
        final s = await AiScenario.start(
          script: [ScriptedProxy.text('Your afternoon is open.')],
        );
        addTearDown(s.dispose);
        // Tomorrow, so the assertion does not depend on the wall clock
        // (today's windows start at "now").
        s.planning.seed(
          title: 'Call mom',
          dateKey: tomorrow,
          time: '14:00',
          durationMinutes: 0,
        );

        await s.service.sendMessage('plan my afternoon tomorrow');

        final prompt = s.proxy.lastUserPrompt();
        // A 30-minute pseudo-block would split the day into
        // "07:00–14:00, 14:30–22:00"; a reminder leaves it whole.
        expect(prompt, contains('Free windows tomorrow'));
        expect(prompt, contains('07:00–22:00 (15h)'));
      },
      skip: 'Phase 3.2 — "?" end time becomes a 30-minute busy block '
          '(review §1.1 #7)',
    );
  });
}
