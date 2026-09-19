// ─── JoinPolicy ───────────────────────────────────────────────────────────────

enum JoinPolicy { open, requestApproval }

extension JoinPolicyStorage on JoinPolicy {
  String get storageValue => name;

  static JoinPolicy fromStorage(String? raw) {
    return JoinPolicy.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => JoinPolicy.open,
    );
  }
}

// ─── CircleVisibility ─────────────────────────────────────────────────────────

enum CircleVisibility { public, private }

extension CircleVisibilityStorage on CircleVisibility {
  String get storageValue => name;

  static CircleVisibility fromStorage(String? raw) {
    return CircleVisibility.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CircleVisibility.public,
    );
  }
}

// ─── CircleMemberRole ─────────────────────────────────────────────────────────

enum CircleMemberRole { member, moderator }

extension CircleMemberRoleStorage on CircleMemberRole {
  String get storageValue => name;

  static CircleMemberRole fromStorage(String? raw) {
    return CircleMemberRole.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CircleMemberRole.member,
    );
  }
}

// ─── CircleMemberStatus ───────────────────────────────────────────────────────

enum CircleMemberStatus { active, pending, removed }

extension CircleMemberStatusStorage on CircleMemberStatus {
  String get storageValue => name;

  static CircleMemberStatus fromStorage(String? raw) {
    return CircleMemberStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CircleMemberStatus.pending,
    );
  }
}

// ─── MessageType ──────────────────────────────────────────────────────────────

enum MessageType { text, image, activityUpdate, systemEvent }

extension MessageTypeStorage on MessageType {
  String get storageValue => name;

  static MessageType fromStorage(String? raw) {
    return MessageType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MessageType.text,
    );
  }
}

// ─── ActivityEventType ────────────────────────────────────────────────────────

enum ActivityEventType {
  goalCompleted,
  habitStreakReached,
  taskFinished,
  challengeProgressUpdated,

  /// A member logged challenge progress with a PUBLIC proof photo
  /// (2026-09-19). entityId = challengeId, value = the photo's URL.
  challengeProofPosted,
  milestoneReached,
  weeklyCommitmentMet,
  memberJoined,
  memberLeft,

  /// Accountability stakes (server-written by the outcome engine): a
  /// forfeited stake photo went live (entityId = challengeId,
  /// value = revealExpiresAtMs).
  stakePhotoRevealed,

  /// The staker paid to take a live stake photo down early (P-5, D9).
  /// entityId = challengeId. Not tappable — there is nothing to see.
  stakePhotoRemoved,

  /// Someone screenshotted a stake photo — the public naming (D11).
  /// entityId = challengeId, value = ban duration in ms.
  screenshotStrike,
}

extension ActivityEventTypeStorage on ActivityEventType {
  String get storageValue => name;

  static ActivityEventType fromStorage(String? raw) {
    return ActivityEventType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ActivityEventType.goalCompleted,
    );
  }
}
