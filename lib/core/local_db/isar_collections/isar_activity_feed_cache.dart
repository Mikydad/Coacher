import 'package:isar_community/isar.dart';

part 'isar_activity_feed_cache.g.dart';

/// Local cache for the last N activity feed items per circle.
///
/// The `payload` field stores the JSON blob of `ActivityFeedItem.toMap()`
/// so the full model can be reconstructed without a network call.
@collection
class IsarActivityFeedCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId; // ActivityFeedItem.id

  @Index()
  late String circleId;

  late String payload; // JSON: ActivityFeedItem.toMap()

  @Index()
  late int createdAtMs;
}
