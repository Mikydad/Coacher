import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/community/application/circle_functions.dart';
import 'package:sidepal/features/community/application/user_circle_membership_service.dart';
import 'package:sidepal/features/community/data/circle_member_repository.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:sidepal/features/community/domain/models/circle_member.dart';

/// Records calls and replays a scripted server answer — the membership
/// service is a thin client of the callables (audit C1/M2), so what matters
/// is that every mutation goes through them and that server `reason`s map
/// to the typed exceptions the screens catch.
class _FakeCircleFunctions implements CircleFunctions {
  final calls = <String>[];
  CircleActionException? fail;

  Future<T> _answer<T>(String call, T value) async {
    calls.add(call);
    final f = fail;
    if (f != null) throw f;
    return value;
  }

  @override
  Future<String> create(Map<String, dynamic> circle) =>
      _answer('create:${circle['id']}', circle['id'] as String);

  @override
  Future<CircleJoinResult> join(String circleId) => _answer(
    'join:$circleId',
    CircleJoinResult(circleId: circleId, status: 'active', alreadyMember: false),
  );

  @override
  Future<void> approveJoin(String circleId, String userId) =>
      _answer('approve:$circleId:$userId', null);

  @override
  Future<void> declineJoin(String circleId, String userId) =>
      _answer('decline:$circleId:$userId', null);

  @override
  Future<void> leave(String circleId) => _answer('leave:$circleId', null);

  @override
  Future<void> removeMember(String circleId, String userId) =>
      _answer('remove:$circleId:$userId', null);

  @override
  Future<void> delete(String circleId) => _answer('delete:$circleId', null);

  @override
  Future<bool> repairIndex(String circleId) =>
      _answer('repair:$circleId', true);
}

class _FakeMemberRepo implements CircleMemberRepository {
  final members = <String, CircleMember>{};

  @override
  Future<CircleMember?> getMember(String circleId, String userId) async =>
      members['$circleId/$userId'];

  @override
  Stream<List<CircleMember>> watchMembers(String circleId) =>
      Stream.value(const []);

  @override
  Future<void> setMember(CircleMember member) async =>
      throw StateError('client must never write member docs');

  @override
  Future<void> deleteMember(String circleId, String userId) async =>
      throw StateError('client must never delete member docs');
}

/// Subclass so the Firestore-backed count is scripted without a Firestore.
class _Service extends UserCircleMembershipService {
  _Service({
    required super.memberRepo,
    required super.functions,
    required this.count,
    super.maxCirclesPerUser,
  }) : super(currentUserId: () => 'me');

  int count;

  @override
  Future<int> myCircleCount() async => count;
}

void main() {
  late _FakeCircleFunctions fn;
  late _FakeMemberRepo repo;

  setUp(() {
    fn = _FakeCircleFunctions();
    repo = _FakeMemberRepo();
  });

  _Service service({int count = 0, int max = 3}) => _Service(
    memberRepo: repo,
    functions: fn,
    count: count,
    maxCirclesPerUser: () => max,
  );

  group('every mutation is a callable', () {
    test('join, approve, decline, leave, remove, delete, repair', () async {
      final s = service();
      await s.joinCircle('c1');
      await s.requestJoin('c2');
      await s.approveJoin('c1', 'u2');
      await s.declineJoin('c1', 'u3');
      await s.leaveCircle('c1');
      await s.removeMember('c1', 'u2');
      await s.deleteCircle('c1');
      await s.ensureCircleIndex('c1');
      expect(fn.calls, [
        'join:c1',
        'join:c2',
        'approve:c1:u2',
        'decline:c1:u3',
        'leave:c1',
        'remove:c1:u2',
        'delete:c1',
        'repair:c1',
      ]);
    });
  });

  group('instant client-side limit pre-check', () {
    test('blocks a join at the cap without a round-trip', () async {
      final s = service(count: 3);
      await expectLater(s.joinCircle('c9'), throwsA(isA<CircleLimitException>()));
      expect(fn.calls, isEmpty);
    });

    test('-1 means unlimited', () async {
      final s = service(count: 30, max: -1);
      await s.joinCircle('c9');
      expect(fn.calls, ['join:c9']);
    });

    test('an existing active member re-opens without hitting the cap', () async {
      repo.members['c1/me'] = CircleMember(
        userId: 'me',
        circleId: 'c1',
        displayName: 'Me',
        role: CircleMemberRole.member,
        status: CircleMemberStatus.active,
        joinedAtMs: 1,
        updatedAtMs: 1,
      );
      final s = service(count: 3);
      await s.joinCircle('c1');
      expect(fn.calls, ['join:c1']);
    });
  });

  group('server reasons map to typed exceptions', () {
    Future<void> expectReason(String reason, Matcher matcher) async {
      fn.fail = CircleActionException('x', 'msg', reason: reason);
      final s = service();
      await expectLater(s.joinCircle('c1'), throwsA(matcher));
    }

    test('circle_full → CircleFullException', () =>
        expectReason('circle_full', isA<CircleFullException>()));
    test('circle_limit → CircleLimitException', () =>
        expectReason('circle_limit', isA<CircleLimitException>()));
    test('invite_only → CirclePrivateException', () =>
        expectReason('invite_only', isA<CirclePrivateException>()));
    test('not_moderator → NotModeratorException', () =>
        expectReason('not_moderator', isA<NotModeratorException>()));
    test('unknown reasons surface as the raw exception', () =>
        expectReason('something_else', isA<CircleActionException>()));
  });
}
