# PathPal — Accountability Stakes System: Feature Specification

**Purpose of this document:** Full specification of the new accountability features for PathPal (formerly CoachForLife). Use this to plan the implementation against the existing codebase (Flutter, Riverpod, Isar, Firebase, offline-first with SyncService, Cloud Functions already in use for the OpenAI proxy).

---

## 1. Product Overview

PathPal is a goal/habit app with AI coaching and community circles. This feature set adds **accountability stakes**: users put something real on the line (social exposure, an embarrassing photo, or money) when committing to a goal. If they succeed, nothing is lost. If they fail, the stake is forfeited.

**Core principle (legal + ethical): no user ever wins another user's money.** Winners get their own stake back. Losers' stakes go to charity. This keeps the system a commitment contract (StickK model), not gambling.

Three user-facing features, all built on one shared **Challenge Core**:

1. **Photo Stakes** — fail your goal and a pre-approved embarrassing photo of you is posted to your circle (group of ~8).
2. **Opposing-Charity Stakes (solo)** — stake real money against yourself; if you fail, it's donated to a rival organization you'd hate to fund (e.g., a rival football club's foundation).
3. **Head-to-Head Challenges** — two users challenge each other. Loser's stake (points or money) goes to charity; winner gets their own stake back. Nobody profits.

Plus a **Points economy** (earn-only at launch, IAP purchase later) as the no-money stake track.

---

## 2. Shared Foundation: Challenge Core

Everything sits on this. Build it first.

### 2.1 Data model (Firestore + Isar mirror, following existing local-first sync pattern)

**`challenges` collection** — one doc per challenge:
- `id`
- `type`: `solo_photo` | `solo_charity` | `h2h_points` | `h2h_money`
- `creatorUid`
- `opponentUid` (nullable — solo challenges have none)
- `circleId` (which circle sees announcements/reveals)
- `goal`: { title, description, measurable criteria }
- `deadline` (server timestamp; authoritative)
- `stake`: type-specific object (see per-feature sections)
- `verificationMode`: `opponent_confirms` | `circle_vote` | `self_report` (default: opponent_confirms for h2h, circle_vote fallback on dispute; self_report only for practice challenges)
- `status`: `draft` → `pending_accept` (h2h only) → `active` → `pending_verification` → `completed_success` | `completed_forfeit` | `cancelled` | `vetoed`
- `outcome`: { decidedAt, decidedBy, result, disputeInfo }
- `createdAt`, `updatedAt`

**`challenge_events` subcollection** — append-only audit log. Every state change (created, accepted, verified, forfeited, vetoed, refunded, donated) gets an event. Needed for disputes and App Review questions. Never mutated.

### 2.2 Outcome engine (Cloud Functions — server-authoritative)

**Critical security rule: all outcome decisions happen server-side.** The client never decides whether a challenge failed, whether a photo posts, or whether points/money move. A jailbroken or offline client must not be able to dodge a forfeit.

- **Scheduled function** (e.g., every 15 min) scans for `active` challenges past `deadline` → moves to `pending_verification` or triggers forfeit per verification rules.
- **Callable functions** for: create, accept, submit completion evidence, confirm/dispute (opponent), cast circle vote, apply mercy veto.
- Offline users cannot dodge deadlines — the server clock decides. When the client reconnects, it syncs the outcome.
- All stake movements (photo reveal, points transfer, refund, donation) are triggered **only** from the outcome engine.

### 2.3 Verification

- **H2H:** opponent confirms completion. On dispute → circle vote (majority of circle members within 48h; tie or no quorum → configurable default, recommend "no forfeit" to be user-favorable).
- **Solo:** self-submit evidence (text/photo), circle can flag; or opt into circle-vote verification for stronger accountability.
- **Practice challenges:** self-report, no stakes — onboarding mode so users learn the loop safely.

### 2.4 Prerequisite (Phase 0 — before any of this)

Finish the existing security blockers first: OpenAI key proxy via Cloud Function, Firestore/Storage rules holes, account-switch `ref.read` uid re-scoping leak, provider invalidation on logout. Photo stakes drastically raise the blast radius of any rules hole (leaked embarrassing photos vs. leaked todos).

---

## 3. Feature 1: Photo Stakes

### 3.1 Flow
1. User creates a solo challenge, selects "photo stake."
2. User uploads an embarrassing photo of **themselves**.
3. **Explicit consent screen** (not buried in ToS): "If you fail this goal by [deadline], this photo will be posted to [circle name] and visible to its N members." User must actively confirm.
4. Photo is NSFW-screened (see 3.3). Rejected photos cannot become stakes.
5. Photo stored in Firebase Storage, **owner-only read access** while challenge is active.
6. On forfeit (decided server-side): Storage access flips to circle-read, photo is posted to the circle feed with an announcement.
7. On success: photo is deleted from Storage.

### 3.2 Mercy veto
- At the moment of forfeit, user may apply **one mercy veto** to block the photo posting.
- Limit: 1 per month per user (tracked server-side), or alternatively costs a significant points amount. Without a limit the mechanic collapses (everyone vetoes); without any veto, genuine-harm cases become a PR/safety problem.
- Veto is logged as a challenge event; challenge still records as `vetoed` (counts as a loss for records/badges, just no photo).

### 3.3 Content moderation
- Cloud Function screens every uploaded stake photo **at upload time** using Google Cloud Vision SafeSearch (or AWS Rekognition moderation labels). Reuse the existing Cloud Function proxy pattern.
- Reject: nudity/adult, violence/gore, likely-minor content.
- Photos should depict the uploader; add in-consent attestation ("this is a photo of me") — cannot be fully verified technically, but required for policy + report handling.

### 3.4 Safety mechanics (Apple UGC requirements — mandatory for approval)
- **Report** any posted photo (report → hidden pending review).
- **Block** users.
- **Delete**: poster can delete a revealed forfeit photo after N days (recommend 7); photos purged on account deletion (in-app account deletion is an Apple requirement anyway).
- Published support/contact method.
- App Privacy labels updated in App Store Connect (photos, UGC).
- Recommend **17+ age rating**; disable photo stakes for under-18 accounts if rating is lower.

### 3.5 Storage rules
```
stake photos:
  while challenge active: read = owner only; write = owner only (once, at creation)
  after forfeit: read = circle members only
  after success/veto/deletion: object deleted
```
This is exactly the class of rules bug found in the earlier audit — treat these rules as security-critical and test them explicitly.

---

## 4. Feature 2: Opposing-Charity Stakes (solo, real money)

### 4.1 Flow
1. User creates a solo challenge, selects "money stake."
2. User picks a **rival recipient** from a curated list (e.g., Manchester United Foundation for a Liverpool fan) and a stake amount.
3. Stripe charges the stake at challenge creation → held in escrow (server-side record; funds sit in the platform Stripe account, flagged as held).
4. Success → **full refund** to the user's card.
5. Failure → stake is **donated** to the chosen rival organization. Receipt/proof posted in-app ("You just funded Man United's foundation 😬").

### 4.2 Recipient list (curated, admin-managed — never free-entry)
- Only **verified registered charities/foundations**: rival sports club foundations, rival university funds, opposing political party funds where legal, etc.
- Playful rivalry only. **No hate groups, no targeting demographic/identity groups — ever.** Curation is the permanent enforcement mechanism: users can request additions, admin vets and adds.
- Stored as an admin-managed Firestore collection: { name, category, charityRegistration, donationMethod, logo, active }.

### 4.3 Payments
- **Stripe** (requires US LLC — see §7). Charge on creation; refund on success; on forfeit, disburse to charity.
- Disbursement: **manual at first** (low volume — admin donates via the charity's own site, uploads receipt), migrate to a donation API (e.g., Pledge / Change-style programmatic nonprofit donation services — verify current providers and fees at build time) once volume justifies it.
- Note: Apple **prohibits charitable donations via IAP** — real-money donation flows are required to go outside IAP, so Stripe here is compliant, not a workaround.

### 4.4 Edge cases to handle
- Failed/declined charge → challenge never activates.
- Refund failures, expired cards → retry + support flow.
- Disputed outcomes → circle vote; chargeback handling policy.
- User deletes account mid-challenge → cancel + refund.

---

## 5. Feature 3: Head-to-Head Challenges

### 5.1 Flow
1. User A challenges User B (same circle): goal(s), deadline, stake type (points or money), each party's charity choice (for money).
2. B accepts → both stakes are locked (points escrow or two Stripe charges). Challenge goes `active`.
3. At deadline: each party's completion is verified (opponent confirms; dispute → circle vote). **Independent outcomes** — both can win, both can lose.
4. Per person: success → own stake back (points released / Stripe refund). Failure → stake donated to that person's pre-chosen charity (or rival-foundation variant).
5. **Nobody ever receives the opponent's stake.**

### 5.2 Social layer
- Circle announcements: challenge started, outcome, forfeit reveals.
- Head-to-head W/L record between users; badges; rematch button.
- Challenge feed within the circle.

### 5.3 Points variant (ships first — no payment infra needed)
Same flow with points as the stake. Loser's points are burned (recorded for the quarterly charity conversion, §6.3).

---

## 6. Points Economy

### 6.1 Ledger (build now, payment-agnostic)
- **Append-only transactions collection**; balance is always computed, never a mutable field. Prevents cheating and makes disputes auditable.
- Transaction: { uid, amount (+/-), source: `earn_goal` | `earn_streak` | `earn_challenge_win` | `signup_bonus` | `stake_lock` | `stake_release` | `stake_forfeit` | `iap_purchase` (later), refId, serverTimestamp }.
- All writes via Cloud Functions only — clients can never write ledger entries directly (Firestore rules deny client writes to the ledger).
- Synced to Isar read-only for offline balance display.

### 6.2 Launch economy: earn-only
- Points granted for: completing goals, streaks, winning challenges, onboarding.
- Entire points economy is live and testable at launch with **zero payment infrastructure**. Tune point values on earned points before money is involved.

### 6.3 Later: IAP purchase
- Apple In-App Purchase via RevenueCat (or `in_app_purchase` + StoreKit). Enroll in the App Store Small Business Program (15% instead of 30%).
- **Points can NEVER be cashed out to money** (Apple rule + gambling law). One-way only.
- "Buy points" screen built now but hidden behind a Remote Config flag; flipping the flag + wiring RevenueCat adds `iap_purchase` as one more ledger source. Server-side receipt validation required.
- Quarterly: forfeited/burned points are converted by PathPal into real charity donations from company revenue, published in-app (trust/marketing; no user money moves, no extra compliance).

---

## 7. Payments Architecture Summary

| Money flow | Rail | Prerequisite |
|---|---|---|
| Users buy points | Apple IAP (RevenueCat/StoreKit) | Apple Developer account |
| Real-money stakes in/out | Stripe: charge → refund (win) or donate (lose) | **US LLC + EIN + business bank (Mercury/Wise)** — this is the LLC path already identified in the Apple-enrollment research |
| Charity disbursement | Manual first → donation API later | Stripe live |
| Developer revenue out | App Store Connect payouts + Stripe payouts → Wise/Payoneer | — |

**Hard rules:**
- Winner never receives loser's money → not gambling (commitment-contract model).
- No user cash-out of points, ever.
- Donations never via IAP (Apple prohibits it) — always Stripe rail.
- All escrow/refund/donate triggers fire only from the server-side outcome engine.

---

## 8. Implementation Plan (phased)

**Phase 0 — Security blockers (~1 week, prerequisite):**
OpenAI key proxy, Firestore/Storage rules fixes, account-switch uid re-scoping fix, provider invalidation on logout, Crashlytics, debug screen removal.

**Phase 1 — Challenge Core + Photo Stakes (~2 weeks):**
- Challenge data model (Firestore + Isar) and sync integration
- Outcome engine Cloud Functions (write with tests **before** UI — it's the trust core)
- Challenge lifecycle UI (create → track → verify → outcome)
- Photo upload + consent flow, NSFW screening function, storage rules, forfeit reveal, mercy veto
- Report / block / delete / account-deletion purge
- Practice (no-stake) challenge mode
Shippable on its own; no payments.

**Phase 2 — Head-to-Head, points variant (~1 week):**
- Two-party extension: invite/accept, dual escrow (points), independent outcomes
- Points ledger + earn-only economy + signup/goal/streak grants
- Social layer: announcements, W/L record, badges, rematch
Still no payments. App is now multiplayer.

**Phase 3 — Business setup (parallel, paperwork not code):**
US LLC + EIN + Mercury/Wise business account + Stripe; Apple Developer enrollment continues on its own track.

**Phase 4 — Money layer (~2 weeks, gated on Stripe):**
- Stripe charge/refund integration into outcome engine hooks (`onSuccess → refund`, `onForfeit → donate`)
- Escrow records, failure/retry/chargeback handling
- Curated rival recipient list (admin collection + request flow)
- Feature 2 (solo opposing-charity) UI, then money-backed H2H
- Manual disbursement process + receipt posting; donation API later
- IAP points purchase behind the existing Remote Config flag
Ships as v1.1 if App Store launch lands first.

**Launch shape:** if Apple enrollment clears after Phases 1–2, launch with photo stakes + points H2H (full accountability marketing story), money stakes follow as the first update.

---

## 9. Cross-Cutting Requirements Checklist

- [ ] Server-authoritative outcomes everywhere; client can never decide forfeits or move stakes
- [ ] Append-only event log on every challenge; append-only points ledger
- [ ] Offline-first UX, but deadlines enforced by server clock (offline ≠ dodge)
- [ ] Firestore rules: ledger client-write-denied; challenges writable only through callable functions or tightly validated paths
- [ ] Storage rules for stake photos tested explicitly (owner-only → circle-read on forfeit → deleted)
- [ ] Apple UGC compliance: filter, report, block, contact info
- [ ] In-app account deletion purges stake photos and cancels/refunds active challenges
- [ ] Privacy labels updated (photos, purchases, UGC)
- [ ] 17+ rating or minor-gating for photo stakes
- [ ] Explicit consent screens for photo stakes (in-flow, not ToS)
- [ ] No user cash-out; winner-gets-own-money-back only
- [ ] Curated charity list only — no free-entry recipients, no hate groups, no demographic targeting
- [ ] IAP receipt validation server-side; Small Business Program enrollment
- [ ] Test plan covers: offline dodging, veto abuse, photo-of-someone-else reports, payment failures, dispute votes, both-lose and both-win H2H outcomes