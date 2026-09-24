# Content Ideas — the SidePal journey

Raw material for posts, threads and videos about building SidePal. Each entry
is a real thing that happened, written as a story beat: what we expected, what
actually happened, what we learned. Add to it whenever something is worth
telling. Dates are real so the timeline holds up.

Format per entry: **Hook** (one line you could open a video with), **What
happened**, **The turn** (the moment it got fixed or made sense), **Takeaway**,
**Formats** (which content shapes it suits).

---

## 2026-09-19/20 · "It took 24 hours to upload one build"

**Hook:** "I pressed Upload at 10pm. The build reached testers at 10pm the
next day. Here's every wall I hit in between."

**What happened:** The app was done, the App Store Connect record existed,
the certificate was fine. First archive built in 11 minutes on a slow
connection, exported, and Xcode said: rejected. Apple now requires the iOS 26
SDK, which only ships with Xcode 26. My Xcode was 16.4.

Then the chain reaction:
- Xcode 26 needs macOS 15.6. I was on 15.5. One OS update and restart.
- The Mac App Store only offers Xcode 27, which is Apple Silicon only. My
  MacBook is Intel. So the App Store route is dead for this machine forever.
- Homebrew has stopped shipping Intel binaries too. The tool I tried to
  install to download Xcode wouldn't compile.
- The download tool I did get picked the Apple Silicon build of Xcode 26.3
  by mistake. 4 GB, unusable: "Bad CPU type in executable".
- Found the Universal build on Apple's developer site, downloaded it by hand,
  installed. Then Xcode 26 wants the iOS platform as a separate 8 GB download.
- Rebuilt. Uploaded. Success. Only warning: "your minimum iOS is 13, from
  spring 2027 it must be 15." Raised it to 15 the same night.

**The turn:** Realising the App Store listing said "requires a Mac with M1 or
later." That one line explained an hour of confusion.

**Takeaway:** An Intel Mac can still ship iOS apps today, but it has an expiry
date. Xcode 27 dropped Intel. When Apple starts requiring the iOS 27 SDK,
this laptop can't publish any more. Plan the hardware change before then.

**Formats:** long-form "day in the life" video; a thread with the timeline
as screenshots; a short on "your Mac has a shipping expiry date."

---

## 2026-09-20 · "The build that installed fine and showed a white screen"

**Hook:** "Every test build worked for two months. The first TestFlight build
was a blank white screen. Same code. Here's why."

**What happened:** Build 3 processed, I installed it from TestFlight, tapped
the icon, and got a white screen forever. No crash, no error, nothing.

Plugged the phone in, launched the app from the terminal, streamed the
phone's system log, and watched the app's own boot breadcrumbs:

```
[boot] binding ready
[boot] resolving storage dir
[boot] opening isar at /var/mobile/.../Documents
[boot] UNCAUGHT: IsarError: Could not initialize IsarCore library
```

The local database library couldn't be found inside the app.

**The turn:** Comparing yesterday's working binary with today's broken one.
The working one exported 108 database functions. The broken one exported 0.
Then the experiment that settled it: take the working binary, run Apple's
`strip` tool on it the way an App Store archive does, count again: 0. Run it
the gentler way: 108.

App Store archives strip symbols. Debug and device test builds never do.
The database library is looked up by name at runtime, so stripping its name
kills it. Two months of green device tests never exercised the one step that
mattered.

One line in a config file fixed it. Rebuilt, installed straight to the phone
over USB before uploading, watched it boot, then uploaded build 4.

**Takeaway:** "Works on my device" and "works from TestFlight" are different
builds. Test the artifact you ship, not the one you develop with. And leave
breadcrumbs in your boot sequence, they turned a silent hang into a
one-line diagnosis.

**Formats:** the strongest technical story so far; a 5-minute "debugging a
white screen" video with the log on screen; a Flutter-community post (this
bites anyone using dart:ffi packages in archived builds).

---

## 2026-09-20 · Small ones worth a line

- **Push notifications almost silently failed.** The APNs key from the team
  migration was scoped to Sandbox only. Fine for debug builds, dead for
  TestFlight. Had to mint a new key with Sandbox & Production. Nobody warns
  you; notifications just don't arrive.
- **A teammate's expired login broke the export.** Xcode had three Apple IDs
  signed in. It tried the wrong one for the company team and failed with
  "No signing certificate found." Removing the stale account fixed it.
- **The "processing" email never came.** The build was ready on the website
  for an hour before I noticed. Don't wait for Apple's email, check the tab.
- **Internal tester showed "No Builds Available" and TestFlight asked for a
  redeem code.** It just needed time. Fifteen minutes later it worked.
