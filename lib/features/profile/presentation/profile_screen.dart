import '../../education/presentation/first_time_feature_card.dart';
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
import '../../../features/coaching/domain/models/enforcement_mode.dart';
import '../../../features/context_override/application/context_override_providers.dart';
import '../../settings/presentation/account_settings_screen.dart';
import '../../settings/presentation/notification_settings_screen.dart';
import '../../settings/presentation/reminder_settings_screen.dart';
import '../../analytics/application/discipline_score.dart';
import '../../feedback/application/feedback_context_collector.dart';
import '../../feedback/application/tester_mode_controller.dart';
import '../../education/presentation/help_dot.dart';
import '../../feedback/presentation/feedback_screen.dart';
import '../application/profile_providers.dart';

import '../../../core/presentation/app_colors.dart';

// ─── Design tokens (Obsidian Pulse) ──────────────────────────────────────────

Color get _kPrimary => AppColors.limeCream;
Color get _kPrimaryDim => AppColors.accentDim;
Color get _kSecondary => AppColors.cyan;
Color get _kSurface => AppColors.ink;
Color get _kSurfaceLow => AppColors.inkDeep;
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
    final defaultMode = ref.watch(defaultEnforcementModeProvider);
    final attentionAsync = ref.watch(attentionStateProvider);
    final streakDays = ref.watch(homeDisplayStreakDaysProvider);

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
                    onEditTap: () => setState(() => _editingName = true),
                    onSaveName: _saveName,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── Discipline Modes ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                      label: 'Discipline Modes',
                      helpId: 'disciplineModes',
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'How strict the app is overall. New tasks inherit '
                        'this based on how important they are — you can '
                        'still change it per task.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _kOnSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FirstTimeFeatureCard(guideId: 'disciplineModes'),
                      _DisciplineModesSection(activeMode: defaultMode),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── Coach Tone ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Coach Tone', helpId: 'coachTone'),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Adjust how your AI coach communicates with you.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _kOnSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _CoachToneSection(activeStyle: coachingStyle),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // ── Core Optimization (settings) ──────────────────────────────
              SliverToBoxAdapter(
                child: _SectionLabel(
                  label: 'Core Optimization',
                  helpId: 'coreOptimization',
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _CoreOptimizationSection(quietLabel: quietLabel),
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

              // ── Version footer (7 taps toggles tester mode) ───────────────
              const SliverToBoxAdapter(child: _VersionFooter()),
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
    required this.onEditTap,
    required this.onSaveName,
  });

  final String initial;
  final String effectiveName;
  final bool editingName;
  final TextEditingController nameController;
  final CoachingStyle coachingStyle;
  final int streakCount;
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
              Text(
                streakCount.toString(),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: _kOnPrimaryContainer,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'DAY STREAK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _kOnPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Discipline Modes section ─────────────────────────────────────────────────

class _DisciplineModesSection extends ConsumerWidget {
  const _DisciplineModesSection({required this.activeMode});

  final EnforcementMode activeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: EnforcementMode.values.map((mode) {
        final isActive = mode == activeMode;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _DisciplineTile(
            mode: mode,
            isActive: isActive,
            onTap: () async {
              final service = ref.read(profilePreferenceServiceProvider);
              await service.setDefaultEnforcementMode(mode);
            },
          ),
        );
      }).toList(),
    );
  }
}

class _DisciplineTile extends StatelessWidget {
  const _DisciplineTile({
    required this.mode,
    required this.isActive,
    required this.onTap,
  });

