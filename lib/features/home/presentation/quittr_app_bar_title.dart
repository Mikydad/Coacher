import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Tappable app bar brand: always returns the user to [HomeScreen].
class QuittrAppBarTitle extends StatelessWidget {
  const QuittrAppBarTitle({super.key});

  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      HomeScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go to home',
      child: InkWell(
        onTap: () => goHome(context),
        child: const Text('Quittr'),
      ),
    );
  }
}