- **The yellow dot.** iOS marks beta apps with a dot next to the name. First
  time you see it, it looks like a warning. It isn't.

---

## 2026-09-22 · "Loading your plan… for a full minute"

**Hook:** "The app's first screen took up to a minute to appear. The data it
was waiting for didn't exist."

**What happened:** Testers reported that the first launch, guest or a fresh
sign-in, sat on "Loading your plan…" for ages. The gate behind that spinner
waited for a full Firestore → local reconcile: about twenty collections,
queried one after another, with a 60-second ceiling. On a slow connection
each round trip is seconds, so twenty of them IS the minute. And for a
brand-new guest account the answer to every one of those queries was
"nothing here": a uid minted two seconds earlier has no data to pull.
Switching from guest to an existing account ran the whole thing twice, back
to back.

**The turn:** Reading the code as a timeline instead of as features. Every
piece had a good reason (tombstones first, cursors, a timeout so the app
can't hang forever), but nobody had added up the wait. Once the spinner was
a sum of round trips, the fix wrote itself: skip the pull for accounts that
were just created, reveal the app as soon as the first screen's data has
landed (or after five seconds, whichever comes first), run the rest of the
sync in parallel behind the live UI, and hold the other startup chores
(push registration, streak checks) until the user can already see
something. A "cancel" that couldn't cancel, the timeout threw and the sync
kept running, got a real checkpoint too.

**Takeaway:** Perceived startup should never be a function of network
speed. Local-first means the screen comes from the device; the network
fills in behind it. And when a loading screen is slow, count the round
trips before you optimise any single one.

**Formats:** a short before/after screen recording on a throttled
connection; a thread on "why your loading screen is a sum, not a max"; a
Flutter post on cooperative cancellation of long async pipelines.

---

## Backlog of earlier beats (expand when needed)

- 2026-09-12 · Moving the app from a personal Apple account to the LLC's
  team: new bundle ID, new certificates, new push key. What breaks, what
  doesn't.
- 2026-09-12 · Crashlytics wired up; three old crashes written off as
  pre-migration noise.
- The offline-first architecture decision: every tap writes locally first,
  sync happens later. Why "airplane mode must be indistinguishable from
  online" became a hard rule.
- Reminder system V2, Direction, Time Tracker, Progress Periods, Public
  Commitment Cards: each shipped as a PRD → build → deploy cycle. Good for
  "how I plan a feature" content.

## 2026-09-23 · The QA report that was right about everything except what mattered

- **Hook:** An external tester's PDF called our reminder "Server backup: Not
  registered" row a Blocker. It wasn't. The Minor they buried was the real bug.
- **What happened:** First job was authenticity: every string, cap ("of 56"),
  weight (60/40) and label in the report exists in the codebase, so the tester
  had a real build. Then the ranking fell apart: all three top findings were
  one honest-but-unreadable diagnostics panel. The "no onboarding tour" note
  was the one worth chasing.
- **The turn:** The obvious diagnosis ("the pref is never cleared") was wrong;
  the wipe clears it. The real holes were at the account boundary: a
  device-level verdict, a provider rebuilt by Riverpod one frame before the
  wipe (judging the new account by the old one's rows), and a capped first
  reveal that lets the probe run before an existing account's tasks land.
  Then my own fix hung a test: the consumer of a "settled" signal reopened it.
- **Takeaway:** Verify the report, then re-rank it. And the second diagnosis
  is often the right one; write the first one down so you can retract it
  cleanly.
- **Formats:** thread ("how I audited a QA report"), short post on
  severity inflation from diagnostics copy, code-walk of the account
  boundary fix.


## 2026-09-24 · 12.5 % crash-free, zero real crashes

- **Hook:** The first week of TestFlight data said one in eight users
  crashed. Not one of them had.
- **What happened:** Couldn't open the console (the in-app browser isn't
  signed in), so I read the reports through the Firebase CLI's MCP server
  over stdio. Every "crash" was a Dart exception the app walked away from:
  a background circle-index repair timing out on a weak link, a Firestore
  listener denied after sign-out, a widget reading `ref` after it was
  gone. The global handler marks every unhandled async error fatal, so the
  dashboard counted survivable hiccups as deaths.
- **The turn:** The fix was not "stop marking things fatal". It was making
  each fire-and-forget site own its failure: catch, decide, log or report.
  The sync abort guard was reporting itself as a failure every time it did
  its job. And the one genuine crash in the list was the build-3 strip
  regression, already dead.
- **Takeaway:** Crash-free users measures your error handling discipline
  before it measures your stability. Read the stack under the number.
- **Formats:** short post ("your crash-free rate is lying"), thread on
  reading Crashlytics via CLI when the console won't let you in, code-walk
  of the four one-line fixes.
