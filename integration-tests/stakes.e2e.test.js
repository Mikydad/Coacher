// End-to-end stake lifecycles against the FULL emulator suite:
// real callables (auth-checked), real security rules on client writes,
// real triggers (evidence arrival stamps, signup bonus, receipts), the
// real sweep (via the emulator-only devRunSweep hook), and the SIMULATED
// payment provider — the exact code paths production will run, minus the
// card charge itself. Zero contact with the live Firebase project.
//
// Run from integration-tests/: `npm test`

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';

import { deleteApp, initializeApp } from 'firebase/app';
import {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import {
  connectFirestoreEmulator,
  doc,
  getFirestore,
  setDoc,
} from 'firebase/firestore';
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} from 'firebase/functions';
import admin from 'firebase-admin';

const PROJECT = 'demo-stakes-e2e';
const SWEEP_URL = `http://127.0.0.1:5001/${PROJECT}/us-central1/devRunSweep`;
const HOUR = 3_600_000;

// ─── Clients ─────────────────────────────────────────────────────────────────

const app = initializeApp({
  projectId: PROJECT,
  apiKey: 'fake-api-key',
  appId: 'demo',
});
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
const clientDb = getFirestore(app);
connectFirestoreEmulator(clientDb, '127.0.0.1', 8089);
const fns = getFunctions(app, 'us-central1');
connectFunctionsEmulator(fns, '127.0.0.1', 5001);

admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function waitFor(what, fn, timeoutMs = 20_000) {
  const start = Date.now();
  for (;;) {
    const value = await fn();
    if (value !== undefined && value !== null && value !== false) return value;
    if (Date.now() - start > timeoutMs) {
      throw new Error(`timed out waiting for ${what}`);
    }
    await new Promise((r) => setTimeout(r, 400));
  }
}

async function runSweep() {
  const res = await fetch(SWEEP_URL, { method: 'POST' });
  assert.equal(res.status, 200, 'devRunSweep should answer in the emulator');
  return res.json();
}

const call = (name) => httpsCallable(fns, name);

function goal() {
  return { title: 'Read for the exam', unitKind: 'minutes', unitTarget: 60, totalUnits: 1 };
}

/** Client-side evidence write — exercises the REAL security rules path. */
async function submitEvidence(challengeId, uid, unitIndex, amount) {
  const now = Date.now();
  const id = `${uid}_${unitIndex}_e2e${now}`;
  await setDoc(doc(clientDb, `stake_challenges/${challengeId}/evidence/${id}`), {
    id,
    uid,
    unitIndex,
    amount,
    source: 'timer',
    recordedAtMs: now,
    updatedAtMs: now,
  });
  // The arrival trigger must stamp it before the engine will count it.
  await waitFor(`arrival stamp on ${id}`, async () => {
    const snap = await db.doc(`stake_challenges/${challengeId}/evidence/${id}`).get();
    return typeof snap.data()?.arrivedAtMs === 'number' ? id : false;
  });
  return id;
}

/** Backdates times (admin bypasses rules) so the sweep sees a due decision. */
async function forceDue(challengeId, evidenceIds, hoursPastDeadline) {
  const now = Date.now();
  const deadline = now - hoursPastDeadline * HOUR;
  await db.doc(`stake_challenges/${challengeId}`).update({ deadlineMs: deadline });
  for (const id of evidenceIds) {
    await db
      .doc(`stake_challenges/${challengeId}/evidence/${id}`)
      .update({ arrivedAtMs: deadline - HOUR });
  }
}

let uidA;
let uidB;

