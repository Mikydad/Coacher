# Tasks — Accountability Circles Phase 4: AI Pulse + Recommendations + Smart Notifications

> PRD reference: `PRD/Chat_feature/prd-accountability-circles.md`
> Prerequisite: Phase 3 complete and all tests green.
>
> **Safety contract:**
> - The existing `CoachingAiClient` and `LocalNotificationsService` are NOT modified.
>   Phase 4 creates new wrapper/extension classes that delegate to them.
> - The existing `notification_response_handler.dart` deep-link routing gets
>   one new `circle:` prefix case added at the end of the existing switch — no
>   existing cases are touched.
> - All new code lives under `lib/features/community/` except the route handler append.

---

## Group 4.1 — AI Pulse Generation

**New service that uses the existing AI client infrastructure. No existing AI code modified.**

### Files to create

#### `lib/features/community/domain/models/ai_pulse.dart`
```dart
class AiPulse {
  const AiPulse({
    required this.id,
    required this.circleId,
    required this.type,
    required this.summary,
    required this.memberLines,
    this.suggestedChallenge,
    required this.generatedAtMs,
  });
  // toMap / fromMap / copyWith
}

enum AiPulseType { daily, weekly }
// with storageValue / fromStorage

class MemberPulseLine {
  const MemberPulseLine({
    required this.userId,
    required this.displayName,
    required this.insight,
  });
  // toMap / fromMap
}
```

#### `lib/features/community/data/ai_pulse_repository.dart`
```dart
abstract class AiPulseRepository {
  Stream<AiPulse?> watchLatestPulse(String circleId, AiPulseType type);
  Future<void> savePulse(AiPulse pulse);

  /// Returns true if a pulse was generated within the last [cooldownMinutes].
  Future<bool> isOnCooldown(String circleId, AiPulseType type, {int cooldownMinutes = 240});
}

class FirestoreAiPulseRepository implements AiPulseRepository {
  // Path: circles/{circleId}/aiPulse/{pulseId}
  // watchLatestPulse: filters by type, orders by generatedAtMs desc, limit 1
  // isOnCooldown: reads latest pulse generatedAtMs, checks against now - cooldown
}
```

Append to `FirestorePaths`:
```dart
static String circleAiPulse(String circleId) => 'circles/$circleId/aiPulse';
```

#### Isar cache: `lib/core/local_db/isar_collections/isar_ai_pulse_cache.dart`
```dart
@collection
class IsarAiPulseCache {
  Id isarId = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('type')], unique: true)
  late String circleId;
  late String type;          // 'daily' | 'weekly'
  late String payload;       // JSON of AiPulse
  late int generatedAtMs;
}
```
Add `IsarAiPulseCacheSchema` to `isar_schemas.dart`.

#### `lib/features/community/application/circle_ai_pulse_service.dart`
```dart
class CircleAiPulseService {
  CircleAiPulseService({
    required AiPulseRepository pulseRepo,
    required ActivityFeedRepository feedRepo,
    required WeeklyCommitmentRepository commitmentRepo,
    required ChallengeRepository challengeRepo,
    required CoachingAiClient aiClient,   // existing client, read-only usage
  });

  /// Generate a daily pulse for a circle if not on cooldown.
  Future<AiPulse?> generateDailyPulse(String circleId) async { ... }

  /// Generate a weekly pulse for a circle if not on cooldown.
  Future<AiPulse?> generateWeeklyPulse(String circleId) async { ... }
}
```

**Daily pulse prompt** (appended to existing `CoachingAiClient` via a new method or
standalone function — do NOT modify the existing `buildSystemPrompt`):
```
You are an AI coaching assistant. Given the recent activity for a small accountability
circle, produce a concise group pulse.

Return JSON: {
  "summary": "<1-sentence overall status>",
  "memberLines": [{"userId": "...", "displayName": "...", "insight": "..."}],
  "suggestedChallenge": "<optional 1-sentence challenge suggestion or null>"
}

Activity (last 24h): [list of ActivityFeedItem descriptions]
```

