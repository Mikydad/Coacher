/**
 * Stake challenge callables (PRD §7.3). Phase 1 scope: solo photo +
 * practice. H2H/team create/accept ship in Phase 2; confirm/vote are
 * already here because disputes exist for solo too (V-1).
 *
 * Every state change goes through assertTransition and appends an event
 * (CC-2/CC-3). No outcome is ever decided here — that is sweep.ts calling
 * the pure engine (spec §2.2).
 */

import {
  CallableRequest,
  HttpsError,
  onCall,
} from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

import { canRemoveRevealedPhoto, vetoEligible } from './decisions';
import { escrowRef, newEscrowDoc } from './escrows';
import { balanceRef, txnRef, writeLedgerTxn } from './ledger';
import { EscrowDoc, getPaymentProvider, validMoneyAmount } from './payments';
import {
  BalanceDoc,
  H2H_STAKE_MAX,
  H2H_STAKE_MIN,
  PHOTO_REMOVAL_PRICE,
  txnId,
} from './points';
import {
  applyStrike,
  banDurationMsForStrike,
  EnforcementDoc,
  isChallengeBanned,
} from './enforcement';
import {
  activityFeedItemDoc,
  AuditEvent,
  CHALLENGES,
  challengeFromSnap,
  ENFORCEMENT,
  eventDoc,
} from './firestore_layout';
import { assertTransition } from './state_machine';
import {
  ChallengeType,
  CONFIRM_WINDOW_MS,
  FrozenGoal,
  Participant,
  REVEAL_WINDOW_MAX_MINS,
  REVEAL_WINDOW_MIN_MINS,
  SoloMode,
  StakeChallenge,
} from './types';
import { voteClosesAtMs } from './decisions';

const REGION = 'us-central1';
const CALL_OPTS = { region: REGION, timeoutSeconds: 30, memory: '256MiB' as const, maxInstances: 10 };

const HOUR_MS = 3_600_000;
const DAY_MS = 24 * HOUR_MS;

/** Phase 1+2+4 — creatable types (team + h2h money still gated off). */
const CREATABLE_TYPES: ReadonlySet<ChallengeType> = new Set([
  'solo_photo',
  'practice',
  'h2h_points',
  'solo_money',
]);

// ─── Shared guards ───────────────────────────────────────────────────────────

function requireAuth(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  return request.auth.uid;
}

/** Photo stakes need a real account (P-9 gating happens client-side too). */
function requireRegistered(request: CallableRequest): void {
  const provider = (request.auth?.token as Record<string, any>)?.firebase
    ?.sign_in_provider;
  if (provider === 'anonymous') {
    throw new HttpsError(
      'permission-denied',
      'Sign in with an account to use stakes.',
    );
  }
}

function str(v: unknown, name: string, min: number, max: number): string {
  if (typeof v !== 'string' || v.length < min || v.length > max) {
    throw new HttpsError('invalid-argument', `${name} must be a string of ${min}–${max} chars.`);
  }
  return v;
}

function int(v: unknown, name: string, min: number, max: number): number {
  if (typeof v !== 'number' || !Number.isInteger(v) || v < min || v > max) {
    throw new HttpsError('invalid-argument', `${name} must be an integer in [${min}, ${max}].`);
  }
  return v;
}

async function loadChallenge(id: string): Promise<StakeChallenge> {
  const snap = await getFirestore().collection(CHALLENGES).doc(id).get();
  if (!snap.exists) throw new HttpsError('not-found', 'Challenge not found.');
  return challengeFromSnap(snap);
}

function participantOf(ch: StakeChallenge, uid: string): Participant {
  const p = ch.participants.find((x) => x.uid === uid);
  if (!p) throw new HttpsError('permission-denied', 'Not a participant.');
  return p;
}

async function isCircleMember(circleId: string, uid: string): Promise<boolean> {
  const snap = await getFirestore()
    .doc(`circles/${circleId}/members/${uid}`)
    .get();
  return snap.exists;
}

