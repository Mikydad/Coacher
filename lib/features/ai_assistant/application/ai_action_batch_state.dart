/// Lifecycle states for an [AiActionBatch] persisted in Isar.
enum AiActionBatchState {
  /// Batch record created but execution not yet started.
  pending,

  /// Execution is in progress.
  executing,

  /// All actions completed successfully.
  completed,

  /// One or more actions failed; rollback may have been triggered.
  partialFailure,

  /// Batch was rolled back — all succeeded steps have been reverted.
  rolledBack,
}
