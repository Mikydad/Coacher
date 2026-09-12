import 'dart:convert';

import 'activity_event.dart';

/// The fixed category set (V1.2 decision 6). Stored as strings; `other` is
/// a real answer, not a fallback for "unknown".
abstract final class ActivityCategories {
  static const String work = 'work';
  static const String learning = 'learning';
  static const String exercise = 'exercise';
  static const String entertainment = 'entertainment';
  static const String rest = 'rest';
  static const String chores = 'chores';
  static const String social = 'social';
  static const String other = 'other';

  static const List<String> all = [
    work,
    learning,
    exercise,
    entertainment,
    rest,
    chores,
    social,
    other,
  ];

  static bool isValid(String? raw) => raw != null && all.contains(raw);

  static String label(String category) => switch (category) {
    work => 'Work',
    learning => 'Learning',
    exercise => 'Exercise',
    entertainment => 'Entertainment',
    rest => 'Rest',
    chores => 'Chores',
    social => 'Social',
    _ => 'Other',
  };
}

enum CategoryRuleSource { ai, user }

CategoryRuleSource categoryRuleSourceFromStorage(String? raw) {
  for (final v in CategoryRuleSource.values) {
    if (v.name == raw) return v;
  }
  return CategoryRuleSource.ai;
}

/// Deterministic id from the normalised text so two devices converge on
/// one rule per activity under plain LWW.
String activityCategoryRuleId(String normalizedText) =>
    'cat_${base64Url.encode(utf8.encode(normalizedText)).replaceAll('=', '')}';

/// "Every 'gym' is Exercise." One rule per normalised activity text,
/// classified by the daily reflection pass (`ai`) or set by the user on the
/// edit sheet (`user`). Never deleted, only overwritten; the reflection
/// pass never proposes a text that already has a `user` rule, so an
/// override is never undone by AI. Synced, local-first, LWW on
/// [updatedAtMs].
class ActivityCategoryRule {
  const ActivityCategoryRule({
    required this.id,
    required this.normalizedText,
    required this.category,
    required this.source,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  factory ActivityCategoryRule.forText(
    String text, {
    required String category,
    required CategoryRuleSource source,
    required int nowMs,
    int? createdAtMs,
  }) {
    final key = normalizeActivityText(text);
    return ActivityCategoryRule(
      id: activityCategoryRuleId(key),
      normalizedText: key,
      category: category,
      source: source,
      createdAtMs: createdAtMs ?? nowMs,
      updatedAtMs: nowMs,
    );
  }

  final String id;
  final String normalizedText;
  final String category;
  final CategoryRuleSource source;
  final int createdAtMs;
  final int updatedAtMs;

  bool get isUserSet => source == CategoryRuleSource.user;

  void validate() {
    if (normalizedText.isEmpty) {
      throw ArgumentError('normalizedText must not be empty');
    }
    if (normalizedText != normalizeActivityText(normalizedText)) {
      throw ArgumentError('normalizedText must be normalised');
    }
    if (!ActivityCategories.isValid(category)) {
      throw ArgumentError('unknown category: $category');
    }
    if (id != activityCategoryRuleId(normalizedText)) {
      throw ArgumentError('id must be deterministic for the text');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'normalizedText': normalizedText,
    'category': category,
    'source': source.name,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': 1,
  };

  factory ActivityCategoryRule.fromMap(Map<String, dynamic> map) {
    final text = normalizeActivityText((map['normalizedText'] as String?) ?? '');
    return ActivityCategoryRule(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? (map['id'] as String).trim()
          : activityCategoryRuleId(text),
      normalizedText: text,
      category: ActivityCategories.isValid(map['category'] as String?)
          ? map['category'] as String
          : ActivityCategories.other,
      source: categoryRuleSourceFromStorage(map['source'] as String?),
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  ActivityCategoryRule copyWith({
    String? category,
    CategoryRuleSource? source,
    int? updatedAtMs,
  }) => ActivityCategoryRule(
    id: id,
    normalizedText: normalizedText,
    category: category ?? this.category,
    source: source ?? this.source,
    createdAtMs: createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
}
