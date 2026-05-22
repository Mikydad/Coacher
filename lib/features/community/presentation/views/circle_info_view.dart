import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../application/circle_providers.dart';
import '../../domain/models/accountability_circle.dart';
import '../../domain/models/circle_enums.dart';
import '../sheets/circle_notif_prefs_sheet.dart';

class CircleInfoView extends ConsumerWidget {
  const CircleInfoView({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circleAsync = ref.watch(circleDetailProvider(circleId));
    final membersAsync = ref.watch(circleMembersProvider(circleId));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return circleAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFB7FF00)),
      ),
      error: (_, __) => const Center(
        child: Text('Could not load circle info.',
            style: TextStyle(color: Color(0xFF8A8FA8))),
      ),
      data: (circle) {
        if (circle == null) return const SizedBox.shrink();
        final isCreator = circle.creatorId == uid;
        final isModerator = circle.moderatorIds.contains(uid);

        final moderators = membersAsync.valueOrNull
                ?.where((m) => circle.moderatorIds.contains(m.userId))
                .toList() ??
            [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Circle header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14171C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: const TextStyle(
                      color: Color(0xFFF0F4FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (circle.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      circle.description!,
                      style: const TextStyle(
                        color: Color(0xFF8A8FA8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(
                          label: circle.category,
                          icon: Icons.category_outlined),
                      _Chip(
                        label: circle.joinPolicy == JoinPolicy.open
                            ? 'Open'
                            : circle.joinPolicy == JoinPolicy.requestApproval
                                ? 'Approval'
                                : 'Invite-only',
                        icon: Icons.lock_outline_rounded,
                      ),
                      _Chip(
                          label: '${circle.memberCount}/${AccountabilityCircle.kMaxMembers} members',
                          icon: Icons.people_outline),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Streak stats ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Current streak',
                    value: '${circle.currentStreak}',
                    suffix: 'days',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF8C42),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Longest streak',
                    value: '${circle.longestStreak}',
                    suffix: 'days',
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Moderators ───────────────────────────────────────────────────
            _SectionLabel('Moderators'),
            const SizedBox(height: 8),
            ...moderators.map(
              (m) => _InfoTile(
                leading: const Icon(Icons.shield_rounded,
                    color: Color(0xFFB7FF00), size: 18),
                title: m.userId == uid ? '${m.displayName} (you)' : m.displayName,
              ),
            ),
            const SizedBox(height: 16),

            // ── Settings ─────────────────────────────────────────────────────
            _SectionLabel('Settings'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notification settings',
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    CircleNotifPrefsSheet(circleId: circleId),
              ),
            ),
            if (isModerator && isCreator)
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit circle',
                onTap: () {
                  // Phase 5+: circle settings editor
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Circle settings coming soon')),
                  );
                },
              ),
            const SizedBox(height: 16),

            // ── Danger zone ──────────────────────────────────────────────────
            _SectionLabel('Danger zone'),
            const SizedBox(height: 8),
            if (isCreator)
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref, circle.name),
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Color(0xFFFF4D4D)),
                label: const Text(
                  'Delete circle',
                  style: TextStyle(color: Color(0xFFFF4D4D)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D4D)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _confirmLeave(context, ref, uid),
                icon: const Icon(Icons.exit_to_app_rounded,
                    color: Color(0xFFFF4D4D)),
                label: const Text(
                  'Leave circle',
                  style: TextStyle(color: Color(0xFFFF4D4D)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D4D)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String circleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171C),
        title: const Text('Delete circle?',
            style: TextStyle(color: Color(0xFFF0F4FF))),
        content: Text(
          'This will permanently delete "$circleName" and remove all members. '
          'This cannot be undone.',
          style: const TextStyle(color: Color(0xFF8A8FA8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A8FA8))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(userCircleMembershipServiceProvider)
          .deleteCircle(circleId);
      // Navigation is handled automatically by the CircleDetailScreen listener
      // which pops back when the circle document disappears from Firestore.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete circle: $e')),
        );
      }
    }
  }

  Future<void> _confirmLeave(
      BuildContext context, WidgetRef ref, String _) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171C),
        title: const Text('Leave circle?',
            style: TextStyle(color: Color(0xFFF0F4FF))),
        content: const Text(
          'You will lose access to the chat, challenges, and activity feed.',
          style: TextStyle(color: Color(0xFF8A8FA8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A8FA8))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(userCircleMembershipServiceProvider)
          .leaveCircle(circleId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not leave: $e')),
        );
      }
    }
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF8A8FA8),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2029),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF8A8FA8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.leading, required this.title});
  final Widget leading;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                color: Color(0xFFF0F4FF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF14171C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8A8FA8), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF0F4FF),
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF8A8FA8), size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8A8FA8),
                  fontSize: 11,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    suffix,
                    style: const TextStyle(
                      color: Color(0xFF8A8FA8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
