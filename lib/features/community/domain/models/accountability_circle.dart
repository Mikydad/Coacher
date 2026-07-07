import '../../../../core/validation/model_validators.dart';
import 'circle_enums.dart';

const Object _sentinel = Object();

/// An accountability circle: a small group (4–8 members) for peer accountability.
class AccountabilityCircle {
  const AccountabilityCircle({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.joinPolicy,
    required this.visibility,
    required this.creatorId,
    required this.moderatorIds,
    required this.memberCount,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.timezone,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  static const int kMaxMembers = 8;
  static const int kMinMembers = 4;

  final String id;
  final String name;
  final String? description;

  /// Category slug: e.g. `'fitness'`, `'learning'`, `'business'`.
  final String category;

  final JoinPolicy joinPolicy;
  final CircleVisibility visibility;

  /// UID of the user who created the circle. Creator is always a moderator.
  final String creatorId;

  /// UIDs of moderators (creator + up to 1 assigned). Max 2.
  final List<String> moderatorIds;

  /// Denormalized count for list views. Updated on join/leave.
  final int memberCount;

  /// Consecutive days the circle met the ≥60% activity threshold.
  final int currentStreak;

  /// All-time highest streak.
  final int longestStreak;

  /// IANA timezone name, e.g. `'Africa/Nairobi'`.
  final String timezone;

  final int createdAtMs;
  final int updatedAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'circle.id');
    ModelValidators.requireNotBlank(creatorId, 'circle.creatorId');
    ModelValidators.requireNotBlank(category, 'circle.category');
    if (name.trim().length < 3 || name.trim().length > 40) {
      throw ArgumentError('circle.name must be 3–40 characters');
    }
    if (memberCount < 0 || memberCount > kMaxMembers) {
      throw ArgumentError('circle.memberCount must be 0–$kMaxMembers');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'category': category,
    'joinPolicy': joinPolicy.storageValue,
    'visibility': visibility.storageValue,
    'creatorId': creatorId,
    'moderatorIds': moderatorIds,
    'memberCount': memberCount,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'timezone': timezone,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
  };

  static AccountabilityCircle fromMap(Map<String, dynamic> map) {
    return AccountabilityCircle(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String? ?? '',
      joinPolicy: JoinPolicyStorage.fromStorage(map['joinPolicy'] as String?),
      visibility: CircleVisibilityStorage.fromStorage(
        map['visibility'] as String?,
      ),
      creatorId: map['creatorId'] as String? ?? '',
      moderatorIds: List<String>.from(map['moderatorIds'] as List? ?? []),
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      timezone: map['timezone'] as String? ?? 'UTC',
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  AccountabilityCircle copyWith({
    String? id,
    String? name,
    Object? description = _sentinel,
    String? category,
    JoinPolicy? joinPolicy,
    CircleVisibility? visibility,
    String? creatorId,
    List<String>? moderatorIds,
    int? memberCount,
    int? currentStreak,
    int? longestStreak,
    String? timezone,
    int? createdAtMs,
    int? updatedAtMs,
  }) {
    return AccountabilityCircle(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description == _sentinel
          ? this.description
          : description as String?,
      category: category ?? this.category,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      visibility: visibility ?? this.visibility,
      creatorId: creatorId ?? this.creatorId,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberCount: memberCount ?? this.memberCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      timezone: timezone ?? this.timezone,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }
}
