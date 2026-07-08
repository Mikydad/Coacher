import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/application/main_tab_navigation.dart';
import '../../../app/presentation/main_tab_shell.dart';

/// Tappable app bar brand: always returns the user to the Home tab.
class PathPalAppBarTitle extends StatelessWidget {
  const PathPalAppBarTitle({super.key});

  static void goHome(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    container.read(mainTabIndexProvider.notifier).state = MainTabIndex.home;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(MainTabShell.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go to home',
      child: InkWell(onTap: () => goHome(context), child: const Text('PathPal')),
    );
  }
}
