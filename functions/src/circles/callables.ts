/**
 * Circle callables.
 *
 * 2026-08-26 — invite-by-key (circleInvite / circleJoinWithInvite).
 * 2026-09-15 — pre-launch audit C1/M2 (decision log D8): EVERY membership
 * mutation moved here. Rules now deny client writes to
 * `circles/{id}/members/*`, `circles/{id}.memberCount`, and the
 * `users/{uid}/circleIds` index, so a stranger can no longer self-write an
 * active member doc or index entry and read a private circle. Membership
 * means `status == 'active'` everywhere (rules, storage, stakes callables).
 * Policy is the pure module ./membership.ts; these are the IO shells.
 *
 * Invite-by-key: a moderator-controlled code is the door into a circle —
 * the ONLY door for private circles, which discovery never lists. Codes
 * live in the client-unreadable `circle_invites/{code}` collection
 * (circle docs are readable by every signed-in user, so a code stored
 * there would be public); minting, lookup, and the join write all happen
 * here so the key is actually verified server-side, never honor-system.
 *
 * Semantics (user decisions, decision log 2026-08-26):
 *  - any ACTIVE member may fetch/share the code (mint-on-demand);
 *  - only a moderator may REGENERATE it (regeneration revokes the old);
 *  - a valid code bypasses request-approval — holding the key IS the
 *    approval; revocation = regenerate.
 */

import {
  CallableRequest,
  HttpsError,
  onCall,
} from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import {
  DocumentReference,
  FieldValue,
  Firestore,
  getFirestore,
  Transaction,
} from 'firebase-admin/firestore';
import { randomBytes } from 'node:crypto';

import {
  decideApprove,
  decideJoin,
  decideRemove,
  FREE_MAX_CIRCLES,
  MAX_MEMBERS,
} from './membership';

const REGION = 'us-central1';
const CALL_OPTS = {
  region: REGION,
  timeoutSeconds: 30,
  memory: '256MiB' as const,
  maxInstances: 10,
};

export const CIRCLE_INVITES = 'circle_invites';

/** No 0/O/1/I — codes get read aloud and retyped. */
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

function requireAuth(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  return request.auth.uid;
}

function requireRegistered(request: CallableRequest): void {
  const provider = (request.auth?.token as Record<string, any>)?.firebase
    ?.sign_in_provider;
  if (provider === 'anonymous') {
    throw new HttpsError(
      'permission-denied',
      'Sign in with an account to use circles.',
    );
  }
}

function str(v: unknown, name: string, min: number, max: number): string {
  if (typeof v !== 'string' || v.length < min || v.length > max) {
    throw new HttpsError(
      'invalid-argument',
      `${name} must be a string of ${min}–${max} chars.`,
    );
  }
  return v;
}

function generateCode(): string {
  const bytes = randomBytes(8);
  let raw = '';
  for (let i = 0; i < 8; i++) {
    raw += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  }
  return `${raw.slice(0, 4)}-${raw.slice(4)}`;
}

/** Canonical form: uppercase, non-alphanumerics dropped, XXXX-XXXX. */
export function normalizeCode(input: string): string | null {
  const raw = input.toUpperCase().replace(/[^A-Z0-9]/g, '');
  if (raw.length !== 8) return null;
  return `${raw.slice(0, 4)}-${raw.slice(4)}`;
}

// ─── circleInvite — fetch (any active member) / regenerate (moderator) ───────

