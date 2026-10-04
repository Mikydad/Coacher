import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../accountability/application/stakes_providers.dart';
import '../../accountability/domain/models/stake_challenge.dart';
import '../../analytics/application/delivery_providers.dart';
import '../../reminders/domain/models/reminder_occurrence_enums.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';
import 'goals_providers.dart';

/// Confirmation dialog + full goal delete (reminders, coaching caches, time
/// block). Shared by the detail-screen menu and the goal-card swipe action
/// so the two paths can't drift in side effects. Returns true when deleted.
///
/// A goal with a LIVE stake gets the honest version (2026-08-25): deleting
/// the goal never silently kills the commitment — the stake keeps running
/// in Accountability and its consequence still fires at the deadline. The
/// dialog says so, and for solo stakes offers a priced early exit
/// (surrender): money donates now, a photo consumes the monthly mercy
/// veto, the loss lands on the record as `surrendered`.
Future<bool> confirmDeleteGoal(
  BuildContext context,
  WidgetRef ref,
  UserGoal goal,
) async {
  final liveStake = ref.read(liveStakeForGoalProvider(goal.id));

  bool deleteConfirmed;
  bool surrender = false;
  if (liveStake == null) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
          'Remove “${goal.title}” and all its actions, milestones, and '
          'check-ins?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    deleteConfirmed = ok == true;
  } else {
    // null = cancelled, false = delete only, true = delete + surrender.
    final choice = await showStakedGoalActionDialog(
      context,
      goal,
      liveStake,
      action: StakedGoalAction.delete,
    );
    deleteConfirmed = choice != null;
    surrender = choice == true;
  }
  if (!deleteConfirmed || !context.mounted) return false;

  final messenger = ScaffoldMessenger.maybeOf(context);
  final stakeToSurrender = surrender ? liveStake : null;

  await ref.read(goalReminderSyncServiceProvider).cancelForGoal(goal.id);
  // The occurrences go with the goal, as a deleted task's do — a lingering
  // overdue day would keep a ghost row on the Recovery Card.
  await ref.read(reminderOccurrenceServiceProvider).deleteForEntity(goal.id);
  await ref.read(goalsRepositoryProvider).deleteGoal(goal.id);
  await clearEntityCoachingCachesForGoal(ref, goal.id);
  await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(goal.id);
  invalidateGoals(ref, goalId: goal.id);

  if (stakeToSurrender != null) {
    _surrenderInBackground(ref, messenger, stakeToSurrender);
  }
  return true;
}

/// Marks [goal] completed (reminders off, coaching caches cleared, time
/// block removed). One path for the detail-screen menu (2026-09-15).
///
/// A goal with a LIVE stake gets the same honesty as delete: completing the
/// goal does NOT settle the stake — the server only decides at the
/// deadline, from the proof logged on the challenge page — so the dialog
/// says so and offers the priced early exit (surrender) for solo stakes.
/// Returns true when the goal was completed.
Future<bool> completeGoal(
  BuildContext context,
  WidgetRef ref,
  UserGoal goal,
) async {
  final liveStake = ref.read(liveStakeForGoalProvider(goal.id));
  var surrender = false;
  if (liveStake != null) {
    final choice = await showStakedGoalActionDialog(
      context,
      goal,
      liveStake,
      action: StakedGoalAction.complete,
    );
    if (choice == null) return false;
    surrender = choice;
  }
  if (!context.mounted) return false;

  final messenger = ScaffoldMessenger.maybeOf(context);
  final stakeToSurrender = surrender ? liveStake : null;

  final done = goal.copyWith(
    status: GoalStatus.completed,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
  );
  await ref.read(goalsRepositoryProvider).upsertGoal(done);
  // Today's open day, if any, ends as "completed" on the record before the
  // re-arm closes the rest as expired.
  await ref
      .read(reminderOccurrenceServiceProvider)
      .resolveAllOpenForEntity(
        done.id,
        kind: ReminderResolutionKind.completed,
      );
  await ref.read(goalReminderSyncServiceProvider).applyForGoal(done);
  await clearEntityCoachingCachesForGoal(ref, done.id);
  await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(goal.id);
  invalidateGoals(ref, goalId: goal.id);

  if (stakeToSurrender != null) {
    _surrenderInBackground(ref, messenger, stakeToSurrender);
  }
  return true;
}

