import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../auth/presentation/widgets/auth_apple_sign_in_button.dart';
import '../../../auth/presentation/widgets/auth_error_text.dart';
import '../../../auth/presentation/widgets/auth_google_sign_in_button.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Registration step (after Welcome — decision log 2026-07-12). Rehosts the
/// existing auth widgets in the onboarding language. Hard gate: the tour
/// continues only with an account; the bottom Skip is the no-account escape
/// (→ anonymous, exits the whole flow).
///
/// Success is handled by the flow shell's auth listener (email AND social
/// paths land there), which advances past this step.
class RegisterStep extends ConsumerStatefulWidget {
  const RegisterStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  ConsumerState<RegisterStep> createState() => _RegisterStepState();
}

class _RegisterStepState extends ConsumerState<RegisterStep> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and a password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final (failure, _) = await ref
        .read(authRepositoryProvider)
        .createUserWithEmail(
          email: email,
          password: password,
          displayName: name.isEmpty ? null : name,
        );

    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _error = failure.toUserMessage();
        _loading = false;
      });
      return;
    }
    // Shell's auth listener advances the flow; just stop the spinner state.
    setState(() => _loading = false);
  }

  void _logInInstead() {
    ref
        .read(onboardingFlowControllerProvider.notifier)
        .setAuthIntent(OnboardingAuthIntent.login);
    Navigator.of(context)
        .pushNamed(LoginScreen.routeName, arguments: _emailCtrl.text.trim())
        .then((_) {
      ref
          .read(onboardingFlowControllerProvider.notifier)
          .setAuthIntent(OnboardingAuthIntent.register);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);

    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: widget.onSkip,
      ctaLabel: 'Create my account',
      onCta: _loading ? null : _submit,
      ctaLoading: _loading,
      belowCta: Center(
        child: TextButton(
          onPressed: _loading ? null : _logInInstead,
          child: Text(
            'Already have an account? Log in',
            style: TextStyle(
              color: OnboardingColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      content: SingleChildScrollView(
        // Keyboard raises the viewport bottom — the form itself is short,
        // scrolling only kicks in while typing on small phones.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Save your journey.', style: OnboardingType.headline),
            const SizedBox(height: 10),
            Text(
              'Your plan, goals, and progress stay with you on any device.',
              style: OnboardingType.body,
            ),
            const SizedBox(height: 22),
            AuthTextField(
              label: 'Name (optional)',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_emailFocus),
              autofillHints: const [AutofillHints.name],
              enabled: !_loading,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: 'Email address',
              controller: _emailCtrl,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              autofillHints: const [AutofillHints.email],
              enabled: !_loading,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: 'Password',
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_loading) _submit();
              },
              autofillHints: const [AutofillHints.newPassword],
              enabled: !_loading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              AuthErrorText(_error!),
            ],
            const SizedBox(height: 20),
            const AuthOrDivider(),
            const SizedBox(height: 20),
            AuthSocialSignInSection(enabled: !_loading),
          ],
        ),
      ),
    );
  }
}
