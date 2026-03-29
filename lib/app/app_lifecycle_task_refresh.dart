import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/local_notifications_service.dart';
import '../core/utils/date_keys.dart';
import '../features/planning/application/planned_task_providers.dart';
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
      if (!mounted) return;
      final container = ProviderScope.containerOf(context);
      unawaited(
        LocalNotificationsService.instance.drainLaunchNotificationResponse(
          (response) => handleNotificationResponse(response, container),
        ),
      );
    });
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
      invalidateTaskListProviders(ref);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      invalidateTaskListProviders(ref);
      _lastTodayKey = DateKeys.todayKey();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
