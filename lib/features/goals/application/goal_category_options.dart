import '../domain/models/goal_categories.dart';

/// The categories a goal can be filed under (Miko, 2026-09-24): the six
/// built-ins, then every custom category the user has ever typed, taken
/// from ALL their goals — paused and completed included, so a category
/// does not vanish when its last active goal finishes. There is no
/// category entity; a custom category exists as a string on goals.
///
/// Custom names are trimmed and deduplicated case-insensitively ("music"
/// and "Music" show once, first spelling wins), sorted A–Z after the
/// built-ins. [extra] is the editor's current pick, kept visible even when
/// no saved goal carries it yet.
List<String> goalCategoryOptions(
  Iterable<String> goalCategoryIds, {
  String? extra,
}) {
  final builtIn = GoalCategories.all;
  final seen = <String>{for (final b in builtIn) b.toLowerCase()};
  final custom = <String>[];
  void add(String? raw) {
    if (raw == null) return;
    final id = raw.trim();
    if (id.isEmpty) return;
    if (seen.add(id.toLowerCase())) custom.add(id);
  }

  goalCategoryIds.forEach(add);
  add(extra);
  custom.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return [...builtIn, ...custom];
}

bool isBuiltInGoalCategory(String id) => GoalCategories.all.contains(id);
