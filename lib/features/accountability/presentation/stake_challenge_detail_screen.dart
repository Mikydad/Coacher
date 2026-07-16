import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/stake_functions.dart';
import '../application/stakes_providers.dart';
import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';
import 'stake_reveal_viewer_screen.dart';
import 'stake_timer_screen.dart';

/// One challenge: the unit grid, evidence log, and the actions the current
/// status allows. Everything renders from the local Isar mirror — airplane
/// mode shows the last-known truth; actions that need the server say so
/// honestly when they fail.
class StakeChallengeDetailScreen extends ConsumerWidget {
  const StakeChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync =
        ref.watch(stakeChallengeStreamProvider(challengeId));
    final evidenceAsync = ref.watch(stakeEvidenceStreamProvider(challengeId));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const PageTitle('Challenge'),
      ),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        data: (challenge) {
          if (challenge == null) {
            return Center(
              child: Text('Challenge not found',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          final evidence = evidenceAsync.value ?? const <StakeEvidence>[];
          return _Body(challenge: challenge, evidence: evidence);
        },
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.challenge, required this.evidence});

  final StakeChallenge challenge;
  final List<StakeEvidence> evidence;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  StakeChallenge get c => widget.challenge;

  /// Sum of evidence per unit for the signed-in user.
  Map<int, int> get _loggedByUnit {
    final uid = FirestorePaths.activeUid;
    final sums = <int, int>{};
    for (final e in widget.evidence) {
      if (e.uid != uid) continue;
      sums[e.unitIndex] = (sums[e.unitIndex] ?? 0) + e.amount;
    }
    return sums;
  }

  @override
  Widget build(BuildContext context) {
    final logged = _loggedByUnit;
    final mercy = c.mercyUnitTarget;
    final today = c.todayUnitIndex;
    final unitLabel = c.frozenGoal.unitKind == 'minutes' ? 'min' : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Text(
          c.frozenGoal.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${c.frozenGoal.unitTarget}$unitLabel a day · '
          '${c.frozenGoal.totalUnits} days · ${c.mode ?? 'disciplined'}',
          style: TextStyle(color: AppColors.textSoft, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _statusBanner(),
        if (c.photoState == StakePhotoState.revealed) ...[
          const SizedBox(height: 12),
          _revealCard(),
        ],
        const SizedBox(height: 20),
        const SectionHeader('Days'),
        const SizedBox(height: 10),
        _unitGrid(logged, mercy, today),
        const SizedBox(height: 8),
        Text(
          'A day passes at ≥$mercy$unitLabel — the 25% mercy.',
          style: TextStyle(color: AppColors.textFaint, fontSize: 12),
        ),
        const SizedBox(height: 20),
        if (c.status == StakeChallengeStatus.active &&
            today >= 0 &&
            today < c.frozenGoal.totalUnits)
          _todayActions(logged[today] ?? 0, unitLabel),
        if (c.status == StakeChallengeStatus.pendingVerification &&
            c.type == StakeChallengeType.soloPhoto)
          _vetoAction(),
        if (c.status == StakeChallengeStatus.draft ||
            c.status == StakeChallengeStatus.pendingAccept)
          _cancelAction(),
      ],
    );
  }

  Widget _statusBanner() {
    final (text, color) = switch (c.status) {
      StakeChallengeStatus.draft => (
        'Your photo is being checked. The challenge arms itself when it '
            'passes.',
        AppColors.amber,
      ),
      StakeChallengeStatus.active => (
        _deadlineText(),
        AppColors.statusGreen,
      ),
      StakeChallengeStatus.pendingVerification => (
        'Deadline passed. The server is deciding — late-synced evidence '
            'still counts for 12 hours.',
        AppColors.amber,
      ),
      StakeChallengeStatus.completedSuccess => (
        'You kept your word. The photo is gone — nobody ever saw it.',
        AppColors.statusGreen,
      ),
      StakeChallengeStatus.completedForfeit => (
        'Forfeited.',
        AppColors.danger,
      ),
      StakeChallengeStatus.vetoed => (
        'Lost, but the mercy veto held the photo back. It stays on your '
            'record.',
        AppColors.textSoft,
      ),
      StakeChallengeStatus.cancelled => (
        c.photoState == StakePhotoState.rejected
            ? 'The photo was rejected by content screening — this stake '
                'never armed. Try a different photo.'
            : 'Cancelled.',
        AppColors.textFaint,
      ),
      StakeChallengeStatus.pendingAccept => (
        'Waiting for your opponent.',
        AppColors.amber,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.45),
      ),
    );
  }

  String _deadlineText() {
    final left = Duration(
      milliseconds: c.deadlineMs - DateTime.now().millisecondsSinceEpoch,
    );
    if (left.isNegative) return 'Deadline reached — syncing the outcome.';
    if (left.inDays >= 1) {
      return 'Live. ${left.inDays}d ${left.inHours % 24}h until the deadline.';
    }
    return 'Live. ${left.inHours}h ${left.inMinutes % 60}m until the deadline.';
  }

  Widget _unitGrid(Map<int, int> logged, int mercy, int today) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < c.frozenGoal.totalUnits; i++)
          _unitCell(i, logged[i] ?? 0, mercy, today),
      ],
    );
  }

  Widget _unitCell(int index, int amount, int mercy, int today) {
    final passed = amount >= mercy;
    final isToday = index == today && !c.status.isTerminal;
    final isPast = index < today;
    final Color bg;
    final Color fgColor;
    if (passed) {
      bg = AppColors.statusGreen.withValues(alpha: 0.18);
      fgColor = AppColors.statusGreen;
    } else if (isPast) {
      bg = AppColors.danger.withValues(alpha: 0.12);
      fgColor = AppColors.danger;
    } else {
      bg = AppColors.inkCard;
      fgColor = AppColors.textSoft;
    }
    return Container(
      width: 42,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? AppColors.accent : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${index + 1}',
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            passed
                ? Icons.check_rounded
                : isPast
                    ? Icons.close_rounded
                    : Icons.circle_outlined,
            size: 13,
            color: fgColor,
          ),
        ],
      ),
    );
  }

  // ─── Today ─────────────────────────────────────────────────────────────────

  Widget _todayActions(int loggedToday, String unitLabel) {
    final target = c.frozenGoal.unitTarget;
    final isMinutes = c.frozenGoal.unitKind == 'minutes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Today'),
        const SizedBox(height: 8),
        Text(
          loggedToday >= c.mercyUnitTarget
              ? 'Done — $loggedToday$unitLabel logged. Day ${c.todayUnitIndex + 1} passed.'
              : '$loggedToday of $target$unitLabel logged.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (isMinutes)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StakeTimerScreen(challenge: c),
                ),
              ),
              icon: const Icon(Icons.timer_rounded),
              label: const Text('Start the timer'),
            ),
          )
        else if (c.type == StakeChallengeType.practice)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _logPracticeCount(target),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Record today'),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _captureCountProof,
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('Capture proof'),
            ),
          ),
      ],
    );
  }

  Future<void> _logPracticeCount(int amount) async {
    setState(() => _busy = true);
    // CC-7 — practice is self-report; the same evidence loop, zero stakes.
    await ref.read(stakesRepositoryProvider).addEvidence(
          challengeId: c.id,
          unitIndex: c.todayUnitIndex,
          amount: amount,
          source: 'checkin',
        );
    if (mounted) setState(() => _busy = false);
  }

  /// M-5 — count goals prove with an in-app CAMERA capture only (no
  /// gallery). The amount is recorded immediately (local-first); the photo
  /// uploads to the circle-reviewable evidence path in the background.
  Future<void> _captureCountProof() async {
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (shot == null || !mounted) return;
    final amount = await _askAmount();
    if (amount == null || !mounted) return;

    setState(() => _busy = true);
    final repo = ref.read(stakesRepositoryProvider);
    final evidence = await repo.addEvidence(
      challengeId: c.id,
      unitIndex: c.todayUnitIndex,
      amount: amount,
      source: 'camera',
    );
    // Background upload — evidence stands locally either way; the photo is
    // the circle's dispute-review artifact, not the record itself.
    final uid = FirestorePaths.activeUid;
    final path = 'stake_evidence/${c.id}/$uid/${evidence.id}.jpg';
    FirebaseStorage.instance
        .ref(path)
        .putFile(File(shot.path), SettableMetadata(contentType: 'image/jpeg'))
        .catchError((Object e) {
      debugPrint('stake evidence photo upload failed (kept locally): $e');
      // ignore: invalid_return_type_for_catch_error
      return null;
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<int?> _askAmount() {
    var value = c.frozenGoal.unitTarget;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('How many?'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () =>
                    setDialogState(() => value = value > 1 ? value - 1 : 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$value',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: () => setDialogState(() => value += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(value),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  /// Owner-side view of their own live reveal (P-4/P-5): countdown, a way
  /// to face it, and the point-removal stub (price lands with the points
  /// economy in Phase 2 — the 30% floor is already enforced server-side).
  Widget _revealCard() {
    final expires = c.revealExpiresAtMs;
    final left = expires == null
        ? null
        : Duration(
            milliseconds: expires - DateTime.now().millisecondsSinceEpoch,
          );
    final leftLabel = left == null || left.isNegative
        ? 'about to expire'
        : left.inHours >= 1
            ? '${left.inHours}h ${left.inMinutes % 60}m'
            : '${left.inMinutes}m';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your photo is live in the circle — $leftLabel left. It deletes '
            'itself when the window closes.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        StakeRevealViewerScreen(challengeId: c.id),
                  ),
                ),
                child: const Text('Face it'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Early removal costs points — coming with the points '
                  'update.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Veto (M-6) ────────────────────────────────────────────────────────────

  Widget _vetoAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Mercy veto'),
        const SizedBox(height: 8),
        Text(
          'If this decides against you, your one monthly veto can stop the '
          'photo from posting. The loss still goes on your record.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _requestVeto,
            icon: const Icon(Icons.shield_rounded),
            label: const Text('Use my mercy veto'),
          ),
        ),
      ],
    );
  }

  Future<void> _requestVeto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Use your monthly veto?'),
        content: const Text(
          'This blocks the photo if you lose — once per 30 days, and the '
          'loss is still recorded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Use it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(stakeFunctionsProvider).applyVeto(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veto requested — it applies when the outcome is decided.')),
        );
      }
    } on StakeActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ─── Cancel draft ──────────────────────────────────────────────────────────

  Widget _cancelAction() {
    return Center(
      child: TextButton(
        onPressed: _busy ? null : _cancelDraft,
        child: Text(
          'Cancel this challenge',
          style: TextStyle(color: AppColors.textFaint),
        ),
      ),
    );
  }

  Future<void> _cancelDraft() async {
    setState(() => _busy = true);
    try {
      await ref.read(stakeFunctionsProvider).cancelDraft(c.id);
      if (mounted) Navigator.of(context).pop();
    } on StakeActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
