/**
 * Account deletion purge (pre-launch audit H12/H17; decision log 2026-09-15
 * D3/D4). The app's in-app "Delete account" re-authenticates, revokes the
 * Apple token, and deletes the Firebase Auth user; this v1 Auth onDelete
 * trigger then runs `purgeAccount`, which:
 *
 *   stakes        — cancels every non-terminal challenge the user is in AND
 *                   settles it: points locks released to every side
 *                   (`stake_release_{id}`, idempotent), held money escrows →
 *                   refund_pending. Photos + evidence + screen docs deleted.
 *   memberships   — leaves every circle (member doc deleted, memberCount −1
 *                   if it was active, dropped from moderatorIds).
 *   user_tree     — `users/{uid}` recursively (routines, goals, reminders,
 *                   memory facts, people, device tokens, circleIds, …).
 *   ai_usage      — `aiUsage/{uid}`.
 *   feedback      — feedback docs + `feedback/{uid}/` screenshots.
 *   reservations  — `stake_photo_reservations` the user held.
 *
 * Every step's outcome is recorded on `account_purges/{uid}`; a failed step
 * leaves the job `partial` and `stakeSweep` re-drives it (every step is
 * idempotent). RETAINED on purpose: `points_ledger/{uid}`, `stake_escrows`,
 * terminal `stake_challenges` + events — the financial audit trail, which
 * carries no profile data. `circle_invites` belong to the circle, not the
 * creator, and stay.
 *
 * v1 because Auth onDelete has no v2 equivalent (identity blocking
 * functions are a different product); v1 and v2 coexist fine.
 */

import * as functionsV1 from 'firebase-functions/v1';
import { logger } from 'firebase-functions/v2';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { ESCROWS, escrowRef, markEscrow, processRefundQueue } from './escrows';
import { CHALLENGES, eventDoc } from './firestore_layout';
import { balanceRef, writeLedgerTxn } from './ledger';
import { PHOTO_RESERVATIONS, PHOTO_SCREENS } from './nsfw_screen';
import { EscrowDoc } from './payments';
import { BalanceDoc } from './points';
import {
  CANCELLABLE_STATUSES,
  PurgeJob,
  PurgeStep,
  PURGE_STEPS,
  purgeStatus,
  settlementForCancellation,
} from './purge_plan';

export const ACCOUNT_PURGES = 'account_purges';

export const stakeAccountPurge = functionsV1
  .region('us-central1')
  .auth.user()
  .onDelete(async (user) => {
    await purgeAccount(user.uid, Date.now());
  });

/** Runs (or re-runs) the purge inventory for [uid]. Idempotent. */
export async function purgeAccount(uid: string, now: number): Promise<PurgeJob> {
  const db = getFirestore();
  const jobRef = db.collection(ACCOUNT_PURGES).doc(uid);
  const existing = (await jobRef.get()).data() as PurgeJob | undefined;
  const job: PurgeJob = {
    uid,
    startedAtMs: existing?.startedAtMs ?? now,
    updatedAtMs: now,
    attempts: (existing?.attempts ?? 0) + 1,
    status: 'running',
    steps: { ...(existing?.steps ?? {}) },
  };
  await jobRef.set(job, { merge: true });

  const runners: Record<PurgeStep, () => Promise<void>> = {
    stakes: () => purgeStakes(uid, now),
    memberships: () => purgeMemberships(uid, now),
    user_tree: () => purgeUserTree(uid),
    ai_usage: () => db.collection('aiUsage').doc(uid).delete().then(() => undefined),
    feedback: () => purgeFeedback(uid),
    reservations: () => purgeReservations(uid),
  };

  for (const step of PURGE_STEPS) {
    if (job.steps[step]?.status === 'done') continue;
    try {
      await runners[step]();
      job.steps[step] = { status: 'done' };
    } catch (e) {
      job.steps[step] = { status: 'failed', error: `${e}`.slice(0, 500) };
      logger.error('account purge step failed', { uid, step, error: `${e}` });
    }
    await jobRef.set({ steps: job.steps, updatedAtMs: Date.now() }, { merge: true });
  }

  job.status = purgeStatus(job);
  job.updatedAtMs = Date.now();
  await jobRef.set({ status: job.status, updatedAtMs: job.updatedAtMs }, { merge: true });
  logger.info('account purge', { uid, status: job.status, attempts: job.attempts });
  return job;
}

/** Sweep hook: re-drive purges that did not finish. */
export async function redrivePartialPurges(now: number, limit = 10): Promise<number> {
  const db = getFirestore();
  const snap = await db
    .collection(ACCOUNT_PURGES)
    .where('status', '==', 'partial')
    .limit(limit)
    .get();
  let redriven = 0;
  for (const doc of snap.docs) {
    const job = doc.data() as PurgeJob;
    // Back off: attempt n waits n × 15 min (one sweep cadence) before retrying.
    if (now - job.updatedAtMs < job.attempts * 15 * 60_000) continue;
    await purgeAccount(doc.id, now);
    redriven += 1;
  }
  return redriven;
}

// ─── Steps ───────────────────────────────────────────────────────────────────

