import 'package:flutter/material.dart';

/// Small centred error label shown below forms on auth screens.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFFF5252),
        fontSize: 13,
        height: 1.4,
      ),
    );
  }
}
