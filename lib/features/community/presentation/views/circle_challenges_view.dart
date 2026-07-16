import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/presentation/keyboard_dismiss.dart';
import '../../../accountability/presentation/accountability_create_flow.dart';
import '../../application/challenge_providers.dart';
import '../../application/circle_providers.dart';
import '../../data/circle_proof_storage.dart';
import '../../domain/models/challenge.dart';
import '../sheets/challenge_create_sheet.dart';
import '../widgets/challenge_vote_banner.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../education/presentation/help_dot.dart';
import '../../../../core/presentation/async_value_ui.dart';

class CircleChallengesView extends ConsumerWidget {
  const CircleChallengesView({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingChallengesProvider(circleId));
    final activeAsync = ref.watch(activeChallengesProvider(circleId));
    final completedAsync = ref.watch(completedChallengesProvider(circleId));

    return Scaffold(
      backgroundColor: AppColors.dark0D1117,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ChallengeCreateSheet(circleId: circleId),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add),
        label: const Text(
          'New challenge',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Entry point #3 into the unified accountability flow — a real
          // stake, distinct from the casual circle challenges below.
          _StakeEntryCard(circleId: circleId),
          const SizedBox(height: 16),
          // Pending — vote banners
          pendingAsync.when(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader('Waiting for votes', helpId: 'challengeVoting'),
                  ...list.map(
                    (c) =>
                        ChallengeVoteBanner(challenge: c, circleId: circleId),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => swallowedAsyncError(
              'circle_challenges_view',
              e,
              const SizedBox.shrink(),
            ),
          ),

          // Active challenges
          activeAsync.when(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader('Active challenges', helpId: 'challengeVoting'),
                  ...list.map(
                    (c) => c.mode == ChallengeMode.competition
                        ? _CompetitionChallengeCard(
                            challenge: c,
                            circleId: circleId,
                          )
                        : _TeamChallengeCard(challenge: c, circleId: circleId),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              'Error loading challenges: $e',
              style: TextStyle(color: AppColors.danger),
            ),
          ),

          // Completed — collapsed section
          completedAsync.when(
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return _CompletedSection(challenges: list);
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => swallowedAsyncError(
              'circle_challenges_view',
              e,
              const SizedBox.shrink(),
            ),
          ),

          // Empty state
          if (pendingAsync.asData?.value.isEmpty == true &&
              activeAsync.asData?.value.isEmpty == true &&
              completedAsync.asData?.value.isEmpty == true)
            _EmptyState(
              onAdd: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ChallengeCreateSheet(circleId: circleId),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.helpId});
  final String text;

  /// Feature-guide id — renders a `?` that opens the help sheet.
  final String? helpId;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: helpId == null
          ? label
          : Row(children: [label, HelpDot(helpId!)]),
    );
  }
}

// ─── Competition card ─────────────────────────────────────────────────────────

class _CompetitionChallengeCard extends ConsumerWidget {
  const _CompetitionChallengeCard({
    required this.challenge,
    required this.circleId,
  });

  final Challenge challenge;
  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final sortedEntries = challenge.memberProgress.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final endsAt = DateTime.fromMillisecondsSinceEpoch(challenge.endsAtMs);
    final daysLeft = endsAt.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$daysLeft d left',
                style: TextStyle(
                  color: daysLeft <= 3 ? AppColors.danger : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${challenge.targetValue} ${challenge.unit}',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Ranked list
          ...sortedEntries.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final userId = entry.value.key;
            final progress = entry.value.value;
            final isMe = userId == uid;
            return _RankRow(
              rank: rank,
              userId: userId,
              progress: progress,
              target: challenge.targetValue,
              unit: challenge.unit,
              isMe: isMe,
            );
          }),

          // Standalone manual update
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => _showManualUpdate(context, ref, uid),
              icon: Icon(
                Icons.add_circle_outline,
                size: 16,
                color: AppColors.accent,
              ),
              label: Text(
                'Log progress',
                style: TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualUpdate(BuildContext context, WidgetRef ref, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualProgressSheet(
        challenge: challenge,
        circleId: circleId,
        userId: uid,
      ),
    );
  }
}

// ─── Team card ────────────────────────────────────────────────────────────────

class _TeamChallengeCard extends ConsumerWidget {
  const _TeamChallengeCard({required this.challenge, required this.circleId});

  final Challenge challenge;
  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final progress = challenge.teamTotal.clamp(0, challenge.targetValue);
    final ratio = challenge.targetValue > 0
        ? progress / challenge.targetValue
        : 0.0;

