import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/theme_brightness_controller.dart';
import '../../../core/presentation/page_headers.dart';

import '../../../app/application/main_tab_navigation.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_session_policy.dart';
import '../../auth/application/user_scoped_invalidation.dart';
import '../../auth/presentation/widgets/connect_account_section.dart';
import '../../../features/coaching/application/coaching_style_providers.dart';
import '../../../features/coaching/domain/models/coaching_style.dart';
import '../../../features/coaching/presentation/widgets/coaching_preference_sections.dart';
import '../../../features/context_override/application/context_override_providers.dart';
import '../../analytics/presentation/analytics_progress_screen.dart';
import '../../settings/presentation/about_support_screen.dart';
import '../../settings/presentation/account_settings_screen.dart';
import '../../settings/presentation/appearance_sheet.dart';
import '../../settings/presentation/coach_ai_settings_screen.dart';
import '../../settings/presentation/notification_settings_screen.dart';
import '../../settings/presentation/setting_row.dart';
import '../../settings/presentation/smart_timing_settings_screen.dart';
import '../../analytics/application/discipline_score.dart';
import '../../analytics/application/focus_providers.dart';
import '../application/profile_hero_stats.dart';
import '../application/profile_providers.dart';

import '../../../core/presentation/app_colors.dart';

// ─── Design tokens (Obsidian Pulse) ──────────────────────────────────────────

