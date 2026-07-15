import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/local_db/isar_collections/isar_goal.dart';
import '../../../core/local_db/isar_collections/isar_reminder.dart';
import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../../core/offline/offline_store.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../features/auth/application/auth_session_policy.dart';
import '../../../features/auth/domain/auth_failure.dart';
import '../../../features/auth/presentation/change_password_screen.dart';
import '../../../features/auth/presentation/forgot_password_screen.dart';
import '../../../features/auth/presentation/widgets/auth_error_text.dart';
import '../../../features/auth/presentation/widgets/auth_text_field.dart';
import '../../../features/auth/presentation/widgets/connect_account_section.dart';
import 'settings_page_scaffold.dart';

import '../../../core/presentation/app_colors.dart';

/// Account-specific settings: password, data, and account deletion.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  static const routeName = '/settings/account';

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _exportLoading = false;
  bool _deleteLoading = false;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool get _hasEmailProvider {
    final user = ref.read(authStateProvider).valueOrNull;
    return user?.providerData.any((p) => p.providerId == 'password') ?? false;
  }

  // ── Change password ───────────────────────────────────────────────────────────

  void _goChangePassword() {
    Navigator.pushNamed(context, ChangePasswordScreen.routeName);
  }

  // ── Forgot password ───────────────────────────────────────────────────────────

  void _goForgotPassword() {
    final email = ref.read(authStateProvider).valueOrNull?.email;
    Navigator.pushNamed(
      context,
      ForgotPasswordScreen.routeName,
      arguments: email,
    );
  }

  // ── Export data ───────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    if (_exportLoading) return;
    setState(() => _exportLoading = true);
    try {
      final isar = OfflineStore.instance.isar;
      if (isar == null) {
        _showSnackbar('Could not access local data. Try again.');
        return;
      }

      final tasks = await isar.isarTasks.where().findAll();
      final goals = await isar.isarGoals.where().findAll();
      final reminders = await isar.isarReminders.where().findAll();

      final payload = {
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': tasks
            .map(
              (t) => {
                'id': t.taskId,
                'title': t.title,
                'status': t.statusName,
                'priority': t.priority,
                'durationMinutes': t.durationMinutes,
                'createdAtMs': t.createdAtMs,
                'updatedAtMs': t.updatedAtMs,
              },
            )
            .toList(),
        'goals': goals
            .map(
              (g) => {
                'id': g.goalId,
                'title': g.title,
                'category': g.categoryId,
                'status': g.statusStorage,
                'horizon': g.horizonStorage,
                'createdAtMs': g.createdAtMs,
                'updatedAtMs': g.updatedAtMs,
              },
            )
            .toList(),
        'reminders': reminders
            .map(
              (r) => {
                'id': r.reminderId,
                'taskId': r.taskId,
                'enabled': r.enabled,
                'createdAtMs': r.createdAtMs,
              },
            )
            .toList(),
      };

      final jsonBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(payload),
      );
      final date = DateTime.now().toIso8601String().substring(0, 10);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              jsonBytes,
              mimeType: 'application/json',
              name: 'coach_export_$date.json',
            ),
          ],
          subject: 'Coach for Life — data export $date',
        ),
      );
    } catch (e) {
      if (mounted) _showSnackbar('Export failed. Please try again.');
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  // ── Delete account ────────────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    // Step 1 — type DELETE to confirm.
    final confirmed = await _showDeleteConfirmDialog();
    if (confirmed != true || !mounted) return;

    // Step 2 — re-authenticate (email users only; skip for anonymous).
    if (_hasEmailProvider) {
      final reAuthOk = await _showReAuthDialog();
      if (!reAuthOk || !mounted) return;
    }

    setState(() => _deleteLoading = true);
    try {
      final failure = await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      if (failure != null) {
        _showSnackbar(failure.toUserMessage());
        setState(() => _deleteLoading = false);
        return;
      }
      // Wipe local data — AuthGate will show AuthLandingScreen automatically.
      await AuthSessionPolicy.clearLocalSession();
    } catch (e) {
      if (mounted) {
        setState(() => _deleteLoading = false);
        _showSnackbar('Delete failed. Please try again.');
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog() async {
    final controller = TextEditingController();
    bool canConfirm = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.inkCard,
          title: Text(
            'Delete account?',
            style: TextStyle(
              color: AppColors.coral,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently deletes your account and all associated data. This cannot be undone.',
                style: TextStyle(color: AppColors.textGray, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Type DELETE to confirm:',
                style: TextStyle(color: AppColors.fg, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: AppColors.fg),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.dark111111,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.gray33),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.gray33),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.coral),
                  ),
                  hintText: 'DELETE',
                  hintStyle: TextStyle(color: AppColors.textDim),
                ),
                onChanged: (v) =>
                    setDialogState(() => canConfirm = v == 'DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGray),
              ),
            ),
            TextButton(
              onPressed: canConfirm ? () => Navigator.pop(ctx, true) : null,
              child: Text(
                'Delete',
                style: TextStyle(
                  color: canConfirm ? AppColors.coral : AppColors.textDim,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showReAuthDialog() async {
    final emailCtrl = TextEditingController(
      text: ref.read(authStateProvider).valueOrNull?.email ?? '',
    );
    final pwCtrl = TextEditingController();
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.inkCard,
          title: Text(
            'Confirm your identity',
            style: TextStyle(color: AppColors.fg, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Re-enter your password to proceed.',
                style: TextStyle(color: AppColors.textGray, height: 1.5),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Email',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Password',
                controller: pwCtrl,
                obscure: true,
                textInputAction: TextInputAction.done,
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                AuthErrorText(error!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGray),
              ),
            ),
            TextButton(
              onPressed: () async {
                final failure = await ref
                    .read(authRepositoryProvider)
                    .reauthenticate(
                      email: emailCtrl.text.trim(),
                      password: pwCtrl.text,
                    );
                if (failure != null) {
                  setDialogState(() => error = failure.toUserMessage());
                } else {
                  if (ctx.mounted) Navigator.pop(ctx, true);
                }
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final hasEmailProvider =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    return SettingsPageScaffold(
      title: 'Account Settings',
      children: [
        // ── Connected identity (registered users; guests connect from the
        // Profile page's Account section) ────────────────────────────────
        if (user != null && !user.isAnonymous) ...[
          const SettingsSectionHeader(label: 'Connected Account'),
          const SizedBox(height: 10),
          ConnectedIdentityCard(user: user),
          const SizedBox(height: 32),
        ],
        const SettingsSectionHeader(label: 'Security'),
        const SizedBox(height: 10),
        SettingsObsidianCard(
          child: Column(
            children: [
              if (hasEmailProvider) ...[
                _ActionRow(
                  title: 'Change password',
                  subtitle: 'Update your sign-in password',
                  onTap: _goChangePassword,
                ),
                const _Divider(),
                _ActionRow(
                  title: 'Forgot password',
                  subtitle: 'Send a reset link to your email',
                  onTap: _goForgotPassword,
                ),
                const _Divider(),
              ],
              const SettingsPlaceholderRow(
                title: 'Two-factor authentication',
                subtitle: 'Add an extra layer of protection',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const SettingsSectionHeader(label: 'Privacy & Data'),
        const SizedBox(height: 10),
        SettingsObsidianCard(
          child: Column(
            children: [
              const SettingsPlaceholderRow(
                title: 'Privacy preferences',
                subtitle: 'Control what is stored and shared',
              ),
              const _Divider(),
              _ActionRow(
                title: 'Export my data',
                subtitle: 'Download a copy of your coaching data',
                onTap: _exportLoading ? null : _exportData,
                trailing: _exportLoading ? const _LoadingIndicator() : null,
              ),
              const _Divider(),
              _ActionRow(
                title: 'Delete account',
                subtitle: 'Permanently remove your account and data',
                onTap: _deleteLoading ? null : _deleteAccount,
                titleColor: AppColors.coral,
                trailing: _deleteLoading ? const _LoadingIndicator() : null,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Local sub-widgets ─────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.trailing,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? kSettingsOnSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: kSettingsOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: kSettingsOnSurfaceVariant,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Divider(height: 1, thickness: 1, color: AppColors.gray2A),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.textGray,
      ),
    );
  }
}
