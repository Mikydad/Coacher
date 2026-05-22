# Tasks — Accountability Circles Phase 1: Foundation

> PRD reference: `PRD/Chat_feature/prd-accountability-circles.md`
>
> **Safety contract:** Every group is additive-only. No existing files are modified except:
> - `lib/core/firebase/firestore_paths.dart` — new static methods appended
> - `lib/app/app.dart` — new route entries appended
> - `lib/features/home/presentation/home_screen.dart` — Community tab wired
> - `lib/core/di/providers.dart` — new provider registrations appended
>
> No existing logic, provider, screen, or model is changed. All new code lives under
> `lib/features/community/` and `test/features/community/`.

---

## Group 1.1 — Domain Models + Firestore Paths

**Pure Dart. No Flutter, no Firebase, no Riverpod. Safe to write first.**

### Files to create

#### `lib/features/community/domain/models/circle_enums.dart`
- `enum JoinPolicy { open, requestApproval }` with `storageValue` + `fromStorage`
- `enum CircleVisibility { public, private }` with `storageValue` + `fromStorage`
- `enum CircleMemberRole { member, moderator }` with `storageValue` + `fromStorage`
- `enum CircleMemberStatus { active, pending, removed }` with `storageValue` + `fromStorage`
- `enum MessageType { text, image, activityUpdate, systemEvent }` with `storageValue` + `fromStorage`
- `enum ActivityEventType { goalCompleted, habitStreakReached, taskFinished, challengeProgressUpdated, milestoneReached, weeklyCommitmentMet, memberJoined, memberLeft }` with `storageValue` + `fromStorage`

Pattern: follow existing `GoalStatus` / `GoalHorizon` enum pattern from
`lib/features/goals/domain/models/goal_enums.dart`.

#### `lib/features/community/domain/models/accountability_circle.dart`
```dart
class AccountabilityCircle {
  const AccountabilityCircle({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.joinPolicy,
    required this.visibility,
    required this.creatorId,
    required this.moderatorIds,
    required this.memberCount,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.timezone,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  static const int kMaxMembers = 8;
  static const int kMinMembers = 4;

  final String id;
  final String name;
  final String? description;
  final String category;
  final JoinPolicy joinPolicy;
  final CircleVisibility visibility;
  final String creatorId;
  final List<String> moderatorIds;
  final int memberCount;
  final int currentStreak;
  final int longestStreak;
  final String timezone;
  final int createdAtMs;
  final int updatedAtMs;
  // toMap / fromMap / copyWith / validate()
}
```
`validate()`: name 3–40 chars, category not empty, memberCount 0–8.

#### `lib/features/community/domain/models/circle_member.dart`
Fields: `userId`, `circleId`, `displayName`, `role`, `status`, `joinedAtMs`, `updatedAtMs`.
`toMap` / `fromMap` / `copyWith`.

#### `lib/features/community/domain/models/circle_message.dart`
Fields: `id`, `circleId`, `senderId`, `senderDisplayName`, `type`, `content`, `imageUrl`,
`activityRef`, `reactions` (`Map<String, List<String>>`), `createdAtMs`.
`toMap` / `fromMap` / `copyWith`.
Note: `reactions` serializes as `Map<String, List<dynamic>>` in Firestore.

#### `lib/features/community/domain/models/activity_feed_item.dart`
Fields: `id`, `circleId`, `userId`, `displayName`, `eventType`, `entityId`, `entityTitle`,
`value`, `dateKey` (for idempotency: `'yyyy-MM-dd'`), `createdAtMs`.
`toMap` / `fromMap` / `copyWith`.

### Files to modify (append only)

