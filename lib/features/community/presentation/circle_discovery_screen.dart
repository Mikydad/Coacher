import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/circle_providers.dart';
import '../application/circle_recommendation_service.dart';
import '../application/user_circle_membership_service.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';
import 'circle_auth_guard.dart';
import 'circle_create_screen.dart';
import 'circle_detail_screen.dart';
import 'sheets/circle_join_code_sheet.dart';

import '../../../core/presentation/app_card.dart';
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
    actionLabel: 'join a group',
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
  // The repair is a background callable (up to a minute on a weak link);
  // access to the circle rests on the member doc, so navigation never waits
  // on it (2026-09-24).
  if (joinedIds.contains(circle.id) ||
      (uid.isNotEmpty && circle.creatorId == uid)) {
    _logDiscoveryJoin('Already joined (index or creator) — opening circle');
    if (!joinedIds.contains(circle.id)) {
      unawaited(service.ensureCircleIndex(circle.id));
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
    unawaited(service.ensureCircleIndex(circle.id));
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

  Future<void> _createCircle() async {
    // Creating a circle requires a real identity (same guard as the tab).
    if (!await ensureRegisteredForCircleAction(
      context,
      ref,
      actionLabel: 'create a group',
    )) {
      return;
    }
    if (mounted) Navigator.pushNamed(context, CircleCreateScreen.routeName);
  }

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
      backgroundColor: AppColors.scaffold,
      // Same "+ Circle" as the Community tab (Miko, 2026-09-19): someone
      // browsing and not finding their circle should be one tap from
      // starting it.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'discover_circle_fab',
        onPressed: _createCircle,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Group',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        title: const PageTitle('Discover groups'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Join with a key',
            icon: const Icon(Icons.key_rounded),
            onPressed: () => showJoinWithCodeSheet(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.divider,
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Recommendations section
                    if (recommendations.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: AppSectionLabel('RECOMMENDED FOR YOU'),
                      ),
                      SizedBox(
                        height: 150,
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
                      const SizedBox(height: 24),
                      const AppSectionLabel('ALL GROUPS'),
                      const SizedBox(height: 12),
                    ],
                    // All circles list
                    if (circles == null || circles!.isEmpty)
                      _EmptyState(
                        message: selectedCategory == 'all'
                            ? 'No groups yet. Create the first one!'
                            : 'No $selectedCategory groups yet.',
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
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfacePanel,
          borderRadius: BorderRadius.circular(20),
          boxShadow: appCardShadow,
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
                      fontSize: 15,
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Join',
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 12,
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
    // Pills (redesign 2026-09-15): olive when selected, white with the
    // shared shadow otherwise — no chip borders.
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        itemCount: _kAllCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _kAllCategories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surfacePanel,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isSelected ? null : appCardShadow,
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.onAccent,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat[0].toUpperCase() + cat.substring(1),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.onAccent
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: appCardShadow,
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTapOutside: (_) => dismissKeyboard(context),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search groups…',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfacePanel,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                ),
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
                  message: 'No groups found for "${controller.text}"',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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

    // Redesign 2026-09-15: white card with the shared shadow, no hairline.
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfacePanel,
        borderRadius: BorderRadius.circular(24),
        boxShadow: appCardShadow,
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
                    fontSize: 17,
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                            content: Text('This group is full (8/8 members).'),
                          ),
                        );
                        return;
                      }
                      setState(() => _joining = true);
                      await widget.onJoin(circle);
                      if (mounted) setState(() => _joining = false);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isJoined || isFull
                    ? AppColors.surfaceLight
                    : AppColors.accent,
                foregroundColor: isJoined || isFull
                    ? AppColors.textPrimary
                    : AppColors.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              child: _joining
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onAccent,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.actionTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Approval',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: AppDashedEmptyState(message: message),
      ),
    );
  }
}