function appendEvent(
  tx: FirebaseFirestore.Transaction,
  challengeId: string,
  event: AuditEvent,
): void {
  const ref = getFirestore()
    .collection(CHALLENGES)
    .doc(challengeId)
    .collection('events')
    .doc();
  tx.create(ref, eventDoc(event));
}

// ─── stakeCreateChallenge ────────────────────────────────────────────────────

interface CreateData {
  id?: unknown;
  type?: unknown;
  circleId?: unknown;
  goal?: unknown;
  mode?: unknown;
  deadlineMs?: unknown;
  photo?: unknown;
  pledge?: unknown;
  // h2h (D5/D6):
  opponentUid?: unknown;
  stakeAmount?: unknown;
  charityId?: unknown; // creator's "loved" pick
  bothLoseCharityId?: unknown;
  // solo money ($-1): the anti-charity + stake in cents
  antiCharityId?: unknown;
  amountCents?: unknown;
}

/** D7 — every charity reference must be on the curated active list. */
async function assertCharityActive(charityId: string): Promise<void> {
  const snap = await getFirestore().doc(`charities/${charityId}`).get();
  if (!snap.exists || snap.data()?.active !== true) {
    throw new HttpsError('invalid-argument', 'Unknown or inactive charity.');
  }
}

export const stakeCreateChallenge = onCall(
  CALL_OPTS,
  async (request: CallableRequest<CreateData>) => {
    const uid = requireAuth(request);
    const now = Date.now();
    const db = getFirestore();

    const type = str(request.data?.type, 'type', 1, 32) as ChallengeType;
    if (!CREATABLE_TYPES.has(type)) {
      throw new HttpsError(
        'failed-precondition',
        `Challenge type ${type} is not available yet.`,
      );
    }
    if (type !== 'practice') requireRegistered(request);

    // Client-generated StableId (house pattern); create() rejects reuse.
    const id = str(request.data?.id, 'id', 8, 64);
    if (!/^[A-Za-z0-9_-]+$/.test(id)) {
      throw new HttpsError('invalid-argument', 'id has invalid characters.');
    }

    // D11 — banned users cannot join/create (active challenges continue).
    const enforcement = (
      await db.collection(ENFORCEMENT).doc(uid).get()
    ).data() as EnforcementDoc | undefined;
    if (isChallengeBanned(enforcement?.challengeBanUntilMs, now)) {
      throw new HttpsError(
        'permission-denied',
        'You are temporarily banned from starting challenges.',
      );
    }

    // CC-6 — the goal is frozen here; later goal edits change nothing.
    const rawGoal = (request.data?.goal ?? {}) as Record<string, unknown>;
    const unitKind = rawGoal.unitKind === 'count' ? 'count' : 'minutes';
    const goal: FrozenGoal = {
      title: str(rawGoal.title, 'goal.title', 1, 80),
      unitKind,
      unitTarget: int(
        rawGoal.unitTarget,
        'goal.unitTarget',
        1,
        unitKind === 'minutes' ? 1440 : 10_000,
      ),
      totalUnits: int(rawGoal.totalUnits, 'goal.totalUnits', 1, 90),
    };

    const mode = str(request.data?.mode ?? 'flexible', 'mode', 1, 16);
    if (!['flexible', 'disciplined', 'extreme'].includes(mode)) {
      throw new HttpsError('invalid-argument', 'mode must be flexible|disciplined|extreme.');
    }

    const deadlineMs = int(
      request.data?.deadlineMs,
      'deadlineMs',
      now + 1 * HOUR_MS,
      now + 120 * DAY_MS,
    );

    // PSY-1 — the pledge is the activating gesture; recorded as an event.
    const rawPledge = (request.data?.pledge ?? {}) as Record<string, unknown>;
    const pledgeWhy = str(rawPledge.why, 'pledge.why', 1, 280);

    const participants: Participant[] = [];
    let circleId = '';
    let initialStatus: StakeChallenge['status'];
    let photoState: string | undefined;
    let sideCharities: Record<string, string> | undefined;
    let bothLoseCharityId: string | undefined;
    let antiCharityId: string | undefined;
    let chargedEscrow: EscrowDoc | undefined;

    if (type === 'solo_photo') {
      circleId = str(request.data?.circleId, 'circleId', 1, 64);
      if (!(await isCircleMember(circleId, uid))) {
        throw new HttpsError('permission-denied', 'Not a member of that circle.');
      }
      const rawPhoto = (request.data?.photo ?? {}) as Record<string, unknown>;
      const storagePath = str(rawPhoto.storagePath, 'photo.storagePath', 1, 256);
      if (storagePath !== `stake_photos/${id}/${uid}.jpg`) {
        throw new HttpsError('invalid-argument', 'photo.storagePath does not match the required layout.');
      }
      participants.push({
        uid,
        teamId: uid,
        stakeKind: 'photo',
        accepted: true,
        photo: {
          storagePath,
          revealWindowMins: int(
            rawPhoto.revealWindowMins,
            'photo.revealWindowMins',
            REVEAL_WINDOW_MIN_MINS,
            REVEAL_WINDOW_MAX_MINS,
          ),
          // P-1 — consent is the tap that invoked this call; server-stamped.
          consentAtMs: now,
        },
      });
      // P-2 — cannot activate until the NSFW screen passes (Step 1.6 trigger).
      initialStatus = 'draft';
      photoState = 'pending_screen';
    } else if (type === 'h2h_points') {
      // 1v1 on points (D5/D6, M-4): challenger proposes goal + mode +
      // stake; both stakes lock at accept, not here.
      circleId = str(request.data?.circleId, 'circleId', 1, 64);
      const opponentUid = str(request.data?.opponentUid, 'opponentUid', 1, 128);
      if (opponentUid === uid) {
        throw new HttpsError('invalid-argument', 'You cannot challenge yourself.');
      }
      if (!(await isCircleMember(circleId, uid)) ||
          !(await isCircleMember(circleId, opponentUid))) {
        throw new HttpsError('permission-denied', 'Both players must be members of that circle.');
      }
      const stakeAmount = int(
        request.data?.stakeAmount,
        'stakeAmount',
        H2H_STAKE_MIN,
        H2H_STAKE_MAX,
      );
      const charityId = str(request.data?.charityId, 'charityId', 1, 64);
      bothLoseCharityId = str(
        request.data?.bothLoseCharityId,
        'bothLoseCharityId',
        1,
        64,
      );
      await assertCharityActive(charityId);
      await assertCharityActive(bothLoseCharityId);

      // Soft balance check for honest UX; the binding check is at accept.
      const bal = (await balanceRef(uid).get()).data() as BalanceDoc | undefined;
      if ((bal?.balance ?? 0) < stakeAmount) {
        throw new HttpsError(
          'failed-precondition',
          `You need ${stakeAmount} points to stake this challenge.`,
        );
      }

      participants.push(
        { uid, teamId: uid, stakeKind: 'points', stakeAmount, accepted: true },
        {
          uid: opponentUid,
          teamId: opponentUid,
          stakeKind: 'points',
          stakeAmount,
          accepted: false,
        },
      );
      sideCharities = { [uid]: charityId };
      initialStatus = 'pending_accept';
      assertTransition('draft', 'pending_accept');
    } else if (type === 'solo_money') {
      // $-1 — charge at creation; the challenge only exists if the charge
      // succeeded. NO mercy on money (D10) beyond the measurement rules.
      // Runs on the SIMULATED provider until Stripe activates
      // (documentation/PHASE3_BUSINESS_SETUP.md).
      const amountCents = int(request.data?.amountCents, 'amountCents', 1, 1_000_000);
      if (!validMoneyAmount(amountCents)) {
        throw new HttpsError('invalid-argument', 'Stake must be between $1 and $100.');
      }
      antiCharityId = str(request.data?.antiCharityId, 'antiCharityId', 1, 64);
      await assertCharityActive(antiCharityId);
      // Circle is optional for solo money (announcement context only).
      const rawCircle = request.data?.circleId;
      if (typeof rawCircle === 'string' && rawCircle.length > 0) {
        circleId = str(rawCircle, 'circleId', 1, 64);
        if (!(await isCircleMember(circleId, uid))) {
          throw new HttpsError('permission-denied', 'Not a member of that circle.');
        }
      }

      const charge = await getPaymentProvider().charge({
        challengeId: id,
        uid,
        amountCents,
      });
      if (!charge.ok) {
        throw new HttpsError(
          'failed-precondition',
          charge.failureReason ?? 'The charge did not go through.',
        );
      }
      chargedEscrow = newEscrowDoc({
        challengeId: id,
        uid,
        amountCents,
        provider: getPaymentProvider().name,
        providerRef: charge.providerRef,
        nowMs: now,
      });

      participants.push({
        uid,
        teamId: uid,
        stakeKind: 'money',
        stakeAmount: amountCents,
        accepted: true,
      });
      initialStatus = 'active';
      assertTransition('draft', 'active');
    } else {
      // Practice: no stake, self-report, activates immediately (CC-7).
      participants.push({
        uid,
        teamId: uid,
        stakeKind: 'points',
        stakeAmount: 0,
        accepted: true,
      });
      initialStatus = 'active';
      assertTransition('draft', 'active');
    }

    const doc: Omit<StakeChallenge, 'id'> & {
      photoState?: string;
      participantUids: string[];
    } = {
      type,
      status: initialStatus,
      creatorUid: uid,
      circleId,
      participants,
      // Denormalized for the client mirror's arrayContains pull.
      participantUids: participants.map((p) => p.uid),
      frozenGoal: goal,
      mode: mode as SoloMode,
      deadlineMs,
      createdAtMs: now,
      updatedAtMs: now,
      ...(photoState !== undefined ? { photoState } : {}),
      ...(sideCharities !== undefined ? { sideCharities } : {}),
      ...(bothLoseCharityId !== undefined ? { bothLoseCharityId } : {}),
      ...(antiCharityId !== undefined ? { antiCharityId } : {}),
    };

    const ref = db.collection(CHALLENGES).doc(id);
    await db.runTransaction(async (tx) => {
      // Handshake with the NSFW trigger (see nsfw_screen.ts): the photo
      // uploads before this call, so its verdict may already be in.
      if (type === 'solo_photo') {
        const screen = await tx.get(db.collection('stake_photo_screens').doc(id));
        const screenStatus = screen.data()?.status;
        if (screenStatus === 'rejected') {
          throw new HttpsError(
            'failed-precondition',
            'This photo was rejected by content screening and cannot be staked.',
          );
        }
        if (screenStatus === 'approved') {
          doc.status = 'active';
          doc.photoState = 'approved';
        }
      }
      tx.create(ref, doc); // throws already-exists on id reuse
      if (chargedEscrow !== undefined) {
        // $-1 — escrow record commits atomically with the challenge.
        tx.create(escrowRef(id, uid), chargedEscrow);
        appendEvent(tx, id, {
          type: 'stake_charged',
          uid,
          atMs: now,
          data: { amountCents: chargedEscrow.amountCents, provider: chargedEscrow.provider },
        });
      }
      appendEvent(tx, id, { type: 'created', uid, atMs: now, data: { challengeType: type } });
      appendEvent(tx, id, { type: 'pledge_signed', uid, atMs: now, data: { why: pledgeWhy } });
      if (doc.status === 'active') {
        appendEvent(tx, id, { type: 'activated', uid, atMs: now });
      } else if (doc.status === 'pending_accept') {
        appendEvent(tx, id, { type: 'invited', uid, atMs: now });
      } else {
        appendEvent(tx, id, { type: 'photo_screen_pending', uid, atMs: now });
      }
    });

    logger.info('stakeCreateChallenge ok', { uid, id, type, status: doc.status });
    return { id, status: doc.status };
  },
);

