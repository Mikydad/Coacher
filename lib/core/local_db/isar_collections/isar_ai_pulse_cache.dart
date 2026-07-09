import 'package:isar_community/isar.dart';

part 'isar_ai_pulse_cache.g.dart';

/// Local cache of the latest AI pulse per circle + type.
///
/// `payload` stores the JSON blob of [AiPulse.toMap()] for offline reads.
@collection
class IsarAiPulseCache {
  Id isarId = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('type')], unique: true)
  late String circleId;

  /// `'daily'` or `'weekly'`
  late String type;

  /// JSON of `AiPulse.toMap()`
  late String payload;

  @Index()
  late int generatedAtMs;
}
