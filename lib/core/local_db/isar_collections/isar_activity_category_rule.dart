import 'package:isar_community/isar.dart';

import '../../../features/time_tracker/domain/models/activity_category_rule.dart';

part 'isar_activity_category_rule.g.dart';

/// Synced "every 'gym' is Exercise" rule (Time Tracker V1.2). One row per
/// normalised activity text; deterministic [ruleId] so devices converge.
@collection
class IsarActivityCategoryRule {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String ruleId;

  @Index()
  late int updatedAtMs;

  @Index(unique: true)
  late String normalizedText;

  late String category;

  /// `ai` | `user`.
  late String sourceStorage;
  late int createdAtMs;

  static IsarActivityCategoryRule fromDomain(ActivityCategoryRule r) {
    return IsarActivityCategoryRule()
      ..ruleId = r.id
      ..updatedAtMs = r.updatedAtMs
      ..normalizedText = r.normalizedText
      ..category = r.category
      ..sourceStorage = r.source.name
      ..createdAtMs = r.createdAtMs;
  }

  ActivityCategoryRule toDomain() => ActivityCategoryRule(
    id: ruleId,
    normalizedText: normalizedText,
    category: category,
    source: categoryRuleSourceFromStorage(sourceStorage),
    createdAtMs: createdAtMs,
    updatedAtMs: updatedAtMs,
  );
}
