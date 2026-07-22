import 'package:sidepal/features/community/data/circle_message_repository.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:sidepal/features/community/domain/models/circle_message.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

CircleMessage _makeMessage({
  String id = 'msg-1',
  String circleId = 'circle-1',
  int createdAtMs = 1_000_000,
  String content = 'Hello!',
}) {
  return CircleMessage(
    id: id,
    circleId: circleId,
    senderId: 'user-1',
    senderDisplayName: 'Alice',
    type: MessageType.text,
    content: content,
    createdAtMs: createdAtMs,
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreCircleMessageRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestoreCircleMessageRepository(firestore: fakeFirestore);
  });

  group('sendMessage / watchMessages', () {
    test('watchMessages emits empty list before any messages', () async {
      final list = await repo.watchMessages('circle-1').first;
      expect(list, isEmpty);
    });

    test('sendMessage then watchMessages includes the message', () async {
      final msg = _makeMessage();
      await repo.sendMessage(msg);

      final list = await repo.watchMessages('circle-1').first;
      expect(list, hasLength(1));
      expect(list.first.id, msg.id);
      expect(list.first.content, msg.content);
    });

    test('newer message appears first (descending order)', () async {
      final older = _makeMessage(id: 'msg-old', createdAtMs: 1_000_000, content: 'Old');
      final newer = _makeMessage(id: 'msg-new', createdAtMs: 2_000_000, content: 'New');
      await repo.sendMessage(older);
      await repo.sendMessage(newer);

      final list = await repo.watchMessages('circle-1').first;
      expect(list.first.id, 'msg-new');
      expect(list.last.id, 'msg-old');
    });

    test('limit is respected', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.sendMessage(_makeMessage(id: 'msg-$i', createdAtMs: i * 1000));
      }
      final list = await repo.watchMessages('circle-1', limit: 3).first;
      expect(list, hasLength(3));
    });
  });

  group('updateReactions', () {
    test('updateReactions stores new reactions map', () async {
      final msg = _makeMessage();
      await repo.sendMessage(msg);

      final reactions = {
        '🔥': ['user-1', 'user-2'],
        '💪': ['user-3'],
      };
      await repo.updateReactions(msg.circleId, msg.id, reactions);

      final list = await repo.watchMessages('circle-1').first;
      final updated = list.firstWhere((m) => m.id == msg.id);
      expect(updated.reactions['🔥'], containsAll(['user-1', 'user-2']));
      expect(updated.reactions['💪'], contains('user-3'));
    });

    test('clearing reactions stores empty map', () async {
      final msg = _makeMessage();
      await repo.sendMessage(msg);
      await repo.updateReactions(msg.circleId, msg.id, {});

      final list = await repo.watchMessages('circle-1').first;
      expect(list.first.reactions, isEmpty);
    });
  });
}
