/**
 * Account deletion — pure planning (no firebase imports; unit-tested).
 *
 * Pre-launch audit H12/H17 (decision log 2026-09-15, D3/D4):
 *  - deletion CANCELS AND REFUNDS every open stake for every participant:
 *    points locks are released to each side, held money escrows go to
 *    refund_pending — deletion is never a forfeit and never strands the
 *    surviving opponent's stake;
 *  - the purge is an inventory of steps recorded on `account_purges/{uid}`
 *    so a failed step is re-driven by the sweep instead of being swallowed.
 *
 * Retained on purpose (financial audit trail): `points_ledger/{uid}`,
 * `stake_escrows`, terminal `stake_challenges` and their events.
 */

/** Statuses that may still move to cancelled (CC-2's non-terminal set). */
export const CANCELLABLE_STATUSES: ReadonlySet<string> = new Set([
  'draft',
  'pending_accept',
  'active',
  'pending_verification',
]);

/**
 * Statuses in which stakes are actually LOCKED: the accept transaction
 * locks both sides' points (PT-4) and charges money escrows; before that
 * (draft / pending_accept) nothing has moved.
 */
export const LOCKED_STATUSES: ReadonlySet<string> = new Set([
  'active',
  'pending_verification',
]);

export interface PurgeParticipant {
  uid: string;
  stakeKind: string;
  stakeAmount?: number;
}

export interface PurgeChallenge {
  id: string;
  status: string;
  participants: PurgeParticipant[];
}

export interface CancellationSettlement {
  /** Ledger `stake_release` per participant whose points were locked. */
  releases: Array<{ uid: string; amount: number }>;
  /** Participants whose HELD money escrow must go to refund_pending. */
  escrowRefundUids: string[];
}

/**
 * What cancelling [ch] because [deletedUid]'s account is gone must settle.
 * Every side is refunded — the deleted user's ledger is retained, so their
 * release row keeps the audit trail symmetric; the survivor gets their
 * points back to spend.
 */
export function settlementForCancellation(
  ch: PurgeChallenge,
  _deletedUid: string,
): CancellationSettlement {
  if (!LOCKED_STATUSES.has(ch.status)) {
    return { releases: [], escrowRefundUids: [] };
  }
  const releases: Array<{ uid: string; amount: number }> = [];
  const escrowRefundUids: string[] = [];
  for (const p of ch.participants) {
    if (p.stakeKind === 'points' && (p.stakeAmount ?? 0) > 0) {
      releases.push({ uid: p.uid, amount: p.stakeAmount! });
    } else if (p.stakeKind === 'money') {
      escrowRefundUids.push(p.uid);
    }
  }
  return { releases, escrowRefundUids };
}

/** The purge's step inventory, in execution order. */
export const PURGE_STEPS = [
  'stakes',
  'memberships',
  'user_tree',
  'ai_usage',
  'feedback',
  'reservations',
] as const;

export type PurgeStep = (typeof PURGE_STEPS)[number];

export type PurgeStepStatus = 'done' | 'failed';

export interface PurgeJob {
  uid: string;
  startedAtMs: number;
  updatedAtMs: number;
  attempts: number;
  status: 'running' | 'done' | 'partial';
  steps: Partial<Record<PurgeStep, { status: PurgeStepStatus; error?: string }>>;
}

/** Overall status from the step results — `partial` means the sweep re-drives. */
export function purgeStatus(job: Pick<PurgeJob, 'steps'>): 'done' | 'partial' {
  for (const step of PURGE_STEPS) {
    if (job.steps[step]?.status !== 'done') return 'partial';
  }
  return 'done';
}