#### `lib/core/firebase/firestore_paths.dart`
Add at bottom of class (do not touch existing methods):
```dart
// ── Community / Accountability Circles ──────────────────────────────────────
static String get circles => 'circles';
static String circleDoc(String circleId) => 'circles/$circleId';
static String circleMembers(String circleId) => 'circles/$circleId/members';
static String circleMemberDoc(String circleId, String userId) =>
    'circles/$circleId/members/$userId';
static String circleMessages(String circleId) => 'circles/$circleId/messages';
static String circleActivityFeed(String circleId) =>
    'circles/$circleId/activityFeed';
static String userCircleIds(String uid) => 'users/$uid/circleIds';
static String userCircleIdDoc(String uid, String circleId) =>
    'users/$uid/circleIds/$circleId';
```

### Tests to create

#### `test/features/community/accountability_circle_model_test.dart`
- `toMap` → `fromMap` round-trip
- `validate()` rejects name < 3 chars, name > 40 chars, memberCount > 8

#### `test/features/community/circle_member_model_test.dart`
- `toMap` → `fromMap` round-trip
- enum `storageValue` + `fromStorage` for all enum types

#### `test/features/community/circle_message_model_test.dart`
- `toMap` → `fromMap` round-trip including nested `reactions` map

#### `test/features/community/activity_feed_item_model_test.dart`
- `toMap` → `fromMap` round-trip
- All `ActivityEventType` storage values round-trip

---

## Group 1.2 — Repository Layer

**Pure interfaces + Firestore implementations. No UI. Depends on Group 1.1.**

### Files to create

#### `lib/features/community/data/circle_repository.dart`
```dart
abstract class CircleRepository {
  Stream<AccountabilityCircle?> watchCircle(String circleId);
  Stream<List<AccountabilityCircle>> watchCircles(List<String> circleIds);
  Future<AccountabilityCircle?> getCircle(String circleId);
  Future<void> createCircle(AccountabilityCircle circle);
  Future<void> updateCircle(AccountabilityCircle circle);
  Future<List<AccountabilityCircle>> searchCircles({String? query, String? category});
}

class FirestoreCircleRepository implements CircleRepository { ... }
```
`searchCircles`: Firestore query on `circles` collection filtered by `category` field.
`watchCircles`: uses `whereIn` on the `id` field (max 10 in Firestore `whereIn`, handle chunking
if > 10 circle ids — V1 max is 3, so no chunking needed).

#### `lib/features/community/data/circle_member_repository.dart`
```dart
abstract class CircleMemberRepository {
  Stream<List<CircleMember>> watchMembers(String circleId);
  Future<CircleMember?> getMember(String circleId, String userId);
  Future<void> setMember(CircleMember member);
  Future<void> deleteMember(String circleId, String userId);
}

class FirestoreCircleMemberRepository implements CircleMemberRepository { ... }
```
`watchMembers`: orders by `joinedAtMs` ascending.

#### `lib/features/community/data/circle_message_repository.dart`
```dart
abstract class CircleMessageRepository {
  Stream<List<CircleMessage>> watchMessages(String circleId, {int limit = 50});
  Future<void> sendMessage(CircleMessage message);
  Future<void> updateReactions(
    String circleId,
    String messageId,
    Map<String, List<String>> reactions,
  );
}

class FirestoreCircleMessageRepository implements CircleMessageRepository { ... }
```
`watchMessages`: orders by `createdAtMs` descending, limited to `limit`.
Use `FirebaseFirestore.instance.collection(...)` directly (same pattern as
`FirestoreGoalsRepository`).

### Tests to create

#### `test/features/community/circle_repository_test.dart`
Use `fake_cloud_firestore` package (already in pubspec if used elsewhere, else add).
- `createCircle` → `getCircle` returns same data
- `watchCircles` emits update after `updateCircle`
- `searchCircles` filters by category

#### `test/features/community/circle_member_repository_test.dart`
- `setMember` (active) → `watchMembers` includes it
- `deleteMember` → `watchMembers` excludes it

#### `test/features/community/circle_message_repository_test.dart`
- `sendMessage` → `watchMessages` emits the message
- Ordering: newer message appears first in stream

---

## Group 1.3 — Riverpod Providers

**Depends on Groups 1.1 + 1.2. No UI. Pure Riverpod wiring.**

