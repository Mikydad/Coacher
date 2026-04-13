/// Last-write-wins helper for remote → Isar merges on [updatedAtMs].
///
/// Skips applying the remote row when local is missing **or** local is newer or
/// same age (`remote > local` required to overwrite).
bool shouldApplyRemoteUpdatedAt({
  required int? localUpdatedAtMs,
  required int remoteUpdatedAtMs,
}) {
  if (localUpdatedAtMs == null) return true;
  return remoteUpdatedAtMs > localUpdatedAtMs;
}