async function purgeStakes(uid: string, now: number): Promise<void> {
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const challenges = await db
    .collection(CHALLENGES)
    .where('participantUids', 'array-contains', uid)
    .get();

  for (const doc of challenges.docs) {
    if (CANCELLABLE_STATUSES.has(doc.data().status as string)) {
      await db.runTransaction(async (tx) => {
        const fresh = await tx.get(doc.ref);
        const data = fresh.data();
        if (!data || !CANCELLABLE_STATUSES.has(data.status as string)) return;
        const ch = {
          id: doc.id,
          status: data.status as string,
          participants: (data.participants ?? []) as Array<{
            uid: string;
            stakeKind: string;
            stakeAmount?: number;
          }>,
        };
        const settlement = settlementForCancellation(ch, uid);

        // All reads before writes (Firestore transactions).
        const balances = new Map<string, BalanceDoc | undefined>();
        for (const r of settlement.releases) {
          balances.set(r.uid, (await tx.get(balanceRef(r.uid))).data() as BalanceDoc | undefined);
        }
        const escrows = new Map<string, EscrowDoc | undefined>();
        for (const euid of settlement.escrowRefundUids) {
          escrows.set(euid, (await tx.get(escrowRef(doc.id, euid))).data() as EscrowDoc | undefined);
        }

        tx.update(doc.ref, {
          status: 'cancelled',
          photoState: 'deleted',
          updatedAtMs: now,
        });
        tx.create(
          doc.ref.collection('events').doc(),
          eventDoc({ type: 'cancelled', uid, atMs: now, data: { accountDeleted: true } }),
        );
        // H17 — cancel-and-refund (D4): every locked stake goes back.
        // `stake_release_{challengeId}` is deterministic, so a repeated
        // Auth event or sweep re-drive cannot double-credit (tx.create
        // rejects the duplicate and this transaction is retried as a
        // no-op once the status guard above sees `cancelled`).
        for (const r of settlement.releases) {
          writeLedgerTxn(tx, r.uid, balances.get(r.uid), {
            source: 'stake_release',
            amount: r.amount,
            refId: doc.id,
            atMs: now,
          });
        }
        for (const euid of settlement.escrowRefundUids) {
          const escrow = escrows.get(euid);
          if (!escrow || escrow.status !== 'held') continue;
          markEscrow(tx, escrowRef(doc.id, euid), escrow, 'refund_pending', now, {
            accountDeleted: true,
          });
        }
      });
    }

    // Photos are purged regardless of challenge state.
    await bucket.deleteFiles({ prefix: `stake_photos/${doc.id}/${uid}.jpg` });
    await bucket.deleteFiles({ prefix: `stake_evidence/${doc.id}/${uid}/` });
    await db.collection(PHOTO_SCREENS).doc(doc.id).delete();
  }

  await db.collection('enforcement').doc(uid).delete();

  // Any escrow of the deleted user still held outside the loop above
  // (defensive — e.g. a challenge already terminal but escrow stuck).
  const heldEscrows = await db
    .collection(ESCROWS)
    .where('uid', '==', uid)
    .where('status', '==', 'held')
    .get();
  for (const doc of heldEscrows.docs) {
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      const escrow = fresh.data() as EscrowDoc | undefined;
      if (!escrow || escrow.status !== 'held') return;
      markEscrow(tx, doc.ref, escrow, 'refund_pending', now, { accountDeleted: true });
    });
  }
  await processRefundQueue(now);
}

async function purgeMemberships(uid: string, now: number): Promise<void> {
  const db = getFirestore();
  // The server-owned index is the authoritative list of active circles;
  // the collection-group query catches pending / removed docs too.
  const memberDocs = await db
    .collectionGroup('members')
    .where('userId', '==', uid)
    .get();
  const circleIds = new Set<string>(memberDocs.docs.map((d) => d.ref.parent.parent!.id));
  const indexed = await db.collection(`users/${uid}/circleIds`).get();
  for (const d of indexed.docs) circleIds.add(d.id);

  for (const circleId of circleIds) {
    await db.runTransaction(async (tx) => {
      const circleRef = db.doc(`circles/${circleId}`);
      const memberRef = db.doc(`circles/${circleId}/members/${uid}`);
      const [circle, member] = await Promise.all([tx.get(circleRef), tx.get(memberRef)]);
      if (member.exists) {
        tx.delete(memberRef);
        if (circle.exists && member.data()?.status === 'active') {
          tx.update(circleRef, {
            memberCount: FieldValue.increment(-1),
            moderatorIds: FieldValue.arrayRemove(uid),
            updatedAtMs: now,
          });
        }
      }
      tx.delete(db.doc(`users/${uid}/circleIds/${circleId}`));
    });
  }
}

async function purgeUserTree(uid: string): Promise<void> {
  const db = getFirestore();
  // Handles a missing parent doc and every nested subcollection.
  await db.recursiveDelete(db.doc(`users/${uid}`));
}

async function purgeFeedback(uid: string): Promise<void> {
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const reports = await db.collection('feedback').where('userId', '==', uid).get();
  for (const doc of reports.docs) await doc.ref.delete();
  await bucket.deleteFiles({ prefix: `feedback/${uid}/` });
}

async function purgeReservations(uid: string): Promise<void> {
  const db = getFirestore();
  const bucket = getStorage().bucket();
  const reservations = await db
    .collection(PHOTO_RESERVATIONS)
    .where('uid', '==', uid)
    .get();
  for (const doc of reservations.docs) {
    await bucket.deleteFiles({ prefix: `stake_photos/${doc.id}/${uid}.jpg` });
    await doc.ref.delete();
  }
}
