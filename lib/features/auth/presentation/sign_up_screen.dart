import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';
import 'login_screen.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_google_sign_in_button.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  static const routeName = '/auth/sign-up';

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  bool _tosAccepted = false;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool _validateClient() {
    bool ok = true;
    String? pwErr;
    String? cfErr;

    if (_passwordCtrl.text.length < 8) {
      pwErr = 'Password must be at least 8 characters.';
      ok = false;
    }
    if (_confirmCtrl.text != _passwordCtrl.text) {
      cfErr = 'Passwords do not match.';
      ok = false;
    }
    setState(() {
      _passwordError = pwErr;
      _confirmError = cfErr;
    });
    return ok;
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_validateClient()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty) {
      setState(() => _formError = 'Please enter your email address.');
      return;
    }

    setState(() => _loading = true);

    final currentUser = ref.read(authRepositoryProvider).currentUser;
    final repo = ref.read(authRepositoryProvider);
    final isLinkingAnonymous = currentUser?.isAnonymous == true;

    // When the current session is anonymous, we LINK rather than create a new
    // account. Firebase preserves the uid — Firestore data at users/{uid} is
    // preserved without any migration needed.
    final (failure, user) = isLinkingAnonymous
        ? await repo.linkAnonymousWithEmail(email: email, password: password)
        : await repo.createUserWithEmail(
            email: email,
            password: password,
            displayName: name.isEmpty ? null : name,
          );

    if (!mounted) return;

    if (failure != null) {
      setState(() => _loading = false);
      // EmailAlreadyInUse can come from both linkAnonymousWithEmail
      // (credential-already-in-use) and createUserWithEmail — handle both.
      if (failure is EmailAlreadyInUse) {
        await _showAlreadyExistsDialog(email);
        return;
      }
      setState(() => _formError = failure.toUserMessage());
      return;
    }

    if (isLinkingAnonymous) {
      // uid is unchanged after linking — existing Firestore data is intact.
      debugPrint('[Auth] anonymous linked: uid=${user?.uid}');
    } else {
      debugPrint('[Auth] sign-up success: uid=${user?.uid}');
    }
  }

  Future<void> _showAlreadyExistsDialog(String email) async {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Account already exists',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'An account with this email already exists. '
          'Sign in to it instead? '
          'Your offline guest data won\'t be merged automatically.',
          style: TextStyle(color: Color(0xFF888888), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign in instead',
                style: TextStyle(
                    color: Color(0xFFB2ED00), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (goToLogin == true && mounted) {
      Navigator.pushReplacementNamed(
        context,
        LoginScreen.routeName,
        arguments: email,
      );
    }
  }

  bool get _canSubmit => _tosAccepted && !_loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050806),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Create Account',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Name (optional)
              AuthTextField(
                label: 'Display name (optional)',
                controller: _nameCtrl,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                autofillHints: const [AutofillHints.name],
                enabled: !_loading,
              ),
              const SizedBox(height: 16),

              // Email
              AuthTextField(
                label: 'Email address',
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                autofillHints: const [AutofillHints.newUsername],
                enabled: !_loading,
              ),
              const SizedBox(height: 16),

              // Password
              AuthTextField(
                label: 'Password (min 8 characters)',
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscure: true,
                errorText: _passwordError,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmFocus),
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_loading,
              ),
              const SizedBox(height: 16),

              // Confirm password
              AuthTextField(
                label: 'Confirm password',
                controller: _confirmCtrl,
                focusNode: _confirmFocus,
                obscure: true,
                errorText: _confirmError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _canSubmit ? _submit() : null,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_loading,
              ),
              const SizedBox(height: 20),

              // ToS checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _tosAccepted,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _tosAccepted = v ?? false),
                    activeColor: const Color(0xFFB2ED00),
                    checkColor: Colors.black,
                    side: const BorderSide(color: Color(0xFF444444), width: 1.5),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: Color(0xFFB2ED00),
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Phase E: link to real ToS URL
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              AuthPrimaryButton(
                label: 'Create account',
                onPressed: _canSubmit ? _submit : null,
                isLoading: _loading,
              ),

              if (_formError != null) ...[
                const SizedBox(height: 14),
                AuthErrorText(_formError!),
              ],

              const AuthOrDivider(),
              AuthGoogleSignInButton(enabled: !_loading),

              const SizedBox(height: 28),
              _buildSignInRow(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
        GestureDetector(
          onTap: _loading
              ? null
              : () => Navigator.pushReplacementNamed(
                    context,
                    LoginScreen.routeName,
                  ),
          child: const Text(
            'Sign in',
            style: TextStyle(
              color: Color(0xFFB2ED00),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
