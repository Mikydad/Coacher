import 'dart:async';

import '../data/form_draft_repository.dart';

/// Debounced draft persistence (10s after last change) plus flush on lifecycle/dispose.
class FormDraftAutosave {
  FormDraftAutosave({
    required FormDraftRepository repository,
    required String key,
    required Map<String, dynamic> Function() capture,
    this.debounce = const Duration(seconds: 10),
  }) : _repository = repository,
       _key = key,
       _capture = capture;

  final FormDraftRepository _repository;
  final String _key;
  final Map<String, dynamic> Function() _capture;
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
    await _repository.save(_key, _capture());
    dirty = false;
  }

  void cancel() {
    _timer?.cancel();
    dirty = false;
  }

  void dispose() {
    _timer?.cancel();
  }
}
