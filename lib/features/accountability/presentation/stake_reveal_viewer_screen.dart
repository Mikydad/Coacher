import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../application/blocked_users.dart';
import '../application/secure_screen.dart';
import '../application/stake_functions.dart';
import '../application/stakes_providers.dart';

/// The secure reveal viewer (P-4/P-6): circle members see a forfeited stake
/// photo here, and ONLY here, for as long as the window lasts.
///
/// - Android: FLAG_SECURE while this route is up — capture comes out black.
/// - iOS: screenshots are detected; the offender's own device self-reports
///   the strike (12h ban + public naming). Screen recording blurs the photo.
/// - The challenge doc is fetched directly (circle members don't mirror
///   other people's challenges in Isar; this surface is network-inherent).
class StakeRevealViewerScreen extends ConsumerStatefulWidget {
  const StakeRevealViewerScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<StakeRevealViewerScreen> createState() =>
      _StakeRevealViewerScreenState();
}

class _StakeRevealViewerScreenState
    extends ConsumerState<StakeRevealViewerScreen> {
  Uint8List? _imageBytes;
  String? _error;
  bool _gone = false;
  bool _hiddenForCapture = false;
  bool _reportedThisView = false;
  int? _expiresAtMs;
  String _goalTitle = '';
  String? _ownerUid;
  Timer? _countdownTick;

  @override
  void initState() {
    super.initState();
    _armSecureMode();
    _load();
    _countdownTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_expiresAtMs != null &&
          DateTime.now().millisecondsSinceEpoch >= _expiresAtMs!) {
        setState(() => _gone = true);
      } else {
        setState(() {}); // countdown text
      }
    });
  }

  Future<void> _armSecureMode() async {
    final alreadyRecording = await SecureScreen.enable(
      onScreenshot: _onScreenshot,
      onCaptureChanged: (capturing) {
        if (mounted) setState(() => _hiddenForCapture = capturing);
      },
    );
    if (alreadyRecording && mounted) {
      setState(() => _hiddenForCapture = true);
    }
  }

  Future<void> _onScreenshot() async {
    if (_reportedThisView) return;
    _reportedThisView = true;
    // D11 — the offender's own device reports the strike. Fire first, talk
    // after: the ban and the circle announcement are not negotiable.
    try {
      await ref
          .read(stakeFunctionsProvider)
          .reportScreenshot(widget.challengeId);
    } on StakeActionException {
      // Screenshot of a photo you can't be striked for (e.g. left the
      // circle mid-view) — nothing else to do.
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Screenshot reported'),
        content: const Text(
          'Screenshotting stake photos breaks the circle\'s trust. Your '
          'circle has been told, and you\'re banned from joining challenges '
          'for a while. Repeats get longer bans.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stake_challenges')
          .doc(widget.challengeId)
          .get();
      final data = snap.data();
      if (data == null) throw StateError('challenge missing');
      _goalTitle = (data['frozenGoal'] as Map<String, dynamic>?)?['title']
              as String? ??
          '';
      _ownerUid = data['creatorUid'] as String?;
      _expiresAtMs = (data['revealExpiresAtMs'] as num?)?.toInt();
      final state = data['photoState'] as String?;
      if (state != 'revealed') {
        setState(() => _gone = true);
        return;
      }
      final participants = (data['participants'] as List?) ?? const [];
      String? path;
      for (final p in participants) {
        final photo = (p as Map<String, dynamic>)['photo'];
        if (photo is Map<String, dynamic> &&
            photo['storagePath'] is String) {
          path = photo['storagePath'] as String;
          break;
        }
      }
      if (path == null) throw StateError('no photo path');
      final bytes =
          await FirebaseStorage.instance.ref(path).getData(10 * 1024 * 1024);
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      // Expired-and-deleted photos land here too (object gone).
      setState(() {
        if (_expiresAtMs != null &&
            DateTime.now().millisecondsSinceEpoch >= _expiresAtMs!) {
          _gone = true;
        } else {
          _error = 'Could not load the photo.';
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTick?.cancel();
    SecureScreen.disable();
    super.dispose();
  }

  String _remainingLabel() {
    final expires = _expiresAtMs;
    if (expires == null) return '';
    final left = Duration(
      milliseconds: expires - DateTime.now().millisecondsSinceEpoch,
    );
    if (left.isNegative) return 'gone';
    if (left.inHours >= 1) {
      return '${left.inHours}h ${left.inMinutes % 60}m left';
    }
    if (left.inMinutes >= 1) {
      return '${left.inMinutes}m ${left.inSeconds % 60}s left';
    }
    return '${left.inSeconds}s left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const PageTitle('Stake forfeited'),
        actions: [
          if (!_gone && _imageBytes != null) ...[
            IconButton(
              tooltip: 'Report this photo',
              icon: const Icon(Icons.flag_rounded),
              onPressed: _report,
            ),
            if (_ownerUid != null && _ownerUid != FirestorePaths.activeUid)
              IconButton(
                tooltip: 'Block this user',
                icon: const Icon(Icons.person_off_rounded),
                onPressed: _blockOwner,
              ),
          ],
        ],
      ),
      body: _gone
          ? _goneState()
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : _imageBytes == null
                  ? const Center(child: CircularProgressIndicator())
                  : _photoView(),
    );
  }

  Widget _photoView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.danger.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Screenshots are punished: a challenge ban and the circle gets '
            'told. This photo disappears on its own — ${_remainingLabel()}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ),
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.memory(_imageBytes!, fit: BoxFit.contain),
                if (_hiddenForCapture)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: const Center(
                          child: Text(
                            'Hidden while screen recording is on',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _goalTitle.isEmpty
                ? 'A promise was broken.'
                : 'The promise was: "$_goalTitle"',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSoft, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _goneState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_off_rounded, size: 48, color: AppColors.fg24),
          const SizedBox(height: 12),
          Text(
            'This photo is gone',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reveals are temporary by design.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _blockOwner() async {
    final ownerUid = _ownerUid;
    if (ownerUid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block this user?'),
        content: const Text(
          'You won\'t see their posts or stake reveals anymore. You can '
          'undo this from their profile later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Local-first: applies instantly, syncs in the background.
    await ref
        .read(blockedUsersRepositoryProvider)
        .setBlocked(ownerUid, blocked: true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _report() async {
    try {
      await ref.read(stakeFunctionsProvider).reportPhoto(widget.challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reported — the photo is hidden pending review.'),
        ),
      );
      Navigator.of(context).pop();
    } on StakeActionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
