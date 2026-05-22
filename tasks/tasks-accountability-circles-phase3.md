# Tasks — Accountability Circles Phase 3: Challenges + Circle Streaks + Removal Voting

> PRD reference: `PRD/Chat_feature/prd-accountability-circles.md`
> Prerequisite: Phase 2 complete and all tests green.
>
> **Safety contract:** Phase 3 extends Phase 2's bridge service by adding a new
> `ChallengeProgressSyncService`. The existing `CircleActivityBridgeService` is not
> modified; the challenge sync is a separate service started alongside it.
> No existing domain models, repositories, or screens outside `community/` are touched.

---

## Group 3.1 — Challenge Domain + Repository

**Pure Dart + Firestore. No UI.**

### Files to create

#### `lib/features/community/domain/models/challenge.dart`
```dart
class Challenge {
  const Challenge({
    required this.id,
    required this.circleId,
    required this.creatorId,
    required this.title,
    required this.mode,
    required this.status,
    required this.targetValue,
    required this.unit,
    this.memberProgress = const {},
    this.teamTotal = 0,
    required this.startsAtMs,
    required this.endsAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  // validate(): title not empty, targetValue > 0, endsAtMs > startsAtMs
  // toMap / fromMap / copyWith
}

enum ChallengeMode { competition, team }
enum ChallengeStatus { pending, active, completed, rejected }
// Both with storageValue + fromStorage
```

#### `lib/features/community/domain/models/challenge_vote.dart`
```dart
class ChallengeVote {
  const ChallengeVote({
    required this.challengeId,
    required this.userId,
    required this.approve,
    required this.createdAtMs,
  });
  // toMap / fromMap
}
```

#### `lib/features/community/data/challenge_repository.dart`
```dart
abstract class ChallengeRepository {
  Stream<List<Challenge>> watchChallenges(String circleId);
  Future<Challenge?> getChallenge(String challengeId);
  Future<void> createChallenge(Challenge challenge);
  Future<void> updateChallenge(Challenge challenge);

  /// Increment memberProgress for userId by delta.
  Future<void> updateProgress({
    required String circleId,
    required String challengeId,
    required String userId,
    required int delta,
  });

  /// Cast a vote (approve/reject).
  Future<void> vote({
    required String challengeId,
    required String circleId,
    required String userId,
    required bool approve,
  });

  /// Get all votes for a challenge.
  Future<List<ChallengeVote>> getVotes(String challengeId);
}

class FirestoreChallengeRepository implements ChallengeRepository {
  // challenges stored at: circles/{circleId}/challenges/{challengeId}
  // votes stored at: circles/{circleId}/challenges/{challengeId}/votes/{userId}
  // updateProgress: Firestore transaction to safely increment
  // vote: sets doc + checks if majority reached; if so, updates challenge status to active
}
```

Majority rule implementation in `vote()`:
```
votesSnap = getVotes(challengeId)
approvalsCount = votesSnap.where(v => v.approve).length
memberCount = circle.memberCount
if (approvalsCount > memberCount / 2) → updateChallenge(status: active)
if (rejectionsCount > memberCount / 2) → updateChallenge(status: rejected)
```

Append to `FirestorePaths`:
```dart
static String circleChallenges(String circleId) =>
    'circles/$circleId/challenges';
static String challengeVotes(String circleId, String challengeId) =>
    'circles/$circleId/challenges/$challengeId/votes';
```

### Tests to create

#### `test/features/community/challenge_model_test.dart`
- `toMap`/`fromMap` round-trip for `Challenge` and `ChallengeVote`
- `validate()` rejects `targetValue = 0`, `endsAtMs < startsAtMs`
- Enum `storageValue`/`fromStorage` for `ChallengeMode`, `ChallengeStatus`

#### `test/features/community/challenge_repository_test.dart`
- `createChallenge` → `watchChallenges` emits it
- `updateProgress` increments `memberProgress[userId]`
- Voting: 3 approvals in 5-member circle → status flips to `active`
- Voting: 3 rejections in 5-member circle → status flips to `rejected`

---

