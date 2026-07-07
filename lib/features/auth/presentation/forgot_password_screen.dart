import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';

import '../../../core/presentation/app_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillEmail});

  static const routeName = '/auth/forgot-password';

  /// Pre-fill the email field (e.g. when navigating from LoginScreen).
  final String? prefillEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.fg,
        title: const Text(
          'Reset Password',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          "Enter the email address linked to your account.\nWe'll send you a reset link.",
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        AuthTextField(
          label: 'Email address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          autofillHints: const [AutofillHints.email],
          enabled: !_loading,
        ),
        const SizedBox(height: 20),
        AuthPrimaryButton(
          label: 'Send reset email',
          onPressed: _loading ? null : _submit,
          isLoading: _loading,
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          AuthErrorText(_error!),
        ],
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          color: AppColors.accentDim,
          size: 56,
        ),
        const SizedBox(height: 20),
        Text(
          'Check your email',
          style: TextStyle(
            color: AppColors.fg,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a password reset link to ${_emailCtrl.text.trim()}.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Back to sign in',
            style: TextStyle(color: AppColors.accentDim, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
