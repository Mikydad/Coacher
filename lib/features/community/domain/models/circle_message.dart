import 'circle_enums.dart';

/// A chat message sent within an [AccountabilityCircle].
class CircleMessage {
  const CircleMessage({
    required this.id,
    required this.circleId,
    required this.senderId,
    required this.senderDisplayName,
    required this.type,
    this.content,
    this.imageUrl,
    this.activityRef,
    this.reactions = const {},
    required this.createdAtMs,
  });

  final String id;
  final String circleId;
  final String senderId;
  final String senderDisplayName;
  final MessageType type;

  /// Text body; present when [type] is [MessageType.text] or [MessageType.systemEvent].
  final String? content;

  /// Firebase Storage download URL; present when [type] is [MessageType.image].
  final String? imageUrl;

  /// ID of the [ActivityFeedItem] this message references (activity updates only).
  final String? activityRef;

  /// emoji → list of userIds who reacted.
  final Map<String, List<String>> reactions;

  final int createdAtMs;

  Map<String, dynamic> toMap() => {
    'id': id,
    'circleId': circleId,
    'senderId': senderId,
    'senderDisplayName': senderDisplayName,
    'type': type.storageValue,
    if (content != null) 'content': content,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (activityRef != null) 'activityRef': activityRef,
    'reactions': reactions.map(
      (emoji, uids) => MapEntry(emoji, List<String>.from(uids)),
    ),
    'createdAtMs': createdAtMs,
  };

  static CircleMessage fromMap(Map<String, dynamic> map) {
    final rawReactions = map['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = rawReactions.map(
      (emoji, value) => MapEntry(
        emoji,
        List<String>.from(value as List? ?? []),
      ),
    );
    return CircleMessage(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderDisplayName: map['senderDisplayName'] as String? ?? '',
      type: MessageTypeStorage.fromStorage(map['type'] as String?),
      content: map['content'] as String?,
      imageUrl: map['imageUrl'] as String?,
      activityRef: map['activityRef'] as String?,
      reactions: reactions,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  CircleMessage copyWith({
    String? id,
    String? circleId,
    String? senderId,
    String? senderDisplayName,
    MessageType? type,
    String? content,
    String? imageUrl,
    String? activityRef,
    Map<String, List<String>>? reactions,
    int? createdAtMs,
  }) {
    return CircleMessage(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      senderId: senderId ?? this.senderId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      type: type ?? this.type,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      activityRef: activityRef ?? this.activityRef,
      reactions: reactions ?? this.reactions,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }
}
