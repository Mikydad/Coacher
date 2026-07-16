/**
 * CC-4 — the 15-minute outcome sweep. The ONLY place challenge outcomes are
 * decided and stake movements originate (with dispute votes feeding in via
 * callables). Composite indexes: (status, deadlineMs) and
 * (photoState, revealExpiresAtMs) — declared in firestore.indexes.json.
 *
 * Every pass is idempotent: each mutation re-checks state inside its
 * transaction, so a crashed or overlapping run cannot double-decide
 * (double reveal, double veto burn).
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { decideChallenge, DecisionInputs, revealExpiresAtMs, sweepAction } from './decisions';
import {
  activityFeedItemDoc,
  CHALLENGES,
  challengeFromSnap,
  ENFORCEMENT,
  eventDoc,
  evidenceFromSnap,
} from './firestore_layout';
import { assertTransition } from './state_machine';
import { Confirmation, StakeChallenge, VetoRequest, Vote } from './types';

const BATCH_LIMIT = 100;

export const stakeSweep = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '256MiB',
    maxInstances: 1, // overlap safety belt on top of transactional re-checks
  },
  async () => {
    const now = Date.now();
    const counts = {
      expired: await expireInvites(now),
      toVerification: await moveToVerification(now),
      decided: await decideDue(now),
      reveals: await expireReveals(now),
    };
    logger.info('stakeSweep done', counts);
  },
);

async function expireInvites(now: number): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(CHALLENGES)
    .where('status', '==', 'pending_accept')
    .where('deadlineMs', '<=', now)
    .limit(BATCH_LIMIT)
    .get();
  for (const doc of snap.docs) {
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.status !== 'pending_accept') return;
      assertTransition('pending_accept', 'cancelled');
      tx.update(doc.ref, { status: 'cancelled', updatedAtMs: now });
      tx.create(doc.ref.collection('events').doc(), eventDoc({ type: 'invite_expired', atMs: now }));
    });
  }
  return snap.size;
}

async function moveToVerification(now: number): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(CHALLENGES)
    .where('status', '==', 'active')
    .where('deadlineMs', '<=', now)
    .limit(BATCH_LIMIT)
    .get();
  for (const doc of snap.docs) {
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.status !== 'active') return;
      assertTransition('active', 'pending_verification');
      tx.update(doc.ref, { status: 'pending_verification', updatedAtMs: now });
      tx.create(doc.ref.collection('events').doc(), eventDoc({ type: 'deadline_reached', atMs: now }));
    });
  }
  return snap.size;
}

async function decideDue(now: number): Promise<number> {
  const db = getFirestore();
  // deadlineMs <= now - 12h is a cheap pre-filter (the earliest any solo
  // decision can be due); the pure sweepAction makes the exact call.
  const snap = await db
    .collection(CHALLENGES)
    .where('status', '==', 'pending_verification')
    .where('deadlineMs', '<=', now - 12 * 3_600_000)
    .limit(BATCH_LIMIT)
    .get();

  let decided = 0;
  for (const doc of snap.docs) {
    const ch = challengeFromSnap(doc);
    const inputs = await loadDecisionInputs(ch);
    const action = sweepAction(ch, inputs.confirmations, now);
    if (action.kind !== 'decide') continue;

    const decision = decideChallenge(ch, inputs, action.atMs);

    // Display names for reveal feed posts, read before the transaction.
    const revealNames = new Map<string, string>();
    for (const r of decision.perParticipant) {
      if (r.resolution.kind !== 'reveal_photo' || !ch.circleId) continue;
      const member = await db
        .doc(`circles/${ch.circleId}/members/${r.uid}`)
        .get();
      revealNames.set(
        r.uid,
        (member.data()?.displayName as string | undefined) ?? 'A member',
      );
    }

    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.status !== 'pending_verification') return; // already handled

      assertTransition('pending_verification', decision.statusAfter);
      const update: Record<string, unknown> = {
        status: decision.statusAfter,
        updatedAtMs: now,
        outcome: {
          decidedAtMs: decision.decidedAtMs,
          perParticipant: decision.perParticipant,
        },
      };

      // Photo lifecycle (P-3/P-4): reveal on forfeit, delete otherwise.
      for (const r of decision.perParticipant) {
        const photo = ch.participants.find((p) => p.uid === r.uid)?.photo;
        if (!photo) continue;
        if (r.resolution.kind === 'reveal_photo') {
          update.photoState = 'revealed';
          update.revealedAtMs = now; // window counts from the actual post
          update.revealExpiresAtMs = revealExpiresAtMs(now, photo.revealWindowMins);
          tx.create(doc.ref.collection('events').doc(), eventDoc({ type: 'photo_revealed', uid: r.uid, atMs: now }));
          // Circle feed post (the announcement) — the client feed renders
          // it natively and opens the secure reveal viewer.
          if (ch.circleId) {
            const feedRef = db
              .collection(`circles/${ch.circleId}/activityFeed`)
              .doc();
            tx.create(
              feedRef,
              activityFeedItemDoc({
                id: feedRef.id,
                circleId: ch.circleId,
                userId: r.uid,
                displayName: revealNames.get(r.uid) ?? 'A member',
                eventType: 'stakePhotoRevealed',
                entityId: ch.id,
                entityTitle: ch.frozenGoal.title,
                value: `${update.revealExpiresAtMs}`,
                nowMs: now,
              }),
            );
          }
        } else {
          // success or veto_blocked → the photo dies unseen.
          update.photoState = 'deleted';
        }
        if (r.resolution.kind === 'veto_blocked') {
          // M-6 — burn the monthly veto only when it actually fired.
          tx.set(
            db.collection(ENFORCEMENT).doc(r.uid),
            { lastVetoAtMs: action.atMs, updatedAtMs: now },
            { merge: true },
          );
        }
      }

      tx.update(doc.ref, update);
      for (const e of decision.events) {
        tx.create(doc.ref.collection('events').doc(), eventDoc(e));
      }
      // Points/money refund+forfeit resolutions are recorded in `outcome`
      // now; the ledger (Phase 2) and Stripe (Phase 4) rails consume them
      // from there — outcome and money movement stay decoupled.
    });

    // Storage deletes AFTER the transaction commits (best-effort, retried
    // by the next sweep via photoState if this crashes in between).
    for (const r of decision.perParticipant) {
      const photo = ch.participants.find((p) => p.uid === r.uid)?.photo;
      if (photo && r.resolution.kind !== 'reveal_photo') {
        await getStorage().bucket().file(photo.storagePath).delete({ ignoreNotFound: true });
      }
    }
    decided += 1;
  }
  return decided;
}

/** P-4 — revealed photos past their window: delete object, mark expired. */
async function expireReveals(now: number): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(CHALLENGES)
    .where('photoState', '==', 'revealed')
    .where('revealExpiresAtMs', '<=', now)
    .limit(BATCH_LIMIT)
    .get();
  for (const doc of snap.docs) {
    const ch = challengeFromSnap(doc);
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.data()?.photoState !== 'revealed') return;
      tx.update(doc.ref, { photoState: 'expired', updatedAtMs: now });
      tx.create(doc.ref.collection('events').doc(), eventDoc({ type: 'photo_expired', atMs: now }));
    });
    for (const p of ch.participants) {
      if (p.photo) {
        await getStorage().bucket().file(p.photo.storagePath).delete({ ignoreNotFound: true });
      }
    }
  }
  return snap.size;
}

