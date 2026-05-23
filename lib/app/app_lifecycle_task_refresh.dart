import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/local_notifications_service.dart';
import '../core/sync/post_sync_refresh_coordinator.dart';
import '../core/sync/sync_service.dart';
import '../core/utils/date_keys.dart';
import '../features/context_override/application/context_override_expiry_poller.dart';
import '../features/reminders/application/attention_orchestrator_providers.dart';
import 'notification_response_handler.dart';

/// Invalidates task-list providers when the app resumes and when the local calendar day changes
/// while the app is foregrounded (avoids stale `FutureProvider` data after midnight).
class AppLifecycleTaskRefresh extends ConsumerStatefulWidget {
  const AppLifecycleTaskRefresh({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleTaskRefresh> createState() => _AppLifecycleTaskRefreshState();
}

class _AppLifecycleTaskRefreshState extends ConsumerState<AppLifecycleTaskRefresh>
    with WidgetsBindingObserver {
  Timer? _dayCheckTimer;
  String? _lastTodayKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastTodayKey = DateKeys.todayKey();
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => _invalidateIfDayChanged());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_drainLaunchNotificationResponse());
    });
  }

  Future<void> _drainLaunchNotificationResponse() async {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context);
    await LocalNotificationsService.instance.drainLaunchNotificationResponse(
      (response) => handleNotificationResponse(response, container),
    );
    flushPendingNotificationNavigationIntent();
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _invalidateIfDayChanged() {
    if (!mounted) return;
    final nowKey = DateKeys.todayKey();
    if (nowKey != _lastTodayKey) {
      _lastTodayKey = nowKey;
      PostSyncRefreshCoordinator.instance.schedule(
        tasks: true,
        coachingDelivery: true,
        todayAnalytics: true,
      );
    }
  }

  Future<void> _refreshAfterResume() async {
    var pulled = false;
    try {
      pulled = await SyncService.instance.syncFromRemote();
    } catch (_) {
      pulled = false;
    }
    if (!mounted) return;
    if (!pulled) {
      // Debounced skip or failed pull: refresh non-stream futures only.
      PostSyncRefreshCoordinator.instance.schedule(tasks: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastTodayKey = DateKeys.todayKey();
      unawaited(_refreshAfterResume());
      unawaited(_drainLaunchNotificationResponse());
      // Check whether any active context override has expired.
      unawaited(ref.read(contextOverrideExpiryPollerProvider).checkNow());
      // Check for notifications that were delivered but never interacted with.
      unawaited(
        ref.read(attentionOrchestratorServiceProvider).checkIgnoredTimeouts(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flushPendingNotificationNavigationIntent();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