export const circleInvite = onCall(
  CALL_OPTS,
  async (
    request: CallableRequest<{ circleId?: unknown; regenerate?: unknown }>,
  ) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const regenerate = request.data?.regenerate === true;
    const db = getFirestore();
    const now = Date.now();

    const memberSnap = await db
      .doc(`circles/${circleId}/members/${uid}`)
      .get();
    if (!memberSnap.exists || memberSnap.data()?.status !== 'active') {
      throw new HttpsError(
        'permission-denied',
        'Only circle members can see the invite key.',
      );
    }
    if (regenerate) {
      const circle = await db.doc(`circles/${circleId}`).get();
      const moderatorIds =
        (circle.data()?.moderatorIds as string[] | undefined) ?? [];
      if (!moderatorIds.includes(uid)) {
        throw new HttpsError(
          'permission-denied',
          'Only a moderator can regenerate the invite key.',
        );
      }
    }

    const existing = await db
      .collection(CIRCLE_INVITES)
      .where('circleId', '==', circleId)
      .limit(1)
      .get();
    if (!existing.empty && !regenerate) {
      return { code: existing.docs[0].id };
    }

    // Mint; `create` throws on the (astronomically unlikely) collision.
    let code = '';
    for (let attempt = 0; attempt < 5; attempt++) {
      code = generateCode();
      try {
        await db
          .collection(CIRCLE_INVITES)
          .doc(code)
          .create({ circleId, createdBy: uid, createdAtMs: now });
        break;
      } catch (e) {
        if (attempt === 4) throw e;
        code = '';
      }
    }
    // Regeneration revokes: the old key stops working the moment the new
    // one exists.
    if (!existing.empty) {
      await existing.docs[0].ref.delete();
    }
    logger.info('circleInvite minted', { circleId, regenerate });
    return { code };
  },
);

// ─── circleJoinWithInvite — the key IS the approval ──────────────────────────

export const circleJoinWithInvite = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ code?: unknown }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const rawCode = str(request.data?.code, 'code', 1, 32);
    const code = normalizeCode(rawCode);
    if (code === null) {
      throw new HttpsError('not-found', 'Invalid or expired invite key.');
    }
    const db = getFirestore();
    const now = Date.now();

    const invite = await db.collection(CIRCLE_INVITES).doc(code).get();
    const circleId = invite.data()?.circleId as string | undefined;
    if (!invite.exists || !circleId) {
      throw new HttpsError('not-found', 'Invalid or expired invite key.');
    }

    const displayName = displayNameOf(request);
    const maxCircles = await maxCirclesFor(db, uid);

    let circleName = '';
    let alreadyMember = false;
    await db.runTransaction(async (tx) => {
      const circleRef = db.doc(`circles/${circleId}`);
      const memberRef = db.doc(`circles/${circleId}/members/${uid}`);
      const indexRef = db.doc(`users/${uid}/circleIds/${circleId}`);

      const circleSnap = await tx.get(circleRef);
      if (!circleSnap.exists) {
        throw new HttpsError('not-found', 'Invalid or expired invite key.');
      }
      const circle = circleSnap.data()!;
      circleName = (circle.name as string | undefined) ?? '';

      const memberSnap = await tx.get(memberRef);
      const status = memberSnap.data()?.status as string | undefined;
      if (memberSnap.exists && status === 'active') {
        // Repair the index only — mirrors the client's joinCircle.
        alreadyMember = true;
        tx.set(indexRef, {
          circleId,
          joinedAtMs: memberSnap.data()?.joinedAtMs ?? now,
        });
        return;
      }

      if (((circle.memberCount as number | undefined) ?? 0) >= MAX_MEMBERS) {
        throw reasoned(
          'resource-exhausted',
          'circle_full',
          `This circle is full (${MAX_MEMBERS} members).`,
        );
      }
      // The key bypasses approval, not the per-account cap.
      const joined = await tx.get(db.collection(`users/${uid}/circleIds`));
      if (maxCircles >= 0 && joined.size >= maxCircles) {
        throw reasoned(
          'resource-exhausted',
          'circle_limit',
          limitMessage(maxCircles),
        );
      }

      // pending was never counted, removed was decremented on leave —
      // either way activation increments.
      tx.set(
        memberRef,
        {
          userId: uid,
          circleId,
          displayName,
          role: (memberSnap.data()?.role as string | undefined) ?? 'member',
          status: 'active',
          joinedAtMs: now,
          updatedAtMs: now,
        },
        { merge: true },
      );
      tx.update(circleRef, {
        memberCount: FieldValue.increment(1),
        updatedAtMs: now,
      });
      tx.set(indexRef, { circleId, joinedAtMs: now });
    });

    logger.info('circleJoinWithInvite ok', { uid, circleId, alreadyMember });
    return { circleId, name: circleName, alreadyMember };
  },
);