    final endsAt = DateTime.fromMillisecondsSinceEpoch(challenge.endsAtMs);
    final daysLeft = endsAt.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, color: AppColors.periwinkle, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$daysLeft d left',
                style: TextStyle(
                  color: daysLeft <= 3 ? AppColors.danger : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.teamTotal}/${challenge.targetValue} ${challenge.unit}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.toDouble(),
              backgroundColor: AppColors.surfaceSlate,
              color: AppColors.accent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),

          // Member chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: challenge.memberProgress.entries.map((e) {
              final isMe = e.key == uid;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: isMe
                      ? Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Text(
                  '${isMe ? "You" : e.key.substring(0, 4)}  ${e.value}',
                  style: TextStyle(
                    color: isMe ? AppColors.accent : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _ManualProgressSheet(
                  challenge: challenge,
                  circleId: circleId,
                  userId: uid,
                ),
              ),
              icon: Icon(
                Icons.add_circle_outline,
                size: 16,
                color: AppColors.periwinkle,
              ),
              label: Text(
                'Log team progress',
                style: TextStyle(color: AppColors.periwinkle, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rank row ─────────────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.userId,
    required this.progress,
    required this.target,
    required this.unit,
    required this.isMe,
  });

  final int rank;
  final String userId;
  final int progress;
  final int target;
  final String unit;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
        ? '🥈'
        : rank == 3
        ? '🥉'
        : '#$rank';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.accent.withValues(alpha: 0.06)
            : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: isMe
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(medal, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              isMe ? 'You' : userId.substring(0, 6),
              style: TextStyle(
                color: isMe ? AppColors.accent : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '$progress/$target $unit',
            style: TextStyle(
              color: isMe ? AppColors.accent : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completed section ────────────────────────────────────────────────────────

class _CompletedSection extends StatefulWidget {
  const _CompletedSection({required this.challenges});
  final List<Challenge> challenges;

  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Text(
                'COMPLETED',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.challenges.length}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              const Spacer(),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
        if (_expanded)
          ...widget.challenges.map(
            (c) => Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.title,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    c.mode == ChallengeMode.team
                        ? '${c.teamTotal}/${c.targetValue} ${c.unit}'
                        : '${c.targetValue} ${c.unit}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Manual progress sheet ────────────────────────────────────────────────────

class _ManualProgressSheet extends ConsumerStatefulWidget {
  const _ManualProgressSheet({
    required this.challenge,
    required this.circleId,
    required this.userId,
  });

  final Challenge challenge;
  final String circleId;
  final String userId;

  @override
  ConsumerState<_ManualProgressSheet> createState() =>
      _ManualProgressSheetState();
}

class _ManualProgressSheetState extends ConsumerState<_ManualProgressSheet> {
  final _valueController = TextEditingController();
  File? _proofImage;
  bool _uploading = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Same compression as the chat proof picker — original camera images
    // can hit the 10MB storage-rules limit and every member re-downloads
    // them full size.
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (xFile == null) return;
    setState(() => _proofImage = File(xFile.path));
  }

  Future<void> _submit() async {
    final delta = int.tryParse(_valueController.text.trim());
    if (delta == null || delta <= 0) return;
    setState(() => _uploading = true);
    try {
      if (_proofImage != null) {
        await ref
            .read(circleProofStorageProvider)
            .uploadChallengeProof(
              circleId: widget.circleId,
              challengeId: widget.challenge.id,
              userId: widget.userId,
              file: _proofImage!,
            );
      }
      await ref
          .read(challengeRepositoryProvider)
          .updateProgress(
            circleId: widget.circleId,
            challengeId: widget.challenge.id,
            userId: widget.userId,
            delta: delta,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.fg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log progress',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.challenge.title,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onTapOutside: (_) => dismissKeyboard(context),
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Amount (${widget.challenge.unit})',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _proofImage == null
                              ? 'Add proof photo (optional)'
                              : 'Photo selected',
                          style: TextStyle(
                            color: _proofImage == null
                                ? AppColors.textMuted
                                : AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _uploading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No challenges yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a challenge to motivate your circle',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New challenge'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry card into the unified accountability flow (real stakes), shown
/// above the casual circle challenges so the two never get confused.
class _StakeEntryCard extends StatelessWidget {
  const _StakeEntryCard({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.coral.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            openAccountabilityCreateFlow(context, prefilledCircleId: circleId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.coral),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stake something real',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Put an embarrassing photo on the line — this circle '
                      'sees it if you fail.',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSoft),
            ],
          ),
        ),
      ),
    );
  }
}
