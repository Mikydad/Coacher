Things I Completely Agree With
1. Deterministic Opportunity Planner

100% yes.

This is exactly what I would build.

Let AI understand:

"Call my cousin tomorrow."

Then let deterministic code decide:

available windows
scoring
reminders
fallbacks

That's how you get reliability.

2. AI doesn't choose times

Again, yes.

The AI shouldn't randomly decide:

3:17 PM.

Instead:

AI says

This is a phone call.

Engine says

Best opportunity is 5:30 while walking.

Perfect separation.

3. New Intention entity

I love this.

Don't stretch Tasks.

Don't stretch Reminders.

Don't stretch Goals.

An intention is fundamentally different.

Examples:

Call my cousin.

Buy flowers before visiting Mom.

Remind me to ask John about the trip.

These aren't tasks in the traditional sense.

4. Memory screen

Absolutely.

If AI remembers something...

The user should see it.

Edit it.

Delete it.

Correct it.

Transparency builds trust.

5. Silent sync

Agreed.

Nobody should ever think about sync.

Things I'd Change
1. "LLM never decides timing."

I disagree slightly.

Their version:

LLM

↓

Never decides.

Mine:

LLM

↓

Makes recommendation

↓

Engine validates

↓

Decision

Example:

LLM:

Mike usually calls family while walking.

Engine:

Walking detected.

25 minutes free.

Compatible.

Decision approved.

The LLM should have an opinion.

The engine should verify it.

That's more human.

2. AI parsing only

I think they're underusing AI.

They want AI for:

parsing
memory extraction
phrasing

I'd add:

prioritization
planning
coaching
brainstorming
recommendation
conflict resolution
asking clarifying questions

Otherwise SidePal risks becoming another deterministic system with a friendly voice.

3. Separate quota

Absolutely yes.

Background intelligence should NEVER consume chat quota.

Imagine:

Morning briefing.

Memory extraction.

Planning.

Then the user opens chat...

"Quota exceeded."

That would feel terrible.

I completely agree with having a separate system budget.

The Big One I'd Add

This is actually the biggest thing I think is missing.

They're building:

User

↓

Intention

↓

Reminder

I'm building:

User

↓

Relationship

Meaning...

The AI should understand:

Mom

is

Mother

not just

Person #17

It should know:

John

is your cofounder.

Sarah

is your sister.

Alex

is your manager.

Because later it can say:

You haven't talked to your sister in a while.

instead of

Reminder #238.

That's what makes assistants feel human.

Q1 — Timing autonomy

I'd answer:

Yes.

If the user says:

Call my cousin tomorrow.

That's already permission.

The assistant should decide the time.

No confirmation needed.

Q2 — Memory

I LOVE their suggestion.

Raw conversation:

Delete after 48h.

Memory:

Keep.

Summary:

Keep.

Facts:

Keep.

Everything visible.

I'd only change one thing.

I don't think inferred memories need confirmation every time.

Instead:

Label them.

Example:

Inferred

Mike prefers coding in the morning.

Tap:

✓ Correct

✏ Edit

🗑 Delete

Much smoother.

Q3 — Quota

Agree completely.

System budget.

Never affect user budget.

Q4 — Fixed reminders

100%.

Opportunity scheduling should augment.

Never replace.

If I explicitly choose:

4 PM.

Don't second guess me.

Q5 — Siri

I'd actually postpone it one phase.

Reason:

Voice conversation is 90% of the value.

Siri launch is 10%.

Ship:

Voice.

Then:

Siri.

Not the other way around.

Q6 — Permissions

I LOVE this recommendation.

Progressive permissions.

Start with:

Calendar.

Later:

Activity.

Later:

Location.

Never ask for everything on day one.

Q7 — Sign in

I'd keep sign in.

Memory.

History.

Cross-device sync.

Assistant.

These all depend on identity.

Q8 — Quiet philosophy

100%.

This is something I care about a lot.

The assistant shouldn't be loud.

It should be helpful.

Imagine:

SidePal sends 12 notifications.

People uninstall it.

Instead:

One.

Perfect.

Notification.

The biggest thing I think should become a principle

I would literally add this to the PRD.

SidePal Design Principle

The assistant should reason continuously, not merely react to commands.

That changes everything.

Examples:

Bad:

User:

Remind me tomorrow.

Good.

Better:

User:

I'm visiting my parents this weekend.

SidePal thinks:

Maybe flowers.

Maybe fuel.

Maybe call beforehand.

No reminders yet.

Just understanding.

Later:

You're passing a florist on your way.

That's where the magic happens.

One more feature I'd eventually add

This isn't for V1, but I think it's a perfect fit.

I call it the "Thinking Loop."

Every so often (locally, quietly), SidePal asks itself:

Given everything I know...

Is there something Mike forgot?
Is there something he's avoiding?
Has something changed?
Should I move an intention?
Does a goal need attention?
Has a better opportunity appeared?

Not because the user asked.

Because that's what a real assistant does.

That one idea could become the foundation of everything proactive in SidePal.