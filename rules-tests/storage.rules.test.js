// Storage security-rules tests (pre-launch audit C1 / M12 / H1).
//
// First Storage suite: uploads are registered-only and stake photos need
// the caller's own `stake_photo_reservations/{challengeId}` doc, so an
// anonymous or unsolicited upload never reaches the paid screening
// trigger; stake evidence needs an existing challenge the caller
// participates in; circle proofs need ACTIVE membership.
//
// Run from rules-tests/: `npm test` (boots firestore + storage emulators —
// storage.rules reads Firestore, so both must be up).
//
// NOTE: this suite runs in its OWN emulators:exec (package.json
// `test:storage`) whose --project MUST equal PROJECT below. Cross-service
// `firestore.get/exists` from Storage rules resolves against the emulator's
// default project, not the test environment's project id — with a mismatch
// every lookup silently returns null and all positive uploads are denied.

import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes } from 'firebase/storage';

const PROJECT = 'demo-storage-rules';
let env;

const OWNER = 'user_owner';
const MEMBER = 'user_member';
const PENDING = 'user_pending';
const STRANGER = 'user_stranger';
const CIRCLE = 'circle_1';
const CH = 'stk_reserved_1';
const CH_UNRESERVED = 'stk_unreserved_1';

const jpg = () => new Uint8Array([0xff, 0xd8, 0xff, 0xdb, 1, 2, 3]);
const meta = { contentType: 'image/jpeg' };

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`circles/${CIRCLE}`).set({ name: 'c', creatorId: OWNER, moderatorIds: [OWNER] });
    await db.doc(`circles/${CIRCLE}/members/${OWNER}`).set({ status: 'active' });
    await db.doc(`circles/${CIRCLE}/members/${MEMBER}`).set({ status: 'active' });
    await db.doc(`circles/${CIRCLE}/members/${PENDING}`).set({ status: 'pending' });
    await db.doc(`stake_photo_reservations/${CH}`).set({ uid: OWNER, atMs: 1, expiresAtMs: 9e15 });
    await db.doc(`stake_challenges/${CH}`).set({
      status: 'active',
      circleId: CIRCLE,
      participantUids: [OWNER],
      photoState: 'approved',
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
    storage: {
      rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await seed();
});

const registered = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'password' } }).storage();
const anonymous = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).storage();

describe('stake_photos — reserved, registered, own filename', () => {
  it('owner with a reservation uploads their own file', async () => {
    await assertSucceeds(
      uploadBytes(ref(registered(OWNER), `stake_photos/${CH}/${OWNER}.jpg`), jpg(), meta),
    );
  });

  it('no reservation → denied (M12: no unsolicited paid screening)', async () => {
    await assertFails(
      uploadBytes(
        ref(registered(OWNER), `stake_photos/${CH_UNRESERVED}/${OWNER}.jpg`),
        jpg(),
        meta,
      ),
    );
  });

  it("another user's reservation → denied (H1: verdict can't be hijacked)", async () => {
    await assertFails(
      uploadBytes(ref(registered(STRANGER), `stake_photos/${CH}/${STRANGER}.jpg`), jpg(), meta),
    );
  });

  it('anonymous sessions never upload', async () => {
    await assertFails(
      uploadBytes(ref(anonymous(OWNER), `stake_photos/${CH}/${OWNER}.jpg`), jpg(), meta),
    );
  });

  it('wrong filename or non-image → denied', async () => {
    await assertFails(
      uploadBytes(ref(registered(OWNER), `stake_photos/${CH}/other.jpg`), jpg(), meta),
    );
    await assertFails(
      uploadBytes(ref(registered(OWNER), `stake_photos/${CH}/${OWNER}.jpg`), jpg(), {
        contentType: 'application/octet-stream',
      }),
    );
  });

  it('owner reads own photo; stranger cannot; nobody deletes', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), `stake_photos/${CH}/${OWNER}.jpg`), jpg(), meta);
    });
    await assertSucceeds(getBytes(ref(registered(OWNER), `stake_photos/${CH}/${OWNER}.jpg`)));
    await assertFails(getBytes(ref(registered(STRANGER), `stake_photos/${CH}/${OWNER}.jpg`)));
    await assertFails(getBytes(ref(registered(MEMBER), `stake_photos/${CH}/${OWNER}.jpg`)));
  });
});

describe('stake_evidence — existing challenge, participant only', () => {
  it('participant uploads under their uid', async () => {
    await assertSucceeds(
      uploadBytes(ref(registered(OWNER), `stake_evidence/${CH}/${OWNER}/e1.jpg`), jpg(), meta),
    );
  });

  it('non-participant, wrong uid folder, or missing challenge → denied', async () => {
    await assertFails(
      uploadBytes(ref(registered(MEMBER), `stake_evidence/${CH}/${MEMBER}/e1.jpg`), jpg(), meta),
    );
    await assertFails(
      uploadBytes(ref(registered(OWNER), `stake_evidence/${CH}/${MEMBER}/e1.jpg`), jpg(), meta),
    );
    await assertFails(
      uploadBytes(
        ref(registered(OWNER), `stake_evidence/${CH_UNRESERVED}/${OWNER}/e1.jpg`),
        jpg(),
        meta,
      ),
    );
    await assertFails(
      uploadBytes(ref(anonymous(OWNER), `stake_evidence/${CH}/${OWNER}/e1.jpg`), jpg(), meta),
    );
  });
});

describe('circle proofs — ACTIVE membership (C1)', () => {
  it('active member uploads a uid-prefixed proof; pending / stranger cannot', async () => {
    await assertSucceeds(
      uploadBytes(ref(registered(MEMBER), `circles/${CIRCLE}/proofs/${MEMBER}_p.jpg`), jpg(), meta),
    );
    await assertFails(
      uploadBytes(
        ref(registered(PENDING), `circles/${CIRCLE}/proofs/${PENDING}_p.jpg`),
        jpg(),
        meta,
      ),
    );
    await assertFails(
      uploadBytes(
        ref(registered(STRANGER), `circles/${CIRCLE}/proofs/${STRANGER}_p.jpg`),
        jpg(),
        meta,
      ),
    );
  });

  it('pending member cannot read proofs', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadBytes(ref(ctx.storage(), `circles/${CIRCLE}/proofs/${MEMBER}_p.jpg`), jpg(), meta);
    });
    await assertSucceeds(getBytes(ref(registered(OWNER), `circles/${CIRCLE}/proofs/${MEMBER}_p.jpg`)));
    await assertFails(getBytes(ref(registered(PENDING), `circles/${CIRCLE}/proofs/${MEMBER}_p.jpg`)));
  });
});