async function loadDecisionInputs(ch: StakeChallenge): Promise<DecisionInputs> {
  const db = getFirestore();
  const ref = db.collection(CHALLENGES).doc(ch.id);

  const [evidenceSnap, confirmSnap, votesSnap, vetoSnap] = await Promise.all([
    ref.collection('evidence').get(),
    ref.collection('confirmations').get(),
    ref.collection('votes').get(),
    ref.collection('vetoRequests').get(),
  ]);

  const evidence = evidenceSnap.docs
    .map(evidenceFromSnap)
    .filter((e): e is NonNullable<typeof e> => e !== null);
  const confirmations = confirmSnap.docs.map((d) => d.data() as unknown as Confirmation);
  const votes = votesSnap.docs.map((d) => d.data() as unknown as Vote);
  const vetoRequests = vetoSnap.docs.map((d) => d.data() as unknown as VetoRequest);

  // V-3 — eligible voters: circle members who are not participants.
  let eligibleVoterCount = 0;
  if (ch.circleId) {
    const members = await db.collection(`circles/${ch.circleId}/members`).count().get();
    eligibleVoterCount = Math.max(0, members.data().count - ch.participants.length);
  }

  // M-6 — last veto per photo participant (solo: at most one).
  const lastVetoAtMsByUid: Record<string, number> = {};
  for (const p of ch.participants) {
    if (p.stakeKind !== 'photo') continue;
    const doc = await db.collection(ENFORCEMENT).doc(p.uid).get();
    const last = doc.data()?.lastVetoAtMs;
    if (typeof last === 'number') lastVetoAtMsByUid[p.uid] = last;
  }

  return { evidence, confirmations, votes, eligibleVoterCount, vetoRequests, lastVetoAtMsByUid };
}