before(async () => {
  // Seed the curated world (admin writes, like the real console/admin SDK).
  await db.doc('charities/rivals_fc').set({ name: 'Rivals FC Foundation', active: true });
  await db.doc('charities/neutral_fund').set({ name: 'Neutral Fund', active: true });

  // Users — the v1 signup-bonus trigger fires off these creations.
  const a = await createUserWithEmailAndPassword(auth, 'alice@test.dev', 'password1');
  uidA = a.user.uid;
  const b = await createUserWithEmailAndPassword(auth, 'bob@test.dev', 'password1');
  uidB = b.user.uid;

  // Circle with both members (h2h requires it).
  await db.doc('circles/e2e_circle').set({
    name: 'E2E Circle',
    creatorId: uidA,
    moderatorIds: [uidA],
    memberCount: 2,
  });
  await db.doc(`circles/e2e_circle/members/${uidA}`).set({ displayName: 'Alice' });
  await db.doc(`circles/e2e_circle/members/${uidB}`).set({ displayName: 'Bob' });

  // Wait for signup bonuses (proves the auth trigger fires), then pin
  // deterministic balances for the h2h scenario.
  for (const uid of [uidA, uidB]) {
    await waitFor(`signup bonus for ${uid}`, async () => {
      const snap = await db.doc(`points_ledger/${uid}/txns/signup_bonus`).get();
      return snap.exists;
    });
    await db.doc(`points_ledger/${uid}`).set(
      { balance: 500, updatedAtMs: Date.now() },
      { merge: true },
    );
  }

  await signInWithEmailAndPassword(auth, 'alice@test.dev', 'password1');
});

after(async () => {
  // Tear BOTH SDKs down or their open handles (auth refresh timers,
  // Firestore channels) keep the event loop alive and node --test hangs
  // forever after the last test passes.
  await admin.app().delete();
  await deleteApp(app);
});

// ─── Scenario 1: solo money — kept word → full refund ────────────────────────

describe('solo money: success → escrow refunded', () => {
  let challengeId;

  it('creates with a simulated charge held in escrow', async () => {
    const result = await call('stakeCreateChallenge')({
      id: `e2e_money_win_${Date.now()}`,
      type: 'solo_money',
      circleId: '',
      goal: goal(),
      mode: 'disciplined',
      deadlineMs: Date.now() + 2 * HOUR,
      amountCents: 2000,
      antiCharityId: 'rivals_fc',
      pledge: { why: 'Because my future self is watching.' },
    });
    challengeId = result.data.id;
    assert.equal(result.data.status, 'active'); // $-1: charge ok → live

    const escrow = (await db.doc(`stake_escrows/${challengeId}_${uidA}`).get()).data();
    assert.equal(escrow.status, 'held');
    assert.equal(escrow.amountCents, 2000);
    assert.equal(escrow.provider, 'simulated');
  });

  it('evidence flows through rules + arrival trigger, sweep refunds', async () => {
    const evidenceId = await submitEvidence(challengeId, uidA, 0, 60);
    await forceDue(challengeId, [evidenceId], 13); // solo due = deadline + 12h

    await runSweep();

    const ch = (await db.doc(`stake_challenges/${challengeId}`).get()).data();
    assert.equal(ch.status, 'completed_success');

    const escrow = (await db.doc(`stake_escrows/${challengeId}_${uidA}`).get()).data();
    assert.equal(escrow.status, 'refunded'); // two-phase move completed
    assert.ok(escrow.refundRef.startsWith('simref_'));
  });
});

// ─── Scenario 2: solo money — broken word → disbursement + receipt ───────────

describe('solo money: forfeit → disbursement queue → receipt lands', () => {
  let challengeId;

  it('no evidence → forfeit, escrow queued for the charity', async () => {
    const result = await call('stakeCreateChallenge')({
      id: `e2e_money_lose_${Date.now()}`,
      type: 'solo_money',
      circleId: '',
      goal: goal(),
      mode: 'disciplined',
      deadlineMs: Date.now() + 2 * HOUR,
      amountCents: 500,
      antiCharityId: 'rivals_fc',
      pledge: { why: 'Watch me fail on purpose (test).' },
    });
    challengeId = result.data.id;
    await forceDue(challengeId, [], 13);

    await runSweep();

    const ch = (await db.doc(`stake_challenges/${challengeId}`).get()).data();
    assert.equal(ch.status, 'completed_forfeit');
    const escrow = (await db.doc(`stake_escrows/${challengeId}_${uidA}`).get()).data();
    assert.equal(escrow.status, 'disbursement_pending');
    assert.equal(escrow.toCharityId, 'rivals_fc'); // D10: no veto, money moves
  });

  it('admin marks disbursed → receipt trigger posts onto the challenge', async () => {
    await db.doc(`stake_escrows/${challengeId}_${uidA}`).update({
      status: 'disbursed',
      receiptUrl: 'https://example.org/receipt-e2e.pdf',
      receiptNote: 'Donated to Rivals FC Foundation',
      updatedAtMs: Date.now(),
    });

    const receipt = await waitFor('donation receipt on the challenge', async () => {
      const snap = await db.doc(`stake_challenges/${challengeId}`).get();
      return snap.data()?.outcome?.receipts?.[uidA];
    });
    assert.equal(receipt.amountCents, 500);
    assert.equal(receipt.receiptUrl, 'https://example.org/receipt-e2e.pdf');
  });
});

