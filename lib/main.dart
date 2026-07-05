import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_lifecycle_task_refresh.dart';
import 'app/application/main_tab_navigation.dart';
import 'app/first_launch_gate.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    appRootProviderContainer = container;
    // Minimal pre-frame phase: Firebase (required before Crashlytics) and
    // the local Isar store. Everything network-bound runs after first frame.
    await AppBootstrap.initializePreFrame(container);

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const AuthGate(
          child: FirstLaunchGate(
            child: AppLifecycleTaskRefresh(
              child: CoachForLifeApp(),
            ),
          ),
        ),
      ),
    );

    // Notification wiring, sync, reminders, and per-user maintenance — after
    // the first frame so a slow connection can't hold the splash hostage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AppBootstrap.completeDeferred(container));
    });
  }, (error, stack) {
    // Uncaught async errors (e.g. unawaited futures). Crashlytics may not be
    // available if bootstrap itself failed before Firebase init.
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      debugPrint('Uncaught zone error (Crashlytics unavailable): $error');
    }
  });
}
