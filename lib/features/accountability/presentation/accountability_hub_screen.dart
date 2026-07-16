import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/points_providers.dart';
import '../application/stakes_providers.dart';
import '../domain/models/points.dart';
import '../domain/models/stake_challenge.dart';
import 'accountability_create_flow.dart';
import 'stake_challenge_detail_screen.dart';

/// The Accountability tab: active stakes first, decided history below,
/// one primary action (New Challenge). Entry point #2 of the three that
/// feed the unified creation flow (goal editor and circle are the others).
class AccountabilityHubScreen extends ConsumerWidget {
  const AccountabilityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(stakeChallengesStreamProvider);
    // PT-3 earn wiring: idempotent re-derivation sweep, once per session.
    ref.read(pointsEarnServiceProvider).sweepToday();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const PageTitle('Accountability'),
        actions: [_PointsChip(onTap: () => _showLedger(context, ref))],
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load challenges',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        data: (all) {
          final open = all.where((c) => !c.status.isTerminal).toList()
            ..sort((a, b) => a.deadlineMs.compareTo(b.deadlineMs));
          final done = all.where((c) => c.status.isTerminal).toList()
            ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));

          if (all.isEmpty) return const _EmptyState();

          // PSY-4-adjacent scoreboard: W/L across decided multi-party
          // challenges (side outcome, not personal — matches the stakes).
          final myUid = FirestorePaths.activeUid;
          var wins = 0;
          var losses = 0;
          for (final c in done.where((c) => c.type.isMultiParty)) {
            final r = c.results.where((r) => r.uid == myUid).firstOrNull;
            if (r == null) continue;
            r.sideWon ? wins++ : losses++;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (wins + losses > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Head-to-head record: $wins W – $losses L',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (open.isNotEmpty) ...[
                const SectionHeader('On the line'),
                const SizedBox(height: 8),
                for (final c in open) _ChallengeCard(challenge: c),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionHeader('Decided'),
                const SizedBox(height: 8),
                for (final c in done) _ChallengeCard(challenge: c),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accountability_new',
        onPressed: () => openAccountabilityCreateFlow(context),
        icon: const Icon(Icons.handshake_rounded),
        label: const Text('New Challenge'),
      ),
    );
  }
}

/// Balance chip in the hub app bar; tap for the ledger history sheet.
class _PointsChip extends ConsumerWidget {
  const _PointsChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(pointsBalanceProvider).valueOrNull ?? 0;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, size: 15, color: AppColors.amber),
              const SizedBox(width: 5),
              Text(
                '$balance',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLedger(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.inkCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final txns = ref.watch(pointsTxnsProvider).valueOrNull ?? const <PointsTxn>[];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: SectionHeader('Points'),
              ),
              Flexible(
                child: txns.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Earn points by checking in, finishing tasks, and '
                          'winning challenges.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: txns.length.clamp(0, 50),
                        itemBuilder: (_, i) {
                          final t = txns[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              _txnLabel(t.source),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                              ),
                            ),
                            trailing: Text(
                              t.amount >= 0 ? '+${t.amount}' : '${t.amount}',
                              style: TextStyle(
                                color: t.amount >= 0
                                    ? AppColors.statusGreen
                                    : AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

String _txnLabel(String source) => switch (source) {
      'signup_bonus' => 'Welcome bonus',
      'earn_checkin' => 'Daily check-in',
      'earn_task' => 'Task completed',
      'earn_goal' => 'Goal progress',
      'earn_streak' => 'Streak bonus',
      'earn_challenge_win' => 'Challenge won',
      'stake_lock' => 'Stake locked',
      'stake_release' => 'Stake returned',
      'stake_forfeit' => 'Stake forfeited',
      'spend_photo_removal' => 'Photo removed early',
      _ => source,
    };

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake_rounded, size: 56, color: AppColors.fg24),
            const SizedBox(height: 16),
            Text(
              'Put something on the line',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stake a photo you\'d hate your circle to see. '
              'Keep your word and it dies unseen — break it and it posts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final StakeChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.inkCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StakeChallengeDetailScreen(challengeId: c.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _StakeIcon(challenge: c),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.frozenGoal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(c),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: c.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(StakeChallenge c) {
    final goal = c.frozenGoal;
    final unit = goal.unitKind == 'minutes' ? 'min' : '×';
    final target = '${goal.unitTarget}$unit a day, ${goal.totalUnits} days';
    switch (c.status) {
      case StakeChallengeStatus.draft:
        return 'Waiting for photo check · $target';
      case StakeChallengeStatus.pendingAccept:
        final me = c.participant(FirestorePaths.activeUid);
        return me != null && !me.accepted
            ? 'You\'ve been challenged — tap to respond'
            : 'Waiting for your opponent to accept';
      case StakeChallengeStatus.active:
        final left = Duration(
          milliseconds:
              c.deadlineMs - DateTime.now().millisecondsSinceEpoch,
        );
        return '$target · ${_remaining(left)} left';
      case StakeChallengeStatus.pendingVerification:
        return 'Deadline passed — being decided';
      default:
        return target;
    }
  }

  String _remaining(Duration d) {
    if (d.isNegative) return 'no time';
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

class _StakeIcon extends StatelessWidget {
  const _StakeIcon({required this.challenge});

  final StakeChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (challenge.type) {
      StakeChallengeType.practice => (Icons.school_rounded, AppColors.textSoft),
      StakeChallengeType.h2hPoints ||
      StakeChallengeType.h2hMoney ||
      StakeChallengeType.teamPoints ||
      StakeChallengeType.teamMoney =>
        (Icons.sports_kabaddi_rounded, AppColors.amber),
      _ => (Icons.photo_camera_rounded, AppColors.coral),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: challenge.type == StakeChallengeType.practice
            ? AppColors.fg12
            : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final StakeChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StakeChallengeStatus.draft => ('checking', AppColors.amber),
      StakeChallengeStatus.pendingAccept => ('invited', AppColors.amber),
      StakeChallengeStatus.active => ('live', AppColors.statusGreen),
      StakeChallengeStatus.pendingVerification => (
        'deciding',
        AppColors.amber,
      ),
      StakeChallengeStatus.completedSuccess => ('kept', AppColors.statusGreen),
      StakeChallengeStatus.completedForfeit => ('forfeited', AppColors.danger),
      StakeChallengeStatus.cancelled => ('cancelled', AppColors.textFaint),
      StakeChallengeStatus.vetoed => ('vetoed', AppColors.textFaint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
