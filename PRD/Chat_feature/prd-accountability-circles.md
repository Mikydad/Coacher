# Accountability Circles — Implementation PRD

## 1. Overview

Accountability Circles is a group accountability feature: small (4–8 member) chat groups
where progress from the user's existing goals, habits, and tasks is surfaced automatically,
reducing the need for manual status updates and keeping conversation focused on accountability
rather than socialising.

This PRD covers the full implementation plan broken into 4 phases. Each phase is independently
shippable. Phase 1 alone delivers a usable circle, with subsequent phases adding richer
accountability mechanics.

---

## 2. Design System Contract

All screens follow the **Obsidian Pulse** design language already used by ProfileScreen,
HomeScreen, and SettingsScreen:

| Token | Value |
|---|---|
| Background primary | `#0D0F12` |
| Surface | `#14171C` |
| Surface raised | `#1C2029` |
| Primary accent | `#B7FF00` |
| Text primary | `#F0F4FF` |
| Text secondary | `#8A8FA8` |
| Border | `rgba(255,255,255,0.06)` |
| Radius | 12–16px |
| Font | Inter |

Rules:
- No lines/dividers except via background tonal shift
- Glass overlays use `BackdropFilter(blur: 12)` + `rgba(255,255,255,0.05)` fill
- Buttons: `FilledButton` with `backgroundColor: Color(0xFFB7FF00)`, `foregroundColor: Colors.black`
- Destructive actions: `Color(0xFFFF4D4D)` accent

---

## 3. Data Architecture

### 3.1 Firestore Collections (top-level, not nested under users/)

Circles are shared documents — they must live at the root, not under a user path.

```
circles/{circleId}
  ├── members/{userId}           – CircleMember doc
  ├── messages/{messageId}       – CircleMessage doc
  ├── activityFeed/{feedItemId}  – ActivityFeedItem doc
  ├── challenges/{challengeId}   – Challenge doc
  └── aiPulse/{pulseId}          – AiPulse doc
```

### 3.2 Domain Models

#### AccountabilityCircle
```dart
class AccountabilityCircle {
  final String id;
  final String name;
  final String? description;
  final String category;        // 'fitness' | 'learning' | 'business' | ...
  final JoinPolicy joinPolicy;  // open | requestApproval
  final CircleVisibility visibility; // public | private
  final String creatorId;
  final List<String> moderatorIds; // max 2 (creator + 1 assigned)
  final int memberCount;           // denormalized for list views
  final int maxMembers;            // always 8
  final int minMembers;            // always 4
  final String timezone;           // e.g. 'Africa/Nairobi'
  final int createdAtMs;
  final int updatedAtMs;
}

enum JoinPolicy { open, requestApproval }
enum CircleVisibility { public, private }
```

#### CircleMember
```dart
class CircleMember {
  final String userId;
  final String circleId;
  final CircleMemberRole role;    // member | moderator
  final CircleMemberStatus status; // active | pending | removed
  final int joinedAtMs;
  final int updatedAtMs;
}

enum CircleMemberRole { member, moderator }
enum CircleMemberStatus { active, pending, removed }
```

#### CircleMessage
```dart
class CircleMessage {
  final String id;
  final String circleId;
  final String senderId;
  final String senderDisplayName;
  final MessageType type;   // text | image | activityUpdate | systemEvent
  final String? content;
  final String? imageUrl;
  final String? activityRef; // id of the feed item this message references
  final Map<String, List<String>> reactions; // emoji → [userId, ...]
  final int createdAtMs;
}

enum MessageType { text, image, activityUpdate, systemEvent }
```

#### ActivityFeedItem
```dart
class ActivityFeedItem {
  final String id;
  final String circleId;
  final String userId;
  final String displayName;
  final ActivityEventType eventType;
  final String? entityId;
  final String? entityTitle;
  final String? value;      // e.g. '11' for streak count
  final int createdAtMs;
}

enum ActivityEventType {
  goalCompleted,
  habitStreakReached,
  taskFinished,
  challengeProgressUpdated,
  milestoneReached,
  weeklyCommitmentMet,
  memberJoined,
  memberLeft,
}
```

