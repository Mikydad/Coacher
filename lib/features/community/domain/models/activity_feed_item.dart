import 'circle_enums.dart';

/// A system-generated or user-triggered event surfaced in the circle activity feed.
class ActivityFeedItem {
  const ActivityFeedItem({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.displayName,
    required this.eventType,
    this.entityId,
    this.entityTitle,
    this.value,
    required this.dateKey,
    required this.createdAtMs,
  });

  final String id;
  final String circleId;
  final String userId;
  final String displayName;
  final ActivityEventType eventType;

  /// ID of the linked goal, task, habit, or milestone.
  final String? entityId;

  /// Human-readable title of the linked entity (e.g. goal name).
  final String? entityTitle;

  /// Supplemental numeric value (e.g. streak count `'11'`).
  final String? value;

  /// `'yyyy-MM-dd'` — used for idempotency checks.
  final String dateKey;

  final int createdAtMs;

  Map<String, dynamic> toMap() => {
    'id': id,
    'circleId': circleId,
    'userId': userId,
    'displayName': displayName,
    'eventType': eventType.storageValue,
    if (entityId != null) 'entityId': entityId,
    if (entityTitle != null) 'entityTitle': entityTitle,
    if (value != null) 'value': value,
    'dateKey': dateKey,
    'createdAtMs': createdAtMs,
  };

  static ActivityFeedItem fromMap(Map<String, dynamic> map) {
    return ActivityFeedItem(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      eventType: ActivityEventTypeStorage.fromStorage(
        map['eventType'] as String?,
      ),
      entityId: map['entityId'] as String?,
      entityTitle: map['entityTitle'] as String?,
      value: map['value'] as String?,
      dateKey: map['dateKey'] as String? ?? '',
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  ActivityFeedItem copyWith({
    String? id,
    String? circleId,
    String? userId,
    String? displayName,
    ActivityEventType? eventType,
    String? entityId,
    String? entityTitle,
    String? value,
    String? dateKey,
    int? createdAtMs,
  }) {
    return ActivityFeedItem(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      eventType: eventType ?? this.eventType,
      entityId: entityId ?? this.entityId,
      entityTitle: entityTitle ?? this.entityTitle,
      value: value ?? this.value,
      dateKey: dateKey ?? this.dateKey,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}