// ─── Shared membership helpers (2026-09-15) ──────────────────────────────────

/**
 * HttpsError with a machine-readable `reason` in `details` so the client
 * maps it to the right exception (CircleFullException etc.) instead of
 * string-matching messages.
 */
function reasoned(
  code:
    | 'not-found'
    | 'permission-denied'
    | 'resource-exhausted'
    | 'failed-precondition'
    | 'invalid-argument',
  reason: string,
  message: string,
): HttpsError {
  return new HttpsError(code, message, { reason });
}

function limitMessage(max: number): string {
  return max === 1
    ? 'Free accounts can be in 1 circle at a time.'
    : `You can only be in ${max} circles at a time.`;
}

function displayNameOf(request: CallableRequest): string {
  return (
    ((request.auth?.token as Record<string, any>)?.name as string | undefined) ??
    'User'
  );
}

/**
 * Per-account circle cap. Tier hook (decision log 2026-07-20, 2026-09-15
 * D2): Pro lifts the cap. The entitlement is read from the SERVER-OWNED
 * `users/{uid}/entitlements/pro` doc (rules: owner-read, write denied —
 * carved out of the user wildcard next to rescueState), which the
 * RevenueCat webhook will write. Until that lands nobody has the doc and
 * every account is on the free cap — the client's TierGate mirrors it.
 */
async function maxCirclesFor(db: Firestore, uid: string): Promise<number> {
  const pro = await db.doc(`users/${uid}/entitlements/pro`).get();
  const active = pro.data()?.active === true;
  const expiresAtMs = pro.data()?.expiresAtMs;
  const unexpired =
    typeof expiresAtMs !== 'number' || expiresAtMs > Date.now();
  return active && unexpired ? -1 : FREE_MAX_CIRCLES;
}

function circleRefs(db: Firestore, circleId: string, uid: string) {
  return {
    circleRef: db.doc(`circles/${circleId}`),
    memberRef: db.doc(`circles/${circleId}/members/${uid}`),
    indexRef: db.doc(`users/${uid}/circleIds/${circleId}`),
  };
}

async function requireModerator(
  tx: Transaction,
  circleRef: DocumentReference,
  uid: string,
): Promise<FirebaseFirestore.DocumentData> {
  const snap = await tx.get(circleRef);
  if (!snap.exists) throw reasoned('not-found', 'not_found', 'Circle not found.');
  const data = snap.data()!;
  const moderatorIds = (data.moderatorIds as string[] | undefined) ?? [];
  if (!moderatorIds.includes(uid)) {
    throw reasoned(
      'permission-denied',
      'not_moderator',
      'Only moderators can perform this action.',
    );
  }
  return data;
}

/** Soft-removes an ACTIVE member (or deletes a pending request). */
function applyRemove(
  tx: Transaction,
  refs: ReturnType<typeof circleRefs>,
  existingStatus: string | undefined,
  targetUid: string,
  now: number,
): 'remove' | 'delete_pending' | 'noop' {
  const decision = decideRemove(existingStatus);
  if (decision.kind === 'remove') {
    tx.update(refs.memberRef, { status: 'removed', updatedAtMs: now });
    tx.update(refs.circleRef, {
      memberCount: FieldValue.increment(-1),
      moderatorIds: FieldValue.arrayRemove(targetUid),
      updatedAtMs: now,
    });
    tx.delete(refs.indexRef);
  } else if (decision.kind === 'delete_pending') {
    tx.delete(refs.memberRef);
  }
  return decision.kind;
}

// ─── circleCreate ────────────────────────────────────────────────────────────

