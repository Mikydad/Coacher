import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/challenge_providers.dart';
import '../../domain/models/challenge.dart';

class ChallengeVoteBanner extends ConsumerStatefulWidget {
  const ChallengeVoteBanner({
    super.key,
    required this.challenge,
    required this.circleId,
  });

  final Challenge challenge;
  final String circleId;

  @override
  ConsumerState<ChallengeVoteBanner> createState() =>
      _ChallengeVoteBannerState();
}

class _ChallengeVoteBannerState
    extends ConsumerState<ChallengeVoteBanner> {
  bool _loading = true;
  bool _hasVoted = false;
  int _voteCount = 0;
  bool _casting = false;

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  Future<void> _loadVotes() async {
    final repo = ref.read(challengeRepositoryProvider);
    final votes = await repo.getVotes(
        widget.circleId, widget.challenge.id);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() {
      _voteCount = votes.length;
      _hasVoted = votes.any((v) => v.userId == uid);
      _loading = false;
    });
  }

  Future<void> _castVote(bool approve) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _casting) return;
    setState(() => _casting = true);
    try {
      await ref.read(challengeRepositoryProvider).vote(
            challengeId: widget.challenge.id,
            circleId: widget.circleId,
            userId: uid,
            approve: approve,
            memberCount:
                widget.challenge.memberProgress.length.clamp(1, 999),
          );
      setState(() => _hasVoted = true);
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challenge.status != ChallengeStatus.pending) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F232A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB7FF00).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_rounded,
                  color: Color(0xFFB7FF00), size: 16),
              const SizedBox(width: 6),
              const Text(
                'Vote to approve',
                style: TextStyle(
                  color: Color(0xFFB7FF00),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                '$_voteCount voted',
                style: const TextStyle(
                  color: Color(0xFF8A8FA8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.challenge.title,
            style: const TextStyle(
              color: Color(0xFFF0F4FF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Target: ${widget.challenge.targetValue} ${widget.challenge.unit}'
            ' · ${widget.challenge.mode.name[0].toUpperCase()}${widget.challenge.mode.name.substring(1)} mode',
            style: const TextStyle(
              color: Color(0xFF8A8FA8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB7FF00),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _VoteButton(
                    label: 'Approve',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF4ADE80),
                    onPressed:
                        (_hasVoted || _casting) ? null : () => _castVote(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VoteButton(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFFF4D4D),
                    onPressed:
                        (_hasVoted || _casting) ? null : () => _castVote(false),
                  ),
                ),
              ],
            ),
          if (_hasVoted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Your vote has been recorded',
                style: TextStyle(
                  color: Color(0xFF8A8FA8),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: disabled ? color.withValues(alpha: 0.35) : color,
        side: BorderSide(
          color: disabled ? color.withValues(alpha: 0.2) : color,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
