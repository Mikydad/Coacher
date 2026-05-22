1. What currently owns reminder scheduling?

Ask:

What is the current reminder execution flow end-to-end?

Specifically:

where reminders are scheduled,
what entity owns scheduling decisions,
whether reminders are pre-scheduled or dynamically computed,
how repeat reminders currently work,
where “flexible / disciplined / extreme” behavior is implemented,
and whether notification timing is deterministic or OS-driven after scheduling.

Please map:
task/habit creation
→ reminder scheduling
→ notification delivery
→ missed handling
→ follow-up reminders
→ cancellation/reschedule flow.

This is the MOST important question.

Because your future architecture depends on:

whether delivery is centralized
or
fragmented across entities.
2. Is there already a notification orchestration layer?

Ask:

Do we currently have a centralized notification orchestration layer/service, or do individual tasks/habits independently schedule notifications?

If centralized:

what abstractions exist?
what inputs does it receive?
does it already support suppression/cooldowns/grouping?

If decentralized:

which entities/services directly schedule notifications?

This determines how hard Layer 4 will be to implement.

3. How does “extreme mode” currently behave internally?

VERY important.

Ask:

How is extreme mode currently implemented internally?

Specifically:

how many reminders are scheduled,
what retry logic exists,
whether retries are precomputed or reactive,
whether escalation timing is fixed or dynamic,
and whether there is any suppression/cooldown logic already.

Please include the actual scheduling behavior timeline for a missed reminder.

You need to know:

whether it’s already spammy,
rigid,
or adaptable.
4. Does the app already track notification fatigue signals?

Ask:

Do we currently track any notification interaction signals?

Examples:

notification dismissed,
notification opened,
ignored reminders,
repeated suppression,
mute behavior,
time-to-action after notification.

If yes:

where are these stored?
are they already included in analytics events?

VERY important for future adaptive delivery.

5. What currently happens when reminders collide?

Critical real-world UX question.

Ask:

What currently happens when multiple reminders are due around the same time?

Examples:

two habits due within 5 minutes,
overdue task + scheduled habit,
extreme mode overlaps.

Do we currently:

batch,
prioritize,
queue,
or independently fire all reminders?

This reveals whether the system already has:

attention management
or just:
notification generation.
6. Are reminders server-driven or device-local?

Ask:

Are reminders currently:

device-local notifications,
Firebase scheduled notifications,
Cloud Function driven,
or hybrid?

And what is the current offline behavior?

This massively affects future architecture.