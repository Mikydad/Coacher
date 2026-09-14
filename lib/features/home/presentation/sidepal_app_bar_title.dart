import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/application/main_tab_navigation.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../app/presentation/main_tab_shell.dart';

/// Tappable app bar brand: always returns the user to the Home tab.
class SidePalAppBarTitle extends StatelessWidget {
  const SidePalAppBarTitle({super.key});

  static void goHome(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    container.read(mainTabIndexProvider.notifier).state = MainTabIndex.home;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(MainTabShell.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    return Semantics(
      button: true,
      label: 'Go to home',
      child: InkWell(
        onTap: () => goHome(context),
        borderRadius: BorderRadius.circular(8),
        // Wordmark (redesign 2026-09-14): 30px bold, no greeting under it.
        child: Text(
          'SidePal',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.1,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
