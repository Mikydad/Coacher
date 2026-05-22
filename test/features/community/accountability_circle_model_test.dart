import 'package:coach_for_life/features/community/domain/models/accountability_circle.dart';
import 'package:coach_for_life/features/community/domain/models/circle_enums.dart';
import 'package:flutter_test/flutter_test.dart';

AccountabilityCircle _makeCircle({
  String name = 'Morning Runners',
  int memberCount = 3,
}) {
  final now = DateTime(2026, 5, 19).millisecondsSinceEpoch;
  return AccountabilityCircle(
    id: 'circle-1',
    name: name,
    description: 'We run every morning.',
    category: 'fitness',
    joinPolicy: JoinPolicy.open,
    visibility: CircleVisibility.public,
    creatorId: 'user-1',
    moderatorIds: ['user-1'],
    memberCount: memberCount,
    currentStreak: 5,
    longestStreak: 12,
    timezone: 'Africa/Nairobi',
    createdAtMs: now,
    updatedAtMs: now,
  );
}

void main() {
  group('AccountabilityCircle toMap / fromMap', () {
    test('round-trip preserves all fields', () {
      final circle = _makeCircle();
      final restored = AccountabilityCircle.fromMap(circle.toMap());

      expect(restored.id, circle.id);
      expect(restored.name, circle.name);
      expect(restored.description, circle.description);
      expect(restored.category, circle.category);
      expect(restored.joinPolicy, circle.joinPolicy);
      expect(restored.visibility, circle.visibility);
      expect(restored.creatorId, circle.creatorId);
      expect(restored.moderatorIds, circle.moderatorIds);
      expect(restored.memberCount, circle.memberCount);
      expect(restored.currentStreak, circle.currentStreak);
      expect(restored.longestStreak, circle.longestStreak);
      expect(restored.timezone, circle.timezone);
      expect(restored.createdAtMs, circle.createdAtMs);
      expect(restored.updatedAtMs, circle.updatedAtMs);
    });

    test('null description round-trips correctly', () {
      final circle = _makeCircle().copyWith(description: null);
      final restored = AccountabilityCircle.fromMap(circle.toMap());
      expect(restored.description, isNull);
    });

    test('joinPolicy requestApproval round-trips', () {
      final circle = _makeCircle().copyWith(joinPolicy: JoinPolicy.requestApproval);
      final restored = AccountabilityCircle.fromMap(circle.toMap());
      expect(restored.joinPolicy, JoinPolicy.requestApproval);
    });

    test('visibility private round-trips', () {
      final circle = _makeCircle().copyWith(visibility: CircleVisibility.private);
      final restored = AccountabilityCircle.fromMap(circle.toMap());
      expect(restored.visibility, CircleVisibility.private);
    });

    test('fromMap with unknown joinPolicy defaults to open', () {
      final map = _makeCircle().toMap()..['joinPolicy'] = 'unknown_value';
      expect(AccountabilityCircle.fromMap(map).joinPolicy, JoinPolicy.open);
    });
  });

  group('AccountabilityCircle.validate()', () {
    test('valid circle does not throw', () {
      expect(() => _makeCircle().validate(), returnsNormally);
    });

    test('name shorter than 3 chars throws', () {
      expect(
        () => _makeCircle(name: 'AB').validate(),
        throwsArgumentError,
      );
    });

    test('name longer than 40 chars throws', () {
      expect(
        () => _makeCircle(name: 'A' * 41).validate(),
        throwsArgumentError,
      );
    });

    test('memberCount > 8 throws', () {
      expect(
        () => _makeCircle(memberCount: 9).validate(),
        throwsArgumentError,
      );
    });

    test('memberCount 0 is valid (empty circle before members join)', () {
      expect(() => _makeCircle(memberCount: 0).validate(), returnsNormally);
    });

    test('memberCount 8 is valid (at capacity)', () {
      expect(() => _makeCircle(memberCount: 8).validate(), returnsNormally);
    });
  });

  group('AccountabilityCircle constants', () {
    test('kMaxMembers is 8', () {
      expect(AccountabilityCircle.kMaxMembers, 8);
    });

    test('kMinMembers is 4', () {
      expect(AccountabilityCircle.kMinMembers, 4);
    });
  });
}
