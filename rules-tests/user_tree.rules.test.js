// Security-rules tests for the users/{uid} tree (P2-03).
//
// The humanizing Phase 5 crons keep server-owned bookkeeping under
// users/{uid}/rescueState and users/{uid}/briefState. The old recursive
// wildcard granted the owner write access to EVERYTHING under their doc,
// which let a (buggy or malicious) client clobber "already rescued /
// briefed today" and re-trigger or suppress pushes. These tests pin the
// carve-out: owner keeps full access to normal subcollections, but the
// two server-owned trees are owner-read-only.
//
// Run from rules-tests/: `npm test`

import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

// NOTE: must differ from the stakes suite's project id — node --test runs
// the *.test.js files in parallel against ONE emulator, and clearFirestore
// is project-scoped. Sharing an id lets one suite wipe the other's seed
// mid-test.
const PROJECT = 'demo-user-tree-rules';
let env;

const OWNER = 'user_owner';
const STRANGER = 'user_stranger';

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
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`users/${OWNER}`).set({ displayName: 'Owner' });
    await db.doc(`users/${OWNER}/intentions/i1`).set({
      title: 'Call cousin Sara',
      status: 'open',
      updatedAtMs: Date.now(),
    });
    await db.doc(`users/${OWNER}/deviceTokens/device_1`).set({
      token: 'tok_1',
      lastSeenMs: Date.now(),
    });
    // Server-owned bookkeeping (written by crons via Admin SDK).
    await db.doc(`users/${OWNER}/rescueState/i1`).set({
      lastRescueAtMs: Date.now(),
      rescuedWindowEndMs: Date.now() + 3_600_000,
    });
    await db.doc(`users/${OWNER}/briefState/morning`).set({
      lastBriefDayKey: '2026-07-24',
    });
  });
});

const asUser = (uid) => env.authenticatedContext(uid).firestore();
const asGuest = () => env.unauthenticatedContext().firestore();

describe('users tree — owner access preserved', () => {
  it('owner reads/writes own user doc', async () => {
    await assertSucceeds(asUser(OWNER).doc(`users/${OWNER}`).get());
    await assertSucceeds(
      asUser(OWNER).doc(`users/${OWNER}`).set({ displayName: 'Me' }, { merge: true }),
    );
  });

  it('owner reads/writes normal subcollection docs', async () => {
    await assertSucceeds(asUser(OWNER).doc(`users/${OWNER}/intentions/i1`).get());
    await assertSucceeds(
      asUser(OWNER).doc(`users/${OWNER}/intentions/i2`).set({
        title: 'Read 20 pages',
        status: 'open',
        updatedAtMs: Date.now(),
      }),
    );
  });

  it('owner can delete own deviceTokens doc (logout deregister, P1-01)', async () => {
    await assertSucceeds(
      asUser(OWNER).doc(`users/${OWNER}/deviceTokens/device_1`).delete(),
    );
  });

  it('owner reads/writes deeply nested subcollection docs', async () => {
    await assertSucceeds(
      asUser(OWNER).doc(`users/${OWNER}/goals/g1/checkins/c1`).set({ ok: true }),
    );
    await assertSucceeds(
      asUser(OWNER).doc(`users/${OWNER}/goals/g1/checkins/c1`).get(),
    );
  });

  it('stranger and guest are denied everywhere in the tree', async () => {
    await assertFails(asUser(STRANGER).doc(`users/${OWNER}`).get());
    await assertFails(asUser(STRANGER).doc(`users/${OWNER}/intentions/i1`).get());
    await assertFails(
      asUser(STRANGER).doc(`users/${OWNER}/intentions/i1`).set({ status: 'done' }),
    );
    await assertFails(asGuest().doc(`users/${OWNER}/intentions/i1`).get());
  });
});