Color get _kPrimary => AppColors.limeCream;
Color get _kPrimaryDim => AppColors.accentDim;
Color get _kSurface => AppColors.ink;
Color get _kSurfaceHigh => AppColors.inkWarm;
Color get _kSurfaceHighest => AppColors.inkElevated;
Color get _kOnSurface => AppColors.white;
Color get _kOnSurfaceVariant => AppColors.textSoft;
Color get _kOnPrimaryFixed => AppColors.limeShadow;
Color get _kError => AppColors.coral;
Color get _kPrimaryContainer => AppColors.accentBright;
Color get _kOnPrimaryContainer => AppColors.accentDeep;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final service = ref.read(profilePreferenceServiceProvider);
    await service.setDisplayName(_nameController.text);
    if (mounted) setState(() => _editingName = false);
  }

  void _onBackPressed() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    navigateToMainTab(context, ref, index: MainTabIndex.home);
  }

  Future<void> _signOut() async {
    // Guests have no way back into an anonymous account — logging out is
    // permanent data loss. Warn honestly and offer Connect as the way out.
    if (!ref.read(isRegisteredProvider)) {
      final choice = await showDialog<String>(
        context: context,
        builder: (_) => const _GuestLogOutDialog(),
      );
      if (!mounted) return;
      if (choice == 'connect') {
        await showConnectAccountFlow(context, ref);
        return;
      }
      if (choice != 'logout') return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _ObsidianDialog(
          title: 'Log Out?',
          body:
              'Your local data will be cleared. You can sign back in any '
              'time.',
          confirmLabel: 'Log Out',
          confirmColor: _kError,
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    // Signal AuthGate to show the landing screen (not silent anon re-sign-in).
    ref.read(pendingAuthLandingProvider.notifier).state = true;

    // Clear in-memory per-user Riverpod state so nothing leaks into the next
    // session, then wipe local data, then sign out so AuthGate reacts cleanly.
    invalidateUserScopedProviders(ref);
    await AuthSessionPolicy.clearLocalSession();
    await ref.read(authRepositoryProvider).signOut();
    // AuthGate will rebuild and show the AuthLandingScreen.
    // No manual navigation required.
  }

  @override
  Widget build(BuildContext context) {
    final displayName = ref.watch(displayNameProvider);
    final coachingStyle = ref.watch(activeCoachingStyleProvider);
    final attentionAsync = ref.watch(attentionStateProvider);
    final streakDays = ref.watch(homeDisplayStreakDaysProvider);
    final heroStats = ref.watch(profileHeroStatsProvider);

    if (!_editingName && _nameController.text != displayName) {
      _nameController.text = displayName;
    }

    final effectiveName = displayName.isEmpty ? 'You' : displayName;
    final initial = effectiveName[0].toUpperCase();

    final attentionState = attentionAsync.valueOrNull;
    final hasQuietHours = attentionState?.hasSleepWindow ?? false;
    final quietLabel = hasQuietHours
        ? '${attentionState!.sleepWindowStart}–${attentionState.sleepWindowEnd}'
        : '8:00 AM';

    return Scaffold(
      backgroundColor: _kSurface,
      // Frosted glass top bar — no AppBar widget so we get full-bleed hero
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Transparent space for the frosted header
              const SliverToBoxAdapter(child: SizedBox(height: 72)),

              // ── Profile Hero ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: _ProfileHero(
                    initial: initial,
                    effectiveName: effectiveName,
                    editingName: _editingName,
                    nameController: _nameController,
                    coachingStyle: coachingStyle,
                    streakCount: streakDays,
                    tasksLabel: heroStats.tasksLabel,
                    goalsLabel: heroStats.goalsLabel,
                    onEditTap: () => setState(() => _editingName = true),
                    onSaveName: _saveName,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Progress (2026-08-23): sits directly under the streak
              // card so checking progress is the first thing available,
              // not a row buried in the settings list.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SettingRow(
                      icon: Icons.leaderboard_rounded,
                      title: 'Progress',
                      subtitle: 'Score trends, streaks & analytics',
                      // Dot while a coaching focus is waiting unseen —
                      // clears once the focus card renders on Progress.
                      trailing: ref.watch(hasUnseenCoachingFocusProvider)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const SettingRowChevron(),
                              ],
                            )
                          : const SettingRowChevron(),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AnalyticsProgressScreen.routeName,
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Discipline Mode + Coach Tone (2026-08-23): the two knobs
              // reached for most often sit out in the open, above the
              // settings doors — each collapsed to its active value.
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DisciplineModeSection(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CoachToneSection(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── Grouped hub (Profile reorg 2026-08-23): every knob lives
              // on a focused sub-page; this list is just the doors in.
              const SliverToBoxAdapter(child: _SectionLabel(label: 'Settings')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _ProfileHubList(quietLabel: quietLabel),
                ),
              ),

              // ── Account (guest only: connect prompt; registered users see
              // their identity in Account settings) ─────────────────────────
              if (!ref.watch(isRegisteredProvider)) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                const SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Account'),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Connect an account so your data survives phone changes '
                      'and reinstalls.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _kOnSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ConnectAccountSection(),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── Log Out ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LogOutButton(onTap: _signOut),
                ),
              ),

              // Version footer + tester-mode taps moved to About & Support.
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),

          // ── Frosted glass top bar (matches home screen style) ─────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 72,
                  color: _kSurface.withValues(alpha: 0.8),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _onBackPressed,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _kOnSurface,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const PageTitle('Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initial,
    required this.effectiveName,
    required this.editingName,
    required this.nameController,
    required this.coachingStyle,
    required this.streakCount,
    required this.tasksLabel,
    required this.goalsLabel,
    required this.onEditTap,
    required this.onSaveName,
  });

  final String initial;
  final String effectiveName;
  final bool editingName;
  final TextEditingController nameController;
  final CoachingStyle coachingStyle;
  final int streakCount;

  /// Preformatted so the card stays a dumb view: "3/5" or an em dash.
  final String tasksLabel;
  final String goalsLabel;
  final VoidCallback onEditTap;
  final VoidCallback onSaveName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Identity card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kSurfaceHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Background glow
              Positioned(
                right: -16,
                top: -16,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(alpha: 0.08),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
              Row(
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPrimaryDim.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          color: _kSurfaceHighest,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: _kOnPrimaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: _kPrimary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            coachingStyle.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Name / editor
                        if (editingName)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  textCapitalization: TextCapitalization.words,
                                  controller: nameController,
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _kOnSurface,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Your name',
                                    hintStyle: TextStyle(
                                      color: _kOnSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => onSaveName(),
                                ),
                              ),
                              GestureDetector(
                                onTap: onSaveName,
                                child: Icon(
                                  Icons.check_rounded,
                                  color: _kPrimaryDim,
                                  size: 20,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            effectiveName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _kOnSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: editingName ? null : onEditTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _kPrimaryDim,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.north_east_rounded,
                                size: 13,
                                color: _kPrimaryDim,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Streak card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kPrimaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimaryDim.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: _kOnPrimaryContainer,
                size: 28,
              ),
              const SizedBox(height: 10),
              // Streak stays the hero; today's tasks and this week's goals
              // sit beside it so progress is readable without a tap
              // (2026-08-23).
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _HeroStat(
                      value: streakCount.toString(),
                      label: 'DAY STREAK',
                      valueSize: 34,
                    ),
                  ),
                  Expanded(
                    child: _HeroStat(
                      value: tasksLabel,
                      label: 'TODAY',
                      valueSize: 26,
                    ),
                  ),
                  Expanded(
                    child: _HeroStat(
                      value: goalsLabel,
                      label: 'THIS WEEK',
                      valueSize: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One number + caption inside the lime hero card. FittedBox keeps a long
/// value ("12/14") from overflowing its third of the row on narrow phones.
class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.valueSize,
  });

  final String value;
  final String label;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              color: _kOnPrimaryContainer,
              height: 1,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: _kOnPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Grouped settings hub (Profile reorg 2026-08-23) ─────────────────────────

class _ProfileHubList extends StatelessWidget {
  const _ProfileHubList({required this.quietLabel});

  final String quietLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          SettingRow(
            icon: Icons.schedule_rounded,
            title: 'Smart Timing',
            subtitle: 'Calendar, motion & head-out nudges',
            trailing: const SettingRowChevron(),
            onTap: () => Navigator.pushNamed(
              context,
              SmartTimingSettingsScreen.routeName,
            ),
          ),
          SettingRow(
            icon: Icons.auto_awesome_rounded,
            title: 'Coach & AI',
            subtitle: 'Coach AI & what SidePal knows',
            trailing: const SettingRowChevron(),
            onTap: () =>
                Navigator.pushNamed(context, CoachAiSettingsScreen.routeName),
          ),
          SettingRow(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications & Reminders',
            subtitle: 'Coaching insights, sleep window & modes',
            trailing: Text(
              quietLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
            onTap: () => Navigator.pushNamed(
              context,
              NotificationSettingsScreen.routeName,
            ),
          ),
          SettingRow(
            icon: Icons.account_circle_outlined,
            title: 'Account & Privacy',
            subtitle: 'Connected account, security & data',
            trailing: const SettingRowChevron(),
            onTap: () =>
                Navigator.pushNamed(context, AccountSettingsScreen.routeName),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isDark =
                  ref.watch(themeBrightnessProvider) == Brightness.dark;
              return SettingRow(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Appearance',
                subtitle: 'Obsidian Pulse dark or light',
                trailing: Text(
                  isDark ? 'DARK' : 'LIGHT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _kPrimary,
                  ),
                ),
                onTap: () => showAppearanceSheet(context),
              );
            },
          ),
          SettingRow(
            icon: Icons.info_outline_rounded,
            title: 'About & Support',
            subtitle: 'Feedback, version & tester mode',
            trailing: const SettingRowChevron(),
            onTap: () =>
                Navigator.pushNamed(context, AboutSupportScreen.routeName),
          ),
        ],
      ),
    );
  }
}

// ─── Log Out button ───────────────────────────────────────────────────────────

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurfaceHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: _kError.withValues(alpha: 0.08),
        splashColor: _kError.withValues(alpha: 0.12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: _kError, size: 18),
              const SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared section label ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: _kOnSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Confirmation dialog ──────────────────────────────────────────────────────

/// Guest log-out warning: anonymous accounts cannot be signed back into, so
/// logging out permanently loses all data. Primary action is the way out —
/// connecting an account; destroying data is the quiet, deliberate option.
class _GuestLogOutDialog extends StatelessWidget {
  const _GuestLogOutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data will be lost',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You're not connected to an account. Logging out permanently "
              'deletes everything on this device — tasks, goals, and '
              "progress can't be recovered.\n\nConnect an account first and "
              'your data stays safe.',
              style: TextStyle(
                fontSize: 13,
                color: _kOnSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, 'connect'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Connect account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kSurfaceHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kOnSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, 'logout'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kError.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kError.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Delete & log out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kError,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ObsidianDialog extends StatelessWidget {
  const _ObsidianDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                color: _kOnSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _kSurfaceHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kOnSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: confirmColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: confirmColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          confirmLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: confirmColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
