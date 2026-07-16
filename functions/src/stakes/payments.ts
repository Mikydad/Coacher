/**
 * Phase 4 — the payment rail behind an abstraction (PRD §4/§7, spec §4.3).
 *
 * There is NO live Stripe account yet, so everything money-shaped runs
 * against [SimulatedPaymentProvider]: same escrow records, same status
 * machine, same refund/disbursement flows — no network, no real money.
 * When Stripe activates (PHASE3_BUSINESS_SETUP.md), a StripePaymentProvider
 * implementing the same three methods slots in behind PAYMENTS_PROVIDER
 * and nothing above this layer changes.
 *
 * §1.1 invariant, enforced by SHAPE: there is no user-to-user transfer
 * method on the interface at all. Money enters escrow from its owner and
 * leaves as a refund to that same owner or a disbursement to a curated
 * charity. Nothing else is expressible.
 *
 * Escrow docs: stake_escrows/{challengeId}_{uid} — one per participant
 * stake, server-written only (rules deny clients).
 */

export type EscrowStatus =
  | 'held'
  | 'refund_pending' // decided: goes back to owner; queue state so the
  // decision transaction NEVER makes network calls (a retried transaction
  // with a live Stripe call inside = double refunds)
  | 'refunded'
  | 'disbursement_pending' // forfeited; queued for the manual donation
  | 'disbursed' // admin donated + posted the receipt
  | 'failed'; // charge never completed — challenge must not activate

/** $-1/$-4 — legal transitions; anything else is a bug, not a state. */
const LEGAL: Record<EscrowStatus, readonly EscrowStatus[]> = {
  held: ['refund_pending', 'disbursement_pending'],
  refund_pending: ['refunded'],
  disbursement_pending: ['disbursed'],
  refunded: [],
  disbursed: [],
  failed: [],
};

export function canTransitionEscrow(
  from: EscrowStatus,
  to: EscrowStatus,
): boolean {
  return (LEGAL[from] ?? []).includes(to);
}

/** Money stake bounds (launch: $1–$100, minor units). RC-tunable later. */
export const MONEY_STAKE_MIN_CENTS = 100;
export const MONEY_STAKE_MAX_CENTS = 10_000;
export const MONEY_CURRENCY = 'usd';

export function validMoneyAmount(amountCents: number): boolean {
  return (
    Number.isInteger(amountCents) &&
    amountCents >= MONEY_STAKE_MIN_CENTS &&
    amountCents <= MONEY_STAKE_MAX_CENTS
  );
}

export interface EscrowDoc {
  challengeId: string;
  uid: string;
  amountCents: number;
  currency: string;
  status: EscrowStatus;
  provider: string;
  /** Provider's charge reference (Stripe PaymentIntent id later). */
  providerRef: string;
  /** Set when forfeited: the curated charity the money must reach. */
  toCharityId?: string;
  createdAtMs: number;
  updatedAtMs: number;
}

export function escrowDocId(challengeId: string, uid: string): string {
  return `${challengeId}_${uid}`;
}

// ─── Provider interface ──────────────────────────────────────────────────────

export interface ChargeResult {
  ok: boolean;
  providerRef: string;
  /** Human-usable failure reason when !ok (declined card etc.). */
  failureReason?: string;
}

export interface PaymentProvider {
  readonly name: string;

  /** Charge the stake into escrow. Must be idempotent per (challengeId, uid). */
  charge(args: {
    challengeId: string;
    uid: string;
    amountCents: number;
  }): Promise<ChargeResult>;

  /** Return the full stake to its owner (win path, or cancellation). */
  refund(escrow: EscrowDoc): Promise<ChargeResult>;
}

/**
 * The stand-in until Stripe activates. Deterministic and instant:
 * - charges succeed, except amounts ending in 99 cents (e.g. $4.99) which
 *   decline — that's the failure-drill hook the PRD test plan needs;
 * - refunds always succeed.
 * No network, no secrets, no real money — but every escrow record,
 * status transition, event, and receipt flow is the real code path.
 */
export class SimulatedPaymentProvider implements PaymentProvider {
  readonly name = 'simulated';

  async charge(args: {
    challengeId: string;
    uid: string;
    amountCents: number;
  }): Promise<ChargeResult> {
    if (args.amountCents % 100 === 99) {
      return {
        ok: false,
        providerRef: '',
        failureReason: 'Card declined (simulated).',
      };
    }
    return {
      ok: true,
      providerRef: `sim_${args.challengeId}_${args.uid}`,
    };
  }

  async refund(escrow: EscrowDoc): Promise<ChargeResult> {
    return { ok: true, providerRef: `simref_${escrow.providerRef}` };
  }
}

/**
 * Provider selection. Hard-locked to the simulation until a Stripe
 * adapter exists AND PAYMENTS_PROVIDER=stripe is set on deploy — flipping
 * the env var without shipping the adapter throws instead of silently
 * simulating real money.
 */
export function getPaymentProvider(): PaymentProvider {
  const configured = process.env.PAYMENTS_PROVIDER ?? 'simulated';
  if (configured === 'simulated') return new SimulatedPaymentProvider();
  throw new Error(
    `PAYMENTS_PROVIDER=${configured} has no adapter yet — implement it before configuring it.`,
  );
}
