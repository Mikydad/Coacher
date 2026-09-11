# SidePal Time Tracking

## 1. Core idea

SidePal Time Tracking is a lightweight activity timeline.

The user does **not** manually track start and end times for every activity. Instead, they simply tell SidePal:

> **“This is what I’m doing right now.”**

SidePal automatically records the time at which that activity was logged.

For example:

> 10:03 PM — Scrolling
> 10:09 PM — Planning
> 10:50 PM — Cleaning

From those timestamps, SidePal can determine how long each activity lasted:

> Scrolling — 6 minutes
> Planning — 41 minutes
> Cleaning — 1h 05m

The user's job is only to create the timestamped events. SidePal handles the time calculations and organization.

The feature should feel much closer to quickly writing something in Notes than using a traditional time-tracking application.

---

# 2. The problem it solves

Most time-tracking applications require too much effort.

A typical tracker asks the user to:

1. Choose a task.
2. Start a timer.
3. Stop the timer.
4. Enter or edit details.
5. Categorize the activity.
6. Review the recorded session.

That works for people who are intentionally tracking billable hours or measuring a specific project.

But SidePal has a different purpose.

The user may simply want to understand:

> “Where did my day actually go?”

The easiest way to answer that is to allow the user to leave simple timestamps throughout the day.

The user doesn't need perfect tracking.

They just need to occasionally record:

> **What am I doing?**

SidePal can reconstruct the timeline from those moments.

---

# 3. Main interaction

The Time page should be extremely simple.

When the user opens it, SidePal immediately captures the current time.

For example:

**10:03 PM**

Then:

**What are you doing?**

`Scrolling`

And one primary action:

**Track**

The user presses Track.

SidePal creates:

> **10:03 PM — Scrolling**

That's the entire basic interaction.

There should be almost no friction between opening the feature and recording an activity.

---

# 4. Timestamp behavior

The timestamp is automatically populated using the current time when the user opens the tracker.

The user should not normally have to enter it manually.

However, the timestamp must be editable.

This is important because users will sometimes remember:

> “I actually started this 20 minutes ago.”

They can tap the timestamp and manually change it.

For example:

> 10:03 PM

can become:

> 9:43 PM

before saving the entry.

The timestamp should therefore represent **the time the user says the activity started**, not necessarily the exact moment they opened the page.

---

# 5. Activity entry

The activity is essentially a short description of what the user was doing.

Examples:

> Working on SidePal

> Scrolling TikTok

> Playing FIFA

> Gym

> Eating

> Cleaning the house

> Studying Flutter

> Watching a movie

The user should not be required to choose a category while logging.

The primary interaction should remain:

**Time + description + Track**

Categorization can happen later through AI or through analysis.

The logging experience should never feel like filling out a form.

---

# 6. The timeline model

The fundamental data model is an **activity event**, not a conventional timer session.

For example:

```text
10:03 PM
Scrolling

10:09 PM
Planning

10:50 PM
Cleaning
```

Each event represents:

> “At this point in time, I started doing this.”

The duration of an activity is derived from the timestamp of the next event.

So:

```text
10:03 — Scrolling
10:09 — Planning
```

means:

```text
Scrolling
10:03 → 10:09
6 minutes
```

Then:

```text
10:09 — Planning
10:50 — Cleaning
```

means:

```text
Planning
10:09 → 10:50
41 minutes
```

This means the user never needs to manually calculate durations for ordinary activity logging.

---

# 7. Example of a complete day

A user might record their day like this:

```text
10:00 AM — Woke up
10:03 AM — Scrolling
10:09 AM — Planning
10:26 AM — Bathroom
10:50 AM — Cleaning house
11:55 AM — Playing game
7:00 PM — Eating
7:04 PM — Playing game
7:06 PM — Wasting time
7:30 PM — Gym
9:30 PM — Got home
10:00 PM — Eating
12:00 AM — Playing game
1:00 AM — Working on bank information
2:00 AM — Sleep
```

The user doesn't need to write durations.

SidePal can transform this into:

