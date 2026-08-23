import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../feedback/application/feedback_context_collector.dart';
import '../../feedback/application/tester_mode_controller.dart';
import '../../feedback/presentation/feedback_screen.dart';
import 'setting_row.dart';
import 'settings_page_scaffold.dart';

/// About & Support page (Profile reorg 2026-08-23): feedback entry plus the
/// version footer, whose 7-tap tester-mode toggle moved here with it.
class AboutSupportScreen extends StatelessWidget {
  const AboutSupportScreen({super.key});

  static const routeName = '/settings/about';

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'About & Support',
      children: [
        const SettingsSectionHeader(label: 'Support'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Column(
            children: [
              SettingRow(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Report a bug or suggest an idea',
                trailing: const SettingRowChevron(),
                onTap: () =>
                    Navigator.pushNamed(context, FeedbackScreen.routeName),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const VersionFooter(),
      ],
    );
  }
}

// ─── Version footer + tester-mode toggle ─────────────────────────────────────

/// Shows the real app version and hides the tester-mode switch: 7 quick taps
/// flip the floating bug-report bubble on/off for this device. (Moved from
/// profile_screen with the About & Support split.)
class VersionFooter extends ConsumerStatefulWidget {
  const VersionFooter({super.key});

  @override
  ConsumerState<VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends ConsumerState<VersionFooter> {
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
        ? 'SIDEPAL'
        : 'SIDEPAL V${info.version} BUILD ${info.buildNumber}';
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
            color: AppColors.textSoft.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
