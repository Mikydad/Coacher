import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../feedback/application/feedback_context_collector.dart';
import '../../feedback/application/tester_mode_controller.dart';
import '../../feedback/presentation/feedback_screen.dart';
import '../application/crashlytics_test_sink.dart';
import 'setting_row.dart';
import 'settings_page_scaffold.dart';
import '../../../core/config/build_flags.dart';

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
///
/// With tester mode ON, a long-press opens the Crashlytics smoke test
/// (non-fatal event or forced crash) — see [CrashlyticsTestSink].
class VersionFooter extends ConsumerStatefulWidget {
  const VersionFooter({super.key, this.crashTriggerEnabled = kTesterBuild});

  /// The forced-crash smoke test exists only in tester builds (audit M11,
  /// `SIDEPAL_TESTER_BUILD`); the App Store binary compiles it out.
  final bool crashTriggerEnabled;

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
            TesterToggleOutcome.notAllowlisted =>
              'Tester access is granted per account — ask the team',
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

  Future<void> _onLongPress() async {
    // Tester builds + tester mode only, so a curious user never meets a
    // "crash the app" dialog. Silent otherwise — the gesture stays hidden.
    if (!widget.crashTriggerEnabled) return;
    if (!ref.read(testerModeProvider)) return;
    final sink = ref.read(crashlyticsTestSinkProvider);
    final messenger = ScaffoldMessenger.of(context);
    final action = await showDialog<CrashTestAction>(
      context: context,
      builder: (_) =>
          CrashTestDialog(collectionEnabled: sink.collectionEnabled),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case CrashTestAction.nonFatal:
        await sink.sendNonFatal();
        if (!mounted) return;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Test event sent — it shows in the Firebase console within a '
              'few minutes',
            ),
          ),
        );
      case CrashTestAction.crash:
        await sink.crash();
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
      onLongPress: _onLongPress,
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

// ─── Crashlytics smoke test dialog ───────────────────────────────────────────

enum CrashTestAction { nonFatal, crash }

/// Styled like the account-deletion dialog: quiet body, coral for the
/// destructive choice. Tells the truth about debug builds so nobody waits
/// for an event that cannot arrive.
class CrashTestDialog extends StatelessWidget {
  const CrashTestDialog({super.key, required this.collectionEnabled});

  final bool collectionEnabled;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.inkCard,
      title: Text(
        'Crashlytics smoke test',
        style: TextStyle(color: AppColors.fg, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Non-fatal sends a test event now and the app keeps running. '
            'Crash closes the app immediately — reopen it to upload the '
            'report.',
            style: TextStyle(color: AppColors.textGray, height: 1.5),
          ),
          if (!collectionEnabled) ...[
            const SizedBox(height: 12),
            Text(
              'Collection is off in this build (debug) — nothing will reach '
              'the console. Use a profile, release or TestFlight build.',
              style: TextStyle(color: AppColors.amber, height: 1.5),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(CrashTestAction.nonFatal),
          child: Text('Send non-fatal', style: TextStyle(color: AppColors.fg)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(CrashTestAction.crash),
          child: Text('Crash app', style: TextStyle(color: AppColors.coral)),
        ),
      ],
    );
  }
}
