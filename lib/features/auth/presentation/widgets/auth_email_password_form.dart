import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/application/profile_providers.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_failure.dart';
import '../forgot_password_screen.dart';
import 'auth_error_text.dart';
import 'auth_primary_button.dart';
import 'auth_text_field.dart';

import '../../../../core/presentation/app_colors.dart';

/// Email + password sign-in fields shared by [LoginScreen] and landing.
class AuthEmailPasswordForm extends ConsumerStatefulWidget {
  const AuthEmailPasswordForm({
    super.key,
    this.prefillEmail,
    this.enabled = true,
    this.onForgotPassword,
  });

  final String? prefillEmail;
  final bool enabled;
  final VoidCallback? onForgotPassword;

  @override
  ConsumerState<AuthEmailPasswordForm> createState() =>
      _AuthEmailPasswordFormState();
}

class _AuthEmailPasswordFormState extends ConsumerState<AuthEmailPasswordForm> {
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final (failure, _) = await ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password);

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _error = failure.toUserMessage();
        _loading = false;
      });
      return;
    }

    final name = ref
        .read(authRepositoryProvider)
        .currentUser
        ?.displayName
        ?.trim();
    if (name != null && name.isNotEmpty) {
      await ref
          .read(profilePreferenceServiceProvider)
          .syncDisplayNameFromAuthIfEmpty(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.enabled && !_loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          label: 'Email address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_passwordFocus),
          autofillHints: const [AutofillHints.email],
          enabled: canSubmit,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Password',
          controller: _passwordCtrl,
          obscure: true,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canSubmit) _submit();
          },
          autofillHints: const [AutofillHints.password],
          enabled: canSubmit,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: canSubmit
                ? () {
                    if (widget.onForgotPassword != null) {
                      widget.onForgotPassword!();
                    } else {
                      Navigator.pushNamed(
                        context,
                        ForgotPasswordScreen.routeName,
                        arguments: _emailCtrl.text.trim(),
                      );
                    }
                  }
                : null,
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AuthPrimaryButton(
          label: 'Sign in with email',
          onPressed: canSubmit ? _submit : null,
          isLoading: _loading,
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          AuthErrorText(_error!),
        ],
      ],
    );
  }
}
