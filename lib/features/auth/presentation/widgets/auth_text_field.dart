import 'package:flutter/material.dart';

/// Styled text field for auth screens.
///
/// Dark `#1A1A1A` fill, `#B2ED00` focused border, 12 px radius.
/// Shows [errorText] in red below the field when non-null.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      focusNode: focusNode,
      enabled: enabled,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(Colors.transparent),
        enabledBorder: _border(const Color(0xFF2E2E2E)),
        focusedBorder: _border(const Color(0xFFB2ED00)),
        errorBorder: _border(const Color(0xFFFF5252)),
        focusedErrorBorder: _border(const Color(0xFFFF5252)),
        disabledBorder: _border(const Color(0xFF1E1E1E)),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
