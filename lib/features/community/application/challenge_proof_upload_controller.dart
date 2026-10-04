import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../profile/application/profile_providers.dart';
import '../data/circle_proof_storage.dart';
import '../domain/models/activity_feed_item.dart';
import '../domain/models/challenge.dart';
import '../domain/models/circle_enums.dart';
import 'challenge_providers.dart';
import 'circle_providers.dart';

/// Where one challenge's log-progress submission stands (2026-09-19).
///
/// Optimistic-then-honest (CLAUDE.md rule 3): the sheet closes at once and
/// the progress shows at once; the transaction and the photo upload run
/// here in the background, and only a genuine failure speaks — on the
/// member's own row, with a retry. Before this, two sequential network
/// waits sat behind one spinner on a modal sheet, and the photo, once
/// stored, was never referenced again.
enum ProofUploadPhase { logging, uploading, failed }

@immutable
class ProofUploadState {
  const ProofUploadState({
    required this.phase,
    required this.pendingDelta,
    required this.progressLogged,
    this.file,
    this.isPublic = true,
    this.error,
  });

  final ProofUploadPhase phase;

  /// Shown on the member's row until the stream carries the real number.
  final int pendingDelta;

  /// True once the progress transaction landed — a retry then skips it.
  final bool progressLogged;
  final File? file;
  final bool isPublic;
  final String? error;

  ProofUploadState copyWith({
    ProofUploadPhase? phase,
    int? pendingDelta,
    bool? progressLogged,
    String? error,
  }) => ProofUploadState(
    phase: phase ?? this.phase,
    pendingDelta: pendingDelta ?? this.pendingDelta,
    progressLogged: progressLogged ?? this.progressLogged,
    file: file,
    isPublic: isPublic,
    error: error,
  );
}

class _Submission {
  const _Submission({
    required this.circleId,
    required this.challenge,
    required this.userId,
    required this.delta,
  });
  final String circleId;
  final Challenge challenge;
  final String userId;
  final int delta;
}

/// challengeId → in-flight submission. Keyed per challenge: one at a time
/// per challenge is all the sheet allows.
class ChallengeProofUploads extends Notifier<Map<String, ProofUploadState>> {
  final _submissions = <String, _Submission>{};

  @override
  Map<String, ProofUploadState> build() => const {};

  ProofUploadState? of(String challengeId) => state[challengeId];

  Future<void> submit({
    required String circleId,
    required Challenge challenge,
    required String userId,
    required int delta,
    File? file,
    bool isPublic = true,
  }) async {
    _submissions[challenge.id] = _Submission(
      circleId: circleId,
      challenge: challenge,
      userId: userId,
      delta: delta,
    );
    _set(
      challenge.id,
      ProofUploadState(
        phase: ProofUploadPhase.logging,
        pendingDelta: delta,
        progressLogged: false,
        file: file,
        isPublic: isPublic,
      ),
    );
    await _run(challenge.id);
  }

  Future<void> retry(String challengeId) async {
    final current = state[challengeId];
    if (current == null || current.phase != ProofUploadPhase.failed) return;
    _set(
      challengeId,
      current.copyWith(
        phase: current.progressLogged
            ? ProofUploadPhase.uploading
            : ProofUploadPhase.logging,
        error: null,
      ),
    );
    await _run(challengeId);
  }

  Future<void> _run(String challengeId) async {
    final sub = _submissions[challengeId];
    var current = state[challengeId];
    if (sub == null || current == null) return;

    // 1. The number: one transaction, then the stream carries it.
    if (!current.progressLogged) {
      try {
        await ref
            .read(challengeRepositoryProvider)
            .updateProgress(
              circleId: sub.circleId,
              challengeId: sub.challenge.id,
              userId: sub.userId,
              delta: sub.delta,
            );
      } catch (e) {
        debugPrint('[ChallengeProof] progress failed: $e');
        _set(
          challengeId,
          current.copyWith(
            phase: ProofUploadPhase.failed,
            error: "Couldn't log that. Tap to retry.",
          ),
        );
        return;
      }
      current = current.copyWith(
        progressLogged: true,
        pendingDelta: 0,
        phase: current.file == null
            ? ProofUploadPhase.uploading
            : ProofUploadPhase.uploading,
      );
      _set(challengeId, current);
    }

    // 2. The photo, then its reference, then the feed line.
    try {
      String? url;
      final file = current.file;
      if (file != null) {
        url = await ref
            .read(circleProofStorageProvider)
            .uploadChallengeProof(
              circleId: sub.circleId,
              challengeId: sub.challenge.id,
              userId: sub.userId,
              file: file,
            );
        await ref
            .read(challengeRepositoryProvider)
            .attachProof(
              circleId: sub.circleId,
              challengeId: sub.challenge.id,
              userId: sub.userId,
              proof: ChallengeProof(
                url: url,
                isPublic: current.isPublic,
                atMs: DateTime.now().millisecondsSinceEpoch,
              ),
            );
      }
      final publicPhoto = url != null && current.isPublic;
      final now = DateTime.now();
      await ref
          .read(activityFeedRepositoryProvider)
          .postFeedItem(
            ActivityFeedItem(
              id: StableId.generate('feed'),
              circleId: sub.circleId,
              userId: sub.userId,
              displayName: _displayName(),
              eventType: publicPhoto
                  ? ActivityEventType.challengeProofPosted
                  : ActivityEventType.challengeProgressUpdated,
              entityId: sub.challenge.id,
              entityTitle: sub.challenge.title,
              value: publicPhoto ? url : null,
              dateKey: DateKeys.todayKey(now),
              createdAtMs: now.millisecondsSinceEpoch,
            ),
          );
    } catch (e) {
      debugPrint('[ChallengeProof] upload failed: $e');
      _set(
        challengeId,
        current.copyWith(
          phase: ProofUploadPhase.failed,
          error: current.file != null
              ? circleProofUploadErrorMessage(e)
              : "Couldn't post that. Tap to retry.",
        ),
      );
      return;
    }

    _submissions.remove(challengeId);
    state = {...state}..remove(challengeId);
  }

  String _displayName() {
    final name = ref.read(displayNameProvider).trim();
    return name.isEmpty ? 'A member' : name;
  }

  void _set(String challengeId, ProofUploadState s) {
    state = {...state, challengeId: s};
  }
}

final challengeProofUploadsProvider =
    NotifierProvider<ChallengeProofUploads, Map<String, ProofUploadState>>(
      ChallengeProofUploads.new,
    );
