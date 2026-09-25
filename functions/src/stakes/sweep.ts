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

import {
  decideChallenge,
  DecisionInputs,
  decisionDueAtMs,
  preRevealNoticeDue,
  revealExpiresAtMs,
  sweepAction,
} from './decisions';
import { DeviceToken, sendToTokens } from '../intentions/push_send';
import {
  activityFeedItemDoc,
  CHALLENGES,
  challengeFromSnap,
  ENFORCEMENT,
  eventDoc,
  evidenceFromSnap,
} from './firestore_layout';
import { redrivePartialPurges } from './account_purge';
import { escrowRef, markEscrow, processRefundQueue } from './escrows';
import { balanceRef, writeLedgerTxn } from './ledger';
import {
  applyVerdictToChallenge,
  PHOTO_RESERVATIONS,
  PHOTO_SCREENS,
} from './nsfw_screen';
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
    reservationsExpired: await expirePhotoReservations(now),
    expired: await expireInvites(now),
    toVerification: await moveToVerification(now),
    // 2026-09-18: an hour before a photo would post, the staker hears
    // about it — and about the veto and the paid takedown — once.
    preRevealNotices: await sendPreRevealNotices(now),
    decided: await decideDue(now),
    reveals: await expireReveals(now),
    // Phase 2 of the two-phase money move: drive refund_pending →
    // refunded through the provider (crash-safe, idempotent).
    refunds: await processRefundQueue(now),
    // H12 — account purges that hit a failed step are re-driven here.
    purgesRedriven: await redrivePartialPurges(now),
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
    // H1 — verdicts written before the binding existed carry no uid/path
    // and are never applied; the owner re-uploads to get a bound verdict.
    if (typeof screen?.uid !== 'string' || typeof screen?.path !== 'string') {
      continue;
    }
    await applyVerdictToChallenge(
      doc.id,
      {
        approved: status === 'approved',
        reasons: (screen?.reasons as string[] | undefined) ?? [],
      },
      now,
      { uid: screen.uid as string, path: screen.path as string },
    );
    applied += 1;
  }
  return applied;
}

/**
 * M12 — reservations that never became a challenge: delete the doc and
 * the orphan object so an abandoned create can't accumulate storage.
 */
async function expirePhotoReservations(now: number): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(PHOTO_RESERVATIONS)
    .where('expiresAtMs', '<=', now)
    .limit(BATCH_LIMIT)
    .get();
  let expired = 0;
  for (const doc of snap.docs) {
    const challenge = await db.collection(CHALLENGES).doc(doc.id).get();
    if (challenge.exists) {
      // Consumed: the challenge pins the object; the reservation is done.
      await doc.ref.delete();
      continue;
    }
    const uid = doc.data().uid as string | undefined;
    if (uid) {
      await getStorage()
        .bucket()
        .file(`stake_photos/${doc.id}/${uid}.jpg`)
        .delete({ ignoreNotFound: true })
        .catch(() => undefined);
    }
    await db.collection(PHOTO_SCREENS).doc(doc.id).delete().catch(() => undefined);
    await doc.ref.delete();
    expired += 1;
  }
  return expired;
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

/**
 * The pre-reveal notice (2026-09-18): for a solo photo stake whose decision
 * is due within the hour and would reveal, one push telling the staker
 * they can still use the monthly mercy veto or take the photo down for
 * points. Stamped on the doc so it goes once; a push nobody could receive
 * (no device tokens) is stamped too, so the pass never spins on it.
 */
