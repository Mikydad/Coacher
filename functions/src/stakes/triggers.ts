/**
 * CC-5 — server arrival stamp for evidence.
 *
 * Evidence docs are client-written through the offline outbox (user-own
 * data, house pattern), so the client cannot be trusted for WHEN a record
 * reached the server. This trigger stamps `arrivedAtMs` on creation; the
 * outcome engine ignores evidence without the stamp or stamped after the
 * decision cutoff. Rules forbid clients writing `arrivedAtMs` themselves
 * and make evidence docs immutable once created.
 */

import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

import { CHALLENGES, eventDoc } from './firestore_layout';
import { EscrowDoc } from './payments';

export const stakeEvidenceArrived = onDocumentCreated(
  {
    document: 'stake_challenges/{challengeId}/evidence/{evidenceId}',
    region: 'us-central1',
    memory: '256MiB',
    maxInstances: 10,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    if (typeof snap.data().arrivedAtMs === 'number') return; // already stamped
    await snap.ref.update({ arrivedAtMs: Date.now() });
  },
);

/**
 * $-3 — receipt posting. Disbursement is manual at launch (admin performs
 * the donation, then edits the escrow doc in the console: status
 * 'disbursed' + receiptUrl). This trigger closes the loop for the user:
 * the receipt lands on the challenge doc (mirror-synced, so the detail
 * screen shows "your $20 funded X — receipt") plus an audit event.
 */
export const stakeDisbursementReceipt = onDocumentUpdated(
  {
    document: 'stake_escrows/{escrowId}',
    region: 'us-central1',
    memory: '256MiB',
    maxInstances: 5,
  },
  async (event) => {
    const before = event.data?.before.data() as EscrowDoc | undefined;
    const after = event.data?.after.data() as (EscrowDoc & {
      receiptUrl?: string;
      receiptNote?: string;
    }) | undefined;
    if (!before || !after) return;
    if (before.status === 'disbursed' || after.status !== 'disbursed') return;

    const now = Date.now();
    const ref = getFirestore().collection(CHALLENGES).doc(after.challengeId);
    await ref.update({
      [`outcome.receipts.${after.uid}`]: {
        amountCents: after.amountCents,
        toCharityId: after.toCharityId ?? '',
        receiptUrl: after.receiptUrl ?? '',
        note: after.receiptNote ?? '',
        atMs: now,
      },
      updatedAtMs: now,
    });
    await ref.collection('events').doc().create(
      eventDoc({
        type: 'donation_receipt',
        uid: after.uid,
        atMs: now,
        data: {
          amountCents: after.amountCents,
          toCharityId: after.toCharityId ?? '',
        },
      }),
    );
  },
);
