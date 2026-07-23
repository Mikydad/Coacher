import 'package:isar_community/isar.dart';

part 'isar_memory_session_state.g.dart';

/// LOCAL-ONLY extraction bookkeeping for summarize-then-purge (PRD §5.2).
/// One row per Coach session that had at least one interaction. Never
/// synced — it describes work THIS device has or hasn't done yet.
///
/// Lifecycle: `pending` (session ended, extraction not yet run) →
/// `extracted` (extract_memory succeeded; raw turns may purge at 48h) or
/// `truncated` (extraction could not run within the 7-day deferral; a
/// deterministic truncation summary was written instead — memory
/// continuity is never silently lost).
@collection
class IsarMemorySessionState {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String sessionId;

  /// `pending` | `extracted` | `truncated`.
  @Index()
  late String status;

  /// Timestamp of the session's newest interaction — inactivity gating and
  /// the purge clock both read this.
  late int lastInteractionAtMs;

  /// How many extraction attempts have failed (offline, AI down, budget
  /// out). Informational; the deferral window is time-based, not count-based.
  late int attemptCount;

  late int updatedAtMs;
}
