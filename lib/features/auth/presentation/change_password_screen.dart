import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../domain/auth_failure.dart';
import 'widgets/auth_error_text.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  static const routeName = '/auth/change-password';

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPw = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (newPw.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }

    final email = ref.read(authRepositoryProvider).currentUser?.email;
    if (email == null) {
      setState(() => _error = 'Could not identify your account email.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);

    // Step 1 — re-authenticate to prove identity before the sensitive change.
    final reAuthFailure =
        await repo.reauthenticate(email: email, password: current);

    if (!mounted) return;
    if (reAuthFailure != null) {
      setState(() {
        _error = reAuthFailure is InvalidCredentials
            ? 'Current password is incorrect.'
            : reAuthFailure.toUserMessage();
        _loading = false;
      });
      return;
    }

    // Step 2 — update the password.
    final updateFailure = await repo.updatePassword(newPw);

    if (!mounted) return;
    if (updateFailure != null) {
      setState(() {
        _error = updateFailure.toUserMessage();
        _loading = false;
      });
      return;
    }

    // Success — notify and go back.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050806),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Change Password',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Current password',
                controller: _currentCtrl,
                obscure: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_newFocus),
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'New password (min 8 characters)',
                controller: _newCtrl,
                focusNode: _newFocus,
                obscure: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmFocus),
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Confirm new password',
                controller: _confirmCtrl,
                focusNode: _confirmFocus,
                obscure: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !_loading,
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Update password',
                onPressed: _loading ? null : _submit,
                isLoading: _loading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                AuthErrorText(_error!),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
