import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sign_up_screen.dart';
import 'widgets/auth_apple_sign_in_button.dart';
import 'widgets/auth_email_password_form.dart';
import 'widgets/auth_google_sign_in_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key, this.prefillEmail});

  static const routeName = '/auth/login';

  final String? prefillEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF050806),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Sign in',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              AuthEmailPasswordForm(prefillEmail: prefillEmail),
              const AuthOrDivider(),
              const AuthSocialSignInSection(enabled: true),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      SignUpScreen.routeName,
                    ),
                    child: const Text(
                      'Create one',
                      style: TextStyle(
                        color: Color(0xFFB2ED00),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