// ─── stakeCancelDraft ────────────────────────────────────────────────────────

export const stakeCancelDraft = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ challengeId?: unknown }>) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    let photoPath: string | undefined;
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(db.collection(CHALLENGES).doc(id));
      if (!snap.exists) throw new HttpsError('not-found', 'Challenge not found.');
      const ch = challengeFromSnap(snap);
      if (ch.creatorUid !== uid) {
        throw new HttpsError('permission-denied', 'Only the creator can cancel.');
      }
      if (ch.status !== 'draft' && ch.status !== 'pending_accept') {
        // An ACTIVE stake cannot be walked away from — that is the product.
        throw new HttpsError('failed-precondition', 'Only drafts and open invites can be cancelled.');
      }
      assertTransition(ch.status, 'cancelled');
      photoPath = ch.participants.find((p) => p.uid === uid)?.photo?.storagePath;
      tx.update(snap.ref, { status: 'cancelled', updatedAtMs: now, photoState: 'deleted' });
      appendEvent(tx, id, { type: 'cancelled', uid, atMs: now });
    });

    if (photoPath) {
      await getStorage().bucket().file(photoPath).delete({ ignoreNotFound: true });
    }
    return { ok: true };
  },
);

// ─── stakeAcceptChallenge / stakeDeclineChallenge (h2h, PT-4) ────────────────
// "B accepts → both stakes are locked." The lock is one transaction: both
// balances are checked and debited together, and only then does the
// challenge go active — no state where one side is committed alone.

