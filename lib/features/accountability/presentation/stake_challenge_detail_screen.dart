import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../community/application/circle_providers.dart';
import '../application/points_providers.dart';
import '../application/stake_functions.dart';
import '../application/stake_seen_store.dart';
import '../application/stakes_providers.dart';
import '../data/stakes_repository.dart';
import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';
import 'accountability_create_flow.dart';
import 'stake_photo_cache.dart';
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
  StakeLiveHydration? _liveWatch;
  String? _lastSeenSignature;
  Uint8List? _stakePhotoBytes;
  bool _stakePhotoLoading = false;
  bool _stakePhotoAttempted = false;

  StakeChallenge get c => widget.challenge;

  /// Owner-only preview of the staked photo. Cache-first: the creator's
  /// device seeded the cache at create time, so the preview is instant
  /// and works offline; only a reinstall/second device downloads (and
  /// then caches). The photo is deleted server-side on success/veto/
  /// expiry — a failed network load on decided challenges is normal.
  void _loadStakePhoto() {
    if (_stakePhotoBytes != null || _stakePhotoAttempted) return;
    if (c.type != StakeChallengeType.soloPhoto) return;
    final path = c.participant(FirestorePaths.activeUid)?.photoStoragePath;
    if (path == null) return;
    _stakePhotoAttempted = true;
    if (c.status.isTerminal) {
      // The server deletes the photo on decided challenges; drop the
      // local copy too, quietly.
      StakePhotoCache.evict(c.id);
      return;
    }
    _stakePhotoLoading = true;
    () async {
      final cached = await StakePhotoCache.read(c.id);
      if (cached != null) {
        if (mounted) {
          setState(() {
            _stakePhotoBytes = cached;
            _stakePhotoLoading = false;
          });
        }
        return;
      }
      try {
        final bytes =
            await FirebaseStorage.instance.ref(path).getData(4 * 1024 * 1024);
        if (bytes != null) {
          await StakePhotoCache.write(c.id, bytes);
          if (mounted) setState(() => _stakePhotoBytes = bytes);
        }
      } catch (_) {
        // Quiet: slow/offline link — the card explains it's still loading
        // only while we genuinely are; on failure it disappears.
      } finally {
        if (mounted) setState(() => _stakePhotoLoading = false);
      }
    }();
  }

  /// While the challenge is NON-TERMINAL, listen to it LIVE (doc +
  /// evidence): photo screening flips draft → active in seconds, the
  /// opponent's accept flips pending_accept → active, and their day marks
  /// land mid-challenge — all far faster than the background pull
  /// (start/resume/connectivity, 30 s throttle). A previous 10 s poll was
  /// silently eaten by that throttle — the listener hears changes in ~1 s.
  /// Cancels itself once the challenge reaches a terminal state.
  void _watchChallengeLive() {
    final wantLive = !c.status.isTerminal;
    if (wantLive && _liveWatch == null) {
      _liveWatch =
          ref.read(stakesRepositoryProvider).hydrateChallengeLive(c.id);
    } else if (!wantLive && _liveWatch != null) {
      _liveWatch!.cancel();
      _liveWatch = null;
    }
  }

  @override
  void dispose() {
    _liveWatch?.cancel();
    super.dispose();
  }

  /// Looking at this screen counts as SEEING the challenge's current
  /// badge-worthy state — the tab badge drops without requiring the
  /// action itself (notification-tray semantics, decided 2026-07-21).
  /// Signature-guarded so rebuilds don't spam the store; a state change
  /// (new day, new status) mints new keys and marks them seen too.
  void _markSeen() {
    final uid = FirestorePaths.activeUid;
    final keys = <String>[];
    if (c.status == StakeChallengeStatus.pendingAccept &&
        c.creatorUid != uid) {
      keys.add(StakeSeenKeys.invite(c.id));
    }
    if (c.status == StakeChallengeStatus.active) {
      final today = c.todayUnitIndex;
      if (today >= 0 && today < c.frozenGoal.totalUnits) {
        keys.add(StakeSeenKeys.evidence(c.id, today));
      }
    }
    if (c.status == StakeChallengeStatus.pendingVerification &&
        c.type.isMultiParty) {
      keys.add(StakeSeenKeys.confirm(c.id));
    }
    if (keys.isEmpty) return;
    final signature = keys.join('|');
    if (signature == _lastSeenSignature) return;
    _lastSeenSignature = signature;
    // Deferred: provider state must not change during build.
    Future.microtask(
      () => ref.read(stakeSeenProvider.notifier).markSeen(keys),
    );
  }

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
    _watchChallengeLive();
    _markSeen();
    _loadStakePhoto();
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
        if (_stakePhotoBytes != null || _stakePhotoLoading) ...[
          const SizedBox(height: 12),
          _stakePhotoCard(),
        ],
        if (c.type.isMultiParty) ...[
          const SizedBox(height: 12),
          _h2hStakeCard(),
        ],
        if (c.type == StakeChallengeType.soloMoney) ...[
          const SizedBox(height: 12),
          _moneyStakeCard(),
        ],
        if (_isInvitedMe) ...[
          const SizedBox(height: 12),
          _inviteActions(),
        ],
        if (c.photoState == StakePhotoState.revealed) ...[
          const SizedBox(height: 12),
          _revealCard(),
        ],
        const SizedBox(height: 20),
        if (c.type.isMultiParty)
          ..._multiPartyGrids(mercy, today)
        else ...[
          const SectionHeader('Days'),
          const SizedBox(height: 10),
          _unitGrid(logged, mercy, today),
        ],
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
        if (c.status == StakeChallengeStatus.pendingVerification &&
            c.type.isMultiParty)
          _confirmDisputeActions(),
        if (c.status.isTerminal && c.type.isMultiParty) _rematchAction(),
        if (c.status == StakeChallengeStatus.draft ||
            (c.status == StakeChallengeStatus.pendingAccept &&
                c.creatorUid == FirestorePaths.activeUid))
          _cancelAction(),
      ],
    );
  }

  /// What's on the line, visible ONLY to its owner while the challenge
  /// lives (the circle sees it exclusively through a forfeit reveal).
  /// Tap for full size.
  Widget _stakePhotoCard() {
    final bytes = _stakePhotoBytes;
    return GestureDetector(
      onTap: bytes == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _StakePhotoFullscreen(bytes: bytes),
                ),
              ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            if (bytes == null)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.fg12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  bytes,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bytes == null
                    ? 'Loading your photo…'
                    : 'This is what\'s on the line. Only you can see it — '
                        'unless you break your word. Tap to view.',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isInvitedMe {
    final me = c.participant(FirestorePaths.activeUid);
    return c.status == StakeChallengeStatus.pendingAccept &&
        me != null &&
        !me.accepted;
  }

  /// One unit grid per player (1v1): mine first, labeled with names when
  /// the circle roster has them.
  List<Widget> _multiPartyGrids(int mercy, int today) {
    final myUid = FirestorePaths.activeUid;
    final members = ref.watch(circleMembersProvider(c.circleId)).valueOrNull;
    String nameOf(String uid) {
      if (uid == myUid) return 'You';
      final m = members?.where((m) => m.userId == uid).firstOrNull;
      return (m == null || m.displayName.isEmpty) ? 'Opponent' : m.displayName;
    }

    final ordered = [...c.participants]
      ..sort((a, b) => a.uid == myUid ? -1 : (b.uid == myUid ? 1 : 0));
    return [
      for (final p in ordered) ...[
        SectionHeader(nameOf(p.uid)),
        const SizedBox(height: 10),
        _unitGrid(_loggedByUnitFor(p.uid), mercy, today),
        const SizedBox(height: 16),
      ],
    ];
  }

  Map<int, int> _loggedByUnitFor(String uid) {
    final sums = <int, int>{};
    for (final e in widget.evidence) {
      if (e.uid != uid) continue;
      sums[e.unitIndex] = (sums[e.unitIndex] ?? 0) + e.amount;
    }
    return sums;
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

  /// D5/D6 — what's riding on this 1v1, in plain words.
  Widget _h2hStakeCard() {
    final stake = c.participants.firstOrNull?.stakeAmount ?? 0;
    final charities = ref.watch(charitiesProvider).valueOrNull ?? const [];
    String charityName(String? id) =>
        charities.where((x) => x.id == id).firstOrNull?.name ?? 'their cause';
    final myUid = FirestorePaths.activeUid;
    final opponent = c.participants.where((p) => p.uid != myUid).firstOrNull;
    final myPick = charityName(c.sideCharities[myUid]);
    final theirPick = charityName(c.sideCharities[opponent?.uid]);
    final bothLose = charityName(c.bothLoseCharityId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$stake points each. If you win, their points fund $myPick. '
        'If they win, yours fund $theirPick. If you BOTH fail, everything '
        'goes to $bothLose.',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  /// $-1/$-3 — what the money is doing right now, receipt included.
  Widget _moneyStakeCard() {
    final myUid = FirestorePaths.activeUid;
    final amountCents = c.participant(myUid)?.stakeAmount ?? 0;
    final amount = '\$${(amountCents / 100).toStringAsFixed(amountCents % 100 == 0 ? 0 : 2)}';
    final charities = ref.watch(charitiesProvider).valueOrNull ?? const [];
    final antiName = charities
            .where((x) => x.id == c.antiCharityId)
            .firstOrNull
            ?.name ??
        'your chosen recipient';
    final receipt = c.receipts[myUid];

    final String text;
    if (c.status == StakeChallengeStatus.active ||
        c.status == StakeChallengeStatus.pendingVerification) {
      text = '$amount held in escrow (simulated). Keep your word and it all '
          'comes back; fail and it funds $antiName. No veto on money.';
    } else if (c.status == StakeChallengeStatus.completedSuccess) {
      text = '$amount refunded. Your word held.';
    } else if (receipt != null) {
      text = '$amount donated to $antiName. '
          '${receipt.note.isNotEmpty ? receipt.note : 'Receipt on file.'}';
    } else if (c.status == StakeChallengeStatus.completedForfeit) {
      text = '$amount forfeited — being donated to $antiName. The receipt '
          'will appear here.';
    } else {
      text = '$amount — ${c.status.storageValue}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.statusGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  /// The invited side's accept/decline (PT-4 — accepting locks BOTH stakes).
  Widget _inviteActions() {
    final stake = c.participant(FirestorePaths.activeUid)?.stakeAmount ?? 0;
    final balance = ref.watch(pointsBalanceProvider).valueOrNull ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          balance >= stake
              ? 'Accepting locks $stake of your points until the outcome.'
              : 'You need $stake points to accept — you have $balance.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed:
                    _busy || balance < stake ? null : _acceptInvite,
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _declineInvite,
                child: const Text('Decline'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _acceptInvite() async {
    // D5 — your loved pick: whoever loses to you funds this.
    final charities = ref.read(charitiesProvider).valueOrNull ?? const [];
    if (charities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Charity list not synced yet — try again online.')),
      );
      return;
    }
    String? picked = charities.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('If you win, their points fund…'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final charity in charities)
                ChoiceChip(
                  label: Text(charity.name),
                  selected: picked == charity.id,
                  onSelected: (_) =>
                      setDialogState(() => picked = charity.id),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Lock stakes & start'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(stakeFunctionsProvider).acceptChallenge(
            challengeId: c.id,
            charityId: picked!,
          );
      // Flip the local mirror NOW — the accept succeeded server-side and
      // the next throttled pull is up to 30 s away; without this the
      // acceptor keeps staring at "waiting for opponent".
      await ref.read(stakesRepositoryProvider).refreshChallenge(c.id);
    } on StakeActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _declineInvite() async {
    setState(() => _busy = true);
    try {
      await ref.read(stakeFunctionsProvider).declineChallenge(c.id);
      await ref.read(stakesRepositoryProvider).refreshChallenge(c.id);
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

  /// V-2 — vouch for or dispute the other side's completion.
  Widget _confirmDisputeActions() {
    final myUid = FirestorePaths.activeUid;
    final opponent = c.participants.where((p) => p.uid != myUid).firstOrNull;
    if (opponent == null || c.participant(myUid) == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Their word'),
        const SizedBox(height: 8),
        Text(
          'Did they really do it? Silence counts as a confirm after 24h; a '
          'dispute sends it to a circle vote.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _confirmOutcome(opponent.uid, dispute: false),
                child: const Text('Looks right'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _confirmOutcome(opponent.uid, dispute: true),
                child: const Text('Dispute'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmOutcome(String aboutUid, {required bool dispute}) async {
    setState(() => _busy = true);
    try {
      await ref.read(stakeFunctionsProvider).confirmOutcome(
            challengeId: c.id,
            aboutUid: aboutUid,
            dispute: dispute,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dispute
                ? 'Disputed — the circle votes for the next 48h.'
                : 'Confirmed.'),
          ),
        );
      }
    } on StakeActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.code == 'already-exists'
              ? 'You already gave your word on this.'
              : e.message),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _rematchAction() {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.replay_rounded, size: 18),
        onPressed: () => openAccountabilityCreateFlow(
          context,
          prefilledTitle: c.frozenGoal.title,
          prefilledCircleId: c.circleId,
        ),
        label: const Text('Rematch'),
      ),
    );
  }

  /// Owner-side view of their own live reveal (P-4/P-5): countdown, a way
  /// to face it, and point-based early removal (D9: 30% floor, 300 pts).
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
              Expanded(child: _removalAction()),
            ],
          ),
        ],
      ),
    );
  }

  /// D9 — early takedown: 30% floor, 300 points, loss stays recorded.
  Widget _removalAction() {
    const price = 300;
    final balance = ref.watch(pointsBalanceProvider).valueOrNull ?? 0;
    final me = c.participant(FirestorePaths.activeUid);
    final revealedAt = c.revealedAtMs;
    final windowMins = me?.revealWindowMins;
    final floorPassed = revealedAt != null &&
        windowMins != null &&
        DateTime.now().millisecondsSinceEpoch >=
            revealedAt + (windowMins * 60000 * 30) ~/ 100;

    if (!floorPassed) {
      return Text(
        'Removal unlocks after 30% of the window.',
        style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
      );
    }
    if (balance < price) {
      return Text(
        'Remove early: $price pts (you have $balance).',
        style: TextStyle(color: AppColors.textFaint, fontSize: 11.5),
      );
    }
    return OutlinedButton(
      onPressed: _busy ? null : _removePhoto,
      child: Text('Remove — $price pts'),
    );
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Take the photo down?'),
        content: const Text(
          'This burns 300 points. The loss stays on your record — only the '
          'photo goes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Leave it up'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Burn the points'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(stakeFunctionsProvider).removePhoto(c.id);
    } on StakeActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

/// Owner-only full-size view of the staked photo (tap target of the
/// preview card). Plain viewer — the SECURE viewer with screenshot
/// enforcement is for circle reveals; your own photo is your business.
class _StakePhotoFullscreen extends StatelessWidget {
  const _StakePhotoFullscreen({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const PageTitle('Your stake'),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
