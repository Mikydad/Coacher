# Phase 3 — Business Setup Runbook

**What this unblocks:** the Stripe rail for Phase 4 (real-money stakes:
charge → refund on win / donate on forfeit) and App Store distribution.
Per the accountability PRD §7, money stakes CANNOT ship without this —
donations must go outside Apple IAP (Apple prohibits charitable donations
via IAP), and Stripe US requires a US entity with a US business bank
account.

**Who does what:** every step in Track A and B is paperwork only the
founder can do (identity documents, signatures, payments). The "meanwhile,
in code" section at the bottom is what can be built in parallel without
any of it.

*This is an execution checklist, not legal or tax advice. Amounts and
provider policies verified July 2026 — re-verify anything marked (~)
before paying.*

---

## The dependency graph

```
LLC formed ──► EIN issued ──► Mercury account ──► Stripe activated ──► PHASE 4 SHIPS
   │                                                    ▲
   │            (EIN is the long pole: 1–8 weeks)       │
   │                                                    │
   └──► D-U-N-S number (~5 business days, free) ──► Apple Developer (organization)
                                                    └─► App Store launch
```

The **EIN wait dominates the timeline**. Everything after it moves in
days. Realistic total: **3–10 weeks**, almost entirely IRS-dependent.

---

## Track A — LLC → EIN → Bank → Stripe

### A1. Form the US LLC (~1–7 days)

- [ ] Pick the formation agent. Verified July 2026 pricing:
  | Agent | Formation | Notes |
  |---|---|---|
  | **doola** | ~$297 | Non-resident specialist; EIN + compliance bundles; total-compliance plan ~$1,999/yr |
  | **Firstbase** | ~$399 | Similar; tax-filing plan ~$899/yr |
  | Stripe Atlas | $500 | Built for Delaware **C-corps** / venture track — wrong shape for this; skip |
- [ ] **State: Wyoming** (recommended). Cheapest ongoing (~$60/yr annual
  report), no state income tax, strong privacy, and it's the default
  non-resident path both agents push. Delaware buys nothing here unless
  raising VC.
- [ ] Company name: check it's clean as an App Store seller name too
  (e.g. "SidePal Labs LLC") — this becomes the public "Seller" line.
- [ ] Agent provides: registered agent + US business address + Articles
  of Organization + operating agreement.

**Deliverables:** Articles of Organization, EIN application filed,
US address.

### A2. EIN — the long pole (1–8 weeks)

- [ ] No SSN needed: Form SS-4 by **fax** to the IRS with line 7b
  "Foreign"; the agents file this as part of their bundle. Online EIN is
  NOT available without an SSN/ITIN — don't chase it.
- [ ] Timeline spread is real: best case ~4–14 business days by return
  fax, worst case 8+ weeks. Start this the day the LLC exists and do
  Track B while waiting.
- [ ] The EIN letter (CP 575 / 147C) is the key artifact — Mercury and
  Stripe both want it.

### A3. Business bank — Mercury (days, after EIN)

- [ ] Apply at mercury.com with: Articles, **EIN**, passport, and a
  **principal-place-of-business address that is NOT the registered
  agent / PO box** (a home address abroad is acceptable — Mercury
  supports non-US founders; review got stricter in 2026, expect
  questions about what the app does).
- [ ] Describe the business honestly: goal-accountability app; money
  flow = commitment stakes refunded on success, donated to registered
  charities on failure; **no user-to-user transfers, no gambling** (the
  §1.1 invariant is also the compliance story banks want to hear).
- [ ] Fallback if declined: Relay; Wise Business works for receiving but
  Stripe needs a **US ACH account in the LLC's name**, so Mercury/Relay
  class accounts are the target.

### A4. Stripe activation (days)

- [ ] Activate with: EIN, Articles, US address, **Mercury account** for
  payouts, passport for every ≥25% owner.
- [ ] Stripe prompts **W-8BEN-E** in-dashboard for foreign-owned US
  entities — complete it there, nothing to prepare.
- [ ] Business description: same commitment-contract story as A3.
  Category: software/SaaS. Do NOT describe it as donations processing or
  crowdfunding — SidePal charges a service (the stake escrow), and
  disbursement to charities is SidePal's own act (manual at first, per
  PRD §4.3).
- [ ] Once activated: create restricted API keys, put the secret key in
  Cloud Functions secrets (same pattern as `OPENAI_API_KEY`), never in
  the client.

### A5. Ongoing compliance (calendar these NOW)

- [ ] **Form 5472 + pro-forma 1120, annually** — mandatory for a
  foreign-owned single-member US LLC even with zero US tax due.
  **Penalty for missing it: $25,000.** This is the single most dangerous
  paperwork item; either an agent compliance plan (doola ~$1,999/yr /
  Firstbase ~$899/yr) or an independent CPA (~$300–500 per filing).
  Due with the 1120 deadline (mid-April, extendable).