export const stakeAcceptChallenge = onCall(
  CALL_OPTS,
  async (
    request: CallableRequest<{ challengeId?: unknown; charityId?: unknown }>,
  ) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const charityId = str(request.data?.charityId, 'charityId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    await assertCharityActive(charityId);

    // D11 — banned users cannot join challenges.
    const enforcement = (
      await db.collection(ENFORCEMENT).doc(uid).get()
    ).data() as EnforcementDoc | undefined;
    if (isChallengeBanned(enforcement?.challengeBanUntilMs, now)) {
      throw new HttpsError(
        'permission-denied',
        'You are temporarily banned from joining challenges.',
      );
    }

    await db.runTransaction(async (tx) => {
      const ref = db.collection(CHALLENGES).doc(id);
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Challenge not found.');
      const ch = challengeFromSnap(snap);
      if (ch.status !== 'pending_accept') {
        throw new HttpsError('failed-precondition', 'This invite is no longer open.');
      }
      if (now >= ch.deadlineMs) {
        throw new HttpsError('failed-precondition', 'This invite has expired.');
      }
      const me = ch.participants.find((p) => p.uid === uid && !p.accepted);
      if (!me) throw new HttpsError('permission-denied', 'This invite is not for you.');
      const stake = me.stakeAmount ?? 0;

      // All reads before writes: both balances.
      const balances = new Map<string, BalanceDoc | undefined>();
      for (const p of ch.participants) {
        balances.set(
          p.uid,
          (await tx.get(balanceRef(p.uid))).data() as BalanceDoc | undefined,
        );
      }

      if ((balances.get(uid)?.balance ?? 0) < stake) {
        throw new HttpsError(
          'failed-precondition',
          `You need ${stake} points to accept this challenge.`,
        );
      }
      const creator = ch.participants.find((p) => p.uid !== uid);
      if (creator && (balances.get(creator.uid)?.balance ?? 0) < stake) {
        // Challenger spent their points since inviting — the invite dies.
        assertTransition('pending_accept', 'cancelled');
        tx.update(ref, { status: 'cancelled', updatedAtMs: now });
        appendEvent(tx, id, {
          type: 'cancelled',
          atMs: now,
          data: { reason: 'challenger_insufficient_points' },
        });
        throw new HttpsError(
          'failed-precondition',
          'The challenger no longer has enough points — the invite was cancelled.',
        );
      }

      // Lock both stakes + activate, atomically (PT-4 stake_lock).
      assertTransition('pending_accept', 'active');
      for (const p of ch.participants) {
        writeLedgerTxn(tx, p.uid, balances.get(p.uid), {
          source: 'stake_lock',
          amount: -stake,
          refId: id,
          atMs: now,
        });
      }
      tx.update(ref, {
        status: 'active',
        participants: ch.participants.map((p) => ({
          ...p,
          accepted: true,
        })),
        [`sideCharities.${uid}`]: charityId,
        updatedAtMs: now,
      });
      appendEvent(tx, id, { type: 'accepted', uid, atMs: now });
      appendEvent(tx, id, { type: 'activated', atMs: now });
    });

    logger.info('stakeAcceptChallenge ok', { uid, id });
    return { ok: true };
  },
);