export const circleCreate = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circle?: Record<string, unknown> }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const db = getFirestore();
    const now = Date.now();
    const raw = (request.data?.circle ?? {}) as Record<string, unknown>;

    // Client-generated StableId (house pattern); create() rejects reuse.
    const id = str(raw.id, 'circle.id', 8, 64);
    if (!/^[A-Za-z0-9_-]+$/.test(id)) {
      throw new HttpsError('invalid-argument', 'circle.id has invalid characters.');
    }
    const name = str(raw.name, 'circle.name', 1, 40).trim();
    if (name.length < 3) {
      throw new HttpsError('invalid-argument', 'circle.name must be 3–40 characters.');
    }
    const description =
      raw.description === undefined || raw.description === null
        ? undefined
        : str(raw.description, 'circle.description', 0, 500).trim();
    const category = str(raw.category, 'circle.category', 1, 40);
    const joinPolicy = str(raw.joinPolicy, 'circle.joinPolicy', 1, 32);
    if (!['open', 'requestApproval'].includes(joinPolicy)) {
      throw new HttpsError('invalid-argument', 'circle.joinPolicy is invalid.');
    }
    const visibility = str(raw.visibility, 'circle.visibility', 1, 32);
    if (!['public', 'private'].includes(visibility)) {
      throw new HttpsError('invalid-argument', 'circle.visibility is invalid.');
    }
    const timezone = str(raw.timezone ?? 'UTC', 'circle.timezone', 1, 64);

    const maxCircles = await maxCirclesFor(db, uid);
    const refs = circleRefs(db, id, uid);

    await db.runTransaction(async (tx) => {
      // Creating a circle also joins it — same cap applies.
      const joined = await tx.get(db.collection(`users/${uid}/circleIds`));
      if (maxCircles >= 0 && joined.size >= maxCircles) {
        throw reasoned('resource-exhausted', 'circle_limit', limitMessage(maxCircles));
      }
      tx.create(refs.circleRef, {
        id,
        name,
        ...(description !== undefined && description.length > 0
          ? { description }
          : {}),
        category,
        joinPolicy,
        visibility,
        creatorId: uid,
        moderatorIds: [uid],
        memberCount: 1,
        currentStreak: 0,
        longestStreak: 0,
        timezone,
        createdAtMs: now,
        updatedAtMs: now,
      });
      tx.create(refs.memberRef, {
        userId: uid,
        circleId: id,
        displayName: displayNameOf(request),
        role: 'moderator',
        status: 'active',
        joinedAtMs: now,
        updatedAtMs: now,
      });
      tx.set(refs.indexRef, { circleId: id, joinedAtMs: now });
    });
    logger.info('circleCreate ok', { uid, circleId: id, visibility, joinPolicy });
    return { circleId: id };
  },
);

// ─── circleJoin — discovery join (open → active, approval → pending) ─────────

export const circleJoin = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circleId?: unknown }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const db = getFirestore();
    const now = Date.now();
    const maxCircles = await maxCirclesFor(db, uid);
    const refs = circleRefs(db, circleId, uid);

    let status: 'active' | 'pending' = 'active';
    let alreadyMember = false;
    await db.runTransaction(async (tx) => {
      const [circleSnap, memberSnap, joined] = await Promise.all([
        tx.get(refs.circleRef),
        tx.get(refs.memberRef),
        tx.get(db.collection(`users/${uid}/circleIds`)),
      ]);
      const circle = circleSnap.data() ?? {};
      const decision = decideJoin({
        exists: circleSnap.exists,
        visibility: circle.visibility as string | undefined,
        joinPolicy: circle.joinPolicy as string | undefined,
        memberCount: (circle.memberCount as number | undefined) ?? 0,
        existingStatus: memberSnap.data()?.status as string | undefined,
        joinedCount: joined.size,
        maxCircles,
      });
      switch (decision.kind) {
        case 'reject':
          switch (decision.reason) {
            case 'not_found':
              throw reasoned('not-found', 'not_found', 'Circle not found.');
            case 'invite_only':
              throw reasoned(
                'permission-denied',
                'invite_only',
                'This circle is private — ask a member for the invite key.',
              );
            case 'circle_full':
              throw reasoned(
                'resource-exhausted',
                'circle_full',
                `This circle is full (${MAX_MEMBERS} members).`,
              );
            case 'circle_limit':
              throw reasoned(
                'resource-exhausted',
                'circle_limit',
                limitMessage(maxCircles),
              );
          }
          break;
        case 'already_active':
          alreadyMember = true;
          // Repair the index only — mirrors the invite join.
          tx.set(refs.indexRef, {
            circleId,
            joinedAtMs: memberSnap.data()?.joinedAtMs ?? now,
          });
          break;
        case 'already_pending':
          status = 'pending';
          break;
        case 'pending':
          status = 'pending';
          tx.set(
            refs.memberRef,
            {
              userId: uid,
              circleId,
              displayName: displayNameOf(request),
              role: 'member',
              status: 'pending',
              joinedAtMs: now,
              updatedAtMs: now,
            },
            { merge: true },
          );
          break;
        case 'activate':
          tx.set(
            refs.memberRef,
            {
              userId: uid,
              circleId,
              displayName: displayNameOf(request),
              role: (memberSnap.data()?.role as string | undefined) ?? 'member',
              status: 'active',
              joinedAtMs: now,
              updatedAtMs: now,
            },
            { merge: true },
          );
          tx.update(refs.circleRef, {
            memberCount: FieldValue.increment(1),
            updatedAtMs: now,
          });
          tx.set(refs.indexRef, { circleId, joinedAtMs: now });
          break;
      }
    });
    logger.info('circleJoin ok', { uid, circleId, status, alreadyMember });
    return { circleId, status, alreadyMember };
  },
);

