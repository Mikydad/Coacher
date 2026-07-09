import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_lifecycle_task_refresh.dart';
import 'app/application/main_tab_navigation.dart';
import 'app/first_launch_gate.dart';
import 'app/presentation/animated_splash.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/presentation/theme_brightness_controller.dart';
import 'features/auth/presentation/auth_gate.dart';

/// Boot breadcrumb that survives release builds (debugPrint is silenced
/// there). A hang between two breadcrumbs localizes itself in device logs.
void _bootLog(String message) {
  // ignore: avoid_print
  print(message);
}

Future<void> main() async {
  // debugPrint is NOT stripped in release builds — 150+ call sites log task
  // titles/uids. Silence it outside debug/profile (AUDIT §7 S7).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _bootLog('[boot] binding ready');
      final container = ProviderContainer();
      appRootProviderContainer = container;
      // Minimal pre-frame phase: Firebase (required before Crashlytics) and
      // the local Isar store. Everything network-bound runs after first frame.
      await AppBootstrap.initializePreFrame(container);
      _bootLog('[boot] pre-frame init done');
      // Resolve persisted dark/light BEFORE the first frame (prefs is local
      // disk, not network) so the app never flashes the wrong mode.
      await loadPersistedBrightness();
      _bootLog('[boot] brightness loaded');

      // Crash reporting is valuable but must NEVER block the first frame —
      // this call proved capable of hanging on-device in release, which
      // left the app on a white screen forever. Bounded + non-fatal.
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode)
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        _bootLog('[boot] crashlytics enable skipped: $e');
      }
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _bootLog('[boot] runApp');
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const AnimatedSplashGate(
            child: AuthGate(
              child: FirstLaunchGate(
                child: AppLifecycleTaskRefresh(child: CoachForLifeApp()),
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
    },
    (error, stack) {
      // ALWAYS surface locally too — routing only to Crashlytics made boot
      // failures look like silent hangs (white screen, no logs).
      _bootLog('[boot] UNCAUGHT: $error');
      _bootLog('$stack');
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    },
  );
}
