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

  group('setMyReactions (own key only — audit L2)', () {
    test('writes reactionsByUser.{uid} and the merged view reflects it', () async {
      final msg = _makeMessage();
      await repo.sendMessage(msg);

      await repo.setMyReactions(msg.circleId, msg.id, 'user-1', ['🔥', '💪']);
      await repo.setMyReactions(msg.circleId, msg.id, 'user-2', ['🔥']);

      final list = await repo.watchMessages('circle-1').first;
      final updated = list.firstWhere((m) => m.id == msg.id);
      expect(updated.reactions['🔥'], containsAll(['user-1', 'user-2']));
      expect(updated.reactions['💪'], ['user-1']);
      expect(updated.reactionsOf('user-2'), ['🔥']);
    });

    test('clearing own reactions leaves the other member untouched', () async {
      final msg = _makeMessage();
      await repo.sendMessage(msg);
      await repo.setMyReactions(msg.circleId, msg.id, 'user-1', ['🔥']);
      await repo.setMyReactions(msg.circleId, msg.id, 'user-2', ['🔥']);
      await repo.setMyReactions(msg.circleId, msg.id, 'user-1', []);

      final list = await repo.watchMessages('circle-1').first;
      expect(list.first.reactions['🔥'], ['user-2']);
      expect(list.first.reactionsOf('user-1'), isEmpty);
    });
  });
}