export const stakeDeclineChallenge = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ challengeId?: unknown }>) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    await db.runTransaction(async (tx) => {
      const ref = db.collection(CHALLENGES).doc(id);
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Challenge not found.');
      const ch = challengeFromSnap(snap);
      if (ch.status !== 'pending_accept') {
        throw new HttpsError('failed-precondition', 'This invite is no longer open.');
      }
      if (!ch.participants.some((p) => p.uid === uid && !p.accepted)) {
        throw new HttpsError('permission-denied', 'This invite is not for you.');
      }
      assertTransition('pending_accept', 'cancelled');
      tx.update(ref, { status: 'cancelled', updatedAtMs: now });
      appendEvent(tx, id, { type: 'declined', uid, atMs: now });
    });
    return { ok: true };
  },
);

// ─── stakeRemovePhoto (P-5/D9) ───────────────────────────────────────────────
// Early takedown of a live reveal: only after the 30% exposure floor, only
// for the price. The loss stays on the record either way.

export const stakeRemovePhoto = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ challengeId?: unknown }>) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    let photoPath: string | undefined;
    await db.runTransaction(async (tx) => {
      const ref = db.collection(CHALLENGES).doc(id);
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Challenge not found.');
      const ch = challengeFromSnap(snap);
      const me = ch.participants.find((p) => p.uid === uid);
      if (!me?.photo) {
        throw new HttpsError('permission-denied', 'Not your stake photo.');
      }
      const data = snap.data()!;
      if (data.photoState !== 'revealed') {
        throw new HttpsError('failed-precondition', 'No live reveal to remove.');
      }
      const revealedAtMs = data.revealedAtMs as number | undefined;
      if (
        revealedAtMs === undefined ||
        !canRemoveRevealedPhoto(revealedAtMs, me.photo.revealWindowMins, now)
      ) {
        throw new HttpsError(
          'failed-precondition',
          'The photo must stay up for at least 30% of its window first.',
        );
      }

      // Dedupe + balance (reads before writes).
      const spendId = txnId('spend_photo_removal', id, now);
      const existing = await tx.get(txnRef(uid, spendId));
      if (existing.exists) return; // already paid — idempotent
      const bal = (await tx.get(balanceRef(uid))).data() as BalanceDoc | undefined;
      if ((bal?.balance ?? 0) < PHOTO_REMOVAL_PRICE) {
        throw new HttpsError(
          'failed-precondition',
          `Removing the photo costs ${PHOTO_REMOVAL_PRICE} points.`,
        );
      }

      writeLedgerTxn(tx, uid, bal, {
        source: 'spend_photo_removal',
        amount: -PHOTO_REMOVAL_PRICE,
        refId: id,
        atMs: now,
      });
      tx.update(ref, { photoState: 'removed', updatedAtMs: now });
      appendEvent(tx, id, { type: 'photo_removed', uid, atMs: now });
      photoPath = me.photo.storagePath;
    });

    if (photoPath) {
      await getStorage().bucket().file(photoPath).delete({ ignoreNotFound: true });
    }
    logger.info('stakeRemovePhoto ok', { uid, id });
    return { ok: true };
  },
);