### Files to create

#### `lib/features/community/application/circle_providers.dart`
```dart
// Repositories
final circleRepositoryProvider = Provider<CircleRepository>(...)
final circleMemberRepositoryProvider = Provider<CircleMemberRepository>(...)
final circleMessageRepositoryProvider = Provider<CircleMessageRepository>(...)

// My circles
final myCircleIdsProvider = FutureProvider<List<String>>(...)
  // reads users/{uid}/circleIds collection, returns list of circleIds

final myCirclesProvider = StreamProvider<List<AccountabilityCircle>>(...)
  // watches circleIds from myCircleIdsProvider, then watchCircles(ids)

// Per-circle
final circleDetailProvider =
    StreamProvider.family<AccountabilityCircle?, String>(...)

final circleMembersProvider =
    StreamProvider.family<List<CircleMember>, String>(...)

final circleMessagesProvider =
    StreamProvider.family<List<CircleMessage>, String>(...)

final circleActiveTabProvider =
    StateProvider.family<int, String>((ref, circleId) => 0);
```

### Tests to create

#### `test/features/community/circle_providers_test.dart`
- `myCirclesProvider` emits empty list when no circles
- `circleDetailProvider` emits circle after creation
- All providers resolve without throwing

---

## Group 1.4 — Membership Service

**Depends on Groups 1.1–1.3. Pure Dart service. No UI.**

### Files to create

#### `lib/features/community/application/user_circle_membership_service.dart`
```dart
class UserCircleMembershipService {
  UserCircleMembershipService({
    required CircleRepository circleRepo,
    required CircleMemberRepository memberRepo,
    required String Function() currentUserId,
    required String Function() currentDisplayName,
  });

  static const int kMaxCirclesPerUser = 3;

  /// Join an open circle immediately.
  /// Throws [CircleLimitException] if user already in 3 circles.
  /// Throws [CircleFullException] if circle.memberCount >= 8.
  Future<void> joinCircle(String circleId) async { ... }

  /// Request to join an approval-required circle.
  /// Sets member status = pending.
  Future<void> requestJoin(String circleId) async { ... }

  /// Approve a pending member (moderator only).
  Future<void> approveJoin(String circleId, String userId) async { ... }

  /// Decline a pending request.
  Future<void> declineJoin(String circleId, String userId) async { ... }

  /// Leave a circle. Decrements memberCount on circle doc.
  Future<void> leaveCircle(String circleId) async { ... }

  /// Direct removal (Phase 1: creator only).
  Future<void> removeMember(String circleId, String userId) async { ... }

  /// How many circles the current user is in.
  Future<int> myCircleCount() async { ... }
}

class CircleLimitException implements Exception {}
class CircleFullException implements Exception {}
```

Implementation notes:
- `joinCircle` / `requestJoin`: write to `circleMembers/{userId}` AND
  `users/{uid}/circleIds/{circleId}` in the same Firestore batch.
- `joinCircle` increments `memberCount` on the circle doc (use a Firestore
  transaction to read-then-increment safely).
- `leaveCircle`: delete both docs, decrement `memberCount`.
- `myCircleCount`: count docs in `users/{uid}/circleIds`.

### Files to modify (append only)

#### `lib/core/di/providers.dart`
Append at end:
```dart
final userCircleMembershipServiceProvider =
    Provider<UserCircleMembershipService>((ref) {
  return UserCircleMembershipService(
    circleRepo: ref.read(circleRepositoryProvider),
    memberRepo: ref.read(circleMemberRepositoryProvider),
    currentUserId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
    currentDisplayName: () =>
        FirebaseAuth.instance.currentUser?.displayName ?? 'User',
  );
});
```

### Tests to create

#### `test/features/community/user_circle_membership_service_test.dart`
Use fake repos:
- `joinCircle` writes member doc + circleId doc
- `joinCircle` throws `CircleLimitException` when count = 3
- `joinCircle` throws `CircleFullException` when memberCount = 8
- `leaveCircle` removes both docs and decrements memberCount
- `approveJoin` changes status from pending → active
- `myCircleCount` returns correct count

