import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/utils/stable_id.dart';
import '../../application/circle_providers.dart';
import '../../domain/models/circle_enums.dart';
import '../../domain/models/circle_member.dart';
import '../../domain/models/removal_vote.dart';

import '../../../../core/presentation/app_colors.dart';

class CircleMembersView extends ConsumerWidget {
  const CircleMembersView({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(circleDetailProvider(circleId));
    final membersAsync = ref.watch(circleMembersProvider(circleId));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final removalVotesAsync = ref.watch(circleRemovalVotesProvider(circleId));

    return membersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => const Center(
        child: Text(
          'Could not load members.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
      data: (members) {
        final circle = circleAsync.valueOrNull;
        final isModerator =
            circle != null && circle.moderatorIds.contains(uid);
        final isCreator = circle?.creatorId == uid;

        final pending = members
            .where((m) => m.status == CircleMemberStatus.pending)
            .toList();
        final active = members
            .where((m) => m.status == CircleMemberStatus.active)
            .toList();

        final activeRemovalVotes =
            removalVotesAsync.valueOrNull ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Removal vote banners (moderator only) ────────────────────────
            if (isModerator && activeRemovalVotes.isNotEmpty) ...[
              const _SectionHeader('Vote to remove', badge: 0, hideBadge: true),
              const SizedBox(height: 8),
              ...activeRemovalVotes.map(
                (v) {
                  final target = members.firstWhere(
                    (m) => m.userId == v.targetUserId,
                    orElse: () => CircleMember(
                      circleId: circleId,
                      userId: v.targetUserId,
                      displayName: v.targetUserId.substring(0, 6),
                      role: CircleMemberRole.member,
                      status: CircleMemberStatus.active,
                      joinedAtMs: 0,
                      updatedAtMs: 0,
                    ),
                  );
                  return _RemovalVoteBanner(
                    vote: v,
                    targetName: target.displayName,
                    currentUserId: uid,
                    circleId: circleId,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Pending approvals (moderator only) ──────────────────────────
            if (isModerator && pending.isNotEmpty) ...[
              _SectionHeader(
                'Pending requests',
                badge: pending.length,
              ),
              const SizedBox(height: 8),
              ...pending.map(
                (m) => _PendingMemberTile(
                  member: m,
                  onApprove: () => _approve(context, ref, m),
                  onDecline: () => _decline(context, ref, m),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Active members ───────────────────────────────────────────────
            _SectionHeader(
              'Members',
              badge: active.length,
            ),
            const SizedBox(height: 8),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No active members yet.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...active.map(
                (m) => _ActiveMemberTile(
                  member: m,
                  isMe: m.userId == uid,
                  canRemove: isCreator && m.userId != uid,
                  canVoteRemove: isModerator && !isCreator && m.userId != uid,
                  onRemove: () => _remove(context, ref, m),
                  onVoteRemove: () => _initiateVoteRemove(context, ref, m),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _initiateVoteRemove(
      BuildContext context, WidgetRef ref, CircleMember member) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now().millisecondsSinceEpoch;
    final vote = RemovalVote(
      id: StableId.generate('rv'),
      circleId: circleId,
      targetUserId: member.userId,
      initiatorId: uid,
      votes: {uid: true},
      status: RemovalVoteStatus.pending,
      createdAtMs: now,
      updatedAtMs: now,
    );
    try {
      await ref.read(removalVoteRepositoryProvider).createVote(vote);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Removal vote started for ${member.displayName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not start removal vote.')),
        );
      }
    }
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, CircleMember member) async {
    try {
      await ref
          .read(userCircleMembershipServiceProvider)
          .approveJoin(circleId, member.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.displayName} approved.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not approve. Try again.')),
        );
      }
    }
  }

  Future<void> _decline(
      BuildContext context, WidgetRef ref, CircleMember member) async {
    try {
      await ref
          .read(userCircleMembershipServiceProvider)
          .declineJoin(circleId, member.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.displayName} declined.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not decline. Try again.')),
        );
      }
    }
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, CircleMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Remove member?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from this circle?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(userCircleMembershipServiceProvider)
          .removeMember(circleId, member.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.displayName} removed.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove member. Try again.')),
        );
      }
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title,
      {required this.badge, this.hideBadge = false});
  final String title;
  final int badge;
  final bool hideBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        if (!hideBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Pending member tile ───────────────────────────────────────────────────────

class _PendingMemberTile extends StatelessWidget {
  const _PendingMemberTile({
    required this.member,
    required this.onApprove,
    required this.onDecline,
  });

  final CircleMember member;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _AvatarInitial(
              name: member.displayName, userId: member.userId),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onDecline,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active member tile ────────────────────────────────────────────────────────

class _ActiveMemberTile extends StatelessWidget {
  const _ActiveMemberTile({
    required this.member,
    required this.isMe,
    required this.canRemove,
    required this.canVoteRemove,
    required this.onRemove,
    required this.onVoteRemove,
  });

  final CircleMember member;
  final bool isMe;
  final bool canRemove;
  final bool canVoteRemove;
  final VoidCallback onRemove;
  final VoidCallback onVoteRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: (canRemove || canVoteRemove)
          ? () => _showRemoveMenu(context)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe
                ? AppColors.accent.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            _AvatarInitial(
                name: member.displayName, userId: member.userId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.displayName + (isMe ? ' (you)' : ''),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (member.role == CircleMemberRole.moderator) ...[
                        const SizedBox(width: 6),
                        _ModeratorBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Joined ${_formatDate(member.joinedAtMs)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (canRemove || canVoteRemove)
              const Icon(Icons.more_vert_rounded,
                  color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showRemoveMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            if (canRemove)
              ListTile(
                leading: const Icon(Icons.person_remove_rounded,
                    color: AppColors.danger),
                title: Text(
                  'Remove ${member.displayName}',
                  style: const TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemove();
                },
              ),
            if (canVoteRemove)
              ListTile(
                leading: const Icon(Icons.how_to_vote_rounded,
                    color: AppColors.amberDeep),
                title: Text(
                  'Vote to remove ${member.displayName}',
                  style: const TextStyle(color: AppColors.amberDeep),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onVoteRemove();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Removal vote banner ───────────────────────────────────────────────────────

class _RemovalVoteBanner extends ConsumerStatefulWidget {
  const _RemovalVoteBanner({
    required this.vote,
    required this.targetName,
    required this.currentUserId,
    required this.circleId,
  });

  final RemovalVote vote;
  final String targetName;
  final String currentUserId;
  final String circleId;

  @override
  ConsumerState<_RemovalVoteBanner> createState() =>
      _RemovalVoteBannerState();
}

class _RemovalVoteBannerState
    extends ConsumerState<_RemovalVoteBanner> {
  bool _casting = false;

  bool get _hasVoted =>
      widget.vote.votes.containsKey(widget.currentUserId);

  Future<void> _cast(bool approve) async {
    if (_casting || _hasVoted) return;
    setState(() => _casting = true);
    try {
      await ref.read(removalVoteRepositoryProvider).castVote(
            circleId: widget.circleId,
            voteId: widget.vote.id,
            userId: widget.currentUserId,
            approve: approve,
          );
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvals =
        widget.vote.votes.values.where((v) => v).length;
    final total = widget.vote.votes.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amberDeep.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_rounded,
                  color: AppColors.amberDeep, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Vote to remove',
                style: TextStyle(
                  color: AppColors.amberDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                '$approvals/$total voted approve',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.targetName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_hasVoted || _casting)
                      ? null
                      : () => _cast(true),
                  icon: const Icon(Icons.check_circle_rounded,
                      size: 16),
                  label: const Text('Approve'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _hasVoted
                        ? AppColors.success.withValues(alpha: 0.35)
                        : AppColors.success,
                    side: BorderSide(
                      color: _hasVoted
                          ? AppColors.success
                              .withValues(alpha: 0.2)
                          : AppColors.success,
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_hasVoted || _casting)
                      ? null
                      : () => _cast(false),
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _hasVoted
                        ? AppColors.danger.withValues(alpha: 0.35)
                        : AppColors.danger,
                    side: BorderSide(
                      color: _hasVoted
                          ? AppColors.danger
                              .withValues(alpha: 0.2)
                          : AppColors.danger,
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          if (_hasVoted)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Your vote has been recorded',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeratorBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Mod',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name, required this.userId});
  final String name;
  final String userId;

  static const _colors = [
    AppColors.accent,
    AppColors.cyanDeep,
    AppColors.orange,
    AppColors.pink,
    AppColors.violet,
    AppColors.mint,
    AppColors.yellow,
    AppColors.danger,
  ];

  Color get _color => _colors[userId.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: _color.withOpacity(0.2),
      child: Text(
        initial,
        style: TextStyle(
          color: _color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatDate(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