**Weekly pulse prompt**: Similar structure but takes 7 days of data + commitment + streak.

Error handling: if AI call fails, return null and log. Never surface AI errors to the user —
the pulse banner simply doesn't appear.

**Note on `CoachingAiClient`**: call `aiClient.complete(prompt)` or the equivalent
public method that already exists. Do not add new methods to `CoachingAiClient`.
If no suitable method exists, create a standalone `CircleAiPromptBuilder` class
with a static `buildDailyPulsePrompt(...)` that returns the prompt string, and
call the AI via the existing HTTP path used by `coaching_ai_client.dart`.

### Files to modify (append only)

#### `lib/core/local_db/isar_collections/isar_schemas.dart`
Append `IsarAiPulseCacheSchema`.

### Tests to create

#### `test/features/community/ai_pulse_model_test.dart`
- `toMap`/`fromMap` round-trip for `AiPulse` and `MemberPulseLine`
- `AiPulseType.daily.storageValue` == `'daily'`

#### `test/features/community/circle_ai_pulse_service_test.dart`
Fake repos + fake AI client:
- `generateDailyPulse` calls AI client with activity data
- On cooldown: returns null without calling AI client
- AI client failure: returns null, does not throw

---

## Group 4.2 — AI Pulse UI

**Depends on Group 4.1. Fills the pinned pulse banner in `CircleActivityView`.**

### Files to create

#### `lib/features/community/application/ai_pulse_providers.dart`
```dart
final aiPulseRepositoryProvider = Provider<AiPulseRepository>(...);
final circleAiPulseServiceProvider = Provider<CircleAiPulseService>(...);

final latestDailyPulseProvider =
    StreamProvider.family<AiPulse?, String>((ref, circleId) {
  return ref
      .watch(aiPulseRepositoryProvider)
      .watchLatestPulse(circleId, AiPulseType.daily);
});

final latestWeeklyPulseProvider =
    StreamProvider.family<AiPulse?, String>((ref, circleId) {
  return ref
      .watch(aiPulseRepositoryProvider)
      .watchLatestPulse(circleId, AiPulseType.weekly);
});
```

#### `lib/features/community/presentation/widgets/ai_pulse_banner.dart`

Widget: `AiPulseBanner extends ConsumerStatefulWidget`
Takes: `String circleId`, `bool isModerator`

Structure (expandable card, collapsed by default):
- **Collapsed**: single line summary text + "↓ Pulse" label + pulsing dot indicator
- **Expanded**:
  - Summary line (bold)
  - Member insight lines: `[avatar] [name]: [insight]`
  - If `suggestedChallenge != null`: accent-colored "Suggested: [text]" banner
    with a "Start challenge" button → opens `ChallengeCreateSheet` pre-filled
- **Moderator only**: "Generate now" button (shown only when not on cooldown)
  - Taps calls `circleAiPulseServiceProvider.generateDailyPulse(circleId)`
  - Shows loading spinner while generating
  - Shows "Updated just now" after success

Wiring in `CircleActivityView`: render `AiPulseBanner` as the first item in the
`ListView` (prepended, not inserted into existing list logic).

### Tests to create

#### `test/features/community/ai_pulse_banner_test.dart`
- Renders summary text when pulse is available
- Expands to show member lines on tap
- "Generate now" button hidden for non-moderators
- Loading state shown while generating

---

## Group 4.3 — AI-Powered Circle Recommendations

**New service + UI section. No existing discovery logic modified.**

### Files to create

#### `lib/features/community/application/circle_recommendation_service.dart`
```dart
class CircleRecommendationService {
  CircleRecommendationService({
    required CircleRepository circleRepo,
    required GoalsRepository goalsRepo,   // existing, read-only
  });

  /// Returns circles scored by relevance to the current user.
  Future<List<ScoredCircle>> getRecommendations({
    required String userId,
    required List<String> activeGoalCategories,
    required String userTimezone,
    required CoachingStyle coachingStyle,
    required List<String> alreadyJoinedIds,
  }) async { ... }
}

class ScoredCircle {
  final AccountabilityCircle circle;
  final double score;             // 0.0–1.0
  final String matchReason;       // "Matches your Learning goal"
}
```