#### WeeklyCommitment
```dart
class WeeklyCommitment {
  final String id;
  final String circleId;
  final String userId;
  final String title;         // e.g. 'Workout ×5'
  final int targetCount;
  final int completedCount;
  final String weekKey;       // 'yyyy-Www'
  final int updatedAtMs;
}
```

#### Challenge
```dart
class Challenge {
  final String id;
  final String circleId;
  final String creatorId;
  final String title;
  final ChallengeMode mode;    // competition | team
  final ChallengeStatus status; // pending | active | completed | rejected
  final int targetValue;
  final String unit;            // 'miles' | 'sessions' | 'pages'
  final Map<String, int> memberProgress; // userId → progress
  final int teamTotal;          // denormalized sum (team mode only)
  final int startsAtMs;
  final int endsAtMs;
  final int createdAtMs;
  final int updatedAtMs;
}

enum ChallengeMode { competition, team }
enum ChallengeStatus { pending, active, completed, rejected }
```

#### AiPulse
```dart
class AiPulse {
  final String id;
  final String circleId;
  final AiPulseType type;     // daily | weekly
  final String summary;
  final List<MemberPulseLine> memberLines;
  final String? suggestedChallenge;
  final int generatedAtMs;
}

enum AiPulseType { daily, weekly }

class MemberPulseLine {
  final String userId;
  final String displayName;
  final String insight;        // 'Workout streak 11' | 'Missed study twice'
}
```

### 3.3 Isar Local Cache (per device)

```
IsarCircleCache        – circle metadata snapshot
IsarCircleMessageCache – last N=50 messages per circle (for offline read)
IsarAiPulseCache       – latest daily + weekly pulse per circle
```

### 3.4 Firestore Path Additions

Add to `FirestorePaths`:
```dart
static String get circles => 'circles';
static String circleDoc(String circleId) => 'circles/$circleId';
static String circleMembers(String circleId) => 'circles/$circleId/members';
static String circleMember(String circleId, String userId) =>
    'circles/$circleId/members/$userId';
static String circleMessages(String circleId) => 'circles/$circleId/messages';
static String circleActivityFeed(String circleId) =>
    'circles/$circleId/activityFeed';
static String circleChallenges(String circleId) =>
    'circles/$circleId/challenges';
static String circleAiPulse(String circleId) =>
    'circles/$circleId/aiPulse';
```

---

## 4. Phase Breakdown

---

### Phase 1 — Foundation: Circle Management & Basic Chat

**Goal:** Users can create, discover, join, and chat in circles.

#### Groups

**Group 1.1 — Domain models + Firestore paths**
- `AccountabilityCircle`, `CircleMember`, `CircleMessage`, `ActivityFeedItem` domain classes
- `JoinPolicy`, `CircleVisibility`, `CircleMemberRole`, `CircleMemberStatus`, `MessageType`, `ActivityEventType` enums (with `storageValue`/`fromStorage`)
- `FirestorePaths` additions
- Tests: model `toMap`/`fromMap` round-trip for all 4 models

**Group 1.2 — Repository layer**
- Abstract `CircleRepository`:
  - `watchCircles(List<String> circleIds)` — stream
  - `watchCircle(String circleId)` — stream
  - `createCircle(AccountabilityCircle circle)`
  - `updateCircle(AccountabilityCircle circle)`
  - `getCircle(String circleId)`
  - `searchCircles({String? query, String? category})` — future
- Abstract `CircleMemberRepository`:
  - `watchMembers(String circleId)` — stream
  - `requestJoin(String circleId)` — sets status=pending
  - `approveJoin(String circleId, String userId)`
  - `leaveCircle(String circleId)`
  - `removeMember(String circleId, String userId)`
- Abstract `CircleMessageRepository`:
  - `watchMessages(String circleId, {int limit = 50})` — stream (ordered by createdAt desc)
  - `sendMessage(CircleMessage message)`
  - `addReaction(String circleId, String messageId, String emoji, String userId)`
  - `removeReaction(String circleId, String messageId, String emoji, String userId)`
- `FirestoreCircleRepository`, `FirestoreCircleMemberRepository`, `FirestoreCircleMessageRepository` implementations
- Tests: repository contract tests with `FakeFirestore` (or mock)

