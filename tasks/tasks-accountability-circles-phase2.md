# Tasks — Accountability Circles Phase 2: Activity Feed + Weekly Commitments

> PRD reference: `PRD/Chat_feature/prd-accountability-circles.md`
> Prerequisite: Phase 1 complete and all tests green.
>
> **Safety contract:** Phase 2 reads from existing goal/habit/task systems but does
> NOT modify any of their write paths. The bridge service is wired as an
> observer/side-effect only. All new code is additive.

---

## Group 2.1 — Activity Feed Domain + Repository

**Pure Dart + Firestore. No UI. Depends on Phase 1.**

### Files to create

#### `lib/features/community/domain/models/activity_feed_item.dart`
Already created in Phase 1 Group 1.1. Confirm it includes `dateKey` field
for idempotency: `String dateKey` (`'yyyy-MM-dd'` format). If missing, add field
and update `toMap`/`fromMap` without breaking existing usage (it's new, no callers yet).

#### `lib/features/community/data/activity_feed_repository.dart`
```dart
abstract class ActivityFeedRepository {
  Stream<List<ActivityFeedItem>> watchFeed(String circleId, {int limit = 30});
  Future<void> postFeedItem(ActivityFeedItem item);

  /// Returns existing item for idempotency check.
  Future<ActivityFeedItem?> findExistingItem({
    required String circleId,
    required String userId,
    required String? entityId,
    required ActivityEventType eventType,
    required String dateKey,
  });
}

class FirestoreActivityFeedRepository implements ActivityFeedRepository {
  // watchFeed: orders by createdAtMs desc, limit
  // postFeedItem: sets document at circleActivityFeed(circleId)/item.id
  // findExistingItem: Firestore query with where clauses
}
```

#### Isar cache: `lib/core/local_db/isar_collections/isar_activity_feed_cache.dart`
```dart
@collection
class IsarActivityFeedCache {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String itemId;         // ActivityFeedItem.id

  late String circleId;
  late String payload;        // JSON blob of ActivityFeedItem.toMap()
  late int createdAtMs;
}
```
Add `IsarActivityFeedCacheSchema` to `isar_schemas.dart` and run
`flutter pub run build_runner build --delete-conflicting-outputs`.

**Important**: only add the new schema to the list in `isar_schemas.dart`.
Do not touch any existing schema entries.

### Files to modify (append only)

#### `lib/core/local_db/isar_collections/isar_schemas.dart`
Append `IsarActivityFeedCacheSchema` to `isarSchemaList`.

#### `lib/features/community/application/circle_providers.dart`
Append:
```dart
final activityFeedRepositoryProvider =
    Provider<ActivityFeedRepository>((ref) => FirestoreActivityFeedRepository());

final circleActivityFeedProvider =
    StreamProvider.family<List<ActivityFeedItem>, String>((ref, circleId) {
  return ref.watch(activityFeedRepositoryProvider).watchFeed(circleId);
});
```

### Tests to create

#### `test/features/community/activity_feed_repository_test.dart`
- `postFeedItem` → `watchFeed` emits item
- `findExistingItem` returns item when matching (userId, entityId, eventType, dateKey)
- `findExistingItem` returns null when no match

---

## Group 2.2 — Activity Bridge Service

**Reads from existing systems. Does NOT modify any existing write paths.**

The bridge service listens to existing Riverpod providers and fans out to circles.
It is started once on app foreground from `app_bootstrap.dart` via a new
`_startCircleActivityBridge(container)` call (appended — no existing calls changed).

### Files to create

#### `lib/features/community/application/circle_activity_bridge_service.dart`
```dart
class CircleActivityBridgeService {
  CircleActivityBridgeService({
    required ActivityFeedRepository feedRepo,
    required UserCircleMembershipService membershipSvc,
    required String Function() currentUserId,
    required String Function() currentDisplayName,
  });

  /// Start listening. Returns a dispose callback.
  VoidCallback start(ProviderContainer container) { ... }
}
```

**What it observes (read-only references to existing providers)**:

| Existing provider | Trigger condition | Event posted |
|---|---|---|
| `goalsStreamProvider` (watch `GoalCheckIn` upserts via `goalDetailProvider`) | A `GoalCheckIn.metCommitment` flips to `true` | `ActivityEventType.goalCompleted` |
| `habitStreakSummaryProvider` | `currentStreak` crosses a milestone value (7, 14, 30, 60, 100) | `ActivityEventType.habitStreakReached` |
| `todayAllTasksRowsProvider` | A task status changes to `TaskStatus.completed` | `ActivityEventType.taskFinished` |
| `goalDetailProvider` | A `GoalMilestone.completed` flips to `true` | `ActivityEventType.milestoneReached` |

**Idempotency**: before posting, call `feedRepo.findExistingItem(...)`. If found, skip.

**Fanout**: for each event, get `myCircleIds` from `UserCircleMembershipService`, then
`postFeedItem` for each circleId.

**Critical safety note**: The bridge reads from existing providers using `container.read(...)`.
It NEVER calls `ref.invalidate`, NEVER modifies existing state. If any provider
throws, log + continue (don't crash the app).

### Files to modify (append only)

#### `lib/core/bootstrap/app_bootstrap.dart`
Append at end of `bootstrap()` function (after existing wiring):
```dart
// Community activity bridge — reads-only; no existing flow modified.
_startCircleActivityBridge(container);
```
And add the private function at the bottom of the file.

### Tests to create

#### `test/features/community/circle_activity_bridge_service_test.dart`
Fake repos + fake providers:
- Goal check-in `metCommitment = true` → `postFeedItem` called once per circle
- Same event on same day → idempotency check prevents duplicate post
- Bridge does not throw if `postFeedItem` fails (logs, continues)
- Streak milestone 7 → `habitStreakReached` posted; streak 6 → not posted
- Non-milestone streak increment → not posted

---

## Group 2.3 — Activity Feed UI

**Depends on Groups 2.1 + 2.2. Fills the Activity tab in `CircleDetailScreen`.**

### Files to create

#### `lib/features/community/presentation/views/circle_activity_view.dart`

Widget: `CircleActivityView extends ConsumerStatefulWidget`
Takes: `String circleId`

Structure:
- Filter chip row: All | Goals | Habits | Tasks (filters `ActivityEventType` locally)
- `ListView` of `_ActivityCard` (reverse chronological)
- `_ActivityCard`:
  - Avatar circle (colored by userId hash mod 6, shows initial of displayName)
  - Display name (bold)
  - Event description line using `_activityCopy(item)`:
    - `goalCompleted` → `"completed ${item.entityTitle ?? 'a goal'} ✅"`
    - `habitStreakReached` → `"reached a ${item.value}-day streak 🔥"`
    - `taskFinished` → `"finished ${item.entityTitle ?? 'a task'} 💪"`
    - `milestoneReached` → `"hit a milestone: ${item.entityTitle} 🎯"`
    - `memberJoined` → `"joined the circle 👋"` (system style — no avatar, centred)
    - `memberLeft` → `"left the circle"` (same)
  - Relative timestamp (e.g. "2h ago", "yesterday")
- Empty state: "No activity yet. Complete a goal or task to see progress here."

### Tests to create

#### `test/features/community/circle_activity_view_test.dart`
Widget test with overridden `circleActivityFeedProvider`:
- `goalCompleted` item renders correct copy
- `habitStreakReached` item renders streak value
- Filter chip "Goals" hides task events
- Empty state shown when feed is empty

---

## Group 2.4 — Weekly Commitments Domain + Repository

**Pure Dart + Firestore. No UI.**

### Files to create

#### `lib/features/community/domain/models/weekly_commitment.dart`
```dart
class WeeklyCommitment {
  const WeeklyCommitment({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.title,
    required this.targetCount,
    required this.completedCount,
    required this.weekKey,   // 'yyyy-Www' (ISO week)
    required this.updatedAtMs,
  });
  // validate(): title not empty, targetCount 1–7, completedCount <= targetCount
  // toMap / fromMap / copyWith
}
```

Week key helper: `DateKeys.isoWeekKey(DateTime date)` — add to existing
`lib/core/utils/date_keys.dart` as a new static method (does not change existing
methods):
```dart
/// Returns ISO week key: 'yyyy-Www' (e.g. '2026-W21').
static String isoWeekKey(DateTime date) { ... }
```

#### `lib/features/community/data/weekly_commitment_repository.dart`
```dart
abstract class WeeklyCommitmentRepository {
  Stream<List<WeeklyCommitment>> watchCommitments(
    String circleId, {
    String? weekKey, // defaults to current week
  });

  /// Upsert a list of commitments for the current user this week.
  Future<void> setCommitments({
    required String circleId,
    required String userId,
    required String weekKey,
    required List<WeeklyCommitment> commitments,
  });

  Future<void> markProgress(String circleId, String commitmentId) async {
    // increments completedCount by 1 up to targetCount
  }
}

class FirestoreWeeklyCommitmentRepository implements WeeklyCommitmentRepository {
  // Firestore path: circles/{circleId}/weeklyCommitments/{id}
  // watchCommitments: filters by weekKey field
}
```

Append to `FirestorePaths`:
```dart
static String circleWeeklyCommitments(String circleId) =>
    'circles/$circleId/weeklyCommitments';
```

### Tests to create

#### `test/features/community/weekly_commitment_model_test.dart`
- `toMap`/`fromMap` round-trip
- `validate()` rejects `targetCount = 0`, `completedCount > targetCount`

#### `test/features/community/weekly_commitment_repository_test.dart`
- `setCommitments` → `watchCommitments` emits correct list
- `markProgress` increments `completedCount` up to `targetCount`

---

## Group 2.5 — Weekly Commitments UI

**Depends on Group 2.4. Fills the Commitments tab.**

### Files to create

#### `lib/features/community/application/weekly_commitment_providers.dart`
```dart
final weeklyCommitmentRepositoryProvider =
    Provider<WeeklyCommitmentRepository>(...);

final circleWeeklyCommitmentsProvider =
    StreamProvider.family<List<WeeklyCommitment>, String>((ref, circleId) {
  final weekKey = DateKeys.isoWeekKey(DateTime.now());
  return ref
      .watch(weeklyCommitmentRepositoryProvider)
      .watchCommitments(circleId, weekKey: weekKey);
});
```

#### `lib/features/community/presentation/views/weekly_commitments_view.dart`

Widget: `WeeklyCommitmentsView extends ConsumerStatefulWidget`
Takes: `String circleId`

Structure:
- **"My commitments this week"** section (editable):
  - List of 1–3 `_CommitmentRow` (tick progress: `completedCount / targetCount` circles)
  - Edit button → `_EditCommitmentsSheet` (bottom sheet to set 1–3 commitment titles + target counts)
  - "Mark progress" tap on a commitment → calls `markProgress`
- **"Circle commitments"** section (read-only):
  - All other members' commitments grouped by userId
  - Compact card: member name, commitment title, `x/y` ticks
- **End-of-week banner** (shown if weekKey is ending within 2 days):
  - "You completed 2/3 commitments this week" with accent color

`_EditCommitmentsSheet`:
- `Column` of 1–3 `TextField` + `DropdownButton<int>` for target (1–7)
- Add button (up to 3), remove button per row
- Save calls `weeklyCommitmentRepositoryProvider.setCommitments(...)`

### Tests to create

#### `test/features/community/weekly_commitments_view_test.dart`
Widget test:
- Current user's commitments shown in "My commitments" section
- Other member commitments shown in "Circle commitments" section
- Progress ticks reflect `completedCount / targetCount`
- End-of-week banner shown/hidden based on weekKey proximity

---

## Phase 2 Completion Checklist

- [ ] 2.1 `ActivityFeedRepository` + Firestore implementation created
- [ ] 2.1 `IsarActivityFeedCache` created and added to schema list
- [ ] 2.1 `build_runner` run after schema addition
- [ ] 2.1 `activityFeedRepositoryProvider` + `circleActivityFeedProvider` added to providers
- [ ] 2.1 Repository tests pass
- [ ] 2.2 `CircleActivityBridgeService` created, all 4 trigger types handled
- [ ] 2.2 Idempotency check prevents duplicate posts
- [ ] 2.2 Bridge wired into `app_bootstrap.dart` (append only)
- [ ] 2.2 Bridge tests pass
- [ ] 2.3 `CircleActivityView` with filter chips and event copy created
- [ ] 2.3 Activity view replaces placeholder in `CircleDetailScreen` Activity tab
- [ ] 2.3 Widget tests pass
- [ ] 2.4 `WeeklyCommitment` model + `isoWeekKey` helper created
- [ ] 2.4 `WeeklyCommitmentRepository` + Firestore implementation created
- [ ] 2.4 Model + repository tests pass
- [ ] 2.5 `weekly_commitment_providers.dart` created
- [ ] 2.5 `WeeklyCommitmentsView` with edit sheet created
- [ ] 2.5 Commitments view replaces placeholder in `CircleDetailScreen` Commitments tab
- [ ] 2.5 Widget tests pass
- [ ] `flutter analyze` — 0 issues
- [ ] All tests green (Phase 1 tests must still pass)
