import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stake_functions.dart';

/// Background replication state of one optimistic challenge create.
///
/// "Start the challenge" commits the local mirror and navigates instantly
/// (optimistic-then-honest, CLAUDE.md principle 3); the photo upload and
/// `stakeCreateChallenge` callable run behind this registry. `error == null`
/// means the create is still in flight; a non-null error is surfaced by the
/// challenge detail screen with Retry/Discard.
class StakeCreateStatus {
  const StakeCreateStatus({this.error, this.canRetry = false});

  /// Null while the create is still replicating.
  final String? error;
  final bool canRetry;

  bool get isSending => error == null;
}

/// In-memory: survives navigation, not an app restart. A create that dies
/// with the app leaves a mirror row with `updatedAtMs == 0` (never echoed
/// by the server); the detail screen treats that as failed-with-discard.
class StakeCreateReplicator extends Notifier<Map<String, StakeCreateStatus>> {
  final _replicateOps = <String, Future<void> Function()>{};
  final _discardOps = <String, Future<void> Function()>{};

  @override
  Map<String, StakeCreateStatus> build() => const {};

  bool isPending(String challengeId) => state.containsKey(challengeId);

  /// Registers the create and starts replicating immediately.
  ///
  /// [replicate] does the network work (upload + callable). It should throw
  /// [StakeActionException] for server failures; terminal outcomes it can
  /// resolve itself (e.g. photo rejected → mirror flipped to cancelled) must
  /// be handled inside and return normally.
  /// [discard] undoes the optimistic local writes (mirror row, minted goal).
  void start(
    String challengeId, {
    required Future<void> Function() replicate,
    required Future<void> Function() discard,
  }) {
    _replicateOps[challengeId] = replicate;
    _discardOps[challengeId] = discard;
    unawaited(_run(challengeId));
  }

  Future<void> retry(String challengeId) async {
    final status = state[challengeId];
    if (status == null || status.isSending) return;
    await _run(challengeId);
  }

  /// Removes the optimistic local writes and forgets the create.
  Future<void> discard(String challengeId) async {
    final op = _discardOps.remove(challengeId);
    _replicateOps.remove(challengeId);
    state = {...state}..remove(challengeId);
    if (op != null) await op();
  }

  Future<void> _run(String challengeId) async {
    final op = _replicateOps[challengeId];
    if (op == null) return;
    state = {...state, challengeId: const StakeCreateStatus()};
    try {
      await op();
      _replicateOps.remove(challengeId);
      _discardOps.remove(challengeId);
      state = {...state}..remove(challengeId);
    } on StakeActionException catch (e) {
      // A lost response on a retry can surface as already-exists even though
      // the server accepted the first attempt — that's a success.
      if (e.code == 'already-exists') {
        _replicateOps.remove(challengeId);
        _discardOps.remove(challengeId);
        state = {...state}..remove(challengeId);
        return;
      }
      state = {
        ...state,
        challengeId: StakeCreateStatus(
          error: e.isRetryable
              ? "Couldn't reach the server. Check your connection and retry."
              : e.message,
          canRetry: e.isRetryable,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        challengeId: StakeCreateStatus(
          error: 'Something went wrong: $e',
          canRetry: true,
        ),
      };
    }
  }
}

final stakeCreateReplicatorProvider =
    NotifierProvider<StakeCreateReplicator, Map<String, StakeCreateStatus>>(
      StakeCreateReplicator.new,
    );