**Group 1.3 — Riverpod providers**
- `circleRepositoryProvider`
- `circleMemberRepositoryProvider`
- `circleMessageRepositoryProvider`
- `myCircleIdsProvider` — reads from `users/{uid}/circles` subcollection (denormalized list of circleIds the user belongs to)
- `myCirclesProvider` — `StreamProvider<List<AccountabilityCircle>>` combining `myCircleIdsProvider` + `watchCircles`
- `circleDetailProvider(circleId)` — `StreamProvider.family`
- `circleMembersProvider(circleId)` — `StreamProvider.family`
- `circleMessagesProvider(circleId)` — `StreamProvider.family`
- `circleMessageCountLimitProvider` — `StateProvider<int>` (for pagination)

**Group 1.4 — User's circle membership tracking**

Firestore denormalization: when a user joins/leaves a circle, also write to
`users/{uid}/circleIds/{circleId}` so `myCircleIdsProvider` has a cheap lookup.

- `UserCircleMembershipService`:
  - `joinCircle(String circleId)` — writes both `circleMembers/{userId}` and `users/{uid}/circleIds/{circleId}`
  - `leaveCircle(String circleId)` — deletes both
  - `getMyCircleIds()` — reads `users/{uid}/circleIds`
- Max-circles enforcement: read count before joining; reject if ≥ 3

**Group 1.5 — Circle creation screen** (`CircleCreateScreen`)
- Fields: name, description, category (chip selector), join policy toggle, visibility toggle
- Validation: name 3–40 chars, category required
- On save: creates circle + adds creator as moderator member
- Route: `/community/create`

**Group 1.6 — Circle discovery screen** (`CircleDiscoveryScreen`)
- Tab bar: Browse (by category) | Search
- Each circle card: name, category badge, members count (e.g. `6 / 8`), timezone, join policy badge
- Join/Request button respects `JoinPolicy`
- Empty state for search
- Route: `/community/discover`

**Group 1.7 — Circle detail screen** (`CircleDetailScreen`)
- Shows circle name, member avatars (up to 8), current member count
- Bottom tab bar: Chat | Activity | Members | Info
- Default tab: Chat
- Route: `/community/circle/:id`

**Group 1.8 — Chat tab** (`CircleChatView`)
- `ListView` of messages, newest at bottom
- Message bubble: sender name + avatar initial + text + timestamp + emoji reactions row
- Input bar: text field + send button + image picker icon
- Image messages: proof images only (picker shows category selector: Workout / Study / Meal / Milestone / Goal Progress)
- Emoji reaction: long-press on message → emoji picker row (6 preset emojis)
- System events (member joined/left) shown as centred grey pills

**Group 1.9 — Member list + pending approvals** (`CircleMembersView`)
- Active members list: avatar, display name, role badge (Moderator), join date
- Moderator only: pending requests section with Approve / Decline buttons
- Moderator only: "Remove member" — initiates vote (Phase 1 can skip voting; direct removal by creator only for simplicity, voting in Phase 3)

**Group 1.10 — Navigation wiring**
- Add "Community" tab to `HomeScreen` bottom nav (currently: Home, Goals, Progress, Community, Profile)
- `CommunityScreen`: shows user's circles list; FAB → create or discover
- Route registration in `app.dart`

---

### Phase 2 — Accountability Layer: Activity Feed + Weekly Commitments

**Goal:** Progress from the user's existing goals/habits/tasks automatically surfaces in the circle, reducing the need to manually report.

**Group 2.1 — Activity feed domain + repository**
- `ActivityFeedRepository`: `watchFeed(String circleId)`, `postFeedItem(ActivityFeedItem item)`
- `FirestoreActivityFeedRepository`
- Isar cache: `IsarActivityFeedCache` — last 30 items per circle

**Group 2.2 — Activity bridge service** (`CircleActivityBridgeService`)

Listens to the user's existing data and fans out to all their circles:

| Trigger source | Event posted |
|---|---|
| `GoalCheckIn.metCommitment = true` | `ActivityEventType.goalCompleted` |
| `StreakSummary.currentStreak` hits a milestone (7, 14, 30, 60, 100) | `ActivityEventType.habitStreakReached` |
| Task marked completed | `ActivityEventType.taskFinished` |
| Goal milestone marked complete | `ActivityEventType.milestoneReached` |

