/**
 * PT-1/PT-2 — ledger IO: the grantPoints callable, the signup bonus, and
 * the shared refs/doc-shapes every ledger writer uses.
 *
 * Layout:
 *   points_ledger/{uid}            — balance doc { balance, dayKey,
 *                                    dayCounts, updatedAtMs }
 *   points_ledger/{uid}/txns/{id}  — immutable txn { source, amount,
 *                                    refId, atMs, data? }
 * Clients read their own tree; ALL writes come from these functions
 * (rules deny client writes — tested in rules-tests/).
 */

import * as functionsV1 from 'firebase-functions/v1';
import {
  CallableRequest,
  HttpsError,
  onCall,
} from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import {
  DocumentReference,
  getFirestore,
  Transaction,
} from 'firebase-admin/firestore';

import {
  applyDailyCap,
  BalanceDoc,
  CLIENT_GRANTABLE,
  EARN_AMOUNTS,
  PointsSource,
  txnId,
  validRefId,
  trustedDelta,
} from './points';

export const LEDGER = 'points_ledger';

export function balanceRef(uid: string): DocumentReference {
  return getFirestore().collection(LEDGER).doc(uid);
}

export function txnRef(uid: string, id: string): DocumentReference {
  return balanceRef(uid).collection('txns').doc(id);
}

export interface TxnData {
  source: PointsSource;
  amount: number;
  refId: string;
  atMs: number;
  data?: Record<string, string | number | boolean>;
}

export function txnDoc(t: TxnData): Record<string, unknown> {
  return {
    source: t.source,
    amount: t.amount,
    refId: t.refId,
    atMs: t.atMs,
    // Mirror-friendly LWW field (txns are immutable; atMs is the truth).
    updatedAtMs: t.atMs,
    ...(t.data !== undefined ? { data: t.data } : {}),
  };
}

/**
 * Writes one txn + the balance update inside an ALREADY-READING
 * transaction. Caller must have read `current` from balanceRef(uid) before
 * any write in the same transaction (Firestore reads-before-writes).
 */
export function writeLedgerTxn(
  tx: Transaction,
  uid: string,
  current: BalanceDoc | undefined,
  t: TxnData,
  extraBalanceFields: Record<string, unknown> = {},
): BalanceDoc {
  // Append-only for real (audit H7 note): deterministic ids are the
  // idempotency backbone, so a duplicate write is a replay bug — create()
  // makes it fail loudly instead of silently overwriting the audit row.
  tx.create(txnRef(uid, txnId(t.source, t.refId, t.atMs)), txnDoc(t));
  const next: BalanceDoc = {
    ...current,
    balance: (current?.balance ?? 0) + t.amount,
    // Audit H7 / D1: the server-awarded share of the balance.
    trusted: Math.max(0, (current?.trusted ?? 0) + trustedDelta(t.source, t.amount)),
    updatedAtMs: t.atMs,
  };
  tx.set(balanceRef(uid), { ...next, ...extraBalanceFields }, { merge: true });
  return next;
}

// ─── grantPoints (client-initiated earn sources only) ────────────────────────
//
// SELF-REPORTED by policy (pre-launch audit H7, decision log 2026-09-15 D1):
// the referenced task / goal / check-in lives in the client-writable user
// tree, so verifying it here would only prove the client wrote a document.
// What bounds it instead: fixed amounts, deterministic ids, daily caps
// (≤110 points/day even with invented ids), and the fence on the one
// consequential sink — photo removal is payable from TRUSTED points only
// (see points.ts). Real verification arrives with server-owned completion
// events, post-launch.

interface GrantData {
  source?: unknown;
  refId?: unknown;
}

export const grantPoints = onCall(
  { region: 'us-central1', timeoutSeconds: 30, memory: '256MiB' as const, maxInstances: 10 },
  async (request: CallableRequest<GrantData>) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
    const uid = request.auth.uid;
    const source = request.data?.source as PointsSource;
    const refId = typeof request.data?.refId === 'string' ? request.data.refId : '';

    if (!CLIENT_GRANTABLE.has(source)) {
      throw new HttpsError('permission-denied', 'That source is not client-grantable.');
    }
    if (!validRefId(refId)) {
      throw new HttpsError('invalid-argument', 'Invalid refId.');
    }
    const amount = EARN_AMOUNTS[source];
    if (amount === undefined) {
      throw new HttpsError('internal', 'No amount for source.');
    }

    const now = Date.now();
    const db = getFirestore();
    const id = txnId(source, refId, now);

    const result = await db.runTransaction(async (tx) => {
      // Read-first dedupe: replays (offline retries, double taps) are the
      // COMMON case by design — deterministic ids make them no-ops.
      const existing = await tx.get(txnRef(uid, id));
      if (existing.exists) return 'duplicate' as const;

      const balSnap = await tx.get(balanceRef(uid));
      const bal = balSnap.data() as BalanceDoc | undefined;
      const cap = applyDailyCap(bal, source, now);
      if (!cap.allowed) return 'capped' as const;

      writeLedgerTxn(tx, uid, bal, { source, amount, refId, atMs: now }, {
        dayKey: cap.dayKey,
        dayCounts: cap.dayCounts,
      });
      return 'granted' as const;
    });

    if (result === 'granted') {
      logger.info('grantPoints', { uid, source, refId, amount });
    }
    return { result };
  },
);

// ─── Signup bonus (once per uid, ever) ───────────────────────────────────────

export const pointsSignupBonus = functionsV1
  .region('us-central1')
  .auth.user()
  .onCreate(async (user) => {
    const uid = user.uid;
    const now = Date.now();
    const db = getFirestore();
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(txnRef(uid, 'signup_bonus'));
      if (existing.exists) return;
      const balSnap = await tx.get(balanceRef(uid));
      writeLedgerTxn(tx, uid, balSnap.data() as BalanceDoc | undefined, {
        source: 'signup_bonus',
        amount: EARN_AMOUNTS.signup_bonus!,
        refId: uid,
        atMs: now,
      });
    });
    logger.info('signup bonus granted', { uid });
  });
