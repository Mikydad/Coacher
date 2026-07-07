import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_service.dart';

/// Whether a Firestore → Isar pull is in progress.
///
/// Drives [CloudSyncGlobalIndicator] and can be watched in tests.
final cloudSyncInProgressProvider =
    NotifierProvider<CloudSyncInProgressNotifier, bool>(
      CloudSyncInProgressNotifier.new,
    );

class CloudSyncInProgressNotifier extends Notifier<bool> {
  @override
  bool build() {
    final notifier = SyncService.instance.isSyncingFromRemote;
    void onChanged() {
      state = notifier.value;
    }

    notifier.addListener(onChanged);
    ref.onDispose(() => notifier.removeListener(onChanged));
    return notifier.value;
  }
}
