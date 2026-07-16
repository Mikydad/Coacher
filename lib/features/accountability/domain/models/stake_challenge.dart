import 'dart:convert';

/// Accountability Stakes — client mirror of the server-owned challenge doc.
///
/// PRD: `PRD/Accountability_feature/prd-accountability-stakes.md` (§7.2).
/// The server (Cloud Functions outcome engine) owns every field; the client
/// reads a synced Isar mirror and mutates ONLY through callables
/// (`StakeFunctions`) — never by writing this doc. Names are prefixed
/// `Stake*` to keep them distinct from the casual circle `Challenge`
/// (`features/community`), which is a separate, unrelated entity.

// ─── Enums (storage strings must match functions/src/stakes/types.ts) ───────

enum StakeChallengeType {
  soloPhoto('solo_photo'),
  soloMoney('solo_money'),
  h2hPoints('h2h_points'),
  h2hMoney('h2h_money'),
  teamPoints('team_points'),
  teamMoney('team_money'),
  practice('practice');

  const StakeChallengeType(this.storageValue);
  final String storageValue;

  static StakeChallengeType fromStorage(String? raw) =>
      values.firstWhere((e) => e.storageValue == raw,
          orElse: () => StakeChallengeType.practice);

  bool get isMultiParty =>
      this == h2hPoints || this == h2hMoney || this == teamPoints || this == teamMoney;
}

enum StakeChallengeStatus {
  draft('draft'),
  pendingAccept('pending_accept'),
  active('active'),
  pendingVerification('pending_verification'),
  completedSuccess('completed_success'),
  completedForfeit('completed_forfeit'),
  cancelled('cancelled'),
  vetoed('vetoed');

  const StakeChallengeStatus(this.storageValue);
  final String storageValue;

  static StakeChallengeStatus fromStorage(String? raw) =>
      values.firstWhere((e) => e.storageValue == raw,
          orElse: () => StakeChallengeStatus.draft);

  bool get isTerminal =>
      this == completedSuccess ||
      this == completedForfeit ||
      this == cancelled ||
      this == vetoed;
}

enum StakePhotoState {
  pendingScreen('pending_screen'),
  approved('approved'),
  rejected('rejected'),
  revealed('revealed'),
  hiddenPendingReview('hidden_pending_review'),
  expired('expired'),
  removed('removed'),
  deleted('deleted');

  const StakePhotoState(this.storageValue);
  final String storageValue;

  static StakePhotoState? fromStorage(String? raw) {
    if (raw == null) return null;
    for (final v in values) {
      if (v.storageValue == raw) return v;
    }
    return null;
  }
}

// ─── Value objects ───────────────────────────────────────────────────────────

/// CC-6 — the goal criteria frozen at creation; editing the linked app goal
/// changes nothing here.
class StakeFrozenGoal {
  const StakeFrozenGoal({
    required this.title,
    required this.unitKind,
    required this.unitTarget,
    required this.totalUnits,
  });

  final String title;

  /// `'minutes'` (timer evidence) or `'count'`.
  final String unitKind;
  final int unitTarget;
  final int totalUnits;

