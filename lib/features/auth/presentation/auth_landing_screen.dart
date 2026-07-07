import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/auth_providers.dart';
import '../application/auth_session_policy.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import 'widgets/auth_apple_sign_in_button.dart';
import 'widgets/auth_email_password_form.dart';
import 'widgets/auth_google_sign_in_button.dart';

import '../../../core/presentation/app_colors.dart';

const String _kMigrationBannerDismissedKey = 'auth_migration_banner_dismissed';

/// Landing screen shown when no user is signed in and [kRequireRegisteredAuth]
/// is `true`, or as the entry point after an explicit sign-out.
class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  static const routeName = '/auth';

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen> {
  bool _guestLoading = false;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerState();
  }

  Future<void> _loadBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _bannerDismissed =
            prefs.getBool(_kMigrationBannerDismissedKey) ?? false;
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMigrationBannerDismissedKey, true);
    if (mounted) setState(() => _bannerDismissed = true);
  }

  Future<void> _continueAsGuest() async {
    if (_guestLoading) return;
    setState(() => _guestLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
      // AuthGate reacts to authStateChanges — no manual navigation.
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous =
        ref.watch(authStateProvider).valueOrNull?.isAnonymous ?? false;
    final showBanner = isAnonymous && !_bannerDismissed;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Migration banner (anonymous users only) ───────────────
            if (showBanner) _MigrationBanner(onDismiss: _dismissBanner),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _AppLogo(),
                    const SizedBox(height: 16),
                    const Text(
                      'Coach for Life',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your personal productivity coach.\nBuild habits that last.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Email / password ──────────────────────────────────────
                    AuthEmailPasswordForm(
                      enabled: !_guestLoading,
                      onForgotPassword: () => Navigator.pushNamed(
                        context,
                        ForgotPasswordScreen.routeName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OutlinedAuthButton(
                      label: 'Create account with email',
                      onPressed: _guestLoading
                          ? null
                          : () => Navigator.pushNamed(
                              context,
                              SignUpScreen.routeName,
                            ),
                    ),
                    const AuthOrDivider(label: 'or continue with'),
                    AuthSocialSignInSection(enabled: !_guestLoading),

                    if (!kRequireRegisteredAuth) ...[
                      const SizedBox(height: 16),
                      _guestLoading
                          ? const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.textGray,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: _continueAsGuest,
                              child: const Text(
                                'Continue as guest',
                                style: TextStyle(
                                  color: AppColors.textFaint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dark1E1E1E, width: 1.5),
      ),
      child: const Center(
        child: Text(
          'CL',
          style: TextStyle(
            color: AppColors.accentDim,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// Banner shown at the top of [AuthLandingScreen] when the current session is
/// anonymous, prompting the user to register to preserve progress.
class _MigrationBanner extends StatelessWidget {
  const _MigrationBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.limeInkDim,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentDim, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create an account to save your progress across devices.',
                  style: TextStyle(
                    color: AppColors.limeSoft,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, SignUpScreen.routeName),
                  child: const Text(
                    'Create account →',
                    style: TextStyle(
                      color: AppColors.accentDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close, color: AppColors.gray55, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedAuthButton extends StatelessWidget {
  const _OutlinedAuthButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.inkSoft, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
