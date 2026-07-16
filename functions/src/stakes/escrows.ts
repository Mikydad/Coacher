/**
 * Escrow IO: the stake_escrows collection and the refund queue.
 *
 * Money movement is two-phase everywhere:
 *   1. A Firestore TRANSACTION records intent (held → refund_pending /
 *      disbursement_pending) atomically with whatever decided it.
 *   2. [processRefundQueue] — called by the sweep and after purges —
 *      drives refund_pending → refunded through the provider, one
 *      idempotent step per escrow. Crash anywhere and the next run
 *      finishes the job; nothing is ever paid twice or stranded.
 * Disbursements stay manual (PRD §4.3): admin performs the donation,
 * then sets status 'disbursed' + receiptUrl on the escrow doc — the
 * receipt trigger posts it back onto the challenge for the user.
 */

import { logger } from 'firebase-functions/v2';
import {
  DocumentReference,
  getFirestore,
  Transaction,
} from 'firebase-admin/firestore';

import {
  canTransitionEscrow,
  escrowDocId,
  EscrowDoc,
  EscrowStatus,
  getPaymentProvider,
} from './payments';

export const ESCROWS = 'stake_escrows';

export function escrowRef(challengeId: string, uid: string): DocumentReference {
  return getFirestore().collection(ESCROWS).doc(escrowDocId(challengeId, uid));
}

export function newEscrowDoc(args: {
  challengeId: string;
  uid: string;
  amountCents: number;
  provider: string;
  providerRef: string;
  nowMs: number;
}): EscrowDoc {
  return {
    challengeId: args.challengeId,
    uid: args.uid,
    amountCents: args.amountCents,
    currency: 'usd',
    status: 'held',
    provider: args.provider,
    providerRef: args.providerRef,
    createdAtMs: args.nowMs,
    updatedAtMs: args.nowMs,
  };
}

/**
 * Phase-1 write of the two-phase move, inside the caller's transaction.
 * The caller must have READ the escrow snap in the same transaction.
 */
export function markEscrow(
  tx: Transaction,
  ref: DocumentReference,
  current: EscrowDoc,
  to: EscrowStatus,
  nowMs: number,
  extra: Record<string, unknown> = {},
): void {
  if (!canTransitionEscrow(current.status, to)) {
    throw new Error(
      `illegal escrow transition ${current.status} -> ${to} (${ref.id})`,
    );
  }
  tx.update(ref, { status: to, updatedAtMs: nowMs, ...extra });
}

/**
 * Phase-2 driver: refund everything in refund_pending. Idempotent — each
 * escrow is re-checked in its own transaction after the provider call
 * resolves, and providers must be idempotent per escrow (the simulated
 * one is by construction; Stripe refunds will use an idempotency key).
 */
export async function processRefundQueue(nowMs: number): Promise<number> {
  const db = getFirestore();
  const provider = getPaymentProvider();
  const snap = await db
    .collection(ESCROWS)
    .where('status', '==', 'refund_pending')
    .limit(100)
    .get();

  let processed = 0;
  for (const doc of snap.docs) {
    const escrow = doc.data() as EscrowDoc;
    const result = await provider.refund(escrow);
    if (!result.ok) {
      // $-4 — leave in queue; the next sweep retries; repeated failures
      // surface in logs for the support flow.
      logger.error('escrow refund failed (will retry)', {
        escrow: doc.id,
        reason: result.failureReason,
      });
      continue;
    }
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.status !== 'refund_pending') return; // already done
      tx.update(doc.ref, {
        status: 'refunded',
        refundRef: result.providerRef,
        updatedAtMs: nowMs,
      });
    });
    processed += 1;
  }
  return processed;
}