- [ ] Wyoming annual report: ~$60/yr on the formation anniversary.
- [ ] FinCEN BOI: domestic LLCs were exempted by the 2025 interim rule —
  (~) re-verify at formation time, rules have churned.
- [ ] Registered agent renewal (usually bundled).

## Track B — Apple Developer (parallel, start immediately)

- [ ] **Decision: individual vs organization.**
  - *Individual*: $99/yr, no D-U-N-S, enroll today — but the App Store
    seller name is your personal name, and an app taking money reads
    better under a company.
  - *Organization* (recommended once the LLC exists): $99/yr + free
    **D-U-N-S number registered to the LLC** (~5 business days via
    Apple's D&B lookup page), legal entity name, and you as Account
    Holder with authority to bind the LLC.
  - Middle path if launch pressure hits before the LLC: enroll as
    individual now, transfer the app to the organization account later
    (Apple supports app transfer) — costs a second $99.
- [ ] Enroll with an Apple Account with two-factor on, legal name.
- [ ] While in App Store Connect: the accountability feature needs
  **17+ rating**, UGC declarations, privacy labels (photos, UGC,
  purchases-later) — PRD §3.4 checklist.

## Costs summary (year one, ~)

| Item | Cost |
|---|---|
| LLC formation (doola/Firstbase, Wyoming) | $297–399 |
| EIN | included / $0 (IRS is free) |
| Mercury / Stripe accounts | $0 (transaction fees only) |
| Apple Developer | $99/yr |
| D-U-N-S | $0 |
| Wyoming annual report (year 2+) | ~$60/yr |
| 5472/1120 filing | $300–500 (CPA) or agent plan $899–1,999/yr |
| **Year-one total** | **~$700–1,000** (lean) |

## This week's actions (order matters)

1. Choose agent + state (recommendation: doola or Firstbase, Wyoming) and
   start formation — everything else waits on this.
2. The moment formation papers exist: agent files SS-4 (EIN clock starts).
3. Same week: request the D-U-N-S for the LLC; start Apple organization
   enrollment as soon as D&B lists it.
4. When the EIN letter lands: Mercury application same day, Stripe the
   day Mercury approves.
5. Calendar the 5472 deadline and the Wyoming annual report immediately.

---

## Meanwhile, in code (no LLC required)

Phase 4's code does NOT need the live Stripe account to be built and
tested — a free Stripe account in **test mode** issues test API keys
immediately, before any activation:

- Payment-intent creation + webhook handler + escrow records in
  `functions/src/stakes/` against Stripe test keys.
- Outcome-engine hooks: `onSuccess → refund`, `onForfeit →
  markForDisbursement` (the D5/D6 routing already computes recipients).
- Charity admin request-flow + receipt-posting surface (no Stripe at all).
- IAP points purchase behind the Remote Config flag (RevenueCat sandbox).
- Failure drills: declined charge, refund failure, chargeback annotation.

Only the final live-keys swap and a real $1 end-to-end test wait for
Track A to finish.

## Sources

- Formation pricing: [globalsolo comparison](https://www.globalsolo.global/blog/stripe-atlas-vs-firstbase-vs-doola-pricing-comparison-2026), [doola vs Atlas](https://saveoffice.io/blog/doola-vs-stripe-atlas-foreign-founder-comparison), [doola review](https://llcfounder.com/articles/doola-review)
- Mercury eligibility: [Mercury help](https://support.mercury.com/hc/en-us/articles/28770467511060-Eligibility), [2026 requirements](https://mizufinancial.com/blog/mercury-bank-account-non-us-founder-2026), [bank comparison](https://corporatee.pro/us-bank-account-non-residents)
- EIN without SSN: [IRS SS-4 instructions](https://www.irs.gov/instructions/iss4), [non-resident EIN guide](https://llcstarters.com/non-residents/ein/), [timelines](https://rocketwave.co/ein-without-ssn-non-resident-guide/)
- Stripe for non-resident US LLCs: [Stripe support](https://support.stripe.com/questions/requirements-for-having-a-us-stripe-account), [Stripe LLC guide](https://stripe.com/resources/more/how-to-open-an-llc-in-the-usa-for-nonresidents), [approval guide](https://rocketwave.co/stripe-account-for-non-us-residents-how-to-get-approved-in-2026/)
- Apple enrollment: [Apple Developer enrollment](https://developer.apple.com/programs/enroll/), [D-U-N-S help](https://developer.apple.com/help/account/membership/D-U-N-S), [memberships](https://developer.apple.com/support/compare-memberships/)