---

## Group 1.5 — Circle Creation Screen

**Depends on Groups 1.1–1.4. New screen, no existing screen modified.**

### Files to create

#### `lib/features/community/presentation/circle_create_screen.dart`

Widget: `CircleCreateScreen extends ConsumerStatefulWidget`
Route: `static const routeName = '/community/create';`

Form fields:
- `TextFormField` for name (validator: 3–40 chars, required)
- Optional `TextFormField` for description
- Category selector: `Wrap` of `ChoiceChip` using these categories:
  `['fitness', 'learning', 'business', 'reading', 'productivity', 'other']`
- `SegmentedButton<JoinPolicy>` for join policy (Open / Approval)
- `SegmentedButton<CircleVisibility>` for visibility (Public / Private)
- Timezone: auto-detect from `DateTime.now().timeZoneName` (display-only in V1)

On save:
1. Validate form
2. Build `AccountabilityCircle` with new `StableId.generate('circle')`
3. Call `circleRepositoryProvider.createCircle(circle)`
4. Call `userCircleMembershipServiceProvider.joinCircle(circleId)` — but skip the
   limit check for the creator (creator creates the circle, so use a direct
   `setMember` call with `role = moderator, status = active`)
5. Invalidate `myCirclesProvider`
6. `Navigator.pushReplacementNamed(context, CircleDetailScreen.routeName, arguments: circleId)`

Design: Obsidian Pulse — dark scaffold, `Color(0xFF14171C)` card background, `Color(0xFFB7FF00)` save button.

### Tests to create

#### `test/features/community/circle_create_screen_test.dart`
Widget test with provider overrides (fake repo, fake membership service):
- Renders all form fields
- Validates: save with empty name shows error
- Validates: save with name < 3 chars shows error
- Successful save calls `createCircle` once

---

## Group 1.6 — Circle Discovery Screen

**Depends on Groups 1.1–1.3. New screen.**

### Files to create

#### `lib/features/community/presentation/circle_discovery_screen.dart`

Widget: `CircleDiscoveryScreen extends ConsumerStatefulWidget`
Route: `static const routeName = '/community/discover';`

Structure:
- `TabBar` with two tabs: Browse | Search
- **Browse tab**: `GridView` of `_CircleCard` widgets, grouped by category chips at top
  - Category chip row (All / Fitness / Learning / etc.) → filters the list
  - `_CircleCard`: circle name, category badge, `${memberCount}/${kMaxMembers} members`,
    timezone, join policy label, Join / Request button
  - Join button: calls `UserCircleMembershipService.joinCircle` or `requestJoin`
  - Shows `SnackBar` on `CircleLimitException` or `CircleFullException`
- **Search tab**: `TextField` → debounced query → `circleRepositoryProvider.searchCircles`
  - Results shown as same `_CircleCard` list
  - Empty state: "No circles found for '…'"

### Tests to create

#### `test/features/community/circle_discovery_screen_test.dart`
- Renders Browse tab by default
- Tapping Search tab shows search field
- Circle cards display name + member count

---

## Group 1.7 — Circle Detail Screen Shell

**Depends on Groups 1.1–1.3. New screen shell only — tabs are added in subsequent groups.**

### Files to create

#### `lib/features/community/presentation/circle_detail_screen.dart`

Widget: `CircleDetailScreen extends ConsumerStatefulWidget`
Route: `static const routeName = '/community/circle';`
Args: `String circleId` passed via `ModalRoute.of(context)?.settings.arguments`

Structure:
- Custom `SliverAppBar` with circle name, streak badge (`🔥 N days`), member count
- Row of up to 8 member avatar initials (pull from `circleMembersProvider`)
- `TabBar` at bottom of header: Chat | Activity | Commitments | Challenges | Members | Info
- `TabBarView` body — each tab returns a placeholder `Center(child: Text('Coming soon'))`
  in Group 1.7; real views wired in subsequent groups