**Scoring formula** (pure Dart, testable):
```
score =
  categoryMatch   × 0.4  (1.0 if any goal category matches circle category)
+ timezoneMatch   × 0.3  (1.0 if within 2 hours, 0.5 if within 4 hours, else 0)
+ activityLevel   × 0.2  (memberCount / kMaxMembers)
+ openPolicy      × 0.1  (1.0 if open join, 0.5 if approval)
```

Recommendations filtered: exclude full circles (memberCount = 8) and
already-joined circles.

#### Add to `CircleDiscoveryScreen`

Modify `CircleDiscoveryScreen` Browse tab to show a "Recommended for you" horizontal
scroll section at the top — before the category filter chips.

This is a **targeted addition** to `CircleDiscoveryScreen`. The existing browse list
and search tab are not touched.

### Tests to create

#### `test/features/community/circle_recommendation_service_test.dart`
- Category match boosts score
- Timezone within 2h gives full timezone score
- Full circle excluded from results
- Already-joined circle excluded
- Results sorted by score descending

---

## Group 4.4 — Per-Circle Notification Preferences

**New model + Firestore storage + settings UI. No existing notification logic modified.**

### Files to create

#### `lib/features/community/domain/models/circle_notif_prefs.dart`
```dart
class CircleNotifPrefs {
  const CircleNotifPrefs({
    required this.circleId,
    this.mentions = true,
    this.challengeUpdates = true,
    this.weeklySummary = true,
    this.accomplishments = true,
    this.reactions = false,       // muted by default per PRD
    this.muteUntilMs,
  });

  final String circleId;
  final bool mentions;
  final bool challengeUpdates;
  final bool weeklySummary;
  final bool accomplishments;
  final bool reactions;
  final int? muteUntilMs;

  bool get isMuted =>
      muteUntilMs != null && muteUntilMs! > DateTime.now().millisecondsSinceEpoch;
  // toMap / fromMap / copyWith
}
```

#### `lib/features/community/data/circle_notif_prefs_repository.dart`
```dart
abstract class CircleNotifPrefsRepository {
  Future<CircleNotifPrefs> getPrefs(String circleId);
  Future<void> savePrefs(CircleNotifPrefs prefs);
}

class FirestoreCircleNotifPrefsRepository implements CircleNotifPrefsRepository {
  // Path: users/{uid}/circleNotifPrefs/{circleId}
}
```

Append to `FirestorePaths`:
```dart
static String userCircleNotifPrefs(String uid) =>
    'users/$uid/circleNotifPrefs';
static String userCircleNotifPrefsDoc(String uid, String circleId) =>
    'users/$uid/circleNotifPrefs/$circleId';
```

#### `lib/features/community/presentation/sheets/circle_notif_prefs_sheet.dart`

Widget: `CircleNotifPrefsSheet extends ConsumerStatefulWidget`
Takes: `String circleId`
Shown from `CircleInfoView` → "Notification settings" tile.

Structure (dark bottom sheet, Obsidian Pulse):
- Toggle rows: Mentions | Challenge updates | Weekly summary | Accomplishments | Reactions
- "Mute circle" toggle — sets `muteUntilMs = null` (permanent) or shows duration picker
- "Mute until tomorrow" button → sets `muteUntilMs = tomorrowMidnight`
- Save button → calls `savePrefs`

### Tests to create

#### `test/features/community/circle_notif_prefs_test.dart`
- `isMuted` returns true when `muteUntilMs` is in the future
- `isMuted` returns false when `muteUntilMs` is in the past
- `toMap`/`fromMap` round-trip
- Default prefs: reactions = false, others = true

---

## Group 4.5 — Smart Notification Routing

**New routing layer. Does NOT modify `LocalNotificationsService`.**

### Files to create