// ─── Scenario 3: the failure drill — declined charge, no challenge ───────────

describe('declined charge ($-1 edge)', () => {
  it('¢99 amounts decline and nothing is created', async () => {
    const id = `e2e_declined_${Date.now()}`;
    await assert.rejects(
      call('stakeCreateChallenge')({
        id,
        type: 'solo_money',
        circleId: '',
        goal: goal(),
        mode: 'disciplined',
        deadlineMs: Date.now() + 2 * HOUR,
        amountCents: 499, // the simulated-decline hook
        antiCharityId: 'rivals_fc',
        pledge: { why: 'This card should bounce.' },
      }),
      /declined/i,
    );
    assert.equal((await db.doc(`stake_challenges/${id}`).get()).exists, false);
    assert.equal((await db.doc(`stake_escrows/${id}_${uidA}`).get()).exists, false);
  });
});

// ─── Scenario 4: h2h points — invite, dual lock, split outcome ───────────────

describe('h2h points: full loop with a winner and a loser', () => {
  let challengeId;

  it('Alice invites, Bob accepts → both stakes locked atomically', async () => {
    await signInWithEmailAndPassword(auth, 'alice@test.dev', 'password1');
    const result = await call('stakeCreateChallenge')({
      id: `e2e_h2h_${Date.now()}`,
      type: 'h2h_points',
      circleId: 'e2e_circle',
      goal: goal(),
      mode: 'disciplined',
      deadlineMs: Date.now() + 2 * HOUR,
      opponentUid: uidB,
      stakeAmount: 100,
      charityId: 'rivals_fc',
      bothLoseCharityId: 'neutral_fund',
      pledge: { why: 'Bob talks too much.' },
    });
    challengeId = result.data.id;
    assert.equal(result.data.status, 'pending_accept');

    await signInWithEmailAndPassword(auth, 'bob@test.dev', 'password1');
    await call('stakeAcceptChallenge')({ challengeId, charityId: 'neutral_fund' });

    const ch = (await db.doc(`stake_challenges/${challengeId}`).get()).data();
    assert.equal(ch.status, 'active');
    for (const uid of [uidA, uidB]) {
      const bal = (await db.doc(`points_ledger/${uid}`).get()).data();
      assert.equal(bal.balance, 400, `stake locked for ${uid}`);
      const lock = await db.doc(`points_ledger/${uid}/txns/stake_lock_${challengeId}`).get();
      assert.equal(lock.data().amount, -100);
    }
  });

  it('only Alice delivers → she gets stake + win bonus, Bob burns his', async () => {
    await signInWithEmailAndPassword(auth, 'alice@test.dev', 'password1');
    const evidenceId = await submitEvidence(challengeId, uidA, 0, 60);
    await forceDue(challengeId, [evidenceId], 25); // multi-party due = deadline + 24h

    await runSweep();

    const ch = (await db.doc(`stake_challenges/${challengeId}`).get()).data();
    assert.equal(ch.status, 'completed_forfeit'); // someone lost

    const balA = (await db.doc(`points_ledger/${uidA}`).get()).data();
    assert.equal(balA.balance, 550, 'Alice: 400 + 100 release + 50 win bonus');
    const balB = (await db.doc(`points_ledger/${uidB}`).get()).data();
    assert.equal(balB.balance, 400, 'Bob: lock burned, nothing back');

    const forfeit = (
      await db.doc(`points_ledger/${uidB}/txns/stake_forfeit_${challengeId}`).get()
    ).data();
    assert.equal(forfeit.data.burnedAmount, 100);
    // D5 — Bob's burn is earmarked for ALICE's loved charity.
    assert.equal(forfeit.data.toCharityId, 'rivals_fc');
  });
});
