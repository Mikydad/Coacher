# PRD — Monetization: Free / Pro Tiers, Payments, Limits

> Decided 2026-07-20 in conversation; **free limits re-cut 2026-09-27**
> (§4, §4.1, §8 — tighter caps, promises + time insights added, guest
> rules). Decision-log entries in `documentation/GUIDELINES.md` are the
> authoritative record. This document is the buildable consolidation.
> Related: `PRD/Accountability_feature/prd-accountability-stakes.md`
> (§6.5 money stakes, §6.6 points economy).

## 1. Payment rails (hard split, Apple-mandated)

| Flow | Rail | Notes |
|---|---|---|
| Pro subscription | Apple/Google IAP via **RevenueCat** | Small Business Program (15%) |
| Points packs (Pro-only) | IAP consumables via same RevenueCat install | Server webhook credits ledger |
| Money stakes + Challenge Fee | **Stripe** (never IAP) | Apple prohibits donations via IAP |

Entitlement pipeline: RevenueCat webhook → Cloud Function →
`entitlements` on the user doc → `RemoteIsarMerge` → Isar watch provider.
Premium *checks* are offline-first (cached entitlement + grace window);
only the purchase moment itself is online.

## 2. Pricing

- **Monthly $9.99 · Annual $79.99** (~$6.67/mo) · **7-day trial**.
- Regional pricing via Apple/Google recommended price tiers — no custom
  country logic in V1.

## 3. Challenge Fee (money challenges)

- **Greater of $2 or 7% of the stake, per participant**, shown as its own
  checkout line (`Stake $30 / Challenge Fee $2.10 / Total $32.10`).
- Non-refundable **once the challenge activates**, win or lose. Winners
  get the full stake back; losers' full stake is donated. SidePal keeps
  only the fee — revenue is identical regardless of outcome.
- Challenge never activates (declined, invite expired, payment failure,
  account-deletion cancel) → **full refund including the fee**.
- Rationale: Stripe's ~2.9% + $0.30 is taken on the total charge and not
  returned on refunds; a flat $2 goes underwater above a ~$58 stake.

## 4. Tier matrix

All numbers are launch values of the `tier_limits_v1` Remote Config
parameter (§7) — none are compile-time constants.