/// Network-inherent, optimistic-then-honest: the goal action already
/// landed locally; the surrender reconciles in the background and only a
/// genuine failure speaks up (the stake then simply stays live).
void _surrenderInBackground(
  WidgetRef ref,
  ScaffoldMessengerState? messenger,
  StakeChallenge stake,
) {
  final functions = ref.read(stakeFunctionsProvider);
  unawaited(() async {
    try {
      await functions.surrender(stake.id);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Stake surrendered.')),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'Surrender failed — the stake stays live in Accountability. '
            '${_httpsErrorMessage(e)}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }());
}

/// Server messages are written for users ("No mercy veto available…");
/// surface them, fall back to the offline story.
String _httpsErrorMessage(Object e) {
  final raw = e.toString();
  final marker = raw.indexOf('] ');
  if (marker > 0 && marker + 2 < raw.length) return raw.substring(marker + 2);
  return 'Check your connection and try again from the stake page.';
}

/// What the user is about to do to a goal that has a live stake.
enum StakedGoalAction { delete, complete }

/// The honest dialog for acting on a goal with a LIVE stake. Returns
/// null = cancelled, false = act but keep the stake, true = act + surrender.
/// Visible for tests; production callers are [confirmDeleteGoal] and
/// [completeGoal].
Future<bool?> showStakedGoalActionDialog(
  BuildContext context,
  UserGoal goal,
  StakeChallenge stake, {
  required StakedGoalAction action,
}) {
  final verb = switch (action) {
    StakedGoalAction.delete => 'Delete',
    StakedGoalAction.complete => 'Complete',
  };
  final title = switch (action) {
    StakedGoalAction.delete => 'Delete goal?',
    StakedGoalAction.complete => 'Mark complete?',
  };
  final question = switch (action) {
    StakedGoalAction.delete =>
      'Remove “${goal.title}” and all its actions, milestones, and '
          'check-ins?',
    StakedGoalAction.complete =>
      'Mark “${goal.title}” as completed? It moves to your archive and '
          'stops reminding and coaching.',
  };
  final doesNotEnd = switch (action) {
    StakedGoalAction.delete => 'Deleting the goal does NOT end it.',
    StakedGoalAction.complete =>
      'Completing the goal does NOT end it — a stake can\'t be won early; '
          'it decides at its deadline from the proof on the challenge page.',
  };
  final me = stake.participant(FirestorePaths.activeUid);
  final kind = me?.stakeKind ?? '';
  final canSurrender =
      !stake.type.isMultiParty &&
      stake.status == StakeChallengeStatus.active &&
      kind != 'points';

  final String keepLine;
  if (stake.type.isMultiParty) {
    keepLine =
        'Others are in this challenge, so it can\'t be surrendered — it '
        'keeps running in Accountability and decides at its deadline.';
  } else if (stake.status == StakeChallengeStatus.pendingVerification) {
    keepLine =
        'Its deadline has already passed — the outcome is being decided '
        'on its own. Manage it from Accountability.';
  } else {
    keepLine =
        'It keeps running in Accountability, and its consequence still '
        'fires if you don\'t finish it.';
  }

  final String? surrenderLine = switch (kind) {
    'money' => () {
      final cents = me?.stakeAmount ?? 0;
      final amount =
          '\$${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
      return 'Surrendering ends it now — your $amount is donated.';
    }(),
    'photo' =>
      'Surrendering ends it now by consuming your monthly mercy veto — '
          'the photo is deleted unseen. If no veto is available, the '
          'surrender is refused and the stake stays live: finish it or '
          'the photo reveals at the deadline.',
    // Public commitment (FR-16): quitting counts as a miss — no free
    // escape hatch, the missed card goes on the record.
    'public' =>
      'Surrendering counts as a miss — it goes on your record, and your '
          'missed card will be waiting on the challenge page.',
    _ => canSurrender ? 'Surrendering ends it now.' : null,
  };

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Text(
              'This goal has a live stake. $doesNotEnd $keepLine',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
          if (canSurrender && surrenderLine != null) ...[
            const SizedBox(height: 10),
            Text(
              surrenderLine,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Cancel'),
        ),
        if (canSurrender)
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('$verb & surrender stake'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('$verb, keep stake'),
        ),
      ],
    ),
  );
}