```text
10:00 → 10:03
Waking up · 3m

10:03 → 10:09
Scrolling · 6m

10:09 → 10:26
Planning · 17m

10:26 → 10:50
Bathroom · 24m

10:50 → 11:55
Cleaning house · 1h 05m

11:55 → 7:00
Playing game / unlogged period
```

The exact treatment of large gaps should be carefully defined so SidePal does not pretend to know what happened during periods the user didn't log.

The fundamental rule is:

> **SidePal should distinguish between recorded information and inferred information.**

It should never manufacture certainty.

---

# 8. Gaps in the timeline

Users will forget to log.

That is expected.

For example:

> 10:03 — Scrolling
> 10:09 — Planning
> 2:00 — Sleep

SidePal should not necessarily claim:

> “You planned for 3h 51m.”

The user may have done many things during that period.

The system should recognize a long gap as an **untracked period** rather than automatically assigning the entire gap to the previous activity.

This is important because the purpose of the feature is to help the user understand their time, not create false precision.

A future version could allow the user to fill a gap manually:

> **4h 12m untracked**
>
> What happened during this period?

But this should not be required for V1.

---

# 9. Optional duration

The user can optionally provide a duration when creating an entry.

For example:

**What are you doing?**

> Study Flutter

**Duration**

> 30 minutes

**Track**

This creates a timed activity:

> 7:42 PM — Study Flutter
> Planned duration: 30 minutes

The duration is optional.

If the user doesn't provide one, SidePal simply records the timestamp.

---

# 10. Why duration is different from normal tracking

There are two use cases.

### A. Recording reality

The user says:

> 7:42 — Studying Flutter

They aren't asking SidePal to remind them of anything.

They're simply recording what they're doing.

### B. Intentionally spending a fixed amount of time

The user says:

> 7:42 — Studying Flutter
> 30 minutes

Now SidePal understands:

> “This person intends to spend 30 minutes on this activity.”

When the duration ends, SidePal can remind the user to log what they are doing next.

For example:

> **30 minutes are up.**
>
> What are you doing now?

The user can then log:

> Still studying Flutter

or:

> Watching YouTube

or another activity.

This makes the duration feature optional rather than forcing every activity into a timer.

---

# 11. Reminder philosophy

The reminder should not feel like an alarm or productivity enforcement.

It should simply help maintain the timeline.

Instead of:

> “You failed to complete your task.”

SidePal says:

> **30 minutes are up. What are you doing now?**

The purpose is:

**continue the timeline.**

Not:

**force the user to be productive.**

---

# 12. Planned task suggestions

The Time Tracker can eventually use SidePal's existing planned tasks to reduce typing.

Suppose the user has planned:

> 7:00–8:00 PM
> Learn Flutter

At 7:42 PM they open Time Tracking.

SidePal can show:

### Suggested from your plan

> **Learn Flutter**

And:

> **Something else**

The user can simply tap:

> Learn Flutter

and track it.

This creates a useful relationship between planned time and actual time.

For example:

```text
Planned:
Learn Flutter
7:00–8:00

Actual:
Started at 7:42
```

This does not mean SidePal should judge the user for starting late.

It simply creates useful information that can later appear in reflection.

---

# 13. Relationship with Direction

Direction and Time Tracking should remain separate concepts.

### Direction

> Where am I trying to go?

### Plan

> What do I intend to do?

### Time Tracking

> What am I actually doing?

### Reflection

> What does SidePal notice about the relationship between those things?

For example:

**Direction**

> Launch SidePal

**Plan**

> Work on SidePal from 7:00–9:00 PM

**Actual timeline**

> 7:42 — SidePal
> 8:18 — YouTube
> 8:45 — SidePal

SidePal now has enough context to eventually say:

> You planned two hours of SidePal work tonight, but your timeline shows two shorter work periods separated by YouTube.

It doesn't have to tell the user what they should do.

It simply shows them what happened.

---

# 14. The purpose of the feature is reflection

The Time Tracker should not primarily be marketed as:

> “Track every minute of your life.”

That sounds exhausting.

The better concept is:

> **Record your day. See where your time went.**

