import 'package:coach_for_life/features/community/domain/models/circle_enums.dart';
import 'package:coach_for_life/features/community/domain/models/circle_message.dart';
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
