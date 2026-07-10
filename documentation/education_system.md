# Education System — Round 1

*Added 2026-07-10 for the friends-and-family beta.*

Users learn PathPal by using it, not by reading slides. One content registry
powers three surfaces; updating a guide updates every surface at once.

## The registry (single source of truth)

[`lib/features/education/domain/feature_guides.dart`](../lib/features/education/domain/feature_guides.dart)
— 9 `FeatureGuide`s (`tasks`, `disciplineModes`, `focus`, `reminders`,
`goals`, `circles`, `analytics`, `planTomorrow`, `coachAi`), each with
title/emoji/oneLiner/what/why/howSteps/tips, lowercase `keywords` for AI
topic matching, `suggestedPrompts` chips, and an optional Try-it destination.

**Content rules** (enforced by `feature_guides_test.dart`):
- No string may contain an `AiInformationalOutputGuard` forbidden substring
  (e.g. "Firestore") — the guard would replace the AI's whole teaching answer.
- Keywords lowercase; `matchTopic` picks the longest matching keyword.
- `isEducationQuestion` = education phrase ("what is", "teach me", …) AND a
  topic match — this gate is what lets questions bypass fast-paths safely.

## Surface 1 — Getting Started guided tour (new users only)

A spotlight walkthrough (`getting_started_tour.dart`, mounted in
`MaterialApp.builder` like the tester bug bubble so it follows across
routes): the screen dims except the target, which pulses with a glow, and an
animated instruction card points at it. Steps advance ONLY when the user
performs the real action — never a "Next" button:

1. `tapAddTask` — spotlight on Home's ADD TASK tile ("Tap here…").
2. `nameTask` — follows into the Add Task screen, spotlights the title field.
3. `saveTask` — spotlights the save button once a title is typed.
4. `completeTask` — back home, collapses to a small NON-BLOCKING hint chip
   ("tap the circle when you're done") because real life may take hours
   between creating and finishing the task; the first task's checkbox glows.
5. `seeProgress` — on completion, spotlights the progress card with a
   celebration, then auto-finishes forever.

"Skip tour" is always visible. Backing out of Add Task without saving rewinds
to step 1. Targets are `TourTargets` GlobalKeys attached in home_screen and
add_task_screen (plus a title-typed hook); a target that isn't on screen
renders no spotlight, which makes off-script navigation safe. The dim is four
plain boxes around the target hole, so taps on the target pass through to the
real button.

- State machine: [`getting_started_controller.dart`](../lib/features/education/application/getting_started_controller.dart).
  Signals: route changes (reuses `FeedbackRouteTracker`), title text hook,
  `todayAllTasksRowsProvider` (created / completed-or-partial) and
  `analyticsPeriodBundleProvider` (`taskDay.weightedCompletionRate > 0` or
  streak > 0 — plain task completion doesn't reliably move the goals/habits
  streak), latched monotonic; resume derives the step from what already
  happened.
- New-vs-existing detection: tri-state pref `education_onboarding_state_v1`
  (absent → probe once: any Isar task or streak > 0 ⇒ existing user, silently
  'done'; else 'active'). The tri-state prevents the classic bug where
  creating your first task makes you look like an existing user on relaunch.
  Safe ordering: FirstLaunchGate seeds Isar before Home builds.
- Account switch wipes the onboarding pref (auth_session_policy.dart);
  seen-cards stay device-level.

## Surface 2 — First-time feature cards

[`first_time_feature_card.dart`](../lib/features/education/presentation/first_time_feature_card.dart)
shown once at the top of 7 screens: Focus, Circles, Goals, Progress,
Plan Tomorrow, Discipline Modes (Profile), Coach AI. Collapsed
(emoji + title + oneLiner) with "More" expanding what/how, "Got it"
(dismiss forever, pref `education_seen_cards_v1` StringList), "Try it"
(navigates to the feature). Cards render nothing until prefs load — a
dismissed card can never flash.

## Surface 3 — Coach AI as teacher

Ask "What is Discipline Mode?", "teach me how reminders work", "Which mode
should I use?" — the coach answers from the matching guide, connected to the
user's real data.

Pipeline (all client-side; the cloud function is untouched):
1. `ai_intent_router.dart`: education phrases route **query** (checked before
   mutate verbs — "explain how to *set* a reminder" used to route mutate).
2. `ai_intent_parser.dart`: `FeatureGuides.isEducationQuestion` +
   `matchTopic` run **before** `AiCapabilityRegistry.detectUnsupported` —
   otherwise "What are Circles?" gets the canned "Circles are not available
   in Coach AI" answer. Commands ("add me to a circle") are not
   education-shaped and still hit the unsupported path (regression-tested
   both directions in `ai_education_grounding_test.dart`).
3. The matched guide's `toPromptBlock()` travels via
   `payload.featureGuide` → `_buildUserPrompt` emits a `FEATURE GUIDE` block;
   one system-prompt rule tells the coach to teach from it (<100 words,
   coach voice, end with a next step).
4. The guide's `suggestedPrompts` lead the chips under the answer.

Cost: ~200 extra words only on matched turns (gpt-4o-mini; 120k-char input
cap, no server change).

## Adding or editing a guide

Edit `feature_guides.dart` only. Every surface updates. Run
`flutter test test/features/education/` — the content tests catch forbidden
substrings, missing keywords, and id collisions. If you add a screen card,
drop `FirstTimeFeatureCard(guideId: '<id>')` at the top of the screen's
scroll body.

## Deferred (Round 2 candidates)

`?` help icon per screen (render the same guide in a bottom sheet), Learning
Center screen (list + search over the registry), videos/GIFs, proactive AI
feature introductions (gate hard against nagging).
