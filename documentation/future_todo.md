# Future Todo — Coach for Life

This file tracks medium and long-term work items that are deferred until core UI is functional.
Add items here when they are discovered but out of scope for the current sprint.

---

## Security

- [ ] Tighten Firestore rules: keep `users/{userId}/...` scoped to `request.auth.uid`; add rules for any new collections before shipping.
- [ ] Long-term auth plan: migrate from anonymous sign-in to email/Apple/Google with account linking so user data survives app reinstall.
- [ ] Enable Firebase App Check before public release to prevent API abuse.

---

## Sync reliability

- [ ] Verify sync queue retry logic, operation ordering, and conflict handling under offline/online transitions.
- [ ] Test reminders end-to-end on a physical device (permissions, background fetch, time zones).
- [ ] Replace silent `debugPrint` failures in bootstrap (`AuthInitializer`, `OfflineStore`) with user-visible diagnostics or structured logging.

---

## Testing and CI

- [ ] Add widget/integration tests for critical flows: home load, task add, timer start/stop, scoring dialog.
- [ ] Set up CI pipeline: `flutter analyze`, `flutter test`, optional iOS build runner.

---

## Architecture

- [ ] Review Firestore data model: add indexes for queries needed by execution day loader, scoring, and streaks.
- [ ] Decide on structure under `users/{uid}` for growth (subcollections vs flat documents).
- [ ] Create separate dev/staging Firebase projects or apps before sharing builds externally.

---

## Source control

- [ ] Initialize a git repository.
- [ ] Add `.gitignore` covering `build/`, `.dart_tool/`, `*.env`, `GoogleService-Info.plist` (or use environment-based injection).

---

## Product / features (post-MVP)

- [ ] Community tab (bottom nav index 3) — currently dead.
- [ ] Profile tab (bottom nav index 4) — currently dead.
- [ ] Progress / analytics tab (bottom nav index 2) — currently dead.
- [ ] Coach Insights card: replace hardcoded quote with AI-generated or rule-based insight using real session data.
- [ ] Streak logic: persist and calculate streak from `timerSessions` or scoring history.
- [ ] "I'm Distracted" button: decide on behavior (interrupt session? log distraction event?).
