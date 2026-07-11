import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../application/circle_providers.dart';
import '../application/circle_recommendation_service.dart';
import '../application/user_circle_membership_service.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';
import 'circle_auth_guard.dart';
import 'circle_detail_screen.dart';

import '../../../core/presentation/app_colors.dart';

const _kAllCategories = [
  'all',
  'fitness',
  'learning',
  'business',
  'reading',
  'productivity',
  'other',
];

void _logDiscoveryJoin(String message) {
  debugPrint('[CircleDiscovery] $message');
  if (kDebugMode) {
    // Visible in `flutter run` / Xcode device log (debugPrint is easy to miss).
    print('[CircleDiscovery] $message');
  }
}

/// Joins [circle] for the current user, or sends a join request when the
/// circle requires approval.
///
/// Shared by [CircleDiscoveryScreen] and the zero-circles "discover" list on
/// the Community tab (`community_screen.dart`) so membership writes are
/// never duplicated between the two entry points.
Future<void> joinOrRequestCircle({
  required BuildContext context,
  required WidgetRef ref,
  required AccountabilityCircle circle,
}) async {
  _logDiscoveryJoin('Join tapped for ${circle.id} (${circle.name})');
  // Joining binds the circle to a real identity — anonymous/guest sessions
  // must register first. (An anonymous user is never already a member, so
  // this never blocks re-opening a joined circle.)
  if (!await ensureRegisteredForCircleAction(
    context,
    ref,
    actionLabel: 'join a circle',
  )) {
    _logDiscoveryJoin('Aborted: account required');
    return;
  }
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) {
    _logDiscoveryJoin('Aborted: not signed in');
    return;
  }

  final joinedIds = ref.read(myCircleIdsProvider).valueOrNull?.toSet() ?? {};
  final service = ref.read(userCircleMembershipServiceProvider);

  // Creator or indexed member — open circle detail (repair index if needed).
  if (joinedIds.contains(circle.id) ||
      (uid.isNotEmpty && circle.creatorId == uid)) {
    _logDiscoveryJoin('Already joined (index or creator) — opening circle');
    if (!joinedIds.contains(circle.id)) {
      await service.ensureCircleIndex(circle.id);
    }
    if (context.mounted) {
      Navigator.pushNamed(
        context,
        CircleDetailScreen.routeName,
        arguments: circle.id,
      );
    }
    return;
  }

  final existingMember = uid.isNotEmpty
      ? await service.isActiveMember(circle.id)
      : false;
  if (existingMember) {
    _logDiscoveryJoin('Already active member — repairing index');
    await service.ensureCircleIndex(circle.id);
    if (context.mounted) {
      Navigator.pushNamed(
        context,
        CircleDetailScreen.routeName,
        arguments: circle.id,
      );
    }
    return;
  }
  try {
    if (circle.joinPolicy == JoinPolicy.open) {
      _logDiscoveryJoin('Calling joinCircle…');
      await service.joinCircle(circle.id);
      _logDiscoveryJoin('joinCircle succeeded');
      invalidateCircleScopedProviders(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Joined ${circle.name}!')));
        Navigator.pushNamed(
          context,
          CircleDetailScreen.routeName,
          arguments: circle.id,
        );
      }
    } else {
      await service.requestJoin(circle.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${circle.name}.')),
        );
      }
    }
  } on CircleLimitException catch (e) {
    _logDiscoveryJoin('CircleLimitException: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  } on CircleFullException catch (e) {
    _logDiscoveryJoin('CircleFullException: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  } catch (e, st) {
    _logDiscoveryJoin('join failed: $e\n$st');
    if (context.mounted) {
      final isPermission =
          e is FirebaseException && e.code == 'permission-denied';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermission
                ? 'Join blocked by Firestore rules. Deploy firestore.rules '
                      '(firebase deploy --only firestore:rules), then retry.'
                : 'Could not join: $e',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class CircleDiscoveryScreen extends ConsumerStatefulWidget {
  const CircleDiscoveryScreen({super.key});

  static const routeName = '/community/discover';

  @override
  ConsumerState<CircleDiscoveryScreen> createState() =>
      _CircleDiscoveryScreenState();
}

class _CircleDiscoveryScreenState extends ConsumerState<CircleDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  String _selectedCategory = 'all';
  List<AccountabilityCircle>? _browseCircles;
  List<AccountabilityCircle> _searchResults = [];
  List<ScoredCircle> _recommendations = [];
  bool _loadingBrowse = false;
  bool _loadingSearch = false;
  Timer? _debounce;
  bool _recommendationsFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging) {
        dismissKeyboard(context);
      }
    });
    _fetchBrowse();
  }

  Future<void> _fetchRecommendations(List<String> joinedIds) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final svc = CircleRecommendationService(
        circleRepo: ref.read(circleRepositoryProvider),
      );
      final recs = await svc.getRecommendations(
        userId: uid,
        activeGoalCategories: const [],
        userTimezone: DateTime.now().timeZoneName,
        alreadyJoinedIds: joinedIds,
      );
      if (mounted) setState(() => _recommendations = recs.take(5).toList());
    } catch (e) {
      debugPrint('circle_discovery_screen: swallowed error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchBrowse({String? category}) async {
    setState(() => _loadingBrowse = true);
    try {
      final results = await ref
          .read(circleRepositoryProvider)
          .searchCircles(
            category: (category == null || category == 'all') ? null : category,
          );
      if (mounted) setState(() => _browseCircles = results);
    } catch (_) {
      if (mounted) setState(() => _browseCircles = []);
    } finally {
      if (mounted) setState(() => _loadingBrowse = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingSearch = true);
      try {
        final results = await ref
            .read(circleRepositoryProvider)
            .searchCircles(query: query.trim());
        if (mounted) setState(() => _searchResults = results);
      } catch (_) {
        if (mounted) setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _loadingSearch = false);
      }
    });
  }

  Future<void> _joinOrRequest(AccountabilityCircle circle) =>
      joinOrRequestCircle(context: context, ref: ref, circle: circle);

  @override
  Widget build(BuildContext context) {
    // Always read live from Riverpod — no local copy needed.
    final joinedIds = ref.watch(myCircleIdsProvider).valueOrNull?.toSet() ?? {};
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Fetch recommendations once we have the joined-IDs list.
    if (!_recommendationsFetched && joinedIds.isNotEmpty) {
      _recommendationsFetched = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fetchRecommendations(joinedIds.toList()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Discover circles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: KeyboardDismissOnTap(
        child: TabBarView(
          controller: _tabController,
          children: [
            _BrowseTab(
              circles: _browseCircles,
              recommendations: _recommendations,
              loading: _loadingBrowse,
              selectedCategory: _selectedCategory,
              joinedIds: joinedIds,
              currentUid: currentUid,
              onCategoryChanged: (cat) {
                setState(() => _selectedCategory = cat);
                _fetchBrowse(category: cat);
              },
              onJoin: _joinOrRequest,
            ),
            _SearchTab(
              controller: _searchController,
              results: _searchResults,
              loading: _loadingSearch,
              joinedIds: joinedIds,
              currentUid: currentUid,
              onChanged: _onSearchChanged,
              onJoin: _joinOrRequest,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Browse tab ────────────────────────────────────────────────────────────────

class _BrowseTab extends StatelessWidget {
  const _BrowseTab({
    required this.circles,
    required this.recommendations,
    required this.loading,
    required this.selectedCategory,
    required this.joinedIds,
    required this.currentUid,
    required this.onCategoryChanged,
    required this.onJoin,
  });

  final List<AccountabilityCircle>? circles;
  final List<ScoredCircle> recommendations;
  final bool loading;
  final String selectedCategory;
  final Set<String> joinedIds;
  final String currentUid;
  final ValueChanged<String> onCategoryChanged;
  final Future<void> Function(AccountabilityCircle) onJoin;

  bool _isJoined(AccountabilityCircle circle) =>
      joinedIds.contains(circle.id) ||
      (currentUid.isNotEmpty && circle.creatorId == currentUid);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryChipRow(
          selected: selectedCategory,
          onChanged: onCategoryChanged,
        ),
        Expanded(
          child: loading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Recommendations section
                    if (recommendations.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'RECOMMENDED FOR YOU',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) => _RecommendedCircleCard(
                            scored: recommendations[i],
                            onJoin: onJoin,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ALL CIRCLES',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // All circles list
                    if (circles == null || circles!.isEmpty)
                      _EmptyState(
                        message: selectedCategory == 'all'
                            ? 'No circles yet. Create the first one!'
                            : 'No $selectedCategory circles yet.',
                      )
                    else
                      ...circles!.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CircleCard(
                            circle: c,
                            joined: _isJoined(c),
                            onJoin: onJoin,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecommendedCircleCard extends StatelessWidget {
  const _RecommendedCircleCard({required this.scored, required this.onJoin});

  final ScoredCircle scored;
  final Future<void> Function(AccountabilityCircle) onJoin;

  @override
  Widget build(BuildContext context) {
    final circle = scored.circle;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        CircleDetailScreen.routeName,
        arguments: circle.id,
      ),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    circle.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              scored.matchReason,
              style: TextStyle(color: AppColors.accent, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: AppColors.textMuted,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '${circle.memberCount}/${AccountabilityCircle.kMaxMembers}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onJoin(circle),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

class _CategoryChipRow extends StatelessWidget {
  const _CategoryChipRow({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _kAllCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _kAllCategories[i];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(
              cat[0].toUpperCase() + cat.substring(1),
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surfaceCard,
            side: BorderSide(
              color: isSelected
                  ? AppColors.accent
                  : AppColors.fg.withOpacity(0.06),
            ),
            onSelected: (_) => onChanged(cat),
          );
        },
      ),
    );
  }
}

// ── Search tab ────────────────────────────────────────────────────────────────

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.controller,
    required this.results,
    required this.loading,
    required this.joinedIds,
    required this.currentUid,
    required this.onChanged,
    required this.onJoin,
  });

  final TextEditingController controller;
  final List<AccountabilityCircle> results;
  final bool loading;
  final Set<String> joinedIds;
  final String currentUid;
  final ValueChanged<String> onChanged;
  final Future<void> Function(AccountabilityCircle) onJoin;

  bool _isJoined(AccountabilityCircle circle) =>
      joinedIds.contains(circle.id) ||
      (currentUid.isNotEmpty && circle.creatorId == currentUid);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onTapOutside: (_) => dismissKeyboard(context),
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search circles…',
              hintStyle: TextStyle(color: AppColors.textMuted),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.fg.withOpacity(0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.fg.withOpacity(0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : controller.text.isEmpty
              ? const _EmptyState(message: 'Start typing to search…')
              : results.isEmpty
              ? _EmptyState(
                  message: 'No circles found for "${controller.text}"',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => CircleCard(
                    circle: results[i],
                    joined: _isJoined(results[i]),
                    onJoin: onJoin,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Shared circle card ────────────────────────────────────────────────────────

class CircleCard extends StatefulWidget {
  const CircleCard({
    required this.circle,
    required this.onJoin,
    this.joined = false,
  });

  final AccountabilityCircle circle;
  final Future<void> Function(AccountabilityCircle) onJoin;
  final bool joined;

  @override
  State<CircleCard> createState() => _CircleCardState();
}

class _CircleCardState extends State<CircleCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final circle = widget.circle;
    final isFull = circle.memberCount >= AccountabilityCircle.kMaxMembers;
    final isJoined = widget.joined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fg.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  circle.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              _CategoryBadge(circle.category),
            ],
          ),
          if (circle.description != null && circle.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              circle.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.group_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${circle.memberCount}/${AccountabilityCircle.kMaxMembers}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  circle.timezone,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _PolicyBadge(circle.joinPolicy),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _joining
                  ? null
                  : () async {
                      if (isJoined) {
                        Navigator.pushNamed(
                          context,
                          CircleDetailScreen.routeName,
                          arguments: circle.id,
                        );
                        return;
                      }
                      if (isFull) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This circle is full (8/8 members).'),
                          ),
                        );
                        return;
                      }
                      setState(() => _joining = true);
                      await widget.onJoin(circle);
                      if (mounted) setState(() => _joining = false);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isJoined
                    ? AppColors.surfaceCard
                    : isFull
                    ? AppColors.surfaceCard
                    : AppColors.accent,
                foregroundColor: isJoined
                    ? AppColors.textMuted
                    : isFull
                    ? AppColors.textMuted
                    : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(40),
              ),
              child: _joining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      isJoined
                          ? 'Open'
                          : isFull
                          ? 'Full'
                          : circle.joinPolicy == JoinPolicy.open
                          ? 'Join'
                          : 'Request to join',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.category);
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PolicyBadge extends StatelessWidget {
  const _PolicyBadge(this.policy);
  final JoinPolicy policy;

  @override
  Widget build(BuildContext context) {
    final isOpen = policy == JoinPolicy.open;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 11,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Approval',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
      ),
    );
  }
}
