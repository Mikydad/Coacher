import '../../../../core/validation/model_validators.dart';
import 'context_override.dart';

const int kUserAttentionStateSchemaVersion = 1;

/// Fixed ID — there is always exactly one record per device.
const String kUserAttentionStateId = 'user_attention_state';

/// The single source of truth for what override is active and when it expires.
///
/// Persisted to Isar as a single-record collection.
/// Queried via [ContextOverrideRepository].
class UserAttentionState {
  const UserAttentionState({
    required this.id,
    required this.activeOverride,
    required this.manuallyMuted,
    required this.updatedAtMs,
    this.overrideExpiresAt,
    this.lastOverrideActivatedAt,
    this.lastAttentionResetAt,
    this.sleepWindowStart,
    this.sleepWindowEnd,
    this.schemaVersion = kUserAttentionStateSchemaVersion,
  });

  /// Always `kUserAttentionStateId`. Single-record pattern.
  final String id;

  /// Currently active override type. `none` when no override is in effect.
  final ContextOverride activeOverride;

  /// When the active override auto-expires. `null` = indefinite (manual end only).
  final DateTime? overrideExpiresAt;

  /// True when the user explicitly muted all non-critical notifications
  /// outside of an override context.
  final bool manuallyMuted;

  /// Epoch ms when the current override was activated. Null when no override.
  final int? lastOverrideActivatedAt;

  /// Epoch ms when the last override ended (by expiry or manual end).
  final int? lastAttentionResetAt;

  /// Daily sleep window start time in `"HH:mm"` local 24h format. E.g. `"23:00"`.
  final String? sleepWindowStart;

  /// Daily sleep window end time in `"HH:mm"` local 24h format. E.g. `"07:00"`.
  final String? sleepWindowEnd;

  final int updatedAtMs;
  final int schemaVersion;

  // ─── Convenience getters ──────────────────────────────────────────────────

  bool get hasActiveOverride => activeOverride != ContextOverride.none;

  bool get isVacationActive => activeOverride == ContextOverride.vacation;

  /// True if `overrideExpiresAt` is set and has already passed [now].
  bool isExpired(DateTime now) {
    final exp = overrideExpiresAt;
    if (exp == null) return false;
    return now.isAfter(exp);
  }

  bool get hasSleepWindow =>
      sleepWindowStart != null &&
      sleepWindowStart!.isNotEmpty &&
      sleepWindowEnd != null &&
      sleepWindowEnd!.isNotEmpty;

  /// Factory that creates the default "clean slate" state for a new device.
  factory UserAttentionState.empty() => UserAttentionState(
    id: kUserAttentionStateId,
    activeOverride: ContextOverride.none,
    manuallyMuted: false,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
  );

  void validate() {
    ModelValidators.requireNotBlank(id, 'userAttentionState.id');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'activeOverride': activeOverride.name,
    'overrideExpiresAtMs': overrideExpiresAt?.millisecondsSinceEpoch,
    'manuallyMuted': manuallyMuted,
    'lastOverrideActivatedAt': lastOverrideActivatedAt,
    'lastAttentionResetAt': lastAttentionResetAt,
    'sleepWindowStart': sleepWindowStart,
    'sleepWindowEnd': sleepWindowEnd,
    'updatedAtMs': updatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static UserAttentionState fromMap(Map<String, dynamic> map) {
    final expiresMs = (map['overrideExpiresAtMs'] as num?)?.toInt();
    return UserAttentionState(
      id: map['id'] as String? ?? kUserAttentionStateId,
      activeOverride: contextOverrideFromStorage(
        map['activeOverride'] as String?,
      ),
      overrideExpiresAt: expiresMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expiresMs)
          : null,
      manuallyMuted: map['manuallyMuted'] as bool? ?? false,
      lastOverrideActivatedAt: (map['lastOverrideActivatedAt'] as num?)
          ?.toInt(),
      lastAttentionResetAt: (map['lastAttentionResetAt'] as num?)?.toInt(),
      sleepWindowStart: map['sleepWindowStart'] as String?,
      sleepWindowEnd: map['sleepWindowEnd'] as String?,
      updatedAtMs: (map['updatedAtMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kUserAttentionStateSchemaVersion,
    );
  }

  UserAttentionState copyWith({
    ContextOverride? activeOverride,
    Object? overrideExpiresAt = _sentinel,
    bool? manuallyMuted,
    Object? lastOverrideActivatedAt = _sentinel,
    Object? lastAttentionResetAt = _sentinel,
    Object? sleepWindowStart = _sentinel,
    Object? sleepWindowEnd = _sentinel,
    int? updatedAtMs,
  }) {
    return UserAttentionState(
      id: id,
      activeOverride: activeOverride ?? this.activeOverride,
      overrideExpiresAt: overrideExpiresAt == _sentinel
          ? this.overrideExpiresAt
          : overrideExpiresAt as DateTime?,
      manuallyMuted: manuallyMuted ?? this.manuallyMuted,
      lastOverrideActivatedAt: lastOverrideActivatedAt == _sentinel
          ? this.lastOverrideActivatedAt
          : lastOverrideActivatedAt as int?,
      lastAttentionResetAt: lastAttentionResetAt == _sentinel
          ? this.lastAttentionResetAt
          : lastAttentionResetAt as int?,
      sleepWindowStart: sleepWindowStart == _sentinel
          ? this.sleepWindowStart
          : sleepWindowStart as String?,
      sleepWindowEnd: sleepWindowEnd == _sentinel
          ? this.sleepWindowEnd
          : sleepWindowEnd as String?,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      schemaVersion: schemaVersion,
    );
  }
}

// Sentinel object used by copyWith to distinguish "not provided" from null.
const Object _sentinel = Object();
