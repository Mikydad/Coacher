import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:sidepal/features/community/domain/models/circle_message.dart';
import 'package:flutter_test/flutter_test.dart';

CircleMessage _makeMessage({
  MessageType type = MessageType.text,
  String? content = 'Hello circle!',
  String? imageUrl,
  Map<String, List<String>> reactions = const {},
}) {
  return CircleMessage(
    id: 'msg-1',
    circleId: 'circle-1',
    senderId: 'user-1',
    senderDisplayName: 'Alice',
    type: type,
    content: content,
    imageUrl: imageUrl,
    reactions: reactions,
    createdAtMs: 1_000_000,
  );
}

void main() {
  _reactionsByUserTests();
  group('CircleMessage toMap / fromMap', () {
    test('text message round-trip preserves all fields', () {
      final msg = _makeMessage();
      final restored = CircleMessage.fromMap(msg.toMap());

      expect(restored.id, msg.id);
      expect(restored.circleId, msg.circleId);
      expect(restored.senderId, msg.senderId);
      expect(restored.senderDisplayName, msg.senderDisplayName);
      expect(restored.type, msg.type);
      expect(restored.content, msg.content);
      expect(restored.imageUrl, msg.imageUrl);
      expect(restored.createdAtMs, msg.createdAtMs);
    });

    test('image message round-trips imageUrl', () {
      final msg = _makeMessage(
        type: MessageType.image,
        content: null,
        imageUrl: 'https://storage.example.com/proof.jpg',
      );
      final restored = CircleMessage.fromMap(msg.toMap());
      expect(restored.type, MessageType.image);
      expect(restored.imageUrl, 'https://storage.example.com/proof.jpg');
      expect(restored.content, isNull);
    });

    test('reactions map round-trips with multiple emojis', () {
      final reactions = {
        '🔥': ['user-1', 'user-2'],
        '💪': ['user-3'],
      };
      final msg = _makeMessage(reactions: reactions);
      final restored = CircleMessage.fromMap(msg.toMap());

      expect(restored.reactions['🔥'], containsAll(['user-1', 'user-2']));
      expect(restored.reactions['💪'], contains('user-3'));
    });

    test('empty reactions map round-trips', () {
      final msg = _makeMessage(reactions: {});
      final restored = CircleMessage.fromMap(msg.toMap());
      expect(restored.reactions, isEmpty);
    });

    test('systemEvent type round-trips', () {
      final msg = _makeMessage(
        type: MessageType.systemEvent,
        content: 'Alice joined the circle',
      );
      final restored = CircleMessage.fromMap(msg.toMap());
      expect(restored.type, MessageType.systemEvent);
    });

    test('activityRef round-trips when set', () {
      final msg = CircleMessage(
        id: 'msg-2',
        circleId: 'circle-1',
        senderId: 'user-1',
        senderDisplayName: 'Alice',
        type: MessageType.activityUpdate,
        activityRef: 'feed-item-42',
        createdAtMs: 1_000_000,
      );
      final restored = CircleMessage.fromMap(msg.toMap());
      expect(restored.activityRef, 'feed-item-42');
    });

    test('null optional fields round-trip as null', () {
      final msg = _makeMessage(content: null, imageUrl: null);
      final restored = CircleMessage.fromMap(msg.toMap());
      expect(restored.content, isNull);
      expect(restored.imageUrl, isNull);
    });
  });
}

// ─── Reactions: own-key write model (pre-launch audit L2) ────────────────────

void _reactionsByUserTests() {
  group('CircleMessage reactionsByUser', () {
    test('fromMap merges legacy emoji→uids with uid→emojis', () {
      final m = CircleMessage.fromMap({
        'id': 'm',
        'circleId': 'c',
        'senderId': 'a',
        'senderDisplayName': 'A',
        'type': 'text',
        'content': 'hi',
        'reactions': {
          '👍': ['a', 'b'],
        },
        'reactionsByUser': {
          'c': ['👍', '🔥'],
          'a': ['🔥'],
        },
        'createdAtMs': 1,
      });
      expect(m.reactions['👍'], ['a', 'b', 'c']);
      expect(m.reactions['🔥'], ['c', 'a']);
      expect(m.reactionsByUser['c'], ['👍', '🔥']);
    });

    test('reactionsOf includes legacy entries so old reactions read as mine', () {
      final m = CircleMessage.fromMap({
        'id': 'm',
        'circleId': 'c',
        'senderId': 'a',
        'senderDisplayName': 'A',
        'type': 'text',
        'reactions': {
          '👍': ['b'],
        },
        'reactionsByUser': {
          'b': ['🔥'],
        },
        'createdAtMs': 1,
      });
      expect(m.reactionsOf('b'), ['🔥', '👍']);
      expect(m.reactionsOf('zzz'), isEmpty);
    });

    test('toMap writes both maps and round-trips', () {
      final m = CircleMessage(
        id: 'm',
        circleId: 'c',
        senderId: 'a',
        senderDisplayName: 'A',
        type: MessageType.text,
        content: 'hi',
        reactionsByUser: const {
          'a': ['👍'],
        },
        createdAtMs: 1,
      );
      final map = m.toMap();
      expect(map['reactionsByUser'], {
        'a': ['👍'],
      });
      final back = CircleMessage.fromMap(map);
      expect(back.reactions['👍'], ['a']);
    });

    test('mergeReactions drops empty emoji buckets and dedupes uids', () {
      final merged = CircleMessage.mergeReactions(
        {
          '👍': ['a'],
          '💤': [],
        },
        {
          'a': ['👍'],
        },
      );
      expect(merged, {
        '👍': ['a'],
      });
    });
  });

  test('tombstone fields round-trip and are absent when not deleted', () {
    final live = CircleMessage(
      id: 'm',
      circleId: 'c',
      senderId: 's',
      senderDisplayName: 'S',
      type: MessageType.text,
      content: 'hi',
      createdAtMs: 1,
    );
    expect(live.isDeleted, isFalse);
    expect(live.toMap().containsKey('deletedAtMs'), isFalse);
    final gone = CircleMessage.fromMap(
      live.copyWith(deletedAtMs: 9, deletedByUid: 's').toMap(),
    );
    expect(gone.isDeleted, isTrue);
    expect(gone.deletedByModerator, isFalse);
    expect(gone.deletedAtMs, 9);
  });
}