## Group 3.2 — Challenge Creation + Voting Flow

**Depends on Group 3.1. New UI components.**

### Files to create

#### `lib/features/community/presentation/sheets/challenge_create_sheet.dart`

Widget: `ChallengeCreateSheet extends ConsumerStatefulWidget`
Shown as `showModalBottomSheet` from `CircleChallengesView`.

Form:
- `TextFormField` — challenge title (required, 3–60 chars)
- `SegmentedButton<ChallengeMode>` — Competition / Team
- `TextFormField` (number) — target value (e.g. 30)
- `TextFormField` — unit (e.g. "miles", "sessions")
- Date range pickers — start date, end date

On save:
1. Validate form
2. Build `Challenge` with `status = ChallengeStatus.pending`, `memberProgress = {}`
3. Call `challengeRepositoryProvider.createChallenge(challenge)`
4. Dismiss sheet
5. Show `SnackBar`: "Challenge submitted — waiting for member votes"

#### `lib/features/community/presentation/widgets/challenge_vote_banner.dart`

Widget: `ChallengeVoteBanner extends ConsumerStatefulWidget`
Takes: `Challenge challenge`, `String circleId`

Shown at the top of `CircleChallengesView` when `challenge.status == ChallengeStatus.pending`.

Structure:
- Banner card: challenge title, creator name, "N members voted"
- Two buttons: ✅ Approve | ❌ Reject
- Disabled after current user already voted (check via `getVotes`)
- On vote: calls `challengeRepositoryProvider.vote(...)` → optimistic UI disable

### Tests to create

#### `test/features/community/challenge_create_sheet_test.dart`
Widget test:
- All form fields render
- Save with empty title shows validator error
- Valid form calls `createChallenge` once

#### `test/features/community/challenge_vote_banner_test.dart`
- Shows approve/reject buttons for pending challenge
- Buttons disabled after user voted
- Does not show for non-pending challenges

---

## Group 3.3 — Challenge Progress UI

**Depends on Groups 3.1 + 3.2. Fills the Challenges tab.**

### Files to create

#### `lib/features/community/application/challenge_providers.dart`
```dart
final challengeRepositoryProvider = Provider<ChallengeRepository>(...);

final circleChallengesProvider =
    StreamProvider.family<List<Challenge>, String>((ref, circleId) {
  return ref.watch(challengeRepositoryProvider).watchChallenges(circleId);
});

final activeChallengesProvider =
    Provider.family<AsyncValue<List<Challenge>>, String>((ref, circleId) {
  return ref.watch(circleChallengesProvider(circleId)).whenData(
    (list) => list.where((c) => c.status == ChallengeStatus.active).toList(),
  );
});

final pendingChallengesProvider =
    Provider.family<AsyncValue<List<Challenge>>, String>((ref, circleId) {
  return ref.watch(circleChallengesProvider(circleId)).whenData(
    (list) => list.where((c) => c.status == ChallengeStatus.pending).toList(),
  );
});
```

#### `lib/features/community/presentation/views/circle_challenges_view.dart`

Widget: `CircleChallengesView extends ConsumerStatefulWidget`
Takes: `String circleId`

Structure:
- **Pending section**: `ChallengeVoteBanner` for each pending challenge
- **Active challenges list**:
  - `_CompetitionChallengeCard` (competition mode):
    - Title, unit, end date countdown
    - Ranked list: `#1 Mike — 8/30`, `#2 Sarah — 7/30`, `#3 David — 5/30`
    - Current user's row highlighted with accent color
  - `_TeamChallengeCard` (team mode):
    - Title, unit, end date countdown
    - `LinearProgressIndicator` showing `teamTotal / targetValue`
    - Label: `137/200 miles`
    - Member contribution breakdown (compact chips)
  - Manual update button (for challenges with no linked entity):
    - Opens `_ManualProgressSheet`: numeric input + optional proof image
    - Proof image upload → Firebase Storage → message posted to chat
- **Completed challenges**: collapsed section with past challenge results
- FAB: "New Challenge" → opens `ChallengeCreateSheet`

### Tests to create

