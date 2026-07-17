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
import { escrowRef, markEscrow, processRefundQueue } from './escrows';
import { balanceRef, writeLedgerTxn } from './ledger';
import { applyVerdictToChallenge, PHOTO_SCREENS } from './nsfw_screen';
import { EscrowDoc } from './payments';
import { BalanceDoc, EARN_AMOUNTS } from './points';
import { assertTransition } from './state_machine';
import { Confirmation, StakeChallenge, VetoRequest, Vote } from './types';

const BATCH_LIMIT = 100;

/** One full sweep pass — extracted so tests can run it on demand. */
export async function runSweepOnce(
  now: number,
): Promise<Record<string, number>> {
  const counts = {
    // Safety net for the upload/create race and lost trigger events: any
    // draft whose screening verdict is already stored gets it applied
    // here (idempotent), instead of waiting forever on a delivery that
    // may never come (bit us on day one: uploads during the trigger's
    // own deployment window were stuck in draft permanently).
    screensApplied: await applyPendingScreens(now),
    expired: await expireInvites(now),
    toVerification: await moveToVerification(now),
    decided: await decideDue(now),
    reveals: await expireReveals(now),
    // Phase 2 of the two-phase money move: drive refund_pending →
    // refunded through the provider (crash-safe, idempotent).
    refunds: await processRefundQueue(now),
  };
  logger.info('stakeSweep done', counts);
  return counts;
}

export const stakeSweep = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '256MiB',
    maxInstances: 1, // overlap safety belt on top of transactional re-checks
  },
  async () => {
    await runSweepOnce(Date.now());
  },
);

async function applyPendingScreens(now: number): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(CHALLENGES)
    .where('status', '==', 'draft')
    .limit(50)
    .get();
  let applied = 0;
  for (const doc of snap.docs) {
    if (doc.data().photoState !== 'pending_screen') continue;
    const screen = (await db.collection(PHOTO_SCREENS).doc(doc.id).get()).data();
    const status = screen?.status;
    if (status !== 'approved' && status !== 'rejected') continue;
    await applyVerdictToChallenge(
      doc.id,
      {
        approved: status === 'approved',
        reasons: (screen?.reasons as string[] | undefined) ?? [],
      },
      now,
    );
    applied += 1;
  }
  return applied;
}

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

      // All reads before writes: balances of points participants, so the
      // ledger effects commit ATOMICALLY with the status flip — a crashed
      // sweep can never decide a challenge but strand the locked points.
      const pointsUids =
        ch.type === 'practice'
          ? []
          : ch.participants
              .filter((p) => p.stakeKind === 'points' && (p.stakeAmount ?? 0) > 0)
              .map((p) => p.uid);
      const balances = new Map<string, BalanceDoc | undefined>();
      for (const uid of pointsUids) {
        balances.set(
          uid,
          (await tx.get(balanceRef(uid))).data() as BalanceDoc | undefined,
        );
      }
      // Money escrows (still reads-before-writes).
      const moneyUids = ch.participants
        .filter((p) => p.stakeKind === 'money' && (p.stakeAmount ?? 0) > 0)
        .map((p) => p.uid);
      const escrows = new Map<string, EscrowDoc | undefined>();
      for (const uid of moneyUids) {
        escrows.set(
          uid,
          (await tx.get(escrowRef(ch.id, uid))).data() as EscrowDoc | undefined,
        );
      }
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

      // PT-4 — points resolutions: winners get their lock back
      // (stake_release), losers' locks burn (stake_forfeit, zero-amount
      // audit row carrying the burned amount + charity for the quarterly
      // conversion). Win bonus ONLY when some side actually lost —
      // both-win pays refunds alone, so colluding friends can't farm the
      // bonus risk-free. Money resolutions stay recorded in `outcome` for
      // the Stripe rail (Phase 4).
      const anySideLost = decision.perParticipant.some((r) => !r.sideWon);
      for (const r of decision.perParticipant) {
        if (!pointsUids.includes(r.uid)) continue;
        const stake =
          ch.participants.find((p) => p.uid === r.uid)?.stakeAmount ?? 0;
        let bal = balances.get(r.uid);
        if (r.sideWon) {
          bal = writeLedgerTxn(tx, r.uid, bal, {
            source: 'stake_release',
            amount: stake,
            refId: ch.id,
            atMs: now,
          });
          if (anySideLost) {
            bal = writeLedgerTxn(tx, r.uid, bal, {
              source: 'earn_challenge_win',
              amount: EARN_AMOUNTS.earn_challenge_win!,
              refId: ch.id,
              atMs: now,
            });
          }
        } else {
          const toCharityId =
            r.resolution.kind === 'forfeit' ? r.resolution.toCharityId : '';
          bal = writeLedgerTxn(tx, r.uid, bal, {
            source: 'stake_forfeit',
            amount: 0,
            refId: ch.id,
            atMs: now,
            data: { burnedAmount: stake, toCharityId },
          });
        }
        balances.set(r.uid, bal);
      }

      // $-2 — money escrows: record the INTENT atomically with the
      // decision (refund_pending / disbursement_pending); the provider
      // call happens in processRefundQueue, never inside this transaction.
      for (const r of decision.perParticipant) {
        if (!moneyUids.includes(r.uid)) continue;
        const escrow = escrows.get(r.uid);
        if (!escrow || escrow.status !== 'held') continue; // nothing to move
        const ref = escrowRef(ch.id, r.uid);
        if (r.sideWon) {
          markEscrow(tx, ref, escrow, 'refund_pending', now);
        } else {
          const toCharityId =
            r.resolution.kind === 'forfeit' ? r.resolution.toCharityId : '';
          markEscrow(tx, ref, escrow, 'disbursement_pending', now, {
            toCharityId,
          });
        }
      }
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
