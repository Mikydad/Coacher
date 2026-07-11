import 'dart:async';

import '../data/form_draft_repository.dart';

/// Debounced draft persistence (10s after last change) plus flush on lifecycle/dispose.
class FormDraftAutosave {
  FormDraftAutosave({
    required FormDraftRepository repository,
    required String key,
    required Map<String, dynamic> Function() capture,
    bool Function()? isMeaningful,
    this.debounce = const Duration(seconds: 10),
  }) : _repository = repository,
       _key = key,
       _capture = capture,
       _isMeaningful = isMeaningful;

  final FormDraftRepository _repository;
  final String _key;
  final Map<String, dynamic> Function() _capture;

  /// Returns whether the current form holds content worth restoring. When it
  /// returns false, [persistIfDirty] clears any stale draft instead of saving,
  /// so a form the user only poked at never triggers a restore prompt later.
  final bool Function()? _isMeaningful;
  final Duration debounce;

  Timer? _timer;
  bool dirty = false;

  void markDirty() {
    dirty = true;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      unawaited(persistIfDirty());
    });
  }

  Future<void> persistIfDirty() async {
    if (!dirty) return;
    _timer?.cancel();
    dirty = false;
    if (_isMeaningful != null && !_isMeaningful()) {
      // Nothing worth restoring — drop any earlier draft rather than persist
      // an empty/config-only form that would prompt "Restore draft?" on reopen.
      await _repository.delete(_key);
      return;
    }
    await _repository.save(_key, _capture());
  }

  void cancel() {
    _timer?.cancel();
    dirty = false;
  }

  void dispose() {
    _timer?.cancel();
  }
}