#### `test/features/community/circle_challenges_view_test.dart`
- Pending challenges show vote banners
- Competition card shows ranked list
- Team card shows progress bar with correct label
- Manual update button present for standalone challenges

---

## Group 3.4 — Challenge Progress Auto-Sync

**Reads from existing systems. Does NOT modify any existing write paths.**

### Files to create

#### `lib/features/community/application/challenge_progress_sync_service.dart`
```dart
class ChallengeProgressSyncService {
  ChallengeProgressSyncService({
    required ChallengeRepository challengeRepo,
    required UserCircleMembershipService membershipSvc,
    required String Function() currentUserId,
  });

  /// Start listening. Returns dispose callback.
  VoidCallback start(ProviderContainer container) { ... }
}
```

**What it observes (read-only)**:

| Existing provider | Matching rule | Action |
|---|---|---|
| `todayAllTasksRowsProvider` | Task completed → match challenge `unit` against task category | Increment `memberProgress[userId]` by 1 |
| `goalsStreamProvider` (check-ins) | Goal check-in `metCommitment = true` → match challenge `unit` against goal category | Increment by 1 |
| `habitStreakSummaryProvider` | Any habit completion event | Match against active team challenges |

**Matching logic** (pure Dart, testable):
```dart
bool _matchesChallengeUnit(String entityCategory, String challengeUnit) {
  // Fuzzy match: 'fitness' category matches 'workout', 'miles', 'sessions'
  // 'learning' matches 'pages', 'sessions', 'chapters'
  // Exact match on unit string as fallback
}
```

**Auto-override rule**: if an entity is auto-linked to a challenge, manual updates for
that challenge by that user are ignored (always use the auto value).
Store flag: `challenges/{id}/memberAutoLinked/{userId}: true`

**Wiring**: appended to `app_bootstrap.dart` alongside `CircleActivityBridgeService`.

### Tests to create

#### `test/features/community/challenge_progress_sync_service_test.dart`
- Task completion in 'fitness' category → increments fitness challenge progress
- Goal check-in for 'reading' goal → increments reading challenge
- Auto-linked user: manual update ignored (service does not decrement)
- Non-matching category → no increment

---

## Group 3.5 — Circle Streak

**Extends circle data model. New service.**

### Files to modify (append only)

#### `lib/features/community/domain/models/accountability_circle.dart`
The `currentStreak`, `longestStreak`, and `lastActiveDate` fields were already added
in Phase 1. Confirm they are present. If not, add via `copyWith` extension (no breaking
change since they have defaults of 0 / null).

### Files to create

#### `lib/features/community/application/circle_streak_service.dart`
```dart
class CircleStreakService {
  CircleStreakService({
    required CircleRepository circleRepo,
    required ActivityFeedRepository feedRepo,
  });

  /// Called once per day (on app foreground after midnight).
  /// Evaluates all circles the user is in and updates streak counts.
  Future<void> evaluateStreaks(List<String> circleIds) async {
    for (final circleId in circleIds) {
      await _evaluateCircle(circleId);
    }
  }

  Future<void> _evaluateCircle(String circleId) async {
    final circle = await circleRepo.getCircle(circleId);
    if (circle == null) return;

    final todayKey = DateKeys.todayKey();
    // Count distinct userIds with feed items today
    final todayFeed = await feedRepo.watchFeed(circleId).first;
    final activeUserIds = todayFeed
        .where((item) => item.dateKey == todayKey)
        .map((item) => item.userId)
        .toSet();

    final threshold = (circle.memberCount * 0.6).ceil();
    if (activeUserIds.length >= threshold) {
      // Increment streak
      final newStreak = circle.currentStreak + 1;
      await circleRepo.updateCircle(
        circle.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > circle.longestStreak
              ? newStreak
              : circle.longestStreak,
        ),
      );
    } else {
      // Break streak
      await circleRepo.updateCircle(
        circle.copyWith(currentStreak: 0),
      );
    }
  }
}
```

Wiring: call `circleStreakService.evaluateStreaks(myCircleIds)` in `app_bootstrap.dart`
on app foreground, after the activity bridge starts (append only).

