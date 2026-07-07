/// A single member's vote on a [Challenge] (approve or reject).
class ChallengeVote {
  const ChallengeVote({
    required this.challengeId,
    required this.userId,
    required this.approve,
    required this.createdAtMs,
  });

  final String challengeId;
  final String userId;
  final bool approve;
  final int createdAtMs;

  Map<String, dynamic> toMap() => {
    'challengeId': challengeId,
    'userId': userId,
    'approve': approve,
    'createdAtMs': createdAtMs,
  };

  static ChallengeVote fromMap(Map<String, dynamic> map) {
    return ChallengeVote(
      challengeId: map['challengeId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      approve: map['approve'] as bool? ?? false,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}
