import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/firebase/firestore_paths.dart';
import 'package:sidepal/features/accountability/application/stake_photo_removal.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';

/// Photo takedown, client side (2026-09-18): the gate mirrors the server's
/// doors, the veto rule mirrors the 30-day cooldown, and the outcome
/// prediction picks the pending-outcome copy.
void main() {
  final revealedAt = DateTime(2026, 9, 18, 12, 0).millisecondsSinceEpoch;
  final me = FirestorePaths.activeUid;

  StakeChallenge ch({
    String status = 'pending_verification',
    String? photoState = 'approved',
    int? revealedAtMs,
    String mode = 'disciplined',
    int totalUnits = 10,
  }) => StakeChallenge.fromMap({
    'id': 'stk',
    'type': 'solo_photo',
    'status': status,
    'creatorUid': me,
    'circleId': 'c1',
    'participants': [
      {
        'uid': me,
        'teamId': me,
        'stakeKind': 'photo',
        'accepted': true,
        'photo': {
          'storagePath': 'stake_photos/stk/$me.jpg',
          'revealWindowMins': 60,
          'consentAtMs': 1,
        },
      },
    ],
    'frozenGoal': {
      'title': 'Read',
      'unitKind': 'minutes',
      'unitTarget': 60,
      'totalUnits': totalUnits,
    },
    'mode': mode,
    'deadlineMs': DateTime(2026, 9, 18, 0, 0).millisecondsSinceEpoch,
    'photoState': photoState,
    'revealedAtMs': revealedAtMs,
    'createdAtMs': 1,
    'updatedAtMs': 2,
  });

  group('photoRemovalGate', () {
    test('pending outcome + screened photo → preReveal (no floor)', () {
      expect(photoRemovalGate(ch()), PhotoRemovalGate.preReveal);
    });

    test('revealed → floor until 30%, then postReveal', () {
      final live = ch(
        status: 'completed_forfeit',
        photoState: 'revealed',
        revealedAtMs: revealedAt,
      );
      final floorAt = photoRemovalFloorAtMs(revealedAt, 60);
      expect(floorAt, revealedAt + 18 * 60000);
      expect(
        photoRemovalGate(
          live,
          now: DateTime.fromMillisecondsSinceEpoch(floorAt - 1),
        ),
        PhotoRemovalGate.floor,
      );
      expect(
        photoRemovalGate(live, now: DateTime.fromMillisecondsSinceEpoch(floorAt)),
        PhotoRemovalGate.postReveal,
      );
    });

    test('active challenge, or removed / deleted photo → none', () {
      expect(photoRemovalGate(ch(status: 'active')), PhotoRemovalGate.none);
      expect(
        photoRemovalGate(ch(status: 'completed_forfeit', photoState: 'removed')),
        PhotoRemovalGate.none,
      );
    });
  });

  test('solo decision lands 12h after the deadline', () {
    final c = ch();
    expect(soloDecisionAtMs(c), c.deadlineMs + 12 * 3600000);
  });

  test('shortfall copy names what counts and how to earn it', () {
    final copy = photoRemovalShortfallCopy(40);
    expect(copy, contains('300'));
    expect(copy, contains('challenge wins'));
    expect(copy, contains('You have 40'));
  });

  group('vetoAvailabilityFrom', () {
    final now = DateTime(2026, 9, 18);
    test('never used → available', () {
      expect(vetoAvailabilityFrom(null, now: now), isA<VetoAvailable>());
    });
    test('used 29 days ago → on cooldown with the next date', () {
      final last = now.subtract(const Duration(days: 29)).millisecondsSinceEpoch;
      final v = vetoAvailabilityFrom(last, now: now);
      expect(v, isA<VetoOnCooldown>());
      expect((v as VetoOnCooldown).nextAtMs, last + 30 * 86400000);
    });
    test('used 30 days ago → available again', () {
      final last = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      expect(vetoAvailabilityFrom(last, now: now), isA<VetoAvailable>());
    });
  });

  group('predictedSoloPass', () {
    test('required units follow the mode (D3)', () {
      expect(ch(mode: 'flexible').requiredUnits, 7);
      expect(ch(mode: 'disciplined').requiredUnits, 9);
      expect(ch(mode: 'extreme').requiredUnits, 10);
    });

    test('a unit passes at the mercy bar (75%), not below', () {
      final c = ch(mode: 'flexible'); // needs 7 of 10; mercy bar 45 min
      final logged = {for (var i = 0; i < 7; i++) i: 45};
      expect(c.predictedSoloPass(logged), isTrue);
      expect(c.predictedSoloPass({...logged, 6: 44}), isFalse);
    });
  });
}