  final EnforcementMode mode;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    switch (mode) {
      case EnforcementMode.flexible:
        icon = Icons.waves_rounded;
        iconColor = _kSecondary;
      case EnforcementMode.disciplined:
        icon = Icons.bolt_rounded;
        iconColor = isActive ? _kOnPrimaryFixed : _kPrimaryDim;
      case EnforcementMode.extreme:
        icon = Icons.shield_rounded;
        iconColor = _kError;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? _kPrimaryContainer.withValues(alpha: 0.05)
              : _kSurfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? _kPrimaryDim.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? _kPrimaryDim : _kSurfaceHighest,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive ? _kPrimary : _kOnSurface,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mode.description,
                    style: TextStyle(fontSize: 12, color: _kOnSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Coach Tone section ───────────────────────────────────────────────────────

class _CoachToneSection extends ConsumerWidget {
  const _CoachToneSection({required this.activeStyle});

  final CoachingStyle activeStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: CoachingStyle.values.map((style) {
        final isActive = style == activeStyle;
        return GestureDetector(
          onTap: () async {
            final service = ref.read(coachingStyleServiceProvider);
            await service.setStyle(style);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? _kPrimaryContainer.withValues(alpha: 0.08)
                  : _kSurfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? _kPrimaryDim.withValues(alpha: 0.4)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _styleTextColor(style, isActive),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _styleCopy(style),
                  style: TextStyle(fontSize: 10, color: _kOnSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _styleTextColor(CoachingStyle style, bool isActive) {
    if (isActive) return _kPrimary;
    switch (style) {
      case CoachingStyle.supportive:
        return _kSecondary;
      case CoachingStyle.balanced:
        return _kOnSurface;
      case CoachingStyle.disciplined:
        return _kOnSurface;
      case CoachingStyle.intense:
        return _kError;
    }
  }

  String _styleCopy(CoachingStyle style) {
    switch (style) {
      case CoachingStyle.supportive:
        return 'Encouraging and light';
      case CoachingStyle.balanced:
        return 'Empathetic and steady';
      case CoachingStyle.disciplined:
        return 'Direct and focused';
      case CoachingStyle.intense:
        return 'Radical honesty only';
    }
  }
}

// ─── Core Optimization (settings list) ───────────────────────────────────────

class _CoreOptimizationSection extends StatelessWidget {
  const _CoreOptimizationSection({required this.quietLabel});

  final String quietLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.account_circle_outlined,
            title: 'Account Settings',
            subtitle: 'Security, Privacy & Data',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: _kOnSurfaceVariant,
              size: 20,
            ),
            onTap: () =>
                Navigator.pushNamed(context, AccountSettingsScreen.routeName),
          ),
          _SettingRow(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'Coaching insights & push alerts',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: _kOnSurfaceVariant,
              size: 20,
            ),
            onTap: () => Navigator.pushNamed(
              context,
              NotificationSettingsScreen.routeName,
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isDark =
                  ref.watch(themeBrightnessProvider) == Brightness.dark;
              return _SettingRow(
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
                onTap: () =>
                    ref.read(themeBrightnessProvider.notifier).toggle(),
              );
            },
          ),
          _SettingRow(
            icon: Icons.alarm_on_rounded,
            title: 'Reminder Settings',
            subtitle: 'Sleep window & attention modes',
            trailing: Text(
              quietLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
            onTap: () =>
                Navigator.pushNamed(context, ReminderSettingsScreen.routeName),
          ),
          _SettingRow(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Report a bug or suggest an idea',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: _kOnSurfaceVariant,
              size: 20,
            ),
            onTap: () => Navigator.pushNamed(context, FeedbackScreen.routeName),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurfaceLow,
      child: InkWell(
        onTap: onTap,
        highlightColor: _kPrimary.withValues(alpha: 0.05),
        splashColor: _kPrimary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: _kOnSurfaceVariant, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: _kOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
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
  const _SectionLabel({required this.label, this.helpId});
  final String label;

  /// Feature-guide id — renders a `?` that opens the help sheet.
  final String? helpId;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: _kOnSurfaceVariant,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: helpId == null
          ? text
          : Row(
              children: [
                Flexible(child: text),
                HelpDot(helpId!),
              ],
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

// ─── Version footer + tester-mode toggle ─────────────────────────────────────

/// Shows the real app version and hides the tester-mode switch: 7 quick taps
/// flip the floating bug-report bubble on/off for this device.
class _VersionFooter extends ConsumerStatefulWidget {
  const _VersionFooter();

  @override
  ConsumerState<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends ConsumerState<_VersionFooter> {
  final SevenTapDetector _taps = SevenTapDetector();

  Future<void> _onTap() async {
    final remaining = _taps.registerTap(DateTime.now());
    final messenger = ScaffoldMessenger.of(context);
    if (remaining == 0) {
      final outcome = await ref.read(testerModeProvider.notifier).toggle();
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (outcome) {
            TesterToggleOutcome.enabled =>
              'Tester mode enabled — bug bubble is on',
            TesterToggleOutcome.disabled => 'Tester mode disabled',
            TesterToggleOutcome.accountRequired =>
              'Sign in with an account to use tester mode',
          }),
        ),
      );
    } else if (remaining <= 3) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            '$remaining more tap${remaining == 1 ? '' : 's'} to toggle '
            'tester mode',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final label = info == null
        ? 'PATHPAL'
        : 'PATHPAL V${info.version} BUILD ${info.buildNumber}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 40),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
            color: _kOnSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
