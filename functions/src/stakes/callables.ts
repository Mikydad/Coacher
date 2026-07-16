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

import { vetoEligible } from './decisions';
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

/** Phase 1 — only these can be created; the rest 'failed-precondition'. */
const CREATABLE_TYPES: ReadonlySet<ChallengeType> = new Set([
  'solo_photo',
  'practice',
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

    const participant: Participant = {
      uid,
      teamId: uid,
      stakeKind: 'photo',
      accepted: true,
    };
    let circleId = '';
    let initialStatus: StakeChallenge['status'];
    let photoState: string | undefined;

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
      participant.photo = {
        storagePath,
        revealWindowMins: int(
          rawPhoto.revealWindowMins,
          'photo.revealWindowMins',
          REVEAL_WINDOW_MIN_MINS,
          REVEAL_WINDOW_MAX_MINS,
        ),
        // P-1 — consent is the tap that invoked this call; server-stamped.
        consentAtMs: now,
      };
      // P-2 — cannot activate until the NSFW screen passes (Step 1.6 trigger).
      initialStatus = 'draft';
      photoState = 'pending_screen';
    } else {
      // Practice: no stake, self-report, activates immediately (CC-7).
      participant.stakeKind = 'points';
      participant.stakeAmount = 0;
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
      participants: [participant],
      // Denormalized for the client mirror's arrayContains pull.
      participantUids: [uid],
      frozenGoal: goal,
      mode: mode as SoloMode,
      deadlineMs,
      createdAtMs: now,
      updatedAtMs: now,
      ...(photoState !== undefined ? { photoState } : {}),
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
      appendEvent(tx, id, { type: 'created', uid, atMs: now, data: { challengeType: type } });
      appendEvent(tx, id, { type: 'pledge_signed', uid, atMs: now, data: { why: pledgeWhy } });
      if (doc.status === 'active') {
        appendEvent(tx, id, { type: 'activated', uid, atMs: now });
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