The user is creating a timeline that SidePal can later reflect back to them.

This means imperfect tracking is okay.

If the user logs ten activities today, SidePal has useful information.

If they log three tomorrow, that's okay too.

The system should never punish incomplete tracking.

---

# 15. Daily reflection

Once there is enough data, SidePal can summarize the day.

For example:

### Your day

> You logged 9h 42m of activities.

**Work**

> 3h 15m

**Exercise**

> 1h 20m

**Entertainment**

> 2h 40m

**Other**

> 2h 27m

Then:

### Something I noticed

> Most of your focused work happened after 9 PM.

The wording should remain observational.

Avoid:

> “You wasted 2 hours.”

Prefer:

> “You spent about 2 hours on gaming today.”

The user can decide whether that was good or bad.

---

# 16. Weekly reflection

Once there is enough data, SidePal can identify patterns.

For example:

> ## Your week
>
> You logged 47h 20m.
>
> **Work:** 16h 40m
> **Learning:** 5h 10m
> **Gaming:** 9h 15m
> **Scrolling:** 6h 30m
> **Exercise:** 5h 05m
>
> ### Something I noticed
>
> Your focused work was most consistent between 9 PM and midnight.
>
> You also tended to start planned work later than scheduled.

The important thing is that the insight is based on the user's own data.

---

# 17. Direction makes the reflection more meaningful

If the user has set:

**This month**

> Get SidePal ready for launch

SidePal can eventually put that context next to their actual time.

For example:

> **Your month**
>
> Your current focus is getting SidePal ready for launch.
>
> You logged 31h 20m working on SidePal this month.
>
> You also logged 24h 10m gaming and 18h 40m scrolling.
>
> **Something I noticed**
>
> Your SidePal work was concentrated into late-night sessions.

The goal is not to say:

> “You should spend less time gaming.”

The goal is:

> **“Here is what your behavior looks like relative to what you said matters.”**

That is the mirror.

---

# 18. What the feature should NOT do

To protect the simplicity of SidePal, V1 should avoid:

* automatic app tracking
* screen-time surveillance
* location tracking
* complicated categories
* mandatory start/stop timers
* productivity scores
* streaks
* rewards
* penalties
* constant reminders
* judgmental language
* requiring users to explain every gap
* requiring perfect tracking

The user should remain in control.

---

# 19. V1 scope

Because SidePal is close to launch, the first implementation should be small.

### Core V1

**Time page**

* Current timestamp automatically populated
* Editable timestamp
* Activity text field
* Track button
* Today's timeline
* Edit existing entries
* Delete existing entries
* Duration calculated from subsequent entries
* Optional manually entered duration
* Local-first persistence
* Sync through the normal SidePal data architecture

The feature does not need sophisticated AI to launch.

The most important thing is getting the underlying timeline data correct.

---

# 20. Later versions

Once the basic timeline exists, additional capabilities can be layered on.

### V1.1

* Planned task suggestions
* Duration reminders
* Better gap handling
* Basic categories

### V1.2

* Daily summaries
* Weekly summaries
* Planned vs actual comparisons
* AI-generated observations

### Later

* Direction-aware reflections
* Long-term time patterns
* Monthly comparisons
* Natural-language questions about time
* More intelligent activity categorization

For example:

> “Where did most of my time go this month?”

or:

> “What do I spend more time on than I think?”

---

# 21. The core product loop

The feature ultimately creates this loop:

**Log**

> 10:03 — Scrolling

↓

**Log again**

> 10:09 — Planning

↓

**SidePal calculates**

> Scrolling = 6 minutes

↓

**Keep logging**

↓

**SidePal builds a timeline**

↓

**SidePal finds patterns**

↓

**SidePal reflects**

> “Something I noticed…”

↓

**User notices their own behavior**

That final step is the reason the feature exists.

---

# 22. The product principle

The strongest way to describe the feature internally is:

> **SidePal doesn't track your time for you. It makes it effortless for you to record your time, then helps you see what you actually did with it.**

And the larger SidePal philosophy is:

> **Don't tell people how to live. Help them see how they're living.**
