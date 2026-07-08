import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/keyboard_dismiss.dart';
import '../application/circle_providers.dart';
import '../domain/models/circle_enums.dart';
import '../domain/models/circle_member.dart';
import 'views/circle_activity_view.dart';
import 'views/circle_chat_view.dart';
import 'views/circle_members_view.dart';
import 'views/circle_challenges_view.dart';
import 'views/circle_info_view.dart';
import 'views/weekly_commitments_view.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  static const routeName = '/community/circle';

  @override
  ConsumerState<CircleDetailScreen> createState() =>
      _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Chat',
    'Activity',
    'Commitments',
    'Challenges',
    'Members',
    'Info',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging) {
        dismissKeyboard(context);
      } else {
        ref
            .read(circleActiveTabProvider(widget.circleId).notifier)
            .state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circleAsync = ref.watch(circleDetailProvider(widget.circleId));
    final membersAsync = ref.watch(circleMembersProvider(widget.circleId));

    // When the circle document is deleted (stream emits null), go back
    // immediately instead of showing a "not found" placeholder.
    ref.listen<AsyncValue<dynamic>>(
      circleDetailProvider(widget.circleId),
      (_, next) {
        if (next is AsyncData && next.value == null) {
          if (context.mounted) Navigator.of(context).popUntil((r) {
            return r.settings.name == '/community' || r.isFirst;
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF15171B),
      body: circleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFB7FF00)),
        ),
        error: (e, _) => const Center(
          child: Text(
            'Could not load circle.',
            style: TextStyle(color: Color(0xFF8A8FA8)),
          ),
        ),
        data: (circle) {
          if (circle == null) {
            // Navigation is handled by the listener above; show a brief
            // loading indicator while the pop animation plays.
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB7FF00)),
            );
          }

          final activeMembers = membersAsync.valueOrNull
                  ?.where((m) => m.status == CircleMemberStatus.active)
                  .toList() ??
              [];

          return KeyboardDismissOnTap(
            child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: const Color(0xFF1E2126),
                foregroundColor: const Color(0xFFF0F4FF),
                expandedHeight: 200,
                pinned: true,
                floating: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _CircleHeader(
                    circleName: circle.name,
                    streak: circle.currentStreak,
                    memberCount: circle.memberCount,
                    members: activeMembers,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: const Color(0xFFB7FF00),
                    unselectedLabelColor: const Color(0xFF8A8FA8),
                    indicatorColor: const Color(0xFFB7FF00),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabAlignment: TabAlignment.start,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Chat
                CircleChatView(circleId: widget.circleId),
                // Activity
                CircleActivityView(circleId: widget.circleId),
                // Commitments
                WeeklyCommitmentsView(circleId: widget.circleId),
                // Challenges
                CircleChallengesView(circleId: widget.circleId),
                // Members
                CircleMembersView(circleId: widget.circleId),
                // Info
                CircleInfoView(circleId: widget.circleId),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _CircleHeader extends StatelessWidget {
  const _CircleHeader({
    required this.circleName,
    required this.streak,
    required this.memberCount,
    required this.members,
  });

  final String circleName;
  final int streak;
  final int memberCount;
  final List<CircleMember> members;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark background
        Container(color: const Color(0xFF15171B)),
        // Glass card
        Positioned.fill(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        circleName,
                        style: const TextStyle(
                          color: Color(0xFFF0F4FF),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (streak > 0) _StreakBadge(streak),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$memberCount / ${AccountabilityCircleConst.kMaxMembers} members',
                  style: const TextStyle(
                    color: Color(0xFF8A8FA8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                if (members.isNotEmpty)
                  _MemberAvatarRow(members: members),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge(this.streak);
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB7FF00).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB7FF00).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Color(0xFFB7FF00),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatarRow extends StatelessWidget {
  const _MemberAvatarRow({required this.members});
  final List<CircleMember> members;

  static const _colors = [
    Color(0xFFB7FF00),
    Color(0xFF00CFFF),
    Color(0xFFFF8C42),
    Color(0xFFFF4D9E),
    Color(0xFF7B61FF),
    Color(0xFF00FF9F),
    Color(0xFFFFD600),
    Color(0xFFFF4D4D),
  ];

  Color _colorFor(String userId) =>
      _colors[userId.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Show at most 8 avatars
    final visible = members.take(8).toList();

    return Row(
      children: visible.map((m) {
        final initial =
            m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?';
        final color = _colorFor(m.userId);
        final isMe = m.userId == uid;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Tooltip(
            message: m.displayName,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(isMe ? 1.0 : 0.2),
              child: Text(
                initial,
                style: TextStyle(
                  color: isMe ? Colors.black : color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Placeholder tab ───────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 15),
      ),
    );
  }
}

// Helper constant to avoid importing the full model just for kMaxMembers
class AccountabilityCircleConst {
  static const int kMaxMembers = 8;
}
