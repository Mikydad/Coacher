import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/community/application/message_delete_policy.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:sidepal/features/community/domain/models/circle_message.dart';

/// Miko, 2026-09-24: own messages for 30 minutes; moderators any message;
/// nobody else's otherwise. Deleted rows read "by admin" when a moderator
/// did it.
final _sentAt = DateTime(2026, 9, 24, 9);

CircleMessage _msg({
  String sender = 'alice',
  MessageType type = MessageType.text,
  int? deletedAtMs,
  String? deletedByUid,
}) => CircleMessage(
  id: 'm',
  circleId: 'c',
  senderId: sender,
  senderDisplayName: 'A',
  type: type,
  content: 'hi',
  createdAtMs: _sentAt.millisecondsSinceEpoch,
  deletedAtMs: deletedAtMs,
  deletedByUid: deletedByUid,
);

void main() {
  group('canDeleteMessage', () {
    test('sender: inside the window yes, after it no', () {
      expect(
        canDeleteMessage(
          _msg(),
          uid: 'alice',
          isModerator: false,
          now: _sentAt.add(const Duration(minutes: 29)),
        ),
        isTrue,
      );
      expect(
        canDeleteMessage(
          _msg(),
          uid: 'alice',
          isModerator: false,
          now: _sentAt.add(const Duration(minutes: 31)),
        ),
        isFalse,
      );
    });

    test("someone else's message: never, unless moderator", () {
      expect(
        canDeleteMessage(_msg(), uid: 'bob', isModerator: false, now: _sentAt),
        isFalse,
      );
      expect(
        canDeleteMessage(
          _msg(),
          uid: 'bob',
          isModerator: true,
          now: _sentAt.add(const Duration(days: 3)),
        ),
        isTrue,
        reason: 'moderators are not bound by the window',
      );
    });

    test('already deleted or a system event: no', () {
      expect(
        canDeleteMessage(
          _msg(deletedAtMs: 1, deletedByUid: 'alice'),
          uid: 'alice',
          isModerator: true,
          now: _sentAt,
        ),
        isFalse,
      );
      expect(
        canDeleteMessage(
          _msg(type: MessageType.systemEvent),
          uid: 'alice',
          isModerator: true,
          now: _sentAt,
        ),
        isFalse,
      );
    });
  });

  group('deletedMessageLabel', () {
    test('names the admin when a moderator deleted it', () {
      final m = _msg(deletedAtMs: 1, deletedByUid: 'mod');
      expect(m.deletedByModerator, isTrue);
      expect(deletedMessageLabel(m, uid: 'alice'), 'Message deleted by admin');
      expect(deletedMessageLabel(m, uid: 'bob'), 'Message deleted by admin');
    });

    test('self-delete reads as yours to you, deleted to others', () {
      final m = _msg(deletedAtMs: 1, deletedByUid: 'alice');
      expect(m.deletedByModerator, isFalse);
      expect(deletedMessageLabel(m, uid: 'alice'), 'You deleted this message');
      expect(deletedMessageLabel(m, uid: 'bob'), 'This message was deleted');
    });
  });
}