Header design: glassmorphism card with `BackdropFilter(blur: 12)`.

---

## Group 1.8 — Chat Tab

**Depends on Group 1.7. Fills the Chat tab in `CircleDetailScreen`.**

### Files to create

#### `lib/features/community/presentation/views/circle_chat_view.dart`

Widget: `CircleChatView extends ConsumerStatefulWidget`
Takes: `String circleId`

Structure:
- `StreamBuilder` / `ref.watch(circleMessagesProvider(circleId))`
- Messages list (`ListView.builder`, `reverse: true`) with:
  - **Text bubble** (`_TextMessageBubble`): avatar initial (colored by userId hash),
    sender name, message content, timestamp, reactions row
  - **Image bubble** (`_ImageMessageBubble`): same header + proof category label +
    `Image.network` thumbnail
  - **System pill** (`_SystemEventPill`): centred grey rounded pill for
    `MessageType.systemEvent`
- Input row at bottom:
  - `TextField` for text
  - Image pick icon (opens `_ProofImageCategorySheet` bottom sheet with 5 categories)
  - Send button (disabled when text empty and no image selected)
- Long-press on message → `_EmojiReactionBar` overlay with 6 emojis:
  `['🔥', '💪', '👏', '✅', '😅', '❤️']`
  Tapping an emoji calls `circleMessageRepositoryProvider.updateReactions(...)`

Image upload:
- Use `image_picker` (already likely in pubspec — check; if not, note as dependency)
- Upload to `Firebase Storage` at `circles/{circleId}/proofs/{uuid}.jpg`
- Then send message with `type = image`, `imageUrl = downloadUrl`

**Dependency check**: If `image_picker` and `firebase_storage` are not in `pubspec.yaml`,
add them before implementing. Do not add packages silently — list additions in the
commit message.

### Tests to create

#### `test/features/community/circle_chat_view_test.dart`
Widget test with overridden `circleMessagesProvider`:
- Text messages render sender name + content
- System event renders as pill (not a bubble)
- Empty state shown when no messages
- Send button disabled when text field empty

---

## Group 1.9 — Members Tab

**Depends on Group 1.7. Fills the Members tab.**

### Files to create

#### `lib/features/community/presentation/views/circle_members_view.dart`

Widget: `CircleMembersView extends ConsumerStatefulWidget`
Takes: `String circleId`

Structure:
- `ref.watch(circleMembersProvider(circleId))` for active + pending members
- **Pending section** (moderator only): `if (isModerator)` — list of pending members
  with Approve / Decline buttons
  - Approve: calls `UserCircleMembershipService.approveJoin`
  - Decline: calls `UserCircleMembershipService.declineJoin`
- **Active members section**: list of `_MemberTile`
  - Avatar initial, display name, role badge ("Moderator"), join date
  - Long-press (creator only, on non-creator members): shows "Remove member" option
    Phase 1: direct removal via `UserCircleMembershipService.removeMember`
    (voting deferred to Phase 3)

`isModerator` check: current user uid is in `circle.moderatorIds`.

### Tests to create

#### `test/features/community/circle_members_view_test.dart`
- Active members displayed
- Pending section hidden for non-moderators
- Approve/Decline buttons present for moderators in pending section

---

## Group 1.10 — Navigation Wiring

**Touches existing files but only appends/adds. No logic changes to existing code.**

### Files to create

#### `lib/features/community/presentation/community_screen.dart`

Widget: `CommunityScreen extends ConsumerStatefulWidget`
Route: `static const routeName = '/community';`

Structure:
- Shows `ref.watch(myCirclesProvider)` list
  - `AsyncValue.loading` → `CircularProgressIndicator`
  - `AsyncValue.error` → error message
  - empty data → "You're not in any circles yet" empty state with two buttons:
    Create a circle | Discover circles
  - data → `ListView` of `_MyCircleCard` (name, member count, streak, category badge)
    → taps navigate to `CircleDetailScreen`
