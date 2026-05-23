import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_lifecycle_task_refresh.dart';
import 'app/application/main_tab_navigation.dart';
import 'app/first_launch_gate.dart';
import 'core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  appRootProviderContainer = container;
  await AppBootstrap.initialize(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FirstLaunchGate(
        child: AppLifecycleTaskRefresh(
          child: CoachForLifeApp(),
        ),
      ),
    ),
  );
}
