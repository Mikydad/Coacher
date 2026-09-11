Direction is where the user tells SidePal what they are trying to move toward — without turning it into a task list.

It answers:

“What matters to me right now?”

Not:

“What tasks do I need to complete?”

That distinction is the whole feature.

1. The Direction page

I would give it its own page because it's fundamentally different from Tasks, Plans, or Time.

The page could simply say:

Your Direction

Give SidePal some context about where you want your life to go.

Then three sections:

This year

What do you want this year to be about?

Build a successful business

This quarter

What are you focused on right now?

Launch SidePal

This month

What matters most this month?

Get SidePal ready for launch

And that's basically the entire setup.

No deadline fields.

No percentages.

No priority levels.

No progress bars.

No subtasks.

No "complete goal" button.

2. Why three time horizons?

Because what matters to someone changes depending on the distance.

For example:

Year

Build a successful business.

That's broad.

Quarter

Launch SidePal.

That's more immediate.

Month

Get SidePal ready for launch.

That's even more concrete.

Then SidePal has a hierarchy of context:

Year → Quarter → Month

The user doesn't need to manually connect them.

SidePal can understand that:

"Get SidePal ready for launch"

is related to:

"Launch SidePal"

which is related to:

"Build a successful business."

3. These aren't "goals" in the traditional sense

This is important for the product.

If you call it Goals, users will expect:

Goal: Launch SidePal
Progress: 64%
Deadline: September 30
Tasks: 12/20 complete

That's not what you're trying to build.

Direction is more like:

This is what I'm trying to move toward.

The user doesn't necessarily know exactly how they're going to get there.

That's SidePal's job to help with later.

4. Direction doesn't constantly interact with the user

This is another important part.

If I say:

This month: Get healthier

I don't want SidePal constantly saying:

"Your goal is getting healthier. You should exercise."

That's annoying.

Instead, Direction sits quietly in the background.

It becomes context for SidePal's other features.

For example:

Plan Tomorrow

SidePal knows:

This month: Get healthier.

So when helping plan tomorrow, it can consider that.

Time

The user logs:

10:03 — YouTube
11:20 — Gym
1:00 — Work

SidePal doesn't immediately judge them.

It records reality.

Insights

Later:

Something I noticed

Your focus this month has been getting healthier.

You've logged 4 gym sessions this week.

Most of your exercise happened in the evening.

That's useful.

5. Direction + Time is where it becomes powerful

Imagine the user sets:

Direction

This quarter

Build my business.

Then over the next month SidePal sees:

SidePal work       32h
Learning            9h
Gaming             21h
Scrolling           17h
Gym                  8h

SidePal doesn't say:

"Gaming is bad."

Instead:

Something I noticed

Your current direction is building your business.

You spent 32 hours working on it this month.

You also spent 38 hours gaming and scrolling.

Most of your business work happened late at night.

You might want to consider whether your current time allocation reflects what matters to you.

That is reflection, not productivity policing.

6. It also makes SidePal's AI smarter

Imagine the user asks:

"Help me plan tomorrow."

Without Direction, SidePal knows:

Tasks + schedule + routines.

With Direction, SidePal knows:

What this person is ultimately trying to accomplish.

So it can reason:

Your month is focused on preparing SidePal for launch. You have 3 hours available tomorrow. Let's prioritize the launch-critical work first.

Or the user asks:

"I feel like I'm not making progress."

SidePal has context.

It can look at:

Direction → Plans → Time → Reality

and respond based on the user's actual situation rather than generic motivational advice.

7. It should evolve over time

The user shouldn't have to constantly rewrite everything.

For example:

January

Year: Build my business
Quarter: Build the product
Month: Finish MVP

Then February:

Month: Launch beta

March:

Quarter: Grow the product
Month: Get first 100 users

The yearly direction might stay the same for 12 months.

The quarterly direction changes every few months.

The monthly direction changes frequently.

So SidePal always has a relatively current understanding of:

Where are you going?

8. I'd make editing extremely easy

The user should be able to open Direction and immediately change something.

For example:

This month

Launch SidePal
Get first 100 users

No complicated workflow.

And when a new month starts, SidePal could simply ask:

What's your focus this month?

That's it.

9. The data model can also be tiny

You don't need a giant goal system.

Conceptually:

Direction
├── yearly
├── quarterly
└── monthly

Each one could basically contain:

text
startDate
endDate

Potentially later:

createdAt
updatedAt

That's enough to start.

You can build all the intelligence on top of this later.

10. The most important design principle

I'd write this somewhere in the internal product spec:

Direction is not something SidePal asks the user to accomplish. It is something SidePal remembers while helping them.

That's the difference.

The user says:

This is what matters to me.

SidePal says:

Okay. I'll keep that in mind.

Then SidePal watches the relationship between:

What you say matters
↓
What you plan
↓
What you actually do

And periodically gives you the mirror.