describe('users tree — server-owned carve-out (rescueState / briefState)', () => {
  it('owner can READ rescueState', async () => {
    await assertSucceeds(asUser(OWNER).doc(`users/${OWNER}/rescueState/i1`).get());
  });

  it('owner canNOT write rescueState', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(`users/${OWNER}/rescueState/i1`)
        .set({ lastRescueAtMs: 0 }, { merge: true }),
    );
    await assertFails(asUser(OWNER).doc(`users/${OWNER}/rescueState/i1`).delete());
    await assertFails(
      asUser(OWNER).doc(`users/${OWNER}/rescueState/i2`).set({ lastRescueAtMs: 1 }),
    );
  });

  it('owner can READ briefState', async () => {
    await assertSucceeds(asUser(OWNER).doc(`users/${OWNER}/briefState/morning`).get());
  });

  it('owner canNOT write briefState', async () => {
    await assertFails(
      asUser(OWNER)
        .doc(`users/${OWNER}/briefState/morning`)
        .set({ lastBriefDayKey: '1970-01-01' }, { merge: true }),
    );
    await assertFails(
      asUser(OWNER).doc(`users/${OWNER}/briefState/morning`).delete(),
    );
  });

  it('stranger cannot read the server-owned trees either', async () => {
    await assertFails(asUser(STRANGER).doc(`users/${OWNER}/rescueState/i1`).get());
    await assertFails(asUser(STRANGER).doc(`users/${OWNER}/briefState/morning`).get());
  });
});

// ─── Pre-launch audit H16 — server-side last-write-wins on the user tree ────

describe('users tree — LWW guard on updatedAtMs (H16)', () => {
  const OWNER_UID = 'user_owner';
  const path = `users/${OWNER_UID}/routines/r1/blocks/b1/tasks/t1`;

  async function seedTask(updatedAtMs) {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(path).set({ title: 'Task', updatedAtMs });
    });
  }

  it('a newer or equal updatedAtMs is accepted', async () => {
    await seedTask(100);
    const db = env.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(db.doc(path).set({ title: 'Newer', updatedAtMs: 200 }, { merge: true }));
    await assertSucceeds(db.doc(path).set({ title: 'Retry', updatedAtMs: 200 }, { merge: true }));
  });

  it('a stale offline edit (older updatedAtMs) is rejected', async () => {
    await seedTask(200);
    const db = env.authenticatedContext(OWNER_UID).firestore();
    await assertFails(db.doc(path).set({ title: 'Stale', updatedAtMs: 100 }, { merge: true }));
    await assertFails(db.doc(path).update({ title: 'Stale', updatedAtMs: 100 }));
  });

  it('a merge that omits updatedAtMs keeps the stored value and passes', async () => {
    await seedTask(200);
    const db = env.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(db.doc(path).set({ title: 'Heartbeat only' }, { merge: true }));
  });

  it('documents without the field, creates, and deletes are unaffected', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`users/${OWNER_UID}/deviceTokens/d1`).set({ token: 'x' });
    });
    const db = env.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(db.doc(`users/${OWNER_UID}/deviceTokens/d1`).update({ token: 'y' }));
    await assertSucceeds(db.doc(`users/${OWNER_UID}/routines/new`).set({ updatedAtMs: 1 }));
    await seedTask(500);
    await assertSucceeds(db.doc(path).delete());
  });

  it('tombstones (deletedEntities) are owner-writable like any user entity', async () => {
    const db = env.authenticatedContext(OWNER_UID).firestore();
    await assertSucceeds(
      db.doc(`users/${OWNER_UID}/deletedEntities/task_t1`).set({
        entityType: 'task',
        entityId: 't1',
        deletedAtMs: 1,
        updatedAtMs: 1,
      }),
    );
    await assertFails(
      env
        .authenticatedContext('user_stranger')
        .firestore()
        .doc(`users/${OWNER_UID}/deletedEntities/task_t1`)
        .get(),
    );
  });
});

// ─── Pre-launch audit M11 / D5 — tester allowlist is console-written ─────────

describe('tester_allowlist — server allowlist', () => {
  it('an account can read only its own grant; nobody writes', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc('tester_allowlist/user_owner').set({ grantedAtMs: 1 });
    });
    await assertSucceeds(env.authenticatedContext('user_owner').firestore().doc('tester_allowlist/user_owner').get());
    await assertFails(env.authenticatedContext('user_stranger').firestore().doc('tester_allowlist/user_owner').get());
    await assertFails(
      env.authenticatedContext('user_stranger').firestore().doc('tester_allowlist/user_stranger').set({ self: true }),
    );
    await assertFails(env.authenticatedContext('user_owner').firestore().doc('tester_allowlist/user_owner').delete());
  });
});

