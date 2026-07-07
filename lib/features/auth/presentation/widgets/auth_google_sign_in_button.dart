import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/application/profile_providers.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_failure.dart';
import 'auth_error_text.dart';

import '../../../../core/presentation/app_colors.dart';

/// "Continue with Google" for auth screens.
class AuthGoogleSignInButton extends ConsumerStatefulWidget {
  const AuthGoogleSignInButton({super.key, this.enabled = true});

  final bool enabled;

  @override
  ConsumerState<AuthGoogleSignInButton> createState() =>
      _AuthGoogleSignInButtonState();
}

class _AuthGoogleSignInButtonState
    extends ConsumerState<AuthGoogleSignInButton> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    if (_loading || !widget.enabled) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final (failure, _) = await ref
        .read(authRepositoryProvider)
        .signInWithGoogle();

    if (!mounted) return;

    if (failure is AuthSignInCanceled) {
      setState(() => _loading = false);
      return;
    }

    if (failure != null) {
      setState(() {
        _error = failure.toUserMessage();
        _loading = false;
      });
      return;
    }

    // Profile UI reads from Isar — seed name after Google profile is on Firebase.
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
    // AuthGate reacts to authStateChanges for navigation.
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _loading || !widget.enabled ? null : _signIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.inkSoft, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textGray,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.g_mobiledata_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          AuthErrorText(_error!),
        ],
      ],
    );
  }
}

/// Horizontal rule with centered label (e.g. "or").
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.gray2A)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textFaint, fontSize: 13),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.gray2A)),
        ],
      ),
    );
  }
}
