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
    this.cadence = 'daily',
    this.interval = 1,
    this.scheduledWeekdays,
    this.repeatDaysOfMonth,
    this.startDateMs,
    this.linkedGoalId,
  });

  final String title;

  /// `'minutes'` (timer evidence) or `'count'`.
  final String unitKind;

  /// Per-ACTION-DAY target (2026-07-22 — units are action days).
  final int unitTarget;

  /// Number of action days between start date and deadline.
  final int totalUnits;

  /// `'daily' | 'weekly' | 'monthly'`; legacy docs default to daily.
  final String cadence;

  /// Daily cadence: every N days (1 = every day).
  final int interval;

  /// Weekly cadence: ISO weekdays 1 (Mon) – 7 (Sun).
  final List<int>? scheduledWeekdays;

  /// Monthly cadence: days of month 1–31.
  final List<int>? repeatDaysOfMonth;

  /// Local-midnight ms of day 0. May be in the future. Legacy docs: null
  /// → the challenge's creation day.
  final int? startDateMs;

  /// The live UserGoal this snapshot was frozen from (staked badge).
  final String? linkedGoalId;

  factory StakeFrozenGoal.fromMap(Map<String, dynamic> m) => StakeFrozenGoal(
        title: (m['title'] as String?) ?? '',
        unitKind: (m['unitKind'] as String?) ?? 'minutes',
        unitTarget: (m['unitTarget'] as num?)?.toInt() ?? 1,
        totalUnits: (m['totalUnits'] as num?)?.toInt() ?? 1,
        cadence: (m['cadence'] as String?) ?? 'daily',
        interval: (m['interval'] as num?)?.toInt() ?? 1,
        scheduledWeekdays: (m['scheduledWeekdays'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        repeatDaysOfMonth: (m['repeatDaysOfMonth'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        startDateMs: (m['startDateMs'] as num?)?.toInt(),
        linkedGoalId: m['linkedGoalId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'unitKind': unitKind,
        'unitTarget': unitTarget,
        'totalUnits': totalUnits,
        'cadence': cadence,
        'interval': interval,
        if (scheduledWeekdays != null) 'scheduledWeekdays': scheduledWeekdays,
        if (repeatDaysOfMonth != null) 'repeatDaysOfMonth': repeatDaysOfMonth,
        if (startDateMs != null) 'startDateMs': startDateMs,
        if (linkedGoalId != null) 'linkedGoalId': linkedGoalId,
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

/// $-3 — proof the forfeited money actually reached the charity.
class StakeDonationReceipt {
  const StakeDonationReceipt({
    required this.amountCents,
    required this.toCharityId,
    required this.receiptUrl,
    required this.note,
    required this.atMs,
  });

  final int amountCents;
  final String toCharityId;
  final String receiptUrl;
  final String note;
  final int atMs;

  factory StakeDonationReceipt.fromMap(Map<String, dynamic> m) =>
      StakeDonationReceipt(
        amountCents: (m['amountCents'] as num?)?.toInt() ?? 0,
        toCharityId: (m['toCharityId'] as String?) ?? '',
        receiptUrl: (m['receiptUrl'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
        atMs: (m['atMs'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'amountCents': amountCents,
        'toCharityId': toCharityId,
        'receiptUrl': receiptUrl,
        'note': note,
        'atMs': atMs,
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
    this.sideCharities = const {},
    this.bothLoseCharityId,
    this.antiCharityId,
    this.receipts = const {},
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

  /// D5 — teamId (== uid for 1v1) → the charity that side loves; the
  /// LOSING side's stake funds the winner's pick.
  final Map<String, String> sideCharities;

  /// D6 — where everything goes when every side loses.
  final String? bothLoseCharityId;

  /// $-1 — solo money: the anti-charity that gets the stake on forfeit.
  final String? antiCharityId;
  final int deadlineMs;

  final StakePhotoState? photoState;
  final int? revealedAtMs;
  final int? revealExpiresAtMs;

  final int? decidedAtMs;
  final List<StakeParticipantResult> results;

  /// $-3 — uid → donation receipt posted by the admin after disbursing a
  /// forfeited money stake (mirror of outcome.receipts).
  final Map<String, StakeDonationReceipt> receipts;

  final int createdAtMs;
  final int updatedAtMs;

  StakeParticipant? participant(String uid) {
    for (final p in participants) {
      if (p.uid == uid) return p;
    }
    return null;
  }

  /// Day 0 of the challenge: the frozen start date (may be in the future),
  /// or the creation day for legacy docs. Local calendar day.
  DateTime get startDay {
    final ms = frozenGoal.startDateMs ?? createdAtMs;
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime(d.year, d.month, d.day);
  }

  /// Whether [day] is an ACTION day under the frozen schedule
  /// (2026-07-22 — units are action days, not every calendar day).
  bool isActionDate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    switch (frozenGoal.cadence) {
      case 'weekly':
        return (frozenGoal.scheduledWeekdays ?? const []).contains(d.weekday);
      case 'monthly':
        return (frozenGoal.repeatDaysOfMonth ?? const []).contains(d.day);
      default:
        final interval = frozenGoal.interval < 1 ? 1 : frozenGoal.interval;
        final sinceStart = d.difference(startDay).inDays;
        return sinceStart >= 0 && sinceStart % interval == 0;
    }
  }

  /// Units are LOCAL calendar ACTION days counted from [startDay] (day 0 =
  /// the first action day). Evidence carries the unitIndex; the server only
  /// enforces arrival time (CC-5), so the day boundary is the user's own
  /// clock — consistent with how the rest of the app treats "today".
  ///
  /// Returns -1 before the start date and on non-action days (existing
  /// `today >= 0` guards then hide today-actions naturally). For legacy
  /// daily/interval-1 docs this is byte-identical to the old
  /// days-since-creation math.
  int unitIndexAt(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    if (day.isBefore(startDay)) return -1;
    if (!isActionDate(day)) return -1;
    var index = -1;
    for (var d = startDay;
        !d.isAfter(day);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (isActionDate(d)) index++;
    }
    return index;
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
      sideCharities: ((m['sideCharities'] as Map?) ?? const {})
          .map((k, v) => MapEntry('$k', '$v')),
      bothLoseCharityId: m['bothLoseCharityId'] as String?,
      antiCharityId: m['antiCharityId'] as String?,
      receipts: {
        for (final e
            in ((outcome?['receipts'] as Map?) ?? const {}).entries)
          if (e.value is Map)
            '${e.key}': StakeDonationReceipt.fromMap(
                (e.value as Map).cast<String, dynamic>()),
      },
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

/// Pure schedule math for a PROSPECTIVE challenge (create flow): how many
/// action days a date range + rhythm produces. Must agree with
/// [StakeChallenge.isActionDate] — the created challenge's `totalUnits`
/// comes from here.
int countChallengeActionDays({
  required DateTime start,
  required DateTime end,
  required String cadence,
  int interval = 1,
  Set<int> scheduledWeekdays = const {},
  Set<int> repeatDaysOfMonth = const {},
}) {
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  if (e.isBefore(s)) return 0;
  final step = interval < 1 ? 1 : interval;
  var count = 0;
  for (var d = s; !d.isAfter(e); d = DateTime(d.year, d.month, d.day + 1)) {
    final isAction = switch (cadence) {
      'weekly' => scheduledWeekdays.contains(d.weekday),
      'monthly' => repeatDaysOfMonth.contains(d.day),
      _ => d.difference(s).inDays % step == 0,
    };
    if (isAction) count++;
  }
  return count;
}
