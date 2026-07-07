enum RemovalVoteStatus { pending, resolved }

extension RemovalVoteStatusStorage on RemovalVoteStatus {
  String get storageValue => name;

  static RemovalVoteStatus fromStorage(String? raw) {
    return RemovalVoteStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RemovalVoteStatus.pending,
    );
  }
}

/// A moderator-initiated vote to remove a member from a circle.
class RemovalVote {
  const RemovalVote({
    required this.id,
    required this.circleId,
    required this.targetUserId,
    required this.initiatorId,
    this.votes = const {},
    this.status = RemovalVoteStatus.pending,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String circleId;
  final String targetUserId;
  final String initiatorId;

  /// userId → true (approve removal) / false (reject).
  final Map<String, bool> votes;

  final RemovalVoteStatus status;
  final int createdAtMs;
  final int updatedAtMs;

  Map<String, dynamic> toMap() => {
    'id': id,
    'circleId': circleId,
    'targetUserId': targetUserId,
    'initiatorId': initiatorId,
    'votes': votes,
    'status': status.storageValue,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static RemovalVote fromMap(Map<String, dynamic> map) {
    final rawVotes = (map['votes'] as Map<String, dynamic>?) ?? {};
    final votes = rawVotes.map((k, v) => MapEntry(k, v as bool));

    return RemovalVote(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      targetUserId: map['targetUserId'] as String? ?? '',
      initiatorId: map['initiatorId'] as String? ?? '',
      votes: votes,
      status: RemovalVoteStatusStorage.fromStorage(map['status'] as String?),
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  RemovalVote copyWith({
    String? id,
    String? circleId,
    String? targetUserId,
    String? initiatorId,
    Map<String, bool>? votes,
    RemovalVoteStatus? status,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return RemovalVote(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      targetUserId: targetUserId ?? this.targetUserId,
      initiatorId: initiatorId ?? this.initiatorId,
      votes: votes ?? this.votes,
      status: status ?? this.status,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