#### `lib/features/community/application/circle_notification_router.dart`
```dart
/// Routes incoming circle-related push events through the user's per-circle
/// notification preferences before delegating to [LocalNotificationsService].
class CircleNotificationRouter {
  CircleNotificationRouter({
    required LocalNotificationsService notifications,  // existing, injected
    required CircleNotifPrefsRepository prefsRepo,
  });

  /// Call this instead of LocalNotificationsService directly for circle events.
  Future<void> deliver({
    required String circleId,
    required CircleNotifType type,  // mention | challenge | accomplishment | reaction | weekly
    required String title,
    required String body,
    required String payload,        // 'circle:{circleId}'
  }) async {
    final prefs = await prefsRepo.getPrefs(circleId);
    if (prefs.isMuted) return;
    if (!_isEnabled(prefs, type)) return;
    await notifications.show(title: title, body: body, payload: payload);
  }
}

enum CircleNotifType { mention, challenge, accomplishment, reaction, weeklySummary }
```

### Files to modify (targeted append)

#### `lib/app/notification_response_handler.dart`
In the existing payload routing switch/if-chain, append **one new case** after
all existing cases (do not modify existing cases):
```dart
// Circle deep link
if (payload.startsWith('circle:')) {
  final circleId = payload.substring('circle:'.length);
  if (circleId.isNotEmpty) {
    navigatorKey.currentState?.pushNamed(
      CircleDetailScreen.routeName,
      arguments: circleId,
    );
  }
  return;
}
```

### Tests to create

#### `test/features/community/circle_notification_router_test.dart`
Fake `LocalNotificationsService` + fake prefs repo:
- Muted circle: `deliver` called → `notifications.show` NOT called
- `reactions = false`: reaction type → not delivered
- `mentions = true`: mention type → delivered
- `muteUntilMs` in past: not muted → delivered normally

---

## Phase 4 Completion Checklist

- [ ] 4.1 `AiPulse` + `MemberPulseLine` models created, tests pass
- [ ] 4.1 `AiPulseRepository` + Firestore implementation created
- [ ] 4.1 `IsarAiPulseCacheSchema` added to schema list, `build_runner` run
- [ ] 4.1 `CircleAiPulseService` created, cooldown + failure tests pass
- [ ] 4.2 `ai_pulse_providers.dart` created
- [ ] 4.2 `AiPulseBanner` widget created, pinned to `CircleActivityView`
- [ ] 4.2 Widget tests pass
- [ ] 4.3 `CircleRecommendationService` + `ScoredCircle` created
- [ ] 4.3 Scoring formula tested (category, timezone, activity, policy)
- [ ] 4.3 "Recommended" section added to `CircleDiscoveryScreen` browse tab
- [ ] 4.4 `CircleNotifPrefs` model + repository created, tests pass
- [ ] 4.4 `CircleNotifPrefsSheet` created, wired from `CircleInfoView`
- [ ] 4.5 `CircleNotificationRouter` created, routing tests pass
- [ ] 4.5 `notification_response_handler.dart` `circle:` case appended
- [ ] `flutter analyze` — 0 issues
- [ ] All Phase 1–3 tests still green

---

## Cross-Phase Notes

### `CircleInfoView` (Info tab — needed by Phase 4)
Create `lib/features/community/presentation/views/circle_info_view.dart` in Phase 4
(or Phase 1 Group 1.7 if desired as a placeholder). Contains:
- Circle name, description, category, join policy, member count
- Creator + moderator names
- Streak stats
- "Notification settings" tile → opens `CircleNotifPrefsSheet`
- "Leave circle" button (danger zone)
- Moderator-only: "Circle settings" tile → edit name/description/policy

### Isar schema version bump
Each time a new Isar collection is added, the Isar database schema version
increments automatically via `build_runner`. Existing collections are not affected.
Run `flutter pub run build_runner build --delete-conflicting-outputs` after each
new `@collection` class is added.

### build_runner summary by phase
| Phase | New Isar collections | Run build_runner? |
|---|---|---|
| 1 | None | No |
| 2 | `IsarActivityFeedCache` | Yes after Group 2.1 |
| 3 | None | No |
| 4 | `IsarAiPulseCacheSchema` | Yes after Group 4.1 |
