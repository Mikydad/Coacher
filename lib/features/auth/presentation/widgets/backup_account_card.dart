import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../goals/application/goals_providers.dart';
import '../../../onboarding/application/onboarding_providers.dart';
import '../../application/auth_providers.dart';
import '../../application/backup_card_policy.dart';
import 'connect_account_section.dart';

/// Home's one-time guest prompt to connect an account ([BackupCardPolicy]).
/// Same shape as the first-time feature cards: quiet, dismissible, never a
/// gate. "Create account" runs the existing connect flow (same uid).
class BackupAccountCard extends ConsumerStatefulWidget {
  const BackupAccountCard({super.key});

  static const String dismissalsKey = 'backup_card_dismissals_v1';
  static const String dismissedAtKey = 'backup_card_dismissed_at_ms_v1';

  @override
  ConsumerState<BackupAccountCard> createState() => _BackupAccountCardState();
}

class _BackupAccountCardState extends ConsumerState<BackupAccountCard> {
  int? _dismissals; // null = prefs not read yet (render nothing, no flash)
  int? _dismissedAtMs;
  String? _loadedForUid;

  Future<void> _load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loadedForUid = uid;
      _dismissals = prefs.getInt('${BackupAccountCard.dismissalsKey}:$uid') ?? 0;
      _dismissedAtMs = prefs.getInt('${BackupAccountCard.dismissedAtKey}:$uid');
    });
  }

  Future<void> _dismiss(String uid) async {
    final next = (_dismissals ?? 0) + 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _dismissals = next;
      _dismissedAtMs = nowMs;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${BackupAccountCard.dismissalsKey}:$uid', next);
    await prefs.setInt('${BackupAccountCard.dismissedAtKey}:$uid', nowMs);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null || !user.isAnonymous) return const SizedBox.shrink();
    final uid = user.uid;
    if (_loadedForUid != uid) {
      _loadedForUid = uid;
      _dismissals = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(uid);
      });
    }
    final dismissals = _dismissals;
    if (dismissals == null) return const SizedBox.shrink();

    final goals = ref.watch(goalsStreamProvider).valueOrNull;
    final profile = ref.watch(onboardingProfileStreamProvider).valueOrNull;
    final completedAt = profile?.completedAtMs;
    final show = BackupCardPolicy.shouldShow(
      isAnonymous: true,
      hasGoal: goals != null && goals.isNotEmpty,
      onboardingCompletedAtMs: completedAt == null || completedAt == 0
          ? null
          : completedAt,
      dismissals: dismissals,
      lastDismissedAtMs: _dismissedAtMs,
      now: DateTime.now(),
    );
    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inkWarm,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.accentDim, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Back up your SidePal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Create an account to sync your data and keep it available '
              'across devices.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSoft,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismiss(uid),
                  child: Text(
                    'Not now',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => showConnectAccountFlow(context, ref),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