Streak shown on `CircleDetailScreen` header — already reads `circle.currentStreak`
from the `circleDetailProvider`. No additional UI changes needed.

### Tests to create

#### `test/features/community/circle_streak_service_test.dart`
- 5/8 members active (62.5%) → streak increments (≥60% threshold met)
- 4/8 members active (50%) → streak resets to 0 (< 60%)
- Streak increases up to longestStreak updates correctly
- Empty circle (0 members) → no crash

---

## Group 3.6 — Member Removal Vote

**Extends Phase 1's direct removal with a vote flow for non-creator moderators.**

### Files to create

#### `lib/features/community/domain/models/removal_vote.dart`
```dart
class RemovalVote {
  const RemovalVote({
    required this.id,
    required this.circleId,
    required this.targetUserId,
    required this.initiatorId,
    required this.votes,        // Map<String, bool> userId → approve
    required this.status,       // pending | resolved
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  // toMap / fromMap / copyWith
}

enum RemovalVoteStatus { pending, resolved }
```

#### `lib/features/community/data/removal_vote_repository.dart`
```dart
abstract class RemovalVoteRepository {
  Stream<List<RemovalVote>> watchActiveVotes(String circleId);
  Future<void> createVote(RemovalVote vote);
  Future<void> castVote({
    required String circleId,
    required String voteId,
    required String userId,
    required bool approve,
  });
}

class FirestoreRemovalVoteRepository implements RemovalVoteRepository {
  // Path: circles/{circleId}/removalVotes/{voteId}
  // castVote: adds to votes map; if majority approve → remove member
  // Majority check: votes.values.where(v => v).length > circle.moderatorCount
  // (Only moderators vote; there are max 2 moderators)
}
```

Append to `FirestorePaths`:
```dart
static String circleRemovalVotes(String circleId) =>
    'circles/$circleId/removalVotes';
```

#### Removal vote UI in `CircleMembersView`

Modify `CircleMembersView` (only the moderator section) to show an open removal vote
banner when `watchActiveVotes` returns pending votes:
- Banner: "Vote to remove [Name]: Approve / Reject"
- Only moderators see and interact with this banner
- On approval: calls `removalVoteRepositoryProvider.castVote(approve: true)`
- When majority reached → `UserCircleMembershipService.removeMember` is called
  automatically by `FirestoreRemovalVoteRepository`

Phase 1 single-creator direct removal remains for the creator role.
The vote flow only activates when there is a second moderator.

### Tests to create

#### `test/features/community/removal_vote_test.dart`
- Creating a vote → `watchActiveVotes` emits it
- 1 moderator approves in a 1-moderator circle → member removed immediately
- In a 2-moderator circle, 1 approval is not enough (50%, not majority)

---

## Phase 3 Completion Checklist

- [ ] 3.1 `Challenge` + `ChallengeVote` models created, tests pass
- [ ] 3.1 `ChallengeRepository` + Firestore implementation created
- [ ] 3.1 Voting logic: majority → status flip, tests pass
- [ ] 3.2 `ChallengeCreateSheet` widget created, tests pass
- [ ] 3.2 `ChallengeVoteBanner` widget created, tests pass
- [ ] 3.3 `challenge_providers.dart` created
- [ ] 3.3 `CircleChallengesView` with competition + team cards + FAB created
- [ ] 3.3 Challenges tab replaces placeholder in `CircleDetailScreen`
- [ ] 3.3 Widget tests pass
- [ ] 3.4 `ChallengeProgressSyncService` created, matching logic tested
- [ ] 3.4 Auto-override flag implemented, tests pass
- [ ] 3.4 Service wired to `app_bootstrap.dart` (append only)
- [ ] 3.5 `CircleStreakService` created, threshold logic tested
- [ ] 3.5 Service wired to `app_bootstrap.dart` (append only)
- [ ] 3.6 `RemovalVote` model + repository created, tests pass
- [ ] 3.6 Removal vote banner wired into `CircleMembersView`
- [ ] `flutter analyze` — 0 issues
- [ ] All Phase 1 + 2 tests still green
