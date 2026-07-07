import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_providers.dart';
import '../../domain/auth_failure.dart';
import 'auth_error_text.dart';
import 'auth_google_sign_in_button.dart';

import '../../../../core/presentation/app_colors.dart';

/// Whether Sign in with Apple should be offered on this platform.
bool get isAppleSignInSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// "Continue with Apple" for auth screens (iOS / macOS only).
class AuthAppleSignInButton extends ConsumerStatefulWidget {
  const AuthAppleSignInButton({super.key, this.enabled = true});

  final bool enabled;

  @override
  ConsumerState<AuthAppleSignInButton> createState() =>
      _AuthAppleSignInButtonState();
}

class _AuthAppleSignInButtonState extends ConsumerState<AuthAppleSignInButton> {
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
        .signInWithApple();

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
  }

  @override
  Widget build(BuildContext context) {
    if (!isAppleSignInSupported) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _loading || !widget.enabled ? null : _signIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white,
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
                      Icon(Icons.apple, color: Colors.black, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Continue with Apple',
                        style: TextStyle(
                          color: Colors.black,
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

/// Google + Apple sign-in buttons with spacing (Apple hidden off iOS/macOS).
class AuthSocialSignInSection extends StatelessWidget {
  const AuthSocialSignInSection({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthGoogleSignInButton(enabled: enabled),
        if (isAppleSignInSupported) ...[
          const SizedBox(height: 12),
          AuthAppleSignInButton(enabled: enabled),
        ],
      ],
    );
  }
}
