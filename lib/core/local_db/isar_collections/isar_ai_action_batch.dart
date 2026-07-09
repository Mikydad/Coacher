import 'package:isar_community/isar.dart';

part 'isar_ai_action_batch.g.dart';

/// Isar-persisted record of a group of AI-confirmed actions.
///
/// Enables:
///   - Atomicity / rollback: if any action in the batch fails, all
///     completed steps can be reverted from [snapshotJson].
///   - Idempotency: a batch whose [batchId] is already `completed` is
///     rejected on retry, preventing duplicate mutations.
///   - Undo: the most recent completed batch can be rolled back within
///     a 30-minute staleness window.
///   - History: the last N batches are queryable for the "Recent AI changes"
///     UI entry point.
@collection
class IsarAiActionBatch {
  Id id = Isar.autoIncrement;

  /// UUID generated before execution begins — used as the idempotency key.
  @Index(unique: true)
  late String batchId;

  /// Batch lifecycle state stored as the enum name (e.g. `'pending'`).
  @Index()
  late String state;

  /// Full JSON serialisation of the `List<AiAction>` sent to the executor.
  late String actionsJson;

  /// JSON snapshot of affected entities *before* mutations.
  /// Used as the rollback payload. Covers [PlannedTask], [ScheduledTimeBlock],
  /// [ReminderConfig], and [ContextOverride] state.
  late String snapshotJson;

  /// Action IDs (from [AiAction.id]) that completed successfully.
  late List<String> succeededActionIds;

  /// Action IDs that failed during execution.
  late List<String> failedActionIds;

  /// Epoch ms when the batch was rolled back, if applicable.
  int? undoneAtMs;

  /// Epoch ms when this batch record was created.
  @Index()
  late int createdAtMs;

  /// LWW timestamp.
  late int updatedAtMs;
}
