// ─── ChallengeMode ────────────────────────────────────────────────────────────

enum ChallengeMode { competition, team }

extension ChallengeModeStorage on ChallengeMode {
  String get storageValue => name;

  static ChallengeMode fromStorage(String? raw) {
    return ChallengeMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ChallengeMode.competition,
    );
  }
}

// ─── ChallengeStatus ──────────────────────────────────────────────────────────

enum ChallengeStatus { pending, active, completed, rejected }

extension ChallengeStatusStorage on ChallengeStatus {
  String get storageValue => name;

  static ChallengeStatus fromStorage(String? raw) {
    return ChallengeStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ChallengeStatus.pending,
    );
  }
}

// ─── Challenge ────────────────────────────────────────────────────────────────

/// A member's latest proof photo for a challenge (2026-09-19). [isPublic]
/// is the member's choice at upload: public proofs show to the circle,
/// private ones only to the uploader (the circle sees a progress line).
class ChallengeProof {
  const ChallengeProof({
    required this.url,
    required this.isPublic,
    required this.atMs,
  });

  final String url;
  final bool isPublic;
  final int atMs;

  Map<String, dynamic> toMap() => {
    'url': url,
    'isPublic': isPublic,
    'atMs': atMs,
  };

  static ChallengeProof? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url'] as String?;
    if (url == null || url.isEmpty) return null;
    return ChallengeProof(
      url: url,
      isPublic: raw['isPublic'] as bool? ?? true,
      atMs: (raw['atMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class Challenge {
  const Challenge({
    required this.id,
    required this.circleId,
    required this.creatorId,
    required this.title,
    required this.mode,
    required this.status,
    required this.targetValue,
    required this.unit,
    this.memberProgress = const {},
    this.memberProofs = const {},
    this.teamTotal = 0,
    required this.startsAtMs,
    required this.endsAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String circleId;
  final String creatorId;
  final String title;
  final ChallengeMode mode;
  final ChallengeStatus status;

  /// Target value each member (competition) or the team (team mode) must reach.
  final int targetValue;

  /// Unit label, e.g. `'miles'`, `'sessions'`, `'pages'`.
  final String unit;

  /// userId → current progress count.
  final Map<String, int> memberProgress;

  /// uid → latest proof photo. Absent for members who never attached one.
  final Map<String, ChallengeProof> memberProofs;

  /// Denormalized sum of all member progress (team mode only).
  final int teamTotal;

  final int startsAtMs;
  final int endsAtMs;
  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    if (title.trim().isEmpty) {
      throw ArgumentError('challenge.title must not be empty');
    }
    if (targetValue <= 0) {
      throw ArgumentError('challenge.targetValue must be > 0');
    }
    if (endsAtMs <= startsAtMs) {
      throw ArgumentError('challenge.endsAtMs must be after startsAtMs');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'circleId': circleId,
    'creatorId': creatorId,
    'title': title,
    'mode': mode.storageValue,
    'status': status.storageValue,
    'targetValue': targetValue,
    'unit': unit,
    'memberProgress': memberProgress,
    if (memberProofs.isNotEmpty)
      'memberProofs': memberProofs.map((k, v) => MapEntry(k, v.toMap())),
    'teamTotal': teamTotal,
    'startsAtMs': startsAtMs,
    'endsAtMs': endsAtMs,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static Challenge fromMap(Map<String, dynamic> map) {
    final rawProgress = (map['memberProgress'] as Map<String, dynamic>?) ?? {};
    final progress = rawProgress.map((k, v) => MapEntry(k, (v as num).toInt()));
    final rawProofs = (map['memberProofs'] as Map<String, dynamic>?) ?? {};
    final proofs = <String, ChallengeProof>{
      for (final e in rawProofs.entries)
        if (ChallengeProof.fromMap(e.value) != null)
          e.key: ChallengeProof.fromMap(e.value)!,
    };

    return Challenge(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      mode: ChallengeModeStorage.fromStorage(map['mode'] as String?),
      status: ChallengeStatusStorage.fromStorage(map['status'] as String?),
      targetValue: (map['targetValue'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? '',
      memberProgress: progress,
      memberProofs: proofs,
      teamTotal: (map['teamTotal'] as num?)?.toInt() ?? 0,
      startsAtMs: (map['startsAtMs'] as num?)?.toInt() ?? 0,
      endsAtMs: (map['endsAtMs'] as num?)?.toInt() ?? 0,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Challenge copyWith({
    String? id,
    String? circleId,
    String? creatorId,
    String? title,
    ChallengeMode? mode,
    ChallengeStatus? status,
    int? targetValue,
    String? unit,
    Map<String, int>? memberProgress,
    Map<String, ChallengeProof>? memberProofs,
    int? teamTotal,
    int? startsAtMs,
    int? endsAtMs,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return Challenge(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      memberProgress: memberProgress ?? this.memberProgress,
      memberProofs: memberProofs ?? this.memberProofs,
      teamTotal: teamTotal ?? this.teamTotal,
      startsAtMs: startsAtMs ?? this.startsAtMs,
      endsAtMs: endsAtMs ?? this.endsAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