- `FloatingActionButton.extended` with `+` label → bottom sheet with two options:
  "Create circle" → `CircleCreateScreen`
  "Discover circles" → `CircleDiscoveryScreen`

### Files to modify (append only)

#### `lib/app/app.dart`
Add imports for new screens at top.
Append to the `routes` map:
```dart
CommunityScreen.routeName: (_) => const CommunityScreen(),
CircleCreateScreen.routeName: (_) => const CircleCreateScreen(),
CircleDiscoveryScreen.routeName: (_) => const CircleDiscoveryScreen(),
CircleDetailScreen.routeName: (context) {
  final id = ModalRoute.of(context)?.settings.arguments as String? ?? '';
  return CircleDetailScreen(circleId: id);
},
```

#### `lib/features/home/presentation/home_screen.dart`
The Community tab already exists in the bottom nav label list but may navigate
nowhere. Wire the Community nav item to push `CommunityScreen.routeName`.

**Change is isolated**: only the `onTap` / navigation logic for the Community
index is added. No other tabs, state, or widgets are touched.

### Tests to create

#### `test/features/community/community_screen_test.dart`
Widget test:
- Empty state renders "not in any circles" message
- My circle card renders circle name
- FAB shows create/discover options

---

## Cross-cutting Concerns for Phase 1

### Error handling pattern
All service calls that can fail (`joinCircle`, `createCircle`, etc.) wrap in
`try/catch` in the calling widget and show `ScaffoldMessenger.of(context).showSnackBar`.
No global error handler changes needed.

### Offline behaviour
Phase 1 does not add Isar caching for circles (Isar cache is Phase 2+).
Offline users will see the Firestore SDK's own offline cache for reads, but
writes will be queued by Firestore's offline support automatically.
No `SyncService` changes needed for Phase 1.

### Auth guard
All community screens assume user is authenticated (same assumption as all other
screens in this app). No auth middleware changes needed.

### Firestore Security Rules (note for backend)
New rules needed for `circles/`, `circles/{id}/members/`, `circles/{id}/messages/`:
- Read: authenticated users
- Write to circle: authenticated user must be member
- Write to messages: authenticated user must be active member
These are backend rules, not app code — document separately if deploying to prod.

### Dependency additions (check before implementing)
- `image_picker`: for proof image upload in chat (Group 1.8)
- `firebase_storage`: for proof image upload (Group 1.8)
Check `pubspec.yaml` before Group 1.8. If missing, add with `flutter pub add`.

---

## Phase 1 Completion Checklist

- [ ] 1.1 All 4 domain models + enums created, tests pass
- [ ] 1.1 `firestore_paths.dart` extended with circle paths (no existing paths touched)
- [ ] 1.2 3 repository interfaces + Firestore implementations created
- [ ] 1.2 Repository tests pass
- [ ] 1.3 All 8 Riverpod providers created, provider tests pass
- [ ] 1.4 `UserCircleMembershipService` created with all 6 methods
- [ ] 1.4 Membership service tests pass (limit enforcement, full circle rejection)
- [ ] 1.4 `userCircleMembershipServiceProvider` appended to `providers.dart`
- [ ] 1.5 `CircleCreateScreen` created, widget tests pass
- [ ] 1.6 `CircleDiscoveryScreen` created, widget tests pass
- [ ] 1.7 `CircleDetailScreen` shell with 6-tab structure (placeholders ok)
- [ ] 1.8 `CircleChatView` with text/image/reaction/system-event support
- [ ] 1.8 Dependency packages confirmed in pubspec
- [ ] 1.9 `CircleMembersView` with pending approval (moderator) + removal (creator)
- [ ] 1.10 `CommunityScreen` created, nav wired
- [ ] 1.10 `app.dart` routes appended (4 new routes)
- [ ] 1.10 `home_screen.dart` Community tab navigates to CommunityScreen
- [ ] `flutter analyze` — 0 issues across all new files
- [ ] All tests green
