import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/accountability/application/stake_action_items.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';
import 'package:sidepal/features/accountability/domain/models/stake_evidence.dart';

/// One predicate for the tab badge and the hub card line (2026-09-24).
const _me = 'me';
const _other = 'other';

StakeChallenge _c({
  required StakeChallengeStatus status,
  StakeChallengeType type = StakeChallengeType.h2hPoints,
  String creator = _other,
  bool meAccepted = false,
}) => StakeChallenge(
  id: 'c1',
  type: type,
  status: status,
  creatorUid: creator,
  circleId: '',
  participants: [
    StakeParticipant(
      uid: _me,
      teamId: 'a',
      stakeKind: 'points',
      accepted: meAccepted,
    ),
    const StakeParticipant(
      uid: _other,
      teamId: 'b',
      stakeKind: 'points',
      accepted: true,
    ),
  ],
  frozenGoal: const StakeFrozenGoal(
    title: 't',
    unitKind: 'minutes',
    unitTarget: 60,
    totalUnits: 7,
  ),
  deadlineMs: 0,
  createdAtMs: DateTime(2026, 9, 20, 9).millisecondsSinceEpoch,
  updatedAtMs: 0,
);

StakeEvidence _ev(int amount, {String uid = _me, int unit = 1}) =>
    StakeEvidence(
      id: 'e$amount',
      challengeId: 'c1',
      uid: uid,
      unitIndex: unit,
      amount: amount,
      source: 'timer',
      recordedAtMs: 0,
      updatedAtMs: 0,
    );

final _day2 = DateTime(2026, 9, 21, 12); // unit index 1

void main() {
  group('invite', () {
    test('needs me while I have not accepted', () {
      final item = stakeActionItemFor(
        _c(status: StakeChallengeStatus.pendingAccept),
        uid: _me,
        evidence: const [],
      );
      expect(item?.reason, StakeActionReason.respondToInvite);
      expect(item?.seenKey, 'invite_c1');
    });

    test('not once I accepted, and never for the creator', () {
      expect(
        stakeActionItemFor(
          _c(status: StakeChallengeStatus.pendingAccept, meAccepted: true),
          uid: _me,
          evidence: const [],
        ),
        isNull,
        reason: 'waiting on the other side is theirs to act on',
      );
      expect(
        stakeActionItemFor(
          _c(status: StakeChallengeStatus.pendingAccept, creator: _me),
          uid: _me,
          evidence: const [],
        ),
        isNull,
      );
    });
  });

  group("today's log", () {
    test('due until my evidence reaches the mercy target', () {
      final c = _c(status: StakeChallengeStatus.active);
      final due = stakeActionItemFor(c, uid: _me, evidence: const [], now: _day2);
      expect(due?.reason, StakeActionReason.logToday);
      expect(due?.seenKey, 'evidence_c1_1');

      // 60-minute target → mercy is 45. Someone else's minutes don't count.
      expect(
        stakeActionItemFor(
          c,
          uid: _me,
          evidence: [_ev(30), _ev(40, uid: _other)],
          now: _day2,
        ),
        isNotNull,
      );
      expect(
        stakeActionItemFor(c, uid: _me, evidence: [_ev(20), _ev(25)], now: _day2),
        isNull,
      );
    });

    test('nothing before the first unit or after the last', () {
      final c = _c(status: StakeChallengeStatus.active);
      expect(
        stakeActionItemFor(c, uid: _me, evidence: const [], now: DateTime(2026, 9, 1)),
        isNull,
      );
      expect(
        stakeActionItemFor(c, uid: _me, evidence: const [], now: DateTime(2026, 10, 30)),
        isNull,
      );
    });
  });

  group('verdict', () {
    test('multi-party awaiting confirmation needs me; solo does not', () {
      expect(
        stakeActionItemFor(
          _c(status: StakeChallengeStatus.pendingVerification),
          uid: _me,
          evidence: const [],
        )?.reason,
        StakeActionReason.confirmResult,
      );
      expect(
        stakeActionItemFor(
          _c(
            status: StakeChallengeStatus.pendingVerification,
            type: StakeChallengeType.soloPhoto,
          ),
          uid: _me,
          evidence: const [],
        ),
        isNull,
      );
    });
  });

  test('a challenge I am not part of never needs me', () {
    expect(
      stakeActionItemFor(
        _c(status: StakeChallengeStatus.pendingAccept),
        uid: 'stranger',
        evidence: const [],
      ),
      isNull,
    );
  });
}
