# PRD — Monetization: Free / Pro Tiers, Payments, Limits

> Decided 2026-07-20 in conversation; decision-log entries in
> `documentation/GUIDELINES.md` are the authoritative record. This document
> is the buildable consolidation. Related: `PRD/Accountability_feature/
> prd-accountability-stakes.md` (§6.5 money stakes, §6.6 points economy).

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
| Tasks | 5 planned per day | Unlimited |
| Goals | 5 active (challenge-created goals count) | Unlimited |
| Habits | 5 Habit Anchor tasks per day (no habit entity exists — anchors are the product's "habits") | Unlimited |
| Reminders | 5 active configurations (a recurring reminder = 1) | Unlimited |
| AI coach | 5 actionable instructions/day (§6) | "Unlimited" (internal fair-use token budget; ~99.9% never hit it) |
| Practice challenges | ✅ Unlimited | ✅ |
| Photo stakes | 3/month, **activated challenges only** | Unlimited |
| Mercy veto | 1/month (safety valve — never paywalled) | 3/month |
| Points: earn | ✅ | ✅ |
| Points: buy (IAP) | ❌ | ✅ |
| Points: spend (photo early removal) | ❌ | ✅ |
| Points H2H / team (create) | ❌ (trial: ✅) | ✅ |
| Money challenges — solo, H2H, team (create) | ❌ (trial: ❌) | ✅ (active *paid* sub + verified payment method) |
| Accept any challenge invite | ✅ (money: payment method required, no Pro) | ✅ |
| Circles | Member of **1** (belong-to, not own); max 5 members | Unlimited circles; max 8 members |
| Join a Pro user's circle | ✅ (counts as their 1) | — |
| Analytics | Streaks, weekly completion %, calendar history, task history | + habit trends, monthly reports, AI insights, weakness detection, goal breakdowns, time-of-day analysis, predictive coaching, data export |
| Streaks, notifications, home widgets, education content | ✅ Free — core habit-formation, never paywalled | ✅ |

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
- **At 5/5**: conversation continues, action features stop —
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
