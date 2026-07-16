import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/stakes_providers.dart';
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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const PageTitle('Accountability'),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
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
    final isPractice = challenge.type == StakeChallengeType.practice;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPractice
            ? AppColors.fg12
            : AppColors.coral.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isPractice ? Icons.school_rounded : Icons.photo_camera_rounded,
        size: 20,
        color: isPractice ? AppColors.textSoft : AppColors.coral,
      ),
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
