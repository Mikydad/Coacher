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