// ─── stakeApplyVeto (M-6) ────────────────────────────────────────────────────

export const stakeApplyVeto = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ challengeId?: unknown }>) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    const ch = await loadChallenge(id);
    participantOf(ch, uid);
    if (ch.status !== 'pending_verification') {
      throw new HttpsError('failed-precondition', 'A veto can only be requested while the outcome is pending.');
    }
    const enforcement = (
      await db.collection(ENFORCEMENT).doc(uid).get()
    ).data() as EnforcementDoc | undefined;
    if (!vetoEligible(ch, enforcement?.lastVetoAtMs ?? null, now)) {
      throw new HttpsError('failed-precondition', 'No mercy veto available (photo stakes only, one per 30 days).');
    }

    await db.runTransaction(async (tx) => {
      tx.set(
        db.collection(CHALLENGES).doc(id).collection('vetoRequests').doc(uid),
        { uid, atMs: now },
      );
      appendEvent(tx, id, { type: 'veto_requested', uid, atMs: now });
    });
    // The sweep applies it at decision time and stamps enforcement.lastVetoAtMs.
    return { ok: true };
  },
);

// ─── stakeConfirmOutcome (V-2) ───────────────────────────────────────────────

export const stakeConfirmOutcome = onCall(
  CALL_OPTS,
  async (
    request: CallableRequest<{ challengeId?: unknown; aboutUid?: unknown; kind?: unknown }>,
  ) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const aboutUid = str(request.data?.aboutUid, 'aboutUid', 1, 128);
    const kind = str(request.data?.kind, 'kind', 1, 16);
    if (kind !== 'confirm' && kind !== 'dispute') {
      throw new HttpsError('invalid-argument', 'kind must be confirm|dispute.');
    }
    const now = Date.now();

    const ch = await loadChallenge(id);
    participantOf(ch, uid);
    participantOf(ch, aboutUid);
    if (uid === aboutUid) {
      throw new HttpsError('invalid-argument', 'Cannot confirm your own completion.');
    }
    if (ch.status !== 'pending_verification') {
      throw new HttpsError('failed-precondition', 'Not awaiting verification.');
    }
    if (now > ch.deadlineMs + CONFIRM_WINDOW_MS) {
      throw new HttpsError('failed-precondition', 'The confirmation window has closed.');
    }

    const db = getFirestore();
    await db.runTransaction(async (tx) => {
      // One statement per pair, immutable (create-only).
      tx.create(
        db.collection(CHALLENGES).doc(id).collection('confirmations').doc(`${uid}_${aboutUid}`),
        { byUid: uid, aboutUid, kind, atMs: now },
      );
      appendEvent(tx, id, {
        type: 'confirmation_recorded',
        uid,
        atMs: now,
        data: { aboutUid, kind },
      });
    });
    return { ok: true };
  },
);

