import 'package:sidepal/features/community/data/circle_member_repository.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:sidepal/features/community/domain/models/circle_member.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

CircleMember _makeMember({
  String userId = 'user-1',
  String circleId = 'circle-1',
  CircleMemberStatus status = CircleMemberStatus.active,
  CircleMemberRole role = CircleMemberRole.member,
}) {
  return CircleMember(
    userId: userId,
    circleId: circleId,
    displayName: 'Alice',
    role: role,
    status: status,
    joinedAtMs: 1_000_000,
    updatedAtMs: 2_000_000,
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreCircleMemberRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestoreCircleMemberRepository(firestore: fakeFirestore);
  });

  group('setMember / getMember', () {
    test('getMember returns null when not found', () async {
      expect(await repo.getMember('circle-1', 'nobody'), isNull);
    });

    test('setMember then getMember returns same record', () async {
      final member = _makeMember();
      await repo.setMember(member);

      final fetched = await repo.getMember(member.circleId, member.userId);
      expect(fetched, isNotNull);
      expect(fetched!.userId, member.userId);
      expect(fetched.role, member.role);
      expect(fetched.status, member.status);
    });

    test('setMember updates an existing record', () async {
      final member = _makeMember(status: CircleMemberStatus.pending);
      await repo.setMember(member);

      final promoted = member.copyWith(
        status: CircleMemberStatus.active,
        role: CircleMemberRole.moderator,
      );
      await repo.setMember(promoted);

      final fetched = await repo.getMember(member.circleId, member.userId);
      expect(fetched!.status, CircleMemberStatus.active);
      expect(fetched.role, CircleMemberRole.moderator);
    });
  });

  group('watchMembers', () {
    test('emits empty list when no members', () async {
      final list = await repo.watchMembers('empty-circle').first;
      expect(list, isEmpty);
    });

    test('includes member after setMember', () async {
      final m1 = _makeMember(userId: 'user-1');
      final m2 = _makeMember(userId: 'user-2');
      await repo.setMember(m1);
      await repo.setMember(m2);

      final list = await repo.watchMembers('circle-1').first;
      expect(list.map((m) => m.userId), containsAll(['user-1', 'user-2']));
    });

    test('excludes member after deleteMember', () async {
      final member = _makeMember(userId: 'user-to-remove');
      await repo.setMember(member);

      await repo.deleteMember(member.circleId, member.userId);

      final list = await repo.watchMembers('circle-1').first;
      expect(list.any((m) => m.userId == 'user-to-remove'), isFalse);
    });
  });

  group('deleteMember', () {
    test('deleting non-existent member does not throw', () async {
      expect(
        () => repo.deleteMember('circle-x', 'ghost-user'),
        returnsNormally,
      );
    });
  });
}
