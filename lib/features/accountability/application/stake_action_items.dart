import '../domain/models/stake_challenge.dart';
import '../domain/models/stake_evidence.dart';
import 'stake_seen_store.dart';

/// Why a challenge needs the user (2026-09-24). The ONE predicate behind
/// the Accountability tab badge and the hub's per-card "needs you" line —
/// the tester's complaint was a lit badge with no card that said which
/// stake lit it, because the two used to be computed apart.
enum StakeActionReason {
  respondToInvite('Respond to the invite'),
  logToday("Log today's progress"),
  confirmResult('Confirm the result');

  const StakeActionReason(this.label);

  final String label;
}

class StakeActionItem {
  const StakeActionItem({required this.reason, required this.seenKey});

  final StakeActionReason reason;

  /// The notification-tray marker: opening the detail screen stores this,
  /// which drops the item from the BADGE count. The card keeps its line
  /// until the action is actually done.
  final String seenKey;
}

/// The action [c] needs from [uid] right now, or null.
///
/// Invite: only while *I* have not accepted — a stake I already accepted,
/// still waiting on the other side, is theirs to act on (the badge used to
/// count it anyway while the card said "waiting for your opponent").
StakeActionItem? stakeActionItemFor(
  StakeChallenge c, {
  required String uid,
  required Iterable<StakeEvidence> evidence,
  DateTime? now,
}) {
  final me = c.participant(uid);
  if (me == null) return null;
  switch (c.status) {
    case StakeChallengeStatus.pendingAccept:
      if (c.creatorUid == uid || me.accepted) return null;
      return StakeActionItem(
        reason: StakeActionReason.respondToInvite,
        seenKey: StakeSeenKeys.invite(c.id),
      );
    case StakeChallengeStatus.active:
      final today = c.unitIndexAt(now ?? DateTime.now());
      if (today < 0 || today >= c.frozenGoal.totalUnits) return null;
      var logged = 0;
      for (final e in evidence) {
        if (e.challengeId == c.id && e.uid == uid && e.unitIndex == today) {
          logged += e.amount;
        }
      }
      if (logged >= c.mercyUnitTarget) return null;
      return StakeActionItem(
        reason: StakeActionReason.logToday,
        seenKey: StakeSeenKeys.evidence(c.id, today),
      );
    case StakeChallengeStatus.pendingVerification:
      if (!c.type.isMultiParty) return null;
      return StakeActionItem(
        reason: StakeActionReason.confirmResult,
        seenKey: StakeSeenKeys.confirm(c.id),
      );
    default:
      return null;
  }
}