// ─── stakeCastVote (V-3) ─────────────────────────────────────────────────────

export const stakeCastVote = onCall(
  CALL_OPTS,
  async (
    request: CallableRequest<{ challengeId?: unknown; aboutUid?: unknown; pass?: unknown }>,
  ) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const aboutUid = str(request.data?.aboutUid, 'aboutUid', 1, 128);
    const pass = request.data?.pass;
    if (typeof pass !== 'boolean') {
      throw new HttpsError('invalid-argument', 'pass must be a boolean.');
    }
    const now = Date.now();
    const db = getFirestore();

    const ch = await loadChallenge(id);
    if (ch.status !== 'pending_verification') {
      throw new HttpsError('failed-precondition', 'Not awaiting verification.');
    }
    // V-3 — voters are circle members who are NOT participants.
    if (ch.participants.some((p) => p.uid === uid)) {
      throw new HttpsError('permission-denied', 'Participants cannot vote.');
    }
    if (!ch.circleId || !(await isCircleMember(ch.circleId, uid))) {
      throw new HttpsError('permission-denied', 'Only circle members can vote.');
    }
    // A dispute about aboutUid must exist with its 48h window still open.
    const disputes = await db
      .collection(CHALLENGES)
      .doc(id)
      .collection('confirmations')
      .where('aboutUid', '==', aboutUid)
      .where('kind', '==', 'dispute')
      .get();
    const open = disputes.docs.some((d) => {
      const atMs = d.data().atMs;
      return typeof atMs === 'number' && now < voteClosesAtMs({ byUid: '', aboutUid, kind: 'dispute', atMs });
    });
    if (!open) {
      throw new HttpsError('failed-precondition', 'No open dispute to vote on.');
    }

    await db.runTransaction(async (tx) => {
      tx.create(
        db.collection(CHALLENGES).doc(id).collection('votes').doc(`${uid}_${aboutUid}`),
        { byUid: uid, aboutUid, pass, atMs: now },
      );
      appendEvent(tx, id, { type: 'vote_cast', uid, atMs: now, data: { aboutUid } });
    });
    return { ok: true };
  },
);

