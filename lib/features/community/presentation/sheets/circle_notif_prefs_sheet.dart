import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/circle_notif_prefs_repository.dart';
import '../../domain/models/circle_notif_prefs.dart';

import '../../../../core/presentation/app_colors.dart';

final _notifPrefsRepositoryProvider = Provider<CircleNotifPrefsRepository>((
  ref,
) {
  return FirestoreCircleNotifPrefsRepository();
});

class CircleNotifPrefsSheet extends ConsumerStatefulWidget {
  const CircleNotifPrefsSheet({super.key, required this.circleId});

  final String circleId;

  @override
  ConsumerState<CircleNotifPrefsSheet> createState() =>
      _CircleNotifPrefsSheetState();
}

class _CircleNotifPrefsSheetState extends ConsumerState<CircleNotifPrefsSheet> {
  CircleNotifPrefs? _prefs;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await ref
          .read(_notifPrefsRepositoryProvider)
          .getPrefs(widget.circleId);
      if (mounted) setState(() => _prefs = prefs);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(_notifPrefsRepositoryProvider).savePrefs(p);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setMuteUntilTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final midnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    setState(
      () => _prefs = _prefs?.copyWith(
        muteUntilMs: midnight.millisecondsSinceEpoch,
      ),
    );
  }

  void _clearMute() {
    setState(() => _prefs = _prefs?.copyWith(muteUntilMs: null));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Notification settings',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose what you hear about from this circle.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_prefs != null) ...[
                      _ToggleRow(
                        label: 'Mentions',
                        subtitle: 'When someone tags you',
                        value: _prefs!.mentions,
                        onChanged: (v) => setState(
                          () => _prefs = _prefs!.copyWith(mentions: v),
                        ),
                      ),
                      _ToggleRow(
                        label: 'Challenge updates',
                        subtitle: 'Progress, votes, completions',
                        value: _prefs!.challengeUpdates,
                        onChanged: (v) => setState(
                          () => _prefs = _prefs!.copyWith(challengeUpdates: v),
                        ),
                      ),
                      _ToggleRow(
                        label: 'Weekly summary',
                        subtitle: 'Your circle\'s weekly pulse',
                        value: _prefs!.weeklySummary,
                        onChanged: (v) => setState(
                          () => _prefs = _prefs!.copyWith(weeklySummary: v),
                        ),
                      ),
                      _ToggleRow(
                        label: 'Accomplishments',
                        subtitle: 'Streaks and milestones',
                        value: _prefs!.accomplishments,
                        onChanged: (v) => setState(
                          () => _prefs = _prefs!.copyWith(accomplishments: v),
                        ),
                      ),
                      _ToggleRow(
                        label: 'Reactions',
                        subtitle: 'When members react to your posts',
                        value: _prefs!.reactions,
                        onChanged: (v) => setState(
                          () => _prefs = _prefs!.copyWith(reactions: v),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.surfaceSlate),
                      const SizedBox(height: 12),

                      // Mute section
                      Row(
                        children: [
                          const Text(
                            'Mute circle',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _prefs!.isMuted,
                            onChanged: (v) =>
                                v ? _setMuteUntilTomorrow() : _clearMute(),
                            activeColor: AppColors.danger,
                          ),
                        ],
                      ),
                      if (_prefs!.isMuted) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Muted until ${_formatMs(_prefs!.muteUntilMs!)}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ] else ...[
                        TextButton.icon(
                          onPressed: _setMuteUntilTomorrow,
                          icon: const Icon(
                            Icons.notifications_off_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          label: const Text(
                            'Mute until tomorrow',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Save preferences'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  static String _formatMs(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
