// ─── AiPulseType ──────────────────────────────────────────────────────────────

enum AiPulseType { daily, weekly }

extension AiPulseTypeStorage on AiPulseType {
  String get storageValue => name;

  static AiPulseType fromStorage(String? raw) {
    return AiPulseType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AiPulseType.daily,
    );
  }
}

// ─── MemberPulseLine ──────────────────────────────────────────────────────────

/// One member's personalised insight within a pulse.
class MemberPulseLine {
  const MemberPulseLine({
    required this.userId,
    required this.displayName,
    required this.insight,
  });

  final String userId;
  final String displayName;
  final String insight;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'insight': insight,
      };

  static MemberPulseLine fromMap(Map<String, dynamic> map) {
    return MemberPulseLine(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      insight: map['insight'] as String? ?? '',
    );
  }
}

// ─── AiPulse ─────────────────────────────────────────────────────────────────

/// An AI-generated group pulse for an accountability circle.
class AiPulse {
  const AiPulse({
    required this.id,
    required this.circleId,
    required this.type,
    required this.summary,
    required this.memberLines,
    this.suggestedChallenge,
    required this.generatedAtMs,
  });

  final String id;
  final String circleId;
  final AiPulseType type;

  /// 1-sentence overall status for the circle.
  final String summary;

  /// Per-member insight lines.
  final List<MemberPulseLine> memberLines;

  /// Optional challenge suggestion.
  final String? suggestedChallenge;

  final int generatedAtMs;

  Map<String, dynamic> toMap() => {
        'id': id,
        'circleId': circleId,
        'type': type.storageValue,
        'summary': summary,
        'memberLines': memberLines.map((l) => l.toMap()).toList(),
        'suggestedChallenge': suggestedChallenge,
        'generatedAtMs': generatedAtMs,
      };

  static AiPulse fromMap(Map<String, dynamic> map) {
    final lines = ((map['memberLines'] as List?)?.cast<Map<String, dynamic>>() ?? [])
        .map(MemberPulseLine.fromMap)
        .toList();

    return AiPulse(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      type: AiPulseTypeStorage.fromStorage(map['type'] as String?),
      summary: map['summary'] as String? ?? '',
      memberLines: lines,
      suggestedChallenge: map['suggestedChallenge'] as String?,
      generatedAtMs: (map['generatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  AiPulse copyWith({
    String? id,
    String? circleId,
    AiPulseType? type,
    String? summary,
    List<MemberPulseLine>? memberLines,
    Object? suggestedChallenge = _sentinel,
    int? generatedAtMs,
  }) {
    return AiPulse(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      memberLines: memberLines ?? this.memberLines,
      suggestedChallenge: suggestedChallenge == _sentinel
          ? this.suggestedChallenge
          : suggestedChallenge as String?,
      generatedAtMs: generatedAtMs ?? this.generatedAtMs,
    );
  }
}

const _sentinel = Object();