// ─── stakeReportScreenshot (P-6/P-7) ─────────────────────────────────────────
// Called by the OFFENDER's own device (iOS detection fires locally). The
// announcement doubles as the owner notification (D11).

export const stakeReportScreenshot = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ challengeId?: unknown }>) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    const ch = await loadChallenge(id);
    if (!ch.circleId || !(await isCircleMember(ch.circleId, uid))) {
      throw new HttpsError('permission-denied', 'Not a member of that circle.');
    }

    // Offender's display name for the public naming (D11); the member doc
    // is the same source the client feed uses.
    const memberSnap = await db
      .doc(`circles/${ch.circleId}/members/${uid}`)
      .get();
    const displayName =
      (memberSnap.data()?.displayName as string | undefined) ?? 'A member';

    const enforcementRef = db.collection(ENFORCEMENT).doc(uid);
    let strikeNumber = 0;
    let banUntilMs = 0;
    await db.runTransaction(async (tx) => {
      const doc = (await tx.get(enforcementRef)).data() as EnforcementDoc | undefined;
      const strike = applyStrike(doc, now);
      strikeNumber = strike.strikeNumber;
      banUntilMs = strike.banUntilMs;
      tx.set(
        enforcementRef,
        {
          screenshotStrikeCount: strike.strikeNumber,
          challengeBanUntilMs: strike.banUntilMs,
          updatedAtMs: now,
        },
        { merge: true },
      );
      appendEvent(tx, id, {
        type: 'screenshot_strike',
        uid,
        atMs: now,
        data: { strikeNumber: strike.strikeNumber, banUntilMs: strike.banUntilMs },
      });
      // Public circle announcement naming the offender (D11).
      const feedRef = db.collection(`circles/${ch.circleId}/activityFeed`).doc();
      tx.create(
        feedRef,
        activityFeedItemDoc({
          id: feedRef.id,
          circleId: ch.circleId,
          userId: uid,
          displayName,
          eventType: 'screenshotStrike',
          entityId: id,
          value: `${banDurationMsForStrike(strike.strikeNumber)}`,
          nowMs: now,
        }),
      );
    });

    logger.info('screenshot strike', { uid, id, strikeNumber });
    return { strikeNumber, banUntilMs };
  },
);

// ─── stakeReportPhoto (P-8) ──────────────────────────────────────────────────

export const stakeReportPhoto = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ challengeId?: unknown }>) => {
    const uid = requireAuth(request);
    const id = str(request.data?.challengeId, 'challengeId', 1, 64);
    const now = Date.now();
    const db = getFirestore();

    const ch = await loadChallenge(id);
    if (!ch.circleId || !(await isCircleMember(ch.circleId, uid))) {
      throw new HttpsError('permission-denied', 'Not a member of that circle.');
    }

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(db.collection(CHALLENGES).doc(id));
      const state = snap.data()?.photoState;
      if (state !== 'revealed') {
        throw new HttpsError('failed-precondition', 'No revealed photo to report.');
      }
      // Report → hidden pending review, immediately (Apple UGC bar).
      tx.update(snap.ref, { photoState: 'hidden_pending_review', updatedAtMs: now });
      appendEvent(tx, id, { type: 'photo_reported', uid, atMs: now });
    });
    return { ok: true };
  },
);
