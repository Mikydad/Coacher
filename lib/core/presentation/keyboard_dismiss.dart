import 'package:flutter/material.dart';

/// Hides the soft keyboard if a text field currently has focus.
void dismissKeyboard(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
}

/// Dismisses the keyboard when the user taps outside focused inputs.
class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => dismissKeyboard(context),
      child: child,
    );
  }
}
