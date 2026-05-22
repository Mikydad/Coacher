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
  milestoneReached,
  weeklyCommitmentMet,
  memberJoined,
  memberLeft,
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
