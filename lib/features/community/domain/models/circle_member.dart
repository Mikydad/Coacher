import 'circle_enums.dart';

/// A user's membership record within an [AccountabilityCircle].
class CircleMember {
  const CircleMember({
    required this.userId,
    required this.circleId,
    required this.displayName,
    required this.role,
    required this.status,
    required this.joinedAtMs,
    required this.updatedAtMs,
  });

  final String userId;
  final String circleId;
  final String displayName;
  final CircleMemberRole role;
  final CircleMemberStatus status;
  final int joinedAtMs;
  final int updatedAtMs;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'circleId': circleId,
    'displayName': displayName,
    'role': role.storageValue,
    'status': status.storageValue,
    'joinedAtMs': joinedAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static CircleMember fromMap(Map<String, dynamic> map) {
    return CircleMember(
      userId: map['userId'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: CircleMemberRoleStorage.fromStorage(map['role'] as String?),
      status: CircleMemberStatusStorage.fromStorage(map['status'] as String?),
      joinedAtMs: (map['joinedAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  CircleMember copyWith({
    String? userId,
    String? circleId,
    String? displayName,
    CircleMemberRole? role,
    CircleMemberStatus? status,
    int? joinedAtMs,
    int? updatedAtMs,
  }) {
    return CircleMember(
      userId: userId ?? this.userId,
      circleId: circleId ?? this.circleId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAtMs: joinedAtMs ?? this.joinedAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