async function sendPreRevealNotices(now: number): Promise<number> {
  const db = getFirestore();
  // Solo decisions land at deadline + 12h; the notice window opens 1h
  // before. `deadlineMs <= now - 11h` is the cheap pre-filter.
  const snap = await db
    .collection(CHALLENGES)
    .where('status', '==', 'pending_verification')
    .where('deadlineMs', '<=', now - 11 * 3_600_000)
    .limit(BATCH_LIMIT)
    .get();

  let sent = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.preRevealNoticeAtMs !== undefined) continue;
    if (data.photoState !== 'approved') continue; // removed / never a photo
    const ch = challengeFromSnap(doc);
    if (ch.type !== 'solo_photo') continue;
    if (!preRevealNoticeDue(ch, now)) continue;

    // Dry-run the decision as it would land: only a reveal is worth a push.
    const inputs = await loadDecisionInputs(ch);
    let wouldReveal = false;
    try {
      const preview = decideChallenge(ch, inputs, decisionDueAtMs(ch));
      wouldReveal = preview.perParticipant.some(
        (r) => r.uid === ch.creatorUid && r.resolution.kind === 'reveal_photo',
      );
    } catch (e) {
      logger.warn('preRevealNotice preview failed', { id: ch.id, e: String(e) });
      continue;
    }
    if (!wouldReveal) {
      await doc.ref.update({ preRevealNoticeAtMs: now, preRevealNoticeSkipped: 'would_not_reveal' });
      continue;
    }

    const tokens = await deviceTokensFor(ch.creatorUid);
    if (tokens.length === 0) {
      await doc.ref.update({ preRevealNoticeAtMs: now, preRevealNoticeSkipped: 'no_devices' });
      continue;
    }
    const minutesLeft = Math.max(1, Math.round((decisionDueAtMs(ch) - now) / 60_000));
    const result = await sendToTokens(ch.creatorUid, tokens, (token) => ({
      token,
      notification: {
        title: 'Your stake photo posts soon',
        body:
          `"${ch.frozenGoal.title}" didn't make it. In about ${minutesLeft} min ` +
          'your photo goes to the group — unless you use your monthly mercy ' +
          'veto or take it down for points. Open the challenge.',
      },
      data: { type: 'stake_pre_reveal', challengeId: ch.id },
      apns: { headers: { 'apns-collapse-id': `stake_pre_reveal_${ch.id}` } },
    }));
    // Honest bookkeeping (P2-02): stamp only when FCM took at least one.
    if (result.delivered > 0) {
      await doc.ref.update({ preRevealNoticeAtMs: now });
      sent += 1;
    }
  }
  return sent;
}

async function deviceTokensFor(uid: string): Promise<DeviceToken[]> {
  const snap = await getFirestore().collection(`users/${uid}/deviceTokens`).get();
  const tokens: DeviceToken[] = [];
  for (const d of snap.docs) {
    const token = d.data().token as string | undefined;
    if (token) tokens.push({ docId: d.id, token });
  }
  return tokens;
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
    // The feed post is skipped when the circle no longer exists
    // (2026-08-25): a bare tx.create into a deleted circle would abort the
    // whole settlement transaction every 15-minute pass — a poison pill
    // that also starves reveals and refunds behind it.
    const revealNames = new Map<string, string>();
    let circleExists = false;
    if (ch.circleId) {
      circleExists = (await db.doc(`circles/${ch.circleId}`).get()).exists;
    }
    for (const r of decision.perParticipant) {
      if (r.resolution.kind !== 'reveal_photo' || !ch.circleId || !circleExists) {
        continue;
      }
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
          // Audit H8 / D1: evidence is client-asserted (unit window and
          // per-row bounds enforced by rules; multi-party outcomes also go
          // through dispute + vote). Recorded on the outcome so the policy
          // is visible on every settled record.
          evidenceSelfReported: true,
        },
      };

      // Photo lifecycle (P-3/P-4): reveal on forfeit, delete otherwise.
      // A photo taken down BEFORE the reveal (stakeRemovePhoto's pre-reveal
      // door, 2026-09-18) stays 'removed': the loss is decided as usual,
      // nothing posts, no feed line, the veto is not burned for it.
      const alreadyRemoved = fresh.data()?.photoState === 'removed';
      for (const r of decision.perParticipant) {
        const photo = ch.participants.find((p) => p.uid === r.uid)?.photo;
        if (!photo) continue;
        if (alreadyRemoved) continue;
        if (r.resolution.kind === 'reveal_photo') {
          update.photoState = 'revealed';
          update.revealedAtMs = now; // window counts from the actual post
          update.revealExpiresAtMs = revealExpiresAtMs(now, photo.revealWindowMins);
          tx.create(doc.ref.collection('events').doc(), eventDoc({ type: 'photo_revealed', uid: r.uid, atMs: now }));
          // Circle feed post (the announcement) — the client feed renders
          // it natively and opens the secure reveal viewer. Skipped when
          // the circle is gone (see circleExists above).
          if (ch.circleId && circleExists) {
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

  // V-3 — eligible voters: ACTIVE circle members who are not participants.
  // Status-filtered (2026-08-25): leaving soft-deletes to status 'removed'
  // and joining starts at 'pending' — counting those ghosts set the quorum
  // bar against members who can never vote, quietly defaulting every
  // dispute to the evidence verdict.
  let eligibleVoterCount = 0;
  if (ch.circleId) {
    const members = await db
      .collection(`circles/${ch.circleId}/members`)
      .where('status', '==', 'active')
      .count()
      .get();
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
