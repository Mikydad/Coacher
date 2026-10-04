import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/community/domain/models/challenge.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';

/// Challenge proofs (2026-09-19) ride on the challenge doc per member and
/// must survive the map round trip; legacy docs have none.
void main() {
  Map<String, dynamic> base() => {
    'id': 'ch1',
    'circleId': 'c1',
    'creatorId': 'u1',
    'title': 'Read 100 pages',
    'mode': 'competition',
    'status': 'active',
    'targetValue': 100,
    'unit': 'pages',
    'memberProgress': {'u1': 40, 'u2': 10},
    'teamTotal': 50,
    'startsAtMs': 1,
    'endsAtMs': 2,
    'createdAtMs': 1,
    'updatedAtMs': 1,
  };

  test('legacy doc → no proofs', () {
    expect(Challenge.fromMap(base()).memberProofs, isEmpty);
    expect(
      Challenge.fromMap(base()).toMap().containsKey('memberProofs'),
      isFalse,
    );
  });

  test('proofs round-trip with their visibility', () {
    final c = Challenge.fromMap(base()).copyWith(
      memberProofs: {
        'u1': const ChallengeProof(
          url: 'https://x/a.jpg',
          isPublic: false,
          atMs: 9,
        ),
      },
    );
    final back = Challenge.fromMap(c.toMap());
    expect(back.memberProofs['u1']?.url, 'https://x/a.jpg');
    expect(back.memberProofs['u1']?.isPublic, isFalse);
    expect(back.memberProofs['u1']?.atMs, 9);
  });

  test('a proof without a url is ignored; isPublic defaults to true', () {
    final c = Challenge.fromMap({
      ...base(),
      'memberProofs': {
        'u1': {'isPublic': false},
        'u2': {'url': 'https://x/b.jpg'},
      },
    });
    expect(c.memberProofs.containsKey('u1'), isFalse);
    expect(c.memberProofs['u2']?.isPublic, isTrue);
  });

  test('the feed knows the photo event', () {
    expect(
      ActivityEventTypeStorage.fromStorage('challengeProofPosted'),
      ActivityEventType.challengeProofPosted,
    );
  });
}
