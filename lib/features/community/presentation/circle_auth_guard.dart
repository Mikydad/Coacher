import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/sign_up_screen.dart';

enum _CircleAuthChoice { login, signUp }

/// Gates account-only circle actions (creating or joining a circle).
///
/// Browsing circles and opening circle details stay open to anonymous users;
/// only identity-bound actions call this. Returns `true` when the current user
/// is registered (signed in and **not** anonymous) and the action may proceed.
///
/// For anonymous or signed-out users it shows a "Log in or sign up" prompt
/// explaining that an account is required, routes to the chosen auth screen,
/// and returns `false` so the caller aborts the action.
Future<bool> ensureRegisteredForCircleAction(
  BuildContext context,
  WidgetRef ref, {
  required String actionLabel,
}) async {
  if (ref.read(isRegisteredProvider)) return true;

  final choice = await showDialog<_CircleAuthChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        'Account required',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        'You need an account to $actionLabel. '
        'Browsing circles stays free — log in or sign up to take part.',
        style: TextStyle(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Not now', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _CircleAuthChoice.login),
          child: Text('Log in', style: TextStyle(color: AppColors.accent)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _CircleAuthChoice.signUp),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text('Sign up'),
        ),
      ],
    ),
  );

  if (!context.mounted || choice == null) return false;

  switch (choice) {
    case _CircleAuthChoice.login:
      await Navigator.pushNamed(context, LoginScreen.routeName);
    case _CircleAuthChoice.signUp:
      await Navigator.pushNamed(context, SignUpScreen.routeName);
  }
  return false;
}
