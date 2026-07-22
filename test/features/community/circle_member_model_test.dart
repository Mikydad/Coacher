import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:sidepal/features/community/domain/models/circle_member.dart';
import 'package:flutter_test/flutter_test.dart';

CircleMember _makeMember({
  CircleMemberRole role = CircleMemberRole.member,
  CircleMemberStatus status = CircleMemberStatus.active,
}) {
  return CircleMember(
    userId: 'user-1',
    circleId: 'circle-1',
    displayName: 'Alice',
    role: role,
    status: status,
    joinedAtMs: 1_000_000,
    updatedAtMs: 2_000_000,
  );
}

void main() {
  group('CircleMember toMap / fromMap', () {
    test('round-trip preserves all fields', () {
      final member = _makeMember();
      final restored = CircleMember.fromMap(member.toMap());

      expect(restored.userId, member.userId);
      expect(restored.circleId, member.circleId);
      expect(restored.displayName, member.displayName);
      expect(restored.role, member.role);
      expect(restored.status, member.status);
      expect(restored.joinedAtMs, member.joinedAtMs);
      expect(restored.updatedAtMs, member.updatedAtMs);
    });

    test('moderator role round-trips', () {
      final m = _makeMember(role: CircleMemberRole.moderator);
      expect(CircleMember.fromMap(m.toMap()).role, CircleMemberRole.moderator);
    });

    test('pending status round-trips', () {
      final m = _makeMember(status: CircleMemberStatus.pending);
      expect(CircleMember.fromMap(m.toMap()).status, CircleMemberStatus.pending);
    });

    test('removed status round-trips', () {
      final m = _makeMember(status: CircleMemberStatus.removed);
      expect(CircleMember.fromMap(m.toMap()).status, CircleMemberStatus.removed);
    });

    test('unknown role defaults to member', () {
      final map = _makeMember().toMap()..['role'] = 'superadmin';
      expect(CircleMember.fromMap(map).role, CircleMemberRole.member);
    });

    test('unknown status defaults to pending', () {
      final map = _makeMember().toMap()..['status'] = 'unknown';
      expect(CircleMember.fromMap(map).status, CircleMemberStatus.pending);
    });
  });

  group('Enum storageValue / fromStorage', () {
    test('JoinPolicy open ↔ open', () {
      expect(JoinPolicy.open.storageValue, 'open');
      expect(JoinPolicyStorage.fromStorage('open'), JoinPolicy.open);
    });

    test('JoinPolicy requestApproval ↔ requestApproval', () {
      expect(JoinPolicy.requestApproval.storageValue, 'requestApproval');
      expect(JoinPolicyStorage.fromStorage('requestApproval'), JoinPolicy.requestApproval);
    });

    test('CircleVisibility public ↔ public', () {
      expect(CircleVisibility.public.storageValue, 'public');
      expect(CircleVisibilityStorage.fromStorage('public'), CircleVisibility.public);
    });

    test('CircleVisibility private ↔ private', () {
      expect(CircleVisibility.private.storageValue, 'private');
      expect(CircleVisibilityStorage.fromStorage('private'), CircleVisibility.private);
    });

    test('CircleMemberRole member ↔ member', () {
      expect(CircleMemberRole.member.storageValue, 'member');
      expect(CircleMemberRoleStorage.fromStorage('member'), CircleMemberRole.member);
    });

    test('CircleMemberRole moderator ↔ moderator', () {
      expect(CircleMemberRole.moderator.storageValue, 'moderator');
      expect(CircleMemberRoleStorage.fromStorage('moderator'), CircleMemberRole.moderator);
    });

    test('CircleMemberStatus active ↔ active', () {
      expect(CircleMemberStatus.active.storageValue, 'active');
      expect(CircleMemberStatusStorage.fromStorage('active'), CircleMemberStatus.active);
    });

    test('CircleMemberStatus pending ↔ pending', () {
      expect(CircleMemberStatus.pending.storageValue, 'pending');
      expect(CircleMemberStatusStorage.fromStorage('pending'), CircleMemberStatus.pending);
    });

    test('CircleMemberStatus removed ↔ removed', () {
      expect(CircleMemberStatus.removed.storageValue, 'removed');
      expect(CircleMemberStatusStorage.fromStorage('removed'), CircleMemberStatus.removed);
    });

    test('MessageType text ↔ text', () {
      expect(MessageType.text.storageValue, 'text');
      expect(MessageTypeStorage.fromStorage('text'), MessageType.text);
    });

    test('MessageType image ↔ image', () {
      expect(MessageType.image.storageValue, 'image');
      expect(MessageTypeStorage.fromStorage('image'), MessageType.image);
    });

    test('MessageType systemEvent ↔ systemEvent', () {
      expect(MessageType.systemEvent.storageValue, 'systemEvent');
      expect(MessageTypeStorage.fromStorage('systemEvent'), MessageType.systemEvent);
    });

    test('unknown MessageType defaults to text', () {
      expect(MessageTypeStorage.fromStorage('video'), MessageType.text);
    });
  });
}
