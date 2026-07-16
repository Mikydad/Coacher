// Security-rules tests for the accountability stakes surface
// (firestore.rules `stake_challenges` / `enforcement` blocks).
//
// Run from rules-tests/: `npm test`
// (firebase emulators:exec boots the Firestore+Storage emulators, then runs
// this file under node:test).
//
// These are the tests the PRD calls security-critical (§7.4): a hole here
// is a leaked embarrassing photo, not a leaked todo.

import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT = 'demo-stakes-rules';
let env;

const OWNER = 'user_owner';
const MEMBER = 'user_member'; // circle member, not participant
const STRANGER = 'user_stranger'; // signed in, unrelated
const CIRCLE = 'circle_1';
const CH = 'stk_test_1';

function docPath(...parts) {
  return parts.join('/');
}

/** Seeds a solo photo challenge + circle membership with rules disabled. */
async function seed({ status = 'active', photoState = 'pending_screen' } = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(docPath('circles', CIRCLE)).set({
      name: 'Test circle',
      creatorId: OWNER,
      moderatorIds: [OWNER],
      memberCount: 2,
    });
    await db.doc(docPath('circles', CIRCLE, 'members', OWNER)).set({ role: 'member' });
    await db.doc(docPath('circles', CIRCLE, 'members', MEMBER)).set({ role: 'member' });
    await db.doc(docPath('stake_challenges', CH)).set({
      type: 'solo_photo',
      status,
      creatorUid: OWNER,
      circleId: CIRCLE,
      participants: [{ uid: OWNER, teamId: OWNER, stakeKind: 'photo', accepted: true }],
      participantUids: [OWNER],
      frozenGoal: { title: 'Read', unitKind: 'minutes', unitTarget: 60, totalUnits: 7 },
      mode: 'disciplined',
      deadlineMs: Date.now() + 86400000,
      createdAtMs: Date.now(),
      updatedAtMs: Date.now(),
      photoState,
    });
    await db
      .doc(docPath('stake_challenges', CH, 'events', 'ev1'))
      .set({ type: 'created', atMs: Date.now() });
    await db.doc(docPath('enforcement', OWNER)).set({ screenshotStrikeCount: 1 });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed();
});

const asUser = (uid) => env.authenticatedContext(uid).firestore();
const asGuest = () => env.unauthenticatedContext().firestore();

describe('stake_challenges — challenge doc', () => {
  it('participant can read', async () => {
    await assertSucceeds(asUser(OWNER).doc(docPath('stake_challenges', CH)).get());
  });

  it('circle member can read', async () => {
    await assertSucceeds(asUser(MEMBER).doc(docPath('stake_challenges', CH)).get());
  });

  it('stranger and guest cannot read', async () => {
    await assertFails(asUser(STRANGER).doc(docPath('stake_challenges', CH)).get());
    await assertFails(asGuest().doc(docPath('stake_challenges', CH)).get());
  });

  it('NOBODY can write the challenge doc — not even the participant', async () => {
    await assertFails(
      asUser(OWNER).doc(docPath('stake_challenges', CH)).update({ status: 'completed_success' }),
    );
    await assertFails(
      asUser(OWNER).doc(docPath('stake_challenges', CH)).update({ deadlineMs: 9999999999999 }),
    );
    await assertFails(asUser(OWNER).doc(docPath('stake_challenges', CH)).delete());
    await assertFails(
      asUser(STRANGER)
        .doc(docPath('stake_challenges', 'stk_new'))
        .set({ status: 'active', participantUids: [STRANGER] }),
    );
  });
});

describe('stake_challenges — events (append-only audit log)', () => {
  it('participant and circle member can read; stranger cannot', async () => {
    await assertSucceeds(asUser(OWNER).doc(docPath('stake_challenges', CH, 'events', 'ev1')).get());
    await assertSucceeds(asUser(MEMBER).doc(docPath('stake_challenges', CH, 'events', 'ev1')).get());
    await assertFails(asUser(STRANGER).doc(docPath('stake_challenges', CH, 'events', 'ev1')).get());
  });

  it('no client can write events', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'events', 'forged'))
        .set({ type: 'decided', atMs: 1 }),
    );
  });
});

describe('stake_challenges — evidence (the one client-writable path)', () => {
  const goodDoc = (uid = OWNER) => ({
    id: `${uid}_0_ev123`,
    uid,
    unitIndex: 0,
    amount: 45,
    source: 'timer',
    recordedAtMs: Date.now(),
    updatedAtMs: Date.now(),
  });

  it('participant can append well-formed evidence with uid-prefixed id', async () => {
    await assertSucceeds(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${OWNER}_0_ev123`))
        .set(goodDoc()),
    );
  });

  it('non-participant circle member cannot append evidence', async () => {
    await assertFails(
      asUser(MEMBER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${MEMBER}_0_ev1`))
        .set(goodDoc(MEMBER)),
    );
  });

  it('id must be uid-prefixed (cannot clobber another user\'s doc)', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', 'someoneelse_0_ev1'))
        .set(goodDoc()),
    );
  });

  it('client can NEVER set arrivedAtMs (server stamp only, CC-5)', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${OWNER}_0_ev124`))
        .set({ ...goodDoc(), arrivedAtMs: 1 }),
    );
  });

  it('evidence is immutable once written', async () => {
    const path = docPath('stake_challenges', CH, 'evidence', `${OWNER}_0_ev125`);
    await assertSucceeds(asUser(OWNER).doc(path).set(goodDoc()));
    await assertFails(asUser(OWNER).doc(path).update({ amount: 999 }));
    await assertFails(asUser(OWNER).doc(path).delete());
  });

  it('shape violations rejected: zero amount, bad source, spoofed uid', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${OWNER}_0_a`))
        .set({ ...goodDoc(), amount: 0 }),
    );
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${OWNER}_0_b`))
        .set({ ...goodDoc(), source: 'gallery' }),
    );
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${OWNER}_0_c`))
        .set({ ...goodDoc(), uid: STRANGER }),
    );
  });

  it('no evidence after the challenge is decided', async () => {
    await env.clearFirestore();
    await seed({ status: 'completed_forfeit' });
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_challenges', CH, 'evidence', `${OWNER}_1_late`))
        .set(goodDoc()),
    );
  });
});

