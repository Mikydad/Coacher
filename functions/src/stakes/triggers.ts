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

import { onDocumentCreated } from 'firebase-functions/v2/firestore';

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