// ─── circleApproveJoin / circleDeclineJoin — moderator only ──────────────────

export const circleApproveJoin = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circleId?: unknown; userId?: unknown }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const userId = str(request.data?.userId, 'userId', 1, 128);
    const db = getFirestore();
    const now = Date.now();
    const refs = circleRefs(db, circleId, userId);

    await db.runTransaction(async (tx) => {
      const circle = await requireModerator(tx, refs.circleRef, uid);
      const memberSnap = await tx.get(refs.memberRef);
      const decision = decideApprove({
        existingStatus: memberSnap.data()?.status as string | undefined,
        memberCount: (circle.memberCount as number | undefined) ?? 0,
      });
      if (decision.kind === 'noop') return;
      if (decision.kind === 'reject') {
        if (decision.reason === 'circle_full') {
          throw reasoned(
            'resource-exhausted',
            'circle_full',
            `This circle is full (${MAX_MEMBERS} members).`,
          );
        }
        throw reasoned('failed-precondition', 'not_pending', 'No pending request.');
      }
      tx.update(refs.memberRef, { status: 'active', updatedAtMs: now });
      tx.update(refs.circleRef, {
        memberCount: FieldValue.increment(1),
        updatedAtMs: now,
      });
      // Cross-user index write — exactly the write the client could never
      // make (owner-only rule), which is why approvals never indexed.
      tx.set(refs.indexRef, { circleId, joinedAtMs: now });
    });
    logger.info('circleApproveJoin ok', { circleId, by: uid, userId });
    return { circleId, userId };
  },
);

export const circleDeclineJoin = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circleId?: unknown; userId?: unknown }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const userId = str(request.data?.userId, 'userId', 1, 128);
    const db = getFirestore();
    const refs = circleRefs(db, circleId, userId);

    await db.runTransaction(async (tx) => {
      await requireModerator(tx, refs.circleRef, uid);
      const memberSnap = await tx.get(refs.memberRef);
      if (memberSnap.data()?.status !== 'pending') {
        throw reasoned('failed-precondition', 'not_pending', 'No pending request.');
      }
      tx.delete(refs.memberRef);
    });
    logger.info('circleDeclineJoin ok', { circleId, by: uid, userId });
    return { circleId, userId };
  },
);

// ─── circleLeave / circleRemoveMember ────────────────────────────────────────

export const circleLeave = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circleId?: unknown }>) => {
    const uid = requireAuth(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const db = getFirestore();
    const now = Date.now();
    const refs = circleRefs(db, circleId, uid);

    let outcome = 'noop';
    await db.runTransaction(async (tx) => {
      const memberSnap = await tx.get(refs.memberRef);
      outcome = applyRemove(
        tx,
        refs,
        memberSnap.data()?.status as string | undefined,
        uid,
        now,
      );
    });
    logger.info('circleLeave', { uid, circleId, outcome });
    return { circleId, outcome };
  },
);

