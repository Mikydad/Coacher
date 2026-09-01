import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_stake_challenge.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';

/// pledgeWhy (2026-09-01) rides the challenge doc so commitment cards can
/// regenerate forever (FR-21): it must survive the Firestore map → domain →
/// Isar row → domain round trip, and stay null for legacy docs.
void main() {
  Map<String, dynamic> baseMap() => {
    'id': 'stk_1',
    'type': 'solo_public',
    'status': 'active',
    'creatorUid': 'u1',
    'circleId': '',
    'participants': [
      {'uid': 'u1', 'teamId': 'u1', 'stakeKind': 'public', 'accepted': true},
    ],
    'frozenGoal': {
      'title': 'Finish my portfolio',
      'unitKind': 'count',
      'unitTarget': 1,
      'totalUnits': 30,
    },
    'mode': 'disciplined',
    'deadlineMs': 1_000_000,
    'createdAtMs': 1,
    'updatedAtMs': 2,
  };

  test('pledgeWhy parses from the doc and round-trips the Isar mirror', () {
    final c = StakeChallenge.fromMap({
      ...baseMap(),
      'pledgeWhy': 'No excuses this time. Watch me.',
    });
    expect(c.pledgeWhy, 'No excuses this time. Watch me.');
    expect(c.type, StakeChallengeType.soloPublic);
    expect(c.participants.single.stakeKind, 'public');

    final back = IsarStakeChallenge.fromDomain(c).toDomain();
    expect(back.pledgeWhy, 'No excuses this time. Watch me.');
    expect(back.type, StakeChallengeType.soloPublic);
  });

  test('legacy docs without pledgeWhy stay null through the mirror', () {
    final c = StakeChallenge.fromMap(baseMap());
    expect(c.pledgeWhy, isNull);
    expect(IsarStakeChallenge.fromDomain(c).toDomain().pledgeWhy, isNull);
  });
}
