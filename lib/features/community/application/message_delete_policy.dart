import '../domain/models/circle_enums.dart';
import '../domain/models/circle_message.dart';

/// Who may delete a circle message (Miko, 2026-09-24):
///  * the sender, for [kOwnMessageDeleteWindow] after sending;
///  * a moderator, any message, any time — the thread then reads
///    "Message deleted by admin" rather than the sender's own wording.
/// Nobody deletes someone else's message otherwise. The window is enforced
/// here (client); the rules allow the sender to edit their own message and
/// a moderator to write only the tombstone fields.
const Duration kOwnMessageDeleteWindow = Duration(minutes: 30);

bool canDeleteMessage(
  CircleMessage message, {
  required String uid,
  required bool isModerator,
  required DateTime now,
}) {
  if (message.isDeleted) return false;
  if (message.type == MessageType.systemEvent) return false;
  if (isModerator) return true;
  if (message.senderId != uid) return false;
  final age = now.millisecondsSinceEpoch - message.createdAtMs;
  return age <= kOwnMessageDeleteWindow.inMilliseconds;
}

/// The in-place wording for a deleted message, as seen by [uid].
String deletedMessageLabel(CircleMessage message, {required String uid}) {
  if (message.deletedByModerator) return 'Message deleted by admin';
  if (message.senderId == uid) return 'You deleted this message';
  return 'This message was deleted';
}
