import 'package:coach_for_life/features/community/data/circle_repository.dart';
import 'package:coach_for_life/features/community/domain/models/accountability_circle.dart';
import 'package:coach_for_life/features/community/domain/models/circle_enums.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

AccountabilityCircle _makeCircle({
  String id = 'circle-1',
  String name = 'Morning Runners',
  String category = 'fitness',
  CircleVisibility visibility = CircleVisibility.public,
}) {
  final now = DateTime(2026, 5, 19).millisecondsSinceEpoch;
  return AccountabilityCircle(
    id: id,
    name: name,
    category: category,
    joinPolicy: JoinPolicy.open,
    visibility: visibility,
    creatorId: 'user-1',
    moderatorIds: ['user-1'],
    memberCount: 1,
    timezone: 'Africa/Nairobi',
    createdAtMs: now,
    updatedAtMs: now,
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreCircleRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestoreCircleRepository(firestore: fakeFirestore);
  });

  group('createCircle / getCircle', () {
    test('getCircle returns null when circle does not exist', () async {
      final result = await repo.getCircle('no-such-id');
      expect(result, isNull);
    });

    test('createCircle then getCircle returns the same circle', () async {
      final circle = _makeCircle();
      await repo.createCircle(circle);
      final fetched = await repo.getCircle(circle.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, circle.id);
      expect(fetched.name, circle.name);
      expect(fetched.category, circle.category);
      expect(fetched.joinPolicy, circle.joinPolicy);
      expect(fetched.visibility, circle.visibility);
    });
  });

  group('updateCircle', () {
    test('updateCircle overwrites name field', () async {
      final circle = _makeCircle();
      await repo.createCircle(circle);

      final updated = circle.copyWith(name: 'Evening Runners');
      await repo.updateCircle(updated);

      final fetched = await repo.getCircle(circle.id);
      expect(fetched!.name, 'Evening Runners');
    });
  });

  group('watchCircle', () {
    test('emits null for non-existent circle', () async {
      expect(
        await repo.watchCircle('ghost-id').first,
        isNull,
      );
    });

    test('emits updated circle after updateCircle', () async {
      final circle = _makeCircle();
      await repo.createCircle(circle);

      final stream = repo.watchCircle(circle.id);
      final first = await stream.first;
      expect(first!.name, 'Morning Runners');

      // Subscribe before updating so the emission can't be missed.
      final sawUpdate = expectLater(
        repo.watchCircle(circle.id),
        emitsThrough(
          predicate<AccountabilityCircle?>((c) => c?.name == 'Night Owls'),
        ),
      );
      await repo.updateCircle(circle.copyWith(name: 'Night Owls'));
      await sawUpdate;
    });
  });

  group('watchCircles', () {
    test('emits empty list when circleIds is empty', () async {
      final list = await repo.watchCircles([]).first;
      expect(list, isEmpty);
    });

    test('emits list after creation', () async {
      final c1 = _makeCircle(id: 'c-1', name: 'Alpha Circle');
      final c2 = _makeCircle(id: 'c-2', name: 'Beta Circle');
      await repo.createCircle(c1);
      await repo.createCircle(c2);

      final list = await repo.watchCircles(['c-1', 'c-2']).first;
      expect(list.map((c) => c.id), containsAll(['c-1', 'c-2']));
    });
  });

  group('searchCircles', () {
    setUp(() async {
      await repo.createCircle(_makeCircle(id: 'fit-1', name: 'Morning Run', category: 'fitness'));
      await repo.createCircle(_makeCircle(id: 'fit-2', name: 'Yoga Flow', category: 'fitness'));
      await repo.createCircle(_makeCircle(id: 'biz-1', name: 'Launch Club', category: 'business'));
      await repo.createCircle(_makeCircle(
        id: 'priv-1',
        name: 'Private Gym',
        category: 'fitness',
        visibility: CircleVisibility.private,
      ));
    });

    test('returns only public circles when no filter', () async {
      final results = await repo.searchCircles();
      expect(results.every((c) => c.visibility == CircleVisibility.public), isTrue);
    });

    test('filters by category', () async {
      final results = await repo.searchCircles(category: 'fitness');
      expect(results.every((c) => c.category == 'fitness'), isTrue);
      expect(results.length, 2); // private one is excluded
    });

    test('filters by query substring (case-insensitive)', () async {
      final results = await repo.searchCircles(query: 'run');
      expect(results.any((c) => c.name == 'Morning Run'), isTrue);
    });

    test('returns empty list when category has no public circles', () async {
      final results = await repo.searchCircles(category: 'cooking');
      expect(results, isEmpty);
    });
  });
}