  factory StakeFrozenGoal.fromMap(Map<String, dynamic> m) => StakeFrozenGoal(
        title: (m['title'] as String?) ?? '',
        unitKind: (m['unitKind'] as String?) ?? 'minutes',
        unitTarget: (m['unitTarget'] as num?)?.toInt() ?? 1,
        totalUnits: (m['totalUnits'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'unitKind': unitKind,
        'unitTarget': unitTarget,
        'totalUnits': totalUnits,
      };
}

class StakeParticipant {
  const StakeParticipant({
    required this.uid,
    required this.teamId,
    required this.stakeKind,
    this.stakeAmount,
    this.photoStoragePath,
    this.revealWindowMins,
    required this.accepted,
  });

  final String uid;
  final String teamId;

  /// `'photo' | 'points' | 'money'`.
  final String stakeKind;
  final int? stakeAmount;
  final String? photoStoragePath;
  final int? revealWindowMins;
  final bool accepted;

  factory StakeParticipant.fromMap(Map<String, dynamic> m) {
    final photo = m['photo'] as Map<String, dynamic>?;
    return StakeParticipant(
      uid: (m['uid'] as String?) ?? '',
      teamId: (m['teamId'] as String?) ?? (m['uid'] as String? ?? ''),
      stakeKind: (m['stakeKind'] as String?) ?? 'photo',
      stakeAmount: (m['stakeAmount'] as num?)?.toInt(),
      photoStoragePath: photo?['storagePath'] as String?,
      revealWindowMins: (photo?['revealWindowMins'] as num?)?.toInt(),
      accepted: (m['accepted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'teamId': teamId,
        'stakeKind': stakeKind,
        if (stakeAmount != null) 'stakeAmount': stakeAmount,
        if (photoStoragePath != null)
          'photo': {
            'storagePath': photoStoragePath,
            'revealWindowMins': revealWindowMins,
          },
        'accepted': accepted,
      };
}

/// One participant's decided result (mirror of the engine's output).
class StakeParticipantResult {
  const StakeParticipantResult({
    required this.uid,
    required this.unitsPassed,
    required this.unitsRequired,
    required this.passed,
    required this.sideWon,
    required this.resolutionKind,
    this.toCharityId,
  });

  final String uid;
  final int unitsPassed;
  final int unitsRequired;

  /// Personal verdict (records/badges).
  final bool passed;

  /// D4/D5 — the stake follows this, not [passed].
  final bool sideWon;

  /// `'none' | 'reveal_photo' | 'veto_blocked' | 'refund' | 'forfeit'`.
  final String resolutionKind;
  final String? toCharityId;

  factory StakeParticipantResult.fromMap(Map<String, dynamic> m) {
    final resolution = m['resolution'] as Map<String, dynamic>?;
    return StakeParticipantResult(
      uid: (m['uid'] as String?) ?? '',
      unitsPassed: (m['unitsPassed'] as num?)?.toInt() ?? 0,
      unitsRequired: (m['unitsRequired'] as num?)?.toInt() ?? 0,
      passed: (m['passed'] as bool?) ?? false,
      sideWon: (m['sideWon'] as bool?) ?? false,
      resolutionKind: (resolution?['kind'] as String?) ?? 'none',
      toCharityId: resolution?['toCharityId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'unitsPassed': unitsPassed,
        'unitsRequired': unitsRequired,
        'passed': passed,
        'sideWon': sideWon,
        'resolution': {
          'kind': resolutionKind,
          if (toCharityId != null) 'toCharityId': toCharityId,
        },
      };
}

// ─── The challenge ───────────────────────────────────────────────────────────

class StakeChallenge {
  const StakeChallenge({
    required this.id,
    required this.type,
    required this.status,
    required this.creatorUid,
    required this.circleId,
    required this.participants,
    required this.frozenGoal,
    this.mode,
    required this.deadlineMs,
    this.photoState,
    this.revealedAtMs,
    this.revealExpiresAtMs,
    this.decidedAtMs,
    this.results = const [],
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final StakeChallengeType type;
  final StakeChallengeStatus status;
  final String creatorUid;

  /// Empty for practice challenges without a circle.
  final String circleId;
  final List<StakeParticipant> participants;
  final StakeFrozenGoal frozenGoal;

  /// `'flexible' | 'disciplined' | 'extreme'` — solo/h2h only (D3/D4).
  final String? mode;
  final int deadlineMs;

  final StakePhotoState? photoState;
  final int? revealedAtMs;
  final int? revealExpiresAtMs;

  final int? decidedAtMs;
  final List<StakeParticipantResult> results;

  final int createdAtMs;
  final int updatedAtMs;

  StakeParticipant? participant(String uid) {
    for (final p in participants) {
      if (p.uid == uid) return p;
    }
    return null;
  }

  /// Units are LOCAL calendar days counted from the creation day (day 0).
  /// Evidence carries the unitIndex; the server only enforces arrival time
  /// (CC-5), so the day boundary is the user's own clock — consistent with
  /// how the rest of the app treats "today".
  int unitIndexAt(DateTime now) {
    final created = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    final startOfCreatedDay = DateTime(created.year, created.month, created.day);
    final startOfNowDay = DateTime(now.year, now.month, now.day);
    return startOfNowDay.difference(startOfCreatedDay).inDays;
  }

  int get todayUnitIndex => unitIndexAt(DateTime.now());

  /// The 25% within-unit mercy bar (M-1), for display: "≥45 min counts".
  int get mercyUnitTarget => (frozenGoal.unitTarget * 3 + 3) ~/ 4;

  factory StakeChallenge.fromMap(Map<String, dynamic> m) {
    final outcome = m['outcome'] as Map<String, dynamic>?;
    final rawResults = (outcome?['perParticipant'] as List?) ?? const [];
    return StakeChallenge(
      id: (m['id'] as String?) ?? '',
      type: StakeChallengeType.fromStorage(m['type'] as String?),
      status: StakeChallengeStatus.fromStorage(m['status'] as String?),
      creatorUid: (m['creatorUid'] as String?) ?? '',
      circleId: (m['circleId'] as String?) ?? '',
      participants: ((m['participants'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StakeParticipant.fromMap)
          .toList(),
      frozenGoal: StakeFrozenGoal.fromMap(
          (m['frozenGoal'] as Map<String, dynamic>?) ?? const {}),
      mode: m['mode'] as String?,
      deadlineMs: (m['deadlineMs'] as num?)?.toInt() ?? 0,
      photoState: StakePhotoState.fromStorage(m['photoState'] as String?),
      revealedAtMs: (m['revealedAtMs'] as num?)?.toInt(),
      revealExpiresAtMs: (m['revealExpiresAtMs'] as num?)?.toInt(),
      decidedAtMs: (outcome?['decidedAtMs'] as num?)?.toInt(),
      results: rawResults
          .whereType<Map<String, dynamic>>()
          .map(StakeParticipantResult.fromMap)
          .toList(),
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (m['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  /// JSON round-trip helpers for the Isar mirror (nested structures are
  /// stored as encoded strings — mirrors are read-only, so no field-level
  /// queries on them are ever needed).
  static List<StakeParticipant> participantsFromJson(String json) =>
      (jsonDecode(json) as List)
          .whereType<Map<String, dynamic>>()
          .map(StakeParticipant.fromMap)
          .toList();

  static String participantsToJson(List<StakeParticipant> list) =>
      jsonEncode(list.map((p) => p.toMap()).toList());
}
