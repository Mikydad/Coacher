import 'package:isar/isar.dart';

part 'isar_notification_ledger_entry.g.dart';

/// Isar-persisted record of every OS notification lifecycle event.
///
/// Replaces the three in-memory maps in [AttentionOrchestratorService]:
///   - `_activeNotificationIds`
///   - `_ignoredCountByEntity`
///   - `_snoozeTimestampsMs`
///
/// Enables boot-time reconciliation, deduplication, and future per-device sync.
@collection
class IsarNotificationLedgerEntry {
  Id id = Isar.autoIncrement;

  /// OS notification ID — unique per active notification slot.
  @Index(unique: true)
  late int notifId;

  /// The task / goal / reminder entity being tracked.
  @Index()
  late String entityId;

  /// Entity kind: `'task'`, `'goal'`, `'reminder'`.
  late String entityKind;

  /// Lifecycle state stored as the enum name (e.g. `'scheduled'`).
  @Index()
  late String state;

  /// Epoch ms when the notification was scheduled to fire.
  @Index()
  int? scheduledForMs;

  /// Epoch ms when the OS confirmed delivery (via callback).
  int? deliveredAtMs;

  /// Epoch ms when the notification was cancelled.
  int? cancelledAtMs;

  /// If snoozed, the epoch ms at which re-delivery should happen.
  int? snoozedUntilMs;

  /// Total number of times this entity's notification has been snoozed.
  int snoozeCount = 0;

  /// Consecutive ignores since the last positive interaction (open/snooze/dismiss).
  int ignoredCount = 0;

  /// Last user interaction: `'opened'`, `'dismissed'`, `'snoozed'`.
  String? interactionType;

  /// Epoch ms of the last user interaction.
  int? interactedAtMs;

  /// Which service scheduled this: `'attention_orchestrator'`, `'goal_reminder_sync'`, etc.
  late String sourceContext;

  /// LWW timestamp for future cross-device sync.
  @Index()
  late int updatedAtMs;
}
