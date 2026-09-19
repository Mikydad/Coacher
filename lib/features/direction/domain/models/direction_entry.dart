import '../direction_periods.dart';

/// Max characters per horizon (decision 4): a statement, not an essay.
const int kDirectionMaxChars = 280;

/// Deterministic id — the single most important correctness decision in the
/// feature: two devices offline in the same month both writing "this month"
/// must converge on ONE document. Same id → same Isar row (unique index) →
/// same Firestore doc → plain LWW on `updatedAtMs`. Random ids would mint
/// duplicate Septembers no merge could reconcile.
String directionEntryId(DirectionHorizon horizon, String periodKey) =>
    'dir_${horizon.name}_$periodKey';

/// How a period's direction turned out, in the user's own judgement
/// (2026-09-19). Asked once, at the end of the period — never scored.
enum DirectionOutcome {
  achieved('achieved', 'Achieved'),
  partly('partly', 'Partly'),
  notYet('not_yet', 'Not yet');

  const DirectionOutcome(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static DirectionOutcome? fromStorage(String? raw) {
    for (final o in values) {
      if (o.storageValue == raw) return o;
    }
    return null;
  }
}

/// What the user says matters for one calendar period of one horizon.
///
/// Direction is not something SidePal asks the user to accomplish. It is
/// something SidePal remembers while helping them. So: no status, no
/// progress, no deadline, no completion — text and a period, nothing else.
///
/// Fully synced entity: Isar is the source of truth, replication happens via
/// the outbox, LWW on [updatedAtMs]. History is kept — one row per horizon
/// per period, never overwritten by the next period. **Clearing is not
/// deleting**: a cleared field writes `text: ''` with a fresh stamp (no
/// tombstone, no delete path), so the row stays as history and a clear beats
/// a stale edit from another device.
class DirectionEntry {
  const DirectionEntry({
    required this.id,
    required this.horizon,
    required this.periodKey,
    required this.text,
    required this.periodStartMs,
    required this.periodEndMs,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.outcome,
    this.outcomeAtMs,
  });

  /// Build the entry for [period] with [text] (trimmed here). [createdAtMs]
  /// is carried from an existing row by the repository; a brand-new row
  /// uses [nowMs].
  factory DirectionEntry.forPeriod(
    DirectionPeriod period, {
    required String text,
    required int nowMs,
    int? createdAtMs,
  }) {
    return DirectionEntry(
      id: directionEntryId(period.horizon, period.key),
      horizon: period.horizon,
      periodKey: period.key,
      text: text.trim(),
      periodStartMs: period.startMs,
      periodEndMs: period.endMs,
      createdAtMs: createdAtMs ?? nowMs,
      updatedAtMs: nowMs,
    );
  }

  /// `dir_<horizon>_<periodKey>` — see [directionEntryId].
  final String id;
  final DirectionHorizon horizon;

  /// `'2026'` | `'2026-Q3'` | `'2026-09'`.
  final String periodKey;

  /// The user's own words. `''` means cleared (row kept for history/LWW).
  final String text;

  final int periodStartMs;
  final int periodEndMs;
  final int createdAtMs;

  /// LWW key — bumped on EVERY write.
  final int updatedAtMs;

  /// The close-out answer (2026-09-19), null until the user gives one.
  final DirectionOutcome? outcome;
  final int? outcomeAtMs;

  /// The period has ended, the user wrote something, and never said how it
  /// went — the page asks, and the end-of-period notice points here.
  bool needsCloseoutAt(DateTime now) =>
      isNotEmpty &&
      outcome == null &&
      now.millisecondsSinceEpoch >= periodEndMs;

  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// The period this entry belongs to (re-derived from the key so the
  /// stored bounds can't drift from the calendar).
  DirectionPeriod? get period => DirectionPeriods.parseKey(periodKey);

  /// Throws [ArgumentError] — the only validation gate (same contract as
  /// every other synced model).
  void validate() {
    final parsed = DirectionPeriods.parseKey(periodKey);
    if (parsed == null) {
      throw ArgumentError('periodKey is malformed: $periodKey');
    }
    if (parsed.horizon != horizon) {
      throw ArgumentError(
        'periodKey $periodKey does not belong to horizon ${horizon.name}',
      );
    }
    if (id != directionEntryId(horizon, periodKey)) {
      throw ArgumentError('id must be deterministic for (horizon, periodKey)');
    }
    if (text.trim().length > kDirectionMaxChars) {
      throw ArgumentError('text must be at most $kDirectionMaxChars chars');
    }
    if (periodStartMs >= periodEndMs) {
      throw ArgumentError('periodStartMs must be before periodEndMs');
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'horizon': horizon.name,
    'periodKey': periodKey,
    'text': text,
    'periodStartMs': periodStartMs,
    'periodEndMs': periodEndMs,
    'createdAtMs': createdAtMs,
    'updatedAtMs': updatedAtMs,
    if (outcome != null) 'outcome': outcome!.storageValue,
    if (outcomeAtMs != null) 'outcomeAtMs': outcomeAtMs,
    'schemaVersion': 1,
  };

  factory DirectionEntry.fromMap(Map<String, dynamic> map) {
    final periodKey = (map['periodKey'] as String?)?.trim() ?? '';
    final horizon =
        directionHorizonFromStorage(map['horizon'] as String?) ??
        DirectionPeriods.parseKey(periodKey)?.horizon ??
        DirectionHorizon.month;
    final parsed = DirectionPeriods.parseKey(periodKey);
    return DirectionEntry(
      id: (map['id'] as String?)?.trim().isNotEmpty == true
          ? (map['id'] as String).trim()
          : directionEntryId(horizon, periodKey),
      horizon: horizon,
      periodKey: periodKey,
      text: (map['text'] as String?) ?? '',
      periodStartMs:
          (map['periodStartMs'] as num?)?.toInt() ?? parsed?.startMs ?? 0,
      periodEndMs: (map['periodEndMs'] as num?)?.toInt() ?? parsed?.endMs ?? 0,
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
      outcome: DirectionOutcome.fromStorage(map['outcome'] as String?),
      outcomeAtMs: (map['outcomeAtMs'] as num?)?.toInt(),
    );
  }

  DirectionEntry copyWith({
    String? text,
    int? updatedAtMs,
    DirectionOutcome? outcome,
    int? outcomeAtMs,
  }) {
    return DirectionEntry(
      id: id,
      horizon: horizon,
      periodKey: periodKey,
      text: text ?? this.text,
      periodStartMs: periodStartMs,
      periodEndMs: periodEndMs,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      outcome: outcome ?? this.outcome,
      outcomeAtMs: outcomeAtMs ?? this.outcomeAtMs,
    );
  }
}
