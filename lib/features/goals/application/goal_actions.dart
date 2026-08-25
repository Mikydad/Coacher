import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../accountability/application/stakes_providers.dart';
import '../../accountability/domain/models/stake_challenge.dart';
import '../../analytics/application/delivery_providers.dart';
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
  final stakes = ref.read(stakeChallengesStreamProvider).value ?? const [];
  StakeChallenge? liveStake;
  for (final c in stakes) {
    if (!c.status.isTerminal && c.frozenGoal.linkedGoalId == goal.id) {
      liveStake = c;
      break;
    }
  }

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
    final choice = await _showStakedDeleteDialog(context, goal, liveStake);
    deleteConfirmed = choice != null;
    surrender = choice == true;
  }
  if (!deleteConfirmed || !context.mounted) return false;

  final messenger = ScaffoldMessenger.maybeOf(context);
  final stakeToSurrender = surrender ? liveStake : null;

  await ref.read(goalReminderSyncServiceProvider).cancelForGoal(goal.id);
  await ref.read(goalsRepositoryProvider).deleteGoal(goal.id);
  await clearEntityCoachingCachesForGoal(ref, goal.id);
  await ref.read(goalBlockSyncServiceProvider).removeBlockForGoal(goal.id);
  invalidateGoals(ref, goalId: goal.id);

  if (stakeToSurrender != null) {
    // Network-inherent, optimistic-then-honest: the goal is already gone
    // locally; the surrender reconciles in the background and only a
    // genuine failure speaks up (the stake then simply stays live).
    final functions = ref.read(stakeFunctionsProvider);
    unawaited(() async {
      try {
        await functions.surrender(stakeToSurrender.id);
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
  return true;
}

/// Server messages are written for users ("No mercy veto available…");
/// surface them, fall back to the offline story.
String _httpsErrorMessage(Object e) {
  final raw = e.toString();
  final marker = raw.indexOf('] ');
  if (marker > 0 && marker + 2 < raw.length) return raw.substring(marker + 2);
  return 'Check your connection and try again from the stake page.';
}

/// Returns null = cancelled, false = delete only, true = delete + surrender.
Future<bool?> _showStakedDeleteDialog(
  BuildContext context,
  UserGoal goal,
  StakeChallenge stake,
) {
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
    _ => canSurrender ? 'Surrendering ends it now.' : null,
  };

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete goal?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remove “${goal.title}” and all its actions, milestones, and '
            'check-ins?',
          ),
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
              'This goal has a live stake. Deleting the goal does NOT end '
              'it. $keepLine',
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
            child: const Text('Delete & surrender stake'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Delete, keep stake'),
        ),
      ],
    ),
  );
}
