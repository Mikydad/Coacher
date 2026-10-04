import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/models/stake_challenge.dart';

/// D9 launch price, mirrored from `functions/src/stakes/points.ts`.
const int kPhotoRemovalPrice = 300;

/// Solo decisions land 12 h after the deadline (evidence grace, CC-5).
const Duration kSoloDecisionGrace = Duration(hours: 12);

/// The client's view of a takedown (2026-09-18), mirroring the server's
/// `photoRemovalDoor` plus what the device knows about points. The button is
/// ALWAYS shown while a takedown exists; the gate decides what a tap says.
enum PhotoRemovalGate {
  /// Deadline passed, outcome pending, photo screened but not posted.
  preReveal,

  /// Live, but the 30 % exposure floor has not passed.
  floor,

  /// Live and past the floor.
  postReveal,

  /// Nothing to take down right now.
  none,
}

PhotoRemovalGate photoRemovalGate(StakeChallenge c, {DateTime? now}) {
  final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
  if (c.status == StakeChallengeStatus.pendingVerification &&
      c.photoState == StakePhotoState.approved) {
    return PhotoRemovalGate.preReveal;
  }
  if (c.photoState != StakePhotoState.revealed) return PhotoRemovalGate.none;
  final revealedAt = c.revealedAtMs;
  final windowMins = c.participant(FirestorePaths.activeUid)?.revealWindowMins;
  if (revealedAt == null || windowMins == null) return PhotoRemovalGate.none;
  return at >= photoRemovalFloorAtMs(revealedAt, windowMins)
      ? PhotoRemovalGate.postReveal
      : PhotoRemovalGate.floor;
}

/// When the 30 % floor passes. Integer math, same as the server.
int photoRemovalFloorAtMs(int revealedAtMs, int revealWindowMins) =>
    revealedAtMs + (revealWindowMins * 60000 * 30) ~/ 100;

/// When the server decides a solo challenge: deadline + 12 h.
int soloDecisionAtMs(StakeChallenge c) =>
    c.deadlineMs + kSoloDecisionGrace.inMilliseconds;

/// The one line for "not enough": says what counts and how to earn it, so
/// the user learns the takedown exists instead of hitting a dead end.
String photoRemovalShortfallCopy(int trusted) =>
    'Taking a photo down costs $kPhotoRemovalPrice points earned from '
    'challenge wins or the signup bonus. You have $trusted. Win a challenge '
    'to earn 50.';

// ─── Mercy veto availability ─────────────────────────────────────────────────

/// 30-day cooldown, mirrored from `VETO_COOLDOWN_MS`.
const Duration kVetoCooldown = Duration(days: 30);

sealed class VetoAvailability {
  const VetoAvailability();
}

class VetoAvailable extends VetoAvailability {
  const VetoAvailable();
}

class VetoOnCooldown extends VetoAvailability {
  const VetoOnCooldown({required this.nextAtMs});
  final int nextAtMs;
}

/// Offline, or the doc could not be read — the rule is still worth stating.
class VetoUnknown extends VetoAvailability {
  const VetoUnknown();
}

VetoAvailability vetoAvailabilityFrom(int? lastVetoAtMs, {DateTime? now}) {
  if (lastVetoAtMs == null) return const VetoAvailable();
  final nextAt = lastVetoAtMs + kVetoCooldown.inMilliseconds;
  final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
  return at >= nextAt ? const VetoAvailable() : VetoOnCooldown(nextAtMs: nextAt);
}

/// Reads the owner-readable `enforcement/{uid}` doc once per screen. Stakes
/// are server-authoritative (decision log 2026-07-16), so a direct read is
/// the honest source here; failure degrades to [VetoUnknown], never blocks.
final vetoAvailabilityProvider = FutureProvider.autoDispose<VetoAvailability>((
  ref,
) async {
  final uid = ref.watch(authUidProvider) ?? FirestorePaths.activeUid;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('enforcement')
        .doc(uid)
        .get();
    return vetoAvailabilityFrom((snap.data()?['lastVetoAtMs'] as num?)?.toInt());
  } catch (e) {
    debugPrint('[Stakes] veto availability unavailable: $e');
    return const VetoUnknown();
  }
});
