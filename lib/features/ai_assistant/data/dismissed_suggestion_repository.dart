import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_dismissed_suggestion_log.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/proactive_suggestion.dart';

/// Persists and queries [IsarDismissedSuggestionLog] entries.
class DismissedSuggestionRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  /// Records that the user dismissed a suggestion of [type].
  Future<void> logDismissal(ProactiveSuggestionType type) async {
    final entry = IsarDismissedSuggestionLog()
      ..suggestionType = type.name
      ..dismissedAtMs = DateTime.now().millisecondsSinceEpoch;
    await _isar.writeTxn(() => _isar.isarDismissedSuggestionLogs.put(entry));
  }

  /// Returns how many times [type] was dismissed within the last [withinDays] days.
  Future<int> countDismissals(
    ProactiveSuggestionType type, {
    int withinDays = 7,
  }) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: withinDays))
        .millisecondsSinceEpoch;
    return _isar.isarDismissedSuggestionLogs
        .filter()
        .suggestionTypeEqualTo(type.name)
        .dismissedAtMsGreaterThan(cutoff)
        .count();
  }

  /// Returns the set of suppressed [ProactiveSuggestionType]s — those dismissed
  /// 3+ times in the last 7 days.
  Future<Set<ProactiveSuggestionType>> suppressedTypes() async {
    final suppressed = <ProactiveSuggestionType>{};
    for (final type in ProactiveSuggestionType.values) {
      final count = await countDismissals(type);
      if (count >= 3) suppressed.add(type);
    }
    return suppressed;
  }

  /// Purges dismissal entries older than [olderThanDays] days.
  /// Called on app open (e.g. in [AppBootstrap]).
  Future<void> purgeOldEntries({int olderThanDays = 7}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .millisecondsSinceEpoch;
    await _isar.writeTxn(() async {
      final old = await _isar.isarDismissedSuggestionLogs
          .filter()
          .dismissedAtMsLessThan(cutoff)
          .findAll();
      for (final entry in old) {
        await _isar.isarDismissedSuggestionLogs.delete(entry.isarId);
      }
    });
  }
}
