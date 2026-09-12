import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_activity_category_rule.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/lww_updated_at.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/activity_category_rule.dart';
import '../domain/models/activity_event.dart';

/// Local-first category rules: Isar is the source of truth, replication via
/// the outbox (push) and RemoteIsarMerge (pull, LWW). Rules are overwritten,
/// never deleted.
class ActivityCategoryRuleRepository {
  ActivityCategoryRuleRepository({int Function()? now})
    : _now = now ?? _wallClock;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  final int Function() _now;

  Isar get _isar => OfflineStore.instance.isar!;

  Stream<List<ActivityCategoryRule>> watchAll() {
    return _isar.isarActivityCategoryRules
        .where()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList(growable: false));
  }

  Future<List<ActivityCategoryRule>> fetchAllOnce() async {
    final rows = await _isar.isarActivityCategoryRules.where().findAll();
    return rows.map((e) => e.toDomain()).toList(growable: false);
  }

  Future<ActivityCategoryRule?> getForText(String text) async {
    final row = await _isar.isarActivityCategoryRules
        .filter()
        .normalizedTextEqualTo(normalizeActivityText(text))
        .findFirst();
    return row?.toDomain();
  }

  /// Set (or overwrite) the rule for [text]. `ai` never overwrites a `user`
  /// rule; `user` always wins locally. Returns the stored rule.
  Future<ActivityCategoryRule?> setCategory(
    String text, {
    required String category,
    required CategoryRuleSource source,
  }) async {
    final existing = await getForText(text);
    if (existing != null) {
      if (existing.isUserSet && source == CategoryRuleSource.ai) return existing;
      if (existing.category == category && existing.source == source) {
        return existing;
      }
    }
    final rule = ActivityCategoryRule.forText(
      text,
      category: category,
      source: source,
      nowMs: _now(),
      createdAtMs: existing?.createdAtMs,
    );
    rule.validate();
    await _isar.writeTxn(() async {
      await _isar.isarActivityCategoryRules.putByRuleId(
        IsarActivityCategoryRule.fromDomain(rule),
      );
    });
    await outboxUpsert(
      entityType: 'activity_category_rule',
      documentPath: FirestorePaths.activityCategoryRuleDocument(rule.id),
      payload: rule.toMap(),
    );
    return rule;
  }
}

/// LWW merge of a remote rule into Isar (unit-testable without Firestore).
Future<bool> mergeActivityCategoryRuleLwwIntoIsar(
  Isar isar,
  ActivityCategoryRule incoming,
) async {
  final existing = await isar.isarActivityCategoryRules
      .filter()
      .ruleIdEqualTo(incoming.id)
      .findFirst();
  if (!shouldApplyRemoteUpdatedAt(
    localUpdatedAtMs: existing?.updatedAtMs,
    remoteUpdatedAtMs: incoming.updatedAtMs,
  )) {
    return false;
  }
  await isar.writeTxn(() async {
    await isar.isarActivityCategoryRules.putByRuleId(
      IsarActivityCategoryRule.fromDomain(incoming),
    );
  });
  return true;
}
