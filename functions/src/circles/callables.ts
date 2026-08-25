/**
 * Circle invite callables (2026-08-26) — the first circle Cloud Functions.
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
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { randomBytes } from 'node:crypto';

const REGION = 'us-central1';
const CALL_OPTS = {
  region: REGION,
  timeoutSeconds: 30,
  memory: '256MiB' as const,
  maxInstances: 10,
};

export const CIRCLE_INVITES = 'circle_invites';

/** Mirrors AccountabilityCircle.kMaxMembers on the client. */
const MAX_MEMBERS = 8;

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

    const displayName =
      ((request.auth?.token as Record<string, any>)?.name as
        | string
        | undefined) ?? 'User';

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
        throw new HttpsError(
          'resource-exhausted',
          `This circle is full (${MAX_MEMBERS} members).`,
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
