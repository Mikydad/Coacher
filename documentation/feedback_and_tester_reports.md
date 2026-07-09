# In-App Feedback & Tester Bug Reports

*Added 2026-07-09 for the friends-and-family beta.*

## What exists

**1. All users — "Send Feedback" (Profile → Core Optimization).**
A form at route `/feedback` with type chips (Bug / Feature idea / Question /
Other), a 2000-char message field, and Send. A diagnostic context snapshot is
attached automatically (see below); no screenshot in this flow.

**2. Testers — floating bug bubble.**
A draggable bug icon overlaid on *every* screen (tabs, pushed details,
dialogs). Tapping it:
1. hides the bubble for one frame and captures a screenshot of the current UI,
2. collects the context snapshot,
3. opens a bottom sheet: screenshot preview with an "Include screenshot"
   toggle, type chips (Bug preselected), description, Send report.

### Enabling tester mode
Tap the **version footer on the Profile page 7 times** (quick taps; a
countdown SnackBar appears after the 4th). Same gesture toggles it off.
Persisted per device (`tester_mode_enabled_v1` in SharedPreferences) — same
build for everyone, no special tester binaries. Enable it on each
family/friend phone right after installing.

## Where reports land

- Firestore: top-level **`feedback/{feedbackId}`** collection
  (`userId`, `type`, `message`, `context` map, optional `screenshotUrl`,
  `status: 'new'`, `createdAtMs`, `schemaVersion`).
- Screenshots: Storage at **`feedback/{uid}/{uid}_{reportId}.png`**.
- **Review in the Firebase console** (Firestore → Data → `feedback`).
  Clients cannot read/update/delete — create-only. If volume ever justifies
  it, the planned upgrade is an admin-only inbox screen inside the app gated
  to the owner uid.

## Context snapshot keys

`appVersion`, `buildNumber`, `platform`, `osVersion`, `deviceModel`, `uid`,
`tab` (home/coach/goals/progress/community/profile), `topRoute` (named route,
tracked by `FeedbackRouteTracker` NavigatorObserver), `brightness`,
`connectivity`, `syncPending` (offline queue size), `timestampLocalIso`.
Every lookup is individually try/caught → `'unknown'`; feedback never fails
because a plugin does.

## Design decisions & invariants

- **Rules/model lockstep**: the `hasOnly` key list in `firestore.rules`
  (`match /feedback/{feedbackId}`) mirrors `FeedbackReport.toMap()`. A unit
  test (`feedback_report_model_test.dart` → "toMap key set matches…") fails
  if they drift. Change both together.
- **Screenshot uploads happen BEFORE the Firestore create** — rules are
  create-only, so there is no second chance to attach the URL. Upload failure
  degrades to a text-only report with `context.screenshotUploadFailed='true'`.
- **Offline**: a failed Firestore write is queued via
  `SyncService.enqueueUpsert` (entityType `feedbackReport`) and replays on
  reconnect. Screenshot bytes are never queued (JSON-only queue).
- **Rate limit**: 30s between submissions (client-side, prefs), armed only
  after a successful submit. Message hard-capped at 2000 chars in UI, model
  validation, and rules.
- **Screenshot capture**: `RepaintBoundary(appScreenshotBoundaryKey)` wraps
  `CoachForLifeApp` in `main.dart` — *above* the MaterialApp because that is
  rebuilt (keyed on brightness) on theme toggle. Captured at pixelRatio 1.0
  (~150–600 KB PNG). The bubble hides itself for one frame first so it never
  appears in its own screenshot.
- **Bubble placement**: injected via `MaterialApp.builder` (covers every
  route). It sits above the Navigator, so it opens the report sheet through
  `appNavigatorKey.currentContext` and route names come from the observer,
  not `ModalRoute.of`.

## Deploying the rules

```
firebase deploy --only firestore:rules,storage --project coach4life-afaaa
```

Both rules files live in the repo (`firestore.rules`, `storage.rules`) and are
wired in `firebase.json`. Remember (errors.md #17): storage rules that read
Firestore need the Rules Firestore Service Agent role — already provisioned.

## Key files

| File | Role |
|---|---|
| `lib/features/feedback/domain/models/feedback_report.dart` | model + type enum |
| `lib/features/feedback/data/firestore_feedback_repository.dart` | upload-then-create, offline fallback |
| `lib/features/feedback/data/feedback_screenshot_storage.dart` | Storage putData |
| `lib/features/feedback/application/feedback_submit_service.dart` | shared submit path + rate limit |
| `lib/features/feedback/application/feedback_context_collector.dart` | context snapshot + `packageInfoProvider` |
| `lib/features/feedback/application/tester_mode_controller.dart` | tester flag + `SevenTapDetector` |
| `lib/features/feedback/application/app_screenshot.dart` | boundary key + capture |
| `lib/features/feedback/application/feedback_route_tracker.dart` | NavigatorObserver |
| `lib/features/feedback/presentation/feedback_screen.dart` | all-user form |
| `lib/features/feedback/presentation/tester_bug_bubble.dart` | bubble layer (via `app.dart` builder) |
| `lib/features/feedback/presentation/tester_report_sheet.dart` | tester bottom sheet |
| `lib/features/profile/presentation/profile_screen.dart` | Send Feedback row + `_VersionFooter` (7-tap) |
