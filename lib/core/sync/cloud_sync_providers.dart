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

/// Whether the offline write queue is stuck with writes that failed to reach
/// Firestore and now need the user's attention.
///
/// This is the ONLY sync state that drives a passive, always-on visible
/// surface ([CloudSyncGlobalIndicator]). Routine background sync — connectivity
/// regained, app resume, the periodic remote pull, post-write queue flushes —
/// never flips it, so normal operation stays silent.
final cloudSyncHasIssueProvider =
    NotifierProvider<CloudSyncHasIssueNotifier, bool>(
      CloudSyncHasIssueNotifier.new,
    );

class CloudSyncHasIssueNotifier extends Notifier<bool> {
  @override
  bool build() {
    final notifier = SyncService.instance.hasSyncIssue;
    void onChanged() {
      state = notifier.value;
    }

    notifier.addListener(onChanged);
    ref.onDispose(() => notifier.removeListener(onChanged));
    return notifier.value;
  }
}
