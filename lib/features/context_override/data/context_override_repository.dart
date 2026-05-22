import 'package:isar/isar.dart';

import '../../../core/local_db/isar_collections/isar_user_attention_state.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/user_attention_state.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class ContextOverrideRepository {
  Future<UserAttentionState?> getAttentionState();

  Future<void> upsertAttentionState(UserAttentionState state);

  /// Reactive stream — emits the current state whenever it changes in Isar.
  Stream<UserAttentionState?> watchAttentionState();
}

// ─── Isar implementation ──────────────────────────────────────────────────────

class IsarContextOverrideRepository implements ContextOverrideRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<UserAttentionState?> getAttentionState() async {
    final row = await _isar.isarUserAttentionStates
        .filter()
        .stateIdEqualTo(kUserAttentionStateId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsertAttentionState(UserAttentionState state) async {
    state.validate();
    await _isar.writeTxn(() async {
      await _isar.isarUserAttentionStates.putByStateId(
        IsarUserAttentionState.fromDomain(state),
      );
    });
  }

  @override
  Stream<UserAttentionState?> watchAttentionState() {
    return _isar.isarUserAttentionStates
        .filter()
        .stateIdEqualTo(kUserAttentionStateId)
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => getAttentionState());
  }
}