- Idempotency: post only if no existing feed item for `(userId, entityId, eventType, dateKey)`
- Wired into `app_bootstrap.dart` or `notification_response_handler.dart` on app foreground

**Group 2.3 — Activity feed UI** (`CircleActivityView`)
- Reverse-chronological feed of cards
- Each card: avatar initial, display name, event icon + text, timestamp
- Event copy examples:
  - `"Mike completed Workout 🔥"`
  - `"Sarah reached a 10-day streak 🏅"`
  - `"David finished Chinese Practice ✅"`
- Filter chip row: All | Goals | Habits | Tasks

**Group 2.4 — Weekly commitments domain + repository**
- `WeeklyCommitmentRepository`: `watchCommitments(String circleId)`, `setCommitments(List<WeeklyCommitment>)`, `markProgress(String commitmentId)`
- `FirestoreWeeklyCommitmentRepository`

**Group 2.5 — Weekly commitment UI** (`WeeklyCommitmentsView`)
- Each user's commitments shown as a compact card with progress ticks
- "My commitments this week" section at top (editable: 1–3 items)
- Read-only section below showing circle members' commitments
- End-of-week summary banner: "You completed 2/3 commitments this week"

---

### Phase 3 — Challenges + Circle Streaks + Removal Voting

**Goal:** Structured shared challenges and group streak mechanics.

**Group 3.1 — Challenge domain + repository**
- `ChallengeRepository`: `watchChallenges(String circleId)`, `createChallenge(Challenge)`, `updateProgress(String circleId, String challengeId, String userId, int delta)`, `vote(String challengeId, String userId, bool approve)`
- `FirestoreChallengeRepository`
- `ChallengeVote` model: `{ challengeId, userId, approve, createdAtMs }`

**Group 3.2 — Challenge creation + voting flow**
- `ChallengeCreateSheet`: bottom sheet — title, mode (competition/team), target, unit, start/end dates
- On submit: challenge status = `pending`
- Voting: all circle members see a vote banner; when majority (>50%) approve → status = `active`
- Challenge cards in `CircleDetailScreen` Info tab

**Group 3.3 — Challenge progress UI** (`CircleChallengesView`)
- Competition mode: ranked leaderboard list per member
- Team mode: group progress bar + member contribution breakdown
- Manual update button (for standalone challenges): text input + optional proof image

**Group 3.4 — Challenge progress auto-sync** (`ChallengeProgressSyncService`)
- Listens to existing goal/habit/task completions (same bridge as Phase 2)
- Matches entity to active challenge by category + unit
- Auto-increments `memberProgress[userId]` in Firestore
- Rule: auto-update always overrides manual for linked entities

**Group 3.5 — Circle streak**
- `CircleStreakService`:
  - Daily job: queries `activityFeed` for current date; if ≥ `ceil(memberCount * 0.6)` members posted activity → increment streak
  - Stores streak in `circles/{circleId}` as `{ currentStreak, longestStreak, lastActiveDate }`
- Streak shown on `CircleDetailScreen` header

**Group 3.6 — Member removal vote**
- Moderator taps "Remove member" → creates `RemovalVote` doc (`circleId`, `targetUserId`, `initiatorId`, `votes: {}`, `status: pending`)
- Other moderators (if any) + moderator themselves vote
- Majority → member removed (status = `removed` in `CircleMember`)
- Notification sent to all members except the removed user

---

### Phase 4 — AI Group Pulse + Smart Notifications + Recommendations

**Goal:** AI-powered circle intelligence and smart notification routing.

**Group 4.1 — AI Pulse generation**
- Cloud Function (or on-device via `CoachingAiClient`): triggered daily + weekly
- Daily pulse:
  - Input: last 24h activity feed items for circle
  - Output: `AiPulse` with per-member `insight` lines
- Weekly pulse:
  - Input: weekly commitment data + challenge progress + streak
  - Output: summary, strongest day, most-missed goal, suggested challenge
- Stored in `circles/{circleId}/aiPulse/{pulseId}`

**Group 4.2 — AI Pulse UI** (`AiPulseView`)
- Shown as a pinned banner at the top of `CircleActivityView`
- Expandable card: headline summary, member lines, suggested challenge CTA
- "Generate now" button for moderators (rate-limited: once per 4h)

