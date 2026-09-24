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
    this.reactionsByUser = const {},
    required this.createdAtMs,
    this.deletedAtMs,
    this.deletedByUid,
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

  /// emoji → list of userIds who reacted — the DISPLAY view. Built by
  /// [fromMap] as the union of the legacy `reactions` field and
  /// [reactionsByUser]; never written back by reaction toggles.
  final Map<String, List<String>> reactions;

  /// userId → list of emoji — the WRITE model (audit L2). Rules let a
  /// member change only their own key, so nobody can forge or erase
  /// another member's reactions. Legacy `reactions` entries stay visible
  /// but are read-only.
  final Map<String, List<String>> reactionsByUser;

  /// The emoji [uid] currently has on this message (own key, plus any
  /// legacy entries — so a pre-migration reaction still reads as "mine").
  List<String> reactionsOf(String uid) {
    final own = List<String>.from(reactionsByUser[uid] ?? const []);
    for (final entry in reactions.entries) {
      if (entry.value.contains(uid) && !own.contains(entry.key)) {
        own.add(entry.key);
      }
    }
    return own;
  }

  /// Merges the legacy emoji → uids map with a uid → emojis map into one
  /// emoji → uids view (stable order: legacy first, then by-user).
  static Map<String, List<String>> mergeReactions(
    Map<String, List<String>> legacy,
    Map<String, List<String>> byUser,
  ) {
    final merged = <String, List<String>>{
      for (final e in legacy.entries) e.key: List<String>.from(e.value),
    };
    for (final entry in byUser.entries) {
      for (final emoji in entry.value) {
        final uids = merged.putIfAbsent(emoji, () => <String>[]);
        if (!uids.contains(entry.key)) uids.add(entry.key);
      }
    }
    merged.removeWhere((_, uids) => uids.isEmpty);
    return merged;
  }

  final int createdAtMs;

  /// Tombstone (2026-09-24, WhatsApp model): a deleted message keeps its
  /// row so the thread shows "This message was deleted" in place, with
  /// content and image stripped. [deletedByUid] is the sender for a
  /// self-delete or a moderator otherwise.
  final int? deletedAtMs;
  final String? deletedByUid;

  bool get isDeleted => deletedAtMs != null;

  /// Deleted by someone other than the sender — a moderator.
  bool get deletedByModerator =>
      isDeleted && deletedByUid != null && deletedByUid != senderId;

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
    'reactionsByUser': reactionsByUser.map(
      (uid, emojis) => MapEntry(uid, List<String>.from(emojis)),
    ),
    'createdAtMs': createdAtMs,
    if (deletedAtMs != null) 'deletedAtMs': deletedAtMs,
    if (deletedByUid != null) 'deletedByUid': deletedByUid,
  };

  static Map<String, List<String>> _stringListMap(Object? raw) {
    final map = raw as Map<String, dynamic>? ?? {};
    return map.map(
      (key, value) => MapEntry(key, List<String>.from(value as List? ?? [])),
    );
  }

  static CircleMessage fromMap(Map<String, dynamic> map) {
    final legacy = _stringListMap(map['reactions']);
    final byUser = _stringListMap(map['reactionsByUser']);
    final reactions = mergeReactions(legacy, byUser);
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
      reactionsByUser: byUser,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      deletedAtMs: (map['deletedAtMs'] as num?)?.toInt(),
      deletedByUid: map['deletedByUid'] as String?,
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
    Map<String, List<String>>? reactionsByUser,
    int? createdAtMs,
    int? deletedAtMs,
    String? deletedByUid,
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
      reactionsByUser: reactionsByUser ?? this.reactionsByUser,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      deletedByUid: deletedByUid ?? this.deletedByUid,
    );
  }
}