| Feature | Free | Pro |
|---|---|---|
| Tasks | **4** planned per day | Unlimited |
| Goals | **3** active (challenge-created goals count) | Unlimited |
| Habits | **4** Habit Anchor tasks per day — own count, separate from the 4 tasks (no habit entity exists — anchors are the product's "habits") | Unlimited |
| Reminders | 5 active configurations (a recurring reminder = 1) | Unlimited |
| Promises | **2 per week** (Mon–Sun, created this week and still existing; Coach-captured count) | Unlimited |
| AI coach | **3** actionable instructions/day (§6) | "Unlimited" (internal fair-use token budget; ~99.9% never hit it) |
| Time tracker — logging + Day timeline | ✅ Unlimited (local, costs nothing; a partial timeline would poison Direction/Coach data) | ✅ |
| Time tracker — insights | ❌ Day summary totals, AI observations, planned vs actual, Direction mirror, Week view, export | ✅ |
| Practice challenges | ✅ Unlimited | ✅ |
| Photo stakes | **1/month**, **activated challenges only**; joining someone else's never counts | Unlimited |
| Mercy veto | 1/month (safety valve — never paywalled) | 3/month |
| Points: earn | ✅ | ✅ |
| Points: buy (IAP) | ❌ | ✅ |
| Points: spend (photo early removal) | ❌ | ✅ |
| Points H2H / team (create) | ❌ (trial: ✅) | ✅ |
| Money challenges — solo, H2H, team (create) | ❌ (trial: ❌) | ✅ (active *paid* sub + verified payment method) |
| Accept any challenge invite | ✅ (money: payment method required, no Pro) | ✅ |
| Circles | Member of **1** (belong-to, not own); max 5 members | Unlimited circles; max 8 members |
| Join a Pro user's circle | ✅ (counts as their 1) | — |
| Analytics | Progress **Day** view; Home weekly bar + Profile THIS WEEK stat | + Week / Month / Quarter / Year progress history, AI insights, data export |
| Streaks, notifications, home widgets, education content | ✅ Free — core habit-formation, never paywalled | ✅ |

**Counting rule:** caps count what exists *now* — deleting a task, goal,
habit, reminder, or promise frees its slot (stakes count activations, so
they don't refund). Coach-created items count exactly like manual ones.

### 4.1 Guests (anonymous, no account)

Guests get the **same caps as Free** for everything that works on-device:
tasks, habits, goals, reminders, promises, time logging. Everything that
needs the server or other people **requires an account**: Coach AI,
circles, stakes (any kind), and buying Pro. Pro is tied to the account,
never to an anonymous session.

Because guest and Free caps are equal, an account is never sold as "more
tasks" — it's sold as **keeping your data** (a guest's plan lives only on
this phone) and as the step before Pro. See §8 for the copy.

## 5. Gating & lifecycle rules

- **Creator-needs-Pro only** (the virality rule): for H2H and team
  challenges (points *and* money), only the challenge **creator** must
  have Pro. Invitees need an account (+ payment method for money) — never
  a subscription. A 4v4 needs exactly one Pro user. The invite-accept
  flow is the acquisition loop; "buy Pro first" is never shown to an
  invitee.
- **Trial scope**: 7-day Pro trial unlocks everything **except money
  challenges** (real charges require an active paid subscription —
  prevents stake-then-cancel abuse). Points H2H/team work in trial.
- **Downgrade — never disrupt in-progress work**: active challenges run
  to completion (money is escrowed); existing over-limit tasks/goals/
  habits/reminders remain but no new ones can be created over the limit;
  circles: user **chooses** which one stays active, the rest go
  read-only until they upgrade or leave down to the limit.
- **Grandfathering at limits-launch**: existing users keep everything
  they have (12 goals stay 12); they can't create over the limit, and
  once they delete down to it they can't exceed it again without Pro.
  Never delete or hide existing user data.
- **Bought points are an asset — never confiscated**: they persist
  through downgrade (visible balance), become spendable again on
  re-upgrade. Disclosed at purchase.
- **Photo-stake monthly quota** counts only challenges that actually
  activated — declined, cancelled-before-start, payment-failed, and
  pre-activation vetoes don't consume an allowance.

## 6. AI instruction quota (free tier)

- **What counts**: server-side AI classifies each user message
  (greeting / casual chat / action request / planning / coaching).
  Only actionable messages consume quota; the client never decides.
- An AI clarifying question + the user's confirmation = **1**
  instruction, not 2.
- **What never counts**: onboarding AI demo, AI-initiated check-ins and
  reminders, greetings/chat.
- **At 3/3**: conversation continues, action features stop —
  "You've reached today's planning limit. You can still chat with
  SidePal, or upgrade to Pro for unlimited planning." No hard stop.
- **Reset**: server-side, at midnight in the user's *configured*
  timezone (not device clock — prevents clock-change bypass).

## 7. Limits as config (the "change one number" requirement)

- **One Remote Config parameter `tier_limits_v1`** (JSON) holds every
  number in §4 plus fee constants (`challengeFeeMinCents: 200`,
  `challengeFeePct: 7`), veto counts, quota sizes. Editing a limit is a
  Firebase-console change, no app release.
- **Compiled-in defaults + cached RC** so limits resolve offline
  (airplane-mode free user still gets 5 tasks, not 0 or ∞).
- **Server enforcement**: Cloud Functions read the same parameter via
  the Admin SDK. Everything touching money, stakes, quotas, or AI is
  enforced server-side; client checks are UI politeness only.
- **Per-user `limitOverrides` on the user doc**, checked before RC —
  support comps, promos, and grandfathering flow through the same
  mechanism.

## 8. Limit prompts — who sees what (2026-09-27)

One rule decides the prompt: **guest → account first (framed as keeping
their data); signed-in free → the Pro plan.** Every prompt is polite, names
the limit plainly, and never blocks what the user already has.

| Who | Situation | Prompt | Primary action |
|---|---|---|---|
| Guest | Hit a cap on something guests can use (tasks, habits, goals, reminders, promises, time insights) | "Your plan lives only on this phone. Sign in so you don't lose it — then you can unlock more with Pro." | Sign in → Pro plan page |
| Guest | Tried an account-only feature (Coach AI, circles, stakes) | "Sign in to use {feature} — it also keeps your data safe if you lose or switch phones." | Sign in (then straight into the feature) |
| Free (signed in) | Hit any cap | "You've used your {n} {items} for {period}. Pro removes the limit." | Pro plan page |
| Free, Coach at 3/3 actions | Asked the Coach to do something | Chat keeps going; the action line reads "You've reached today's 3 Coach actions — I can still talk it through, or Pro unlocks unlimited." | Link to Pro plan page |
| Invitee (any tier) | Accepting a challenge invite | Never a Pro prompt (virality rule, §5). A guest invitee sees the sign-in prompt only. | — |

Sign-in from a guest prompt keeps all local data (the existing guest-first
link flow); after sign-in a guest who came from a *cap* lands on the Pro
plan page, one who came from an *account-only feature* lands in that
feature.