**Group 4.3 — AI-powered circle recommendations**
- At discovery: query circles matching user's active goal categories + timezone + coaching style
- `CircleRecommendationService`: scores circles by: category match, timezone proximity, coaching style match, activity level
- Shown as "Recommended for you" section in `CircleDiscoveryScreen`

**Group 4.4 — Per-circle notification preferences**
- `CircleNotificationPrefs` model: `{ circleId, mentions, challengeUpdates, weeklySummary, accomplishments, reactions, muteUntilMs }`
- Stored under `users/{uid}/circleNotifPrefs/{circleId}`
- UI: settings sheet accessible from circle Info tab → "Notification settings"
- Options: toggle each category, Mute circle, Mute until tomorrow

**Group 4.5 — Smart notification routing**
- Wrap existing `LocalNotificationsService` with circle-aware routing:
  - Mentions → always deliver if not muted
  - Challenge updates → respect preference
  - Reactions → muted by default
  - Weekly summary → respect preference
- Deep link payload: `circle:{circleId}` → opens `CircleDetailScreen`

---

## 5. Screen Route Map

```
/community                      → CommunityScreen (my circles list)
/community/create               → CircleCreateScreen
/community/discover             → CircleDiscoveryScreen
/community/circle/:id           → CircleDetailScreen
  └── tabs:
      chat                      → CircleChatView
      activity                  → CircleActivityView
      commitments               → WeeklyCommitmentsView
      challenges                → CircleChallengesView
      members                   → CircleMembersView
      info                      → CircleInfoView
```

---

## 6. Constraints & Rules (from PRD)

| Rule | Detail |
|---|---|
| Max circles per user | 3 (premium: 5, out of scope V1) |
| Circle size | 4 min, 8 max |
| Moderators | Creator + up to 1 assigned |
| Images | Only for proof categories (Workout / Study / Meal / Milestone / Goal Progress) |
| No video/voice | Explicitly excluded V1 |
| Chat exists to support accountability | Activity feed is primary; chat is secondary |
| Circle streak threshold | ≥ 60% of members active on given day |
| Challenge voting | >50% of members approve |
| Auto progress overrides manual | When entity is linked to a challenge |

---

## 7. Implementation Order

```
Phase 1 (Foundation)           → shippable: circles + chat
  Group 1.1  models + paths
  Group 1.2  repositories
  Group 1.3  providers
  Group 1.4  membership service
  Group 1.5  create screen
  Group 1.6  discovery screen
  Group 1.7  detail screen shell
  Group 1.8  chat tab
  Group 1.9  members tab
  Group 1.10 nav wiring

Phase 2 (Activity Feed)        → shippable: auto activity surfacing
  Group 2.1  feed domain + repo
  Group 2.2  bridge service
  Group 2.3  feed UI
  Group 2.4  commitments domain + repo
  Group 2.5  commitments UI

Phase 3 (Challenges + Streaks) → shippable: structured accountability
  Group 3.1  challenge domain + repo
  Group 3.2  challenge create + vote
  Group 3.3  challenge UI
  Group 3.4  progress auto-sync
  Group 3.5  circle streak
  Group 3.6  removal vote

Phase 4 (AI + Notifications)   → shippable: intelligent layer
  Group 4.1  AI pulse generation
  Group 4.2  AI pulse UI
  Group 4.3  recommendations
  Group 4.4  notif preferences
  Group 4.5  smart routing
```

---

## 8. Testing Strategy

Each group ships with:

- **Domain tests**: `toMap`/`fromMap` round-trips, enum storage values, validators
- **Repository tests**: fake Firestore (or `FakeFirebaseFirestore`) covering CRUD + stream ordering
- **Service tests**: `CircleActivityBridgeService`, `ChallengeProgressSyncService`, `CircleStreakService` with fake repos
- **Widget tests**: screens that can be tested without Firebase (overriding providers)

Integration tests (Phase 3+): challenge vote flow, streak calculation, removal vote.

---

## 9. Out of Scope (V1)

- Video / voice rooms
- Public social feed
- AI moderation
- Betting system
- Accountability partner 1:1 matching
- Dynamic AI-assembled circles
- Premium (>3 circles, >8 members)
