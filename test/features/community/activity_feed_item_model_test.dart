import 'package:sidepal/features/community/domain/models/activity_feed_item.dart';
import 'package:sidepal/features/community/domain/models/circle_enums.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityFeedItem _makeItem({
  ActivityEventType eventType = ActivityEventType.goalCompleted,
}) {
  return ActivityFeedItem(
    id: 'feed-1',
    circleId: 'circle-1',
    userId: 'user-1',
    displayName: 'Alice',
    eventType: eventType,
    entityId: 'goal-42',
    entityTitle: 'Morning Run',
    value: '5',
    dateKey: '2026-05-19',
    createdAtMs: 1_000_000,
  );
}

void main() {
  group('ActivityFeedItem toMap / fromMap', () {
    test('round-trip preserves all fields', () {
      final item = _makeItem();
      final restored = ActivityFeedItem.fromMap(item.toMap());

      expect(restored.id, item.id);
      expect(restored.circleId, item.circleId);
      expect(restored.userId, item.userId);
      expect(restored.displayName, item.displayName);
      expect(restored.eventType, item.eventType);
      expect(restored.entityId, item.entityId);
      expect(restored.entityTitle, item.entityTitle);
      expect(restored.value, item.value);
      expect(restored.dateKey, item.dateKey);
      expect(restored.createdAtMs, item.createdAtMs);
    });

    test('null optional fields round-trip as null', () {
      final item = ActivityFeedItem(
        id: 'feed-2',
        circleId: 'circle-1',
        userId: 'user-1',
        displayName: 'Bob',
        eventType: ActivityEventType.memberJoined,
        dateKey: '2026-05-19',
        createdAtMs: 1_000_000,
      );
      final restored = ActivityFeedItem.fromMap(item.toMap());
      expect(restored.entityId, isNull);
      expect(restored.entityTitle, isNull);
      expect(restored.value, isNull);
    });
  });

  group('ActivityEventType storageValue / fromStorage', () {
    for (final type in ActivityEventType.values) {
      test('${type.name} round-trips', () {
        expect(
          ActivityEventTypeStorage.fromStorage(type.storageValue),
          type,
        );
      });
    }

    test('unknown value defaults to goalCompleted', () {
      expect(
        ActivityEventTypeStorage.fromStorage('unknownEvent'),
        ActivityEventType.goalCompleted,
      );
    });
  });
}