describe('enforcement — strikes/bans/veto timestamps', () => {
  it('user reads own doc; others and writes always denied', async () => {
    await assertSucceeds(asUser(OWNER).doc(docPath('enforcement', OWNER)).get());
    await assertFails(asUser(MEMBER).doc(docPath('enforcement', OWNER)).get());
    await assertFails(
      asUser(OWNER).doc(docPath('enforcement', OWNER)).set({ screenshotStrikeCount: 0 }),
    );
  });
});

describe('points_ledger — the money printer stays welded shut (PT-2)', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(docPath('points_ledger', OWNER)).set({ balance: 100 });
      await ctx
        .firestore()
        .doc(docPath('points_ledger', OWNER, 'txns', 'signup_bonus'))
        .set({ source: 'signup_bonus', amount: 50, atMs: 1 });
    });
  });

  it('user reads own balance and txns', async () => {
    await assertSucceeds(asUser(OWNER).doc(docPath('points_ledger', OWNER)).get());
    await assertSucceeds(
      asUser(OWNER).doc(docPath('points_ledger', OWNER, 'txns', 'signup_bonus')).get(),
    );
  });

  it('nobody else reads it', async () => {
    await assertFails(asUser(MEMBER).doc(docPath('points_ledger', OWNER)).get());
    await assertFails(
      asUser(STRANGER).doc(docPath('points_ledger', OWNER, 'txns', 'signup_bonus')).get(),
    );
  });

  it('NO client write, not even the owner', async () => {
    await assertFails(
      asUser(OWNER).doc(docPath('points_ledger', OWNER)).set({ balance: 999999 }),
    );
    await assertFails(
      asUser(OWNER)
        .doc(docPath('points_ledger', OWNER, 'txns', 'earn_task_forged_2026-07-16'))
        .set({ source: 'earn_task', amount: 999999, atMs: 1 }),
    );
    await assertFails(
      asUser(OWNER).doc(docPath('points_ledger', OWNER, 'txns', 'signup_bonus')).delete(),
    );
  });
});

describe('charities — curated list (D7)', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(docPath('charities', 'rivals_fc')).set({
        name: 'Rivals FC Foundation',
        active: true,
      });
      await ctx.firestore().doc(docPath('charities', 'retired_org')).set({
        name: 'Retired Org',
        active: false,
      });
    });
  });

  it('signed-in users read active charities; inactive are invisible', async () => {
    await assertSucceeds(asUser(OWNER).doc(docPath('charities', 'rivals_fc')).get());
    await assertFails(asUser(OWNER).doc(docPath('charities', 'retired_org')).get());
    await assertFails(asGuest().doc(docPath('charities', 'rivals_fc')).get());
  });

  it('no client writes — curation is admin-only, permanently', async () => {
    await assertFails(
      asUser(OWNER).doc(docPath('charities', 'my_own_llc')).set({ name: 'x', active: true }),
    );
    await assertFails(
      asUser(OWNER).doc(docPath('charities', 'rivals_fc')).update({ active: false }),
    );
  });
});

describe('stake_escrows — money records ($-1/$-2)', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(docPath('stake_escrows', `${CH}_${OWNER}`)).set({
        challengeId: CH,
        uid: OWNER,
        amountCents: 2000,
        currency: 'usd',
        status: 'held',
        provider: 'simulated',
        providerRef: 'sim_x',
        createdAtMs: 1,
        updatedAtMs: 1,
      });
    });
  });

  it('owner reads own escrow; others cannot', async () => {
    await assertSucceeds(asUser(OWNER).doc(docPath('stake_escrows', `${CH}_${OWNER}`)).get());
    await assertFails(asUser(MEMBER).doc(docPath('stake_escrows', `${CH}_${OWNER}`)).get());
    await assertFails(asGuest().doc(docPath('stake_escrows', `${CH}_${OWNER}`)).get());
  });

  it('no client write — a writable escrow is a money mover', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_escrows', `${CH}_${OWNER}`))
        .update({ status: 'refund_pending' }),
    );
    await assertFails(
      asUser(OWNER)
        .doc(docPath('stake_escrows', `${CH}_${OWNER}`))
        .update({ amountCents: 1 }),
    );
    await assertFails(asUser(OWNER).doc(docPath('stake_escrows', `${CH}_${OWNER}`)).delete());
    await assertFails(
      asUser(STRANGER).doc(docPath('stake_escrows', 'forged_x')).set({ uid: STRANGER, status: 'refund_pending' }),
    );
  });
});