export const circleRemoveMember = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circleId?: unknown; userId?: unknown }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const userId = str(request.data?.userId, 'userId', 1, 128);
    if (userId === uid) {
      throw new HttpsError('invalid-argument', 'Use circleLeave to leave.');
    }
    const db = getFirestore();
    const now = Date.now();
    const refs = circleRefs(db, circleId, userId);

    let outcome = 'noop';
    await db.runTransaction(async (tx) => {
      const circle = await requireModerator(tx, refs.circleRef, uid);
      if (circle.creatorId === userId) {
        throw reasoned(
          'permission-denied',
          'cannot_remove_creator',
          'The circle creator cannot be removed.',
        );
      }
      const memberSnap = await tx.get(refs.memberRef);
      outcome = applyRemove(
        tx,
        refs,
        memberSnap.data()?.status as string | undefined,
        userId,
        now,
      );
    });
    logger.info('circleRemoveMember', { circleId, by: uid, userId, outcome });
    return { circleId, userId, outcome };
  },
);

// ─── circleDelete — creator only; removes the whole tree ─────────────────────

export const circleDelete = onCall(
  { ...CALL_OPTS, timeoutSeconds: 120 },
  async (request: CallableRequest<{ circleId?: unknown }>) => {
    const uid = requireAuth(request);
    requireRegistered(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const db = getFirestore();
    const circleRef = db.doc(`circles/${circleId}`);

    const circle = await circleRef.get();
    if (!circle.exists) return { circleId, deleted: false };
    if (circle.data()?.creatorId !== uid) {
      throw reasoned(
        'permission-denied',
        'not_creator',
        'Only the creator can delete a circle.',
      );
    }

    // Every member's index first (8 max), then the invite key, then the
    // circle tree (members, messages, feed, challenges, pulses, votes).
    const members = await circleRef.collection('members').get();
    const batch = db.batch();
    for (const m of members.docs) {
      batch.delete(db.doc(`users/${m.id}/circleIds/${circleId}`));
    }
    batch.delete(db.doc(`users/${uid}/circleIds/${circleId}`));
    const invites = await db
      .collection(CIRCLE_INVITES)
      .where('circleId', '==', circleId)
      .get();
    for (const inv of invites.docs) batch.delete(inv.ref);
    await batch.commit();
    await db.recursiveDelete(circleRef);
    logger.info('circleDelete ok', { circleId, by: uid, members: members.size });
    return { circleId, deleted: true };
  },
);

// ─── circleRepairIndex — self-service consistency check ──────────────────────

/**
 * Replaces the client's ensureCircleIndex/pruneStaleCircleIndexes now that
 * the index is server-owned: index present ⇔ member doc active.
 */
export const circleRepairIndex = onCall(
  CALL_OPTS,
  async (request: CallableRequest<{ circleId?: unknown }>) => {
    const uid = requireAuth(request);
    const circleId = str(request.data?.circleId, 'circleId', 1, 64);
    const db = getFirestore();
    const refs = circleRefs(db, circleId, uid);

    let action = 'noop';
    await db.runTransaction(async (tx) => {
      const [circleSnap, memberSnap, indexSnap] = await Promise.all([
        tx.get(refs.circleRef),
        tx.get(refs.memberRef),
        tx.get(refs.indexRef),
      ]);
      const active = circleSnap.exists && memberSnap.data()?.status === 'active';
      if (active && !indexSnap.exists) {
        tx.set(refs.indexRef, {
          circleId,
          joinedAtMs: memberSnap.data()?.joinedAtMs ?? Date.now(),
        });
        action = 'indexed';
      } else if (!active && indexSnap.exists) {
        tx.delete(refs.indexRef);
        action = 'pruned';
      }
    });
    return { circleId, action, active: action !== 'pruned' };
  },
);
