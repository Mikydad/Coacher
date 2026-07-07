/// Per-circle notification preferences for a user.
class CircleNotifPrefs {
  const CircleNotifPrefs({
    required this.circleId,
    this.mentions = true,
    this.challengeUpdates = true,
    this.weeklySummary = true,
    this.accomplishments = true,
    this.reactions = false,
    this.muteUntilMs,
  });

  final String circleId;
  final bool mentions;
  final bool challengeUpdates;
  final bool weeklySummary;
  final bool accomplishments;

  /// Reactions are muted by default per PRD.
  final bool reactions;

  /// Null = not muted. A future timestamp = muted until then.
  final int? muteUntilMs;

  bool get isMuted =>
      muteUntilMs != null &&
      muteUntilMs! > DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    'circleId': circleId,
    'mentions': mentions,
    'challengeUpdates': challengeUpdates,
    'weeklySummary': weeklySummary,
    'accomplishments': accomplishments,
    'reactions': reactions,
    'muteUntilMs': muteUntilMs,
  };

  static CircleNotifPrefs fromMap(Map<String, dynamic> map) {
    return CircleNotifPrefs(
      circleId: map['circleId'] as String? ?? '',
      mentions: map['mentions'] as bool? ?? true,
      challengeUpdates: map['challengeUpdates'] as bool? ?? true,
      weeklySummary: map['weeklySummary'] as bool? ?? true,
      accomplishments: map['accomplishments'] as bool? ?? true,
      reactions: map['reactions'] as bool? ?? false,
      muteUntilMs: (map['muteUntilMs'] as num?)?.toInt(),
    );
  }

  CircleNotifPrefs copyWith({
    String? circleId,
    bool? mentions,
    bool? challengeUpdates,
    bool? weeklySummary,
    bool? accomplishments,
    bool? reactions,
    Object? muteUntilMs = _sentinel,
  }) {
    return CircleNotifPrefs(
      circleId: circleId ?? this.circleId,
      mentions: mentions ?? this.mentions,
      challengeUpdates: challengeUpdates ?? this.challengeUpdates,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      accomplishments: accomplishments ?? this.accomplishments,
      reactions: reactions ?? this.reactions,
      muteUntilMs: muteUntilMs == _sentinel
          ? this.muteUntilMs
          : muteUntilMs as int?,
    );
  }
}

const _sentinel = Object();
