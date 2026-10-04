// Security-rules tests for the circles surface (pre-launch audit C1, M1,
// M2, L2 — decision log 2026-09-15 D8).
//
// Membership is SERVER-OWNED: member docs, memberCount, and the
// users/{uid}/circleIds index are written only by the circle callables.
// These tests pin the attack cases the audit demonstrated: a stranger
// self-writing a member doc or index entry to read a private circle,
// pending/removed members keeping access, any signed-in user corrupting
// memberCount, a member flipping a challenge's status or forging another
// member's progress, and a member forging another member's reactions.
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

// Distinct project id: the suites run in parallel against one emulator and
// clearFirestore is project-scoped.
const PROJECT = 'demo-circles-rules';
let env;

const MOD = 'user_mod'; // creator + moderator
const MEMBER = 'user_member'; // active member
const PENDING = 'user_pending'; // requested, not approved
const REMOVED = 'user_removed'; // left / removed
const STRANGER = 'user_stranger'; // signed in, unrelated
const PRIVATE = 'circle_private';
const PUBLIC = 'circle_public';
const MSG = 'msg_1';
const CH = 'challenge_1';

const p = (...parts) => parts.join('/');

async function seed() {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [id, visibility] of [
      [PRIVATE, 'private'],
      [PUBLIC, 'public'],
    ]) {
      await db.doc(p('circles', id)).set({
        id,
        name: `${visibility} circle`,
        category: 'fitness',
        joinPolicy: 'requestApproval',
        visibility,
        creatorId: MOD,
        moderatorIds: [MOD],
        memberCount: 2,
        createdAtMs: 1,
        updatedAtMs: 1,
      });
      const member = (uid, status, role = 'member') => ({
        userId: uid,
        circleId: id,
        displayName: uid,
        role,
        status,
        joinedAtMs: 1,
        updatedAtMs: 1,
      });
      await db.doc(p('circles', id, 'members', MOD)).set(member(MOD, 'active', 'moderator'));
      await db.doc(p('circles', id, 'members', MEMBER)).set(member(MEMBER, 'active'));
      await db.doc(p('circles', id, 'members', PENDING)).set(member(PENDING, 'pending'));
      await db.doc(p('circles', id, 'members', REMOVED)).set(member(REMOVED, 'removed'));
      await db.doc(p('users', MOD, 'circleIds', id)).set({ circleId: id, joinedAtMs: 1 });
      await db.doc(p('users', MEMBER, 'circleIds', id)).set({ circleId: id, joinedAtMs: 1 });
      await db.doc(p('circles', id, 'messages', MSG)).set({
        id: MSG,
        circleId: id,
        senderId: MOD,
        senderDisplayName: 'mod',
        type: 'text',
        content: 'hello',
        reactions: { '👍': [MOD] },
        reactionsByUser: { [MEMBER]: ['🔥'] },
        createdAtMs: 1,
      });
      await db.doc(p('circles', id, 'challenges', CH)).set({
        id: CH,
        circleId: id,
        creatorId: MOD,
        title: 'Run',
        status: 'pending',
        memberProgress: { [MOD]: 1, [MEMBER]: 2 },
        teamTotal: 3,
        updatedAtMs: 1,
      });
    }
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

const as = (uid) => env.authenticatedContext(uid).firestore();

describe('C1 — membership cannot be self-granted', () => {
  it('a stranger cannot create their own member doc', async () => {
    await assertFails(
      as(STRANGER)
        .doc(p('circles', PRIVATE, 'members', STRANGER))
        .set({ userId: STRANGER, status: 'active', role: 'member' }),
    );
  });

  it('a pending member cannot activate themselves', async () => {
    await assertFails(
      as(PENDING).doc(p('circles', PRIVATE, 'members', PENDING)).update({ status: 'active' }),
    );
  });

  it('a member cannot edit their own member doc at all, nor delete it', async () => {
    await assertFails(
      as(MEMBER).doc(p('circles', PRIVATE, 'members', MEMBER)).update({ role: 'moderator' }),
    );
    await assertFails(as(MEMBER).doc(p('circles', PRIVATE, 'members', MEMBER)).delete());
  });

  it('even a moderator cannot write member docs directly (callables only)', async () => {
    await assertFails(
      as(MOD).doc(p('circles', PRIVATE, 'members', PENDING)).update({ status: 'active' }),
    );
  });

  it('a user cannot write their own circleIds index', async () => {
    await assertFails(
      as(STRANGER)
        .doc(p('users', STRANGER, 'circleIds', PRIVATE))
        .set({ circleId: PRIVATE, joinedAtMs: 1 }),
    );
    await assertFails(as(MEMBER).doc(p('users', MEMBER, 'circleIds', PRIVATE)).delete());
  });

  it('a user can still READ their own circleIds index', async () => {
    await assertSucceeds(as(MEMBER).doc(p('users', MEMBER, 'circleIds', PRIVATE)).get());
    await assertSucceeds(as(MEMBER).collection(p('users', MEMBER, 'circleIds')).get());
    await assertFails(as(STRANGER).doc(p('users', MEMBER, 'circleIds', PRIVATE)).get());
  });

  it('the server-owned entitlements tree is owner-read, never client-written', async () => {
    await assertFails(
      as(MEMBER).doc(p('users', MEMBER, 'entitlements', 'pro')).set({ active: true }),
    );
    await assertSucceeds(as(MEMBER).doc(p('users', MEMBER, 'entitlements', 'pro')).get());
  });
});

describe('C1 — only ACTIVE members read private content', () => {
  for (const [who, uid, ok] of [
    ['moderator', MOD, true],
    ['active member', MEMBER, true],
    ['pending member', PENDING, false],
    ['removed member', REMOVED, false],
    ['stranger', STRANGER, false],
  ]) {
    it(`${who} ${ok ? 'can' : 'cannot'} read messages / feed / challenges`, async () => {
      const check = ok ? assertSucceeds : assertFails;
      await check(as(uid).doc(p('circles', PRIVATE, 'messages', MSG)).get());
      await check(as(uid).collection(p('circles', PRIVATE, 'messages')).get());
      await check(as(uid).doc(p('circles', PRIVATE, 'challenges', CH)).get());
      await check(as(uid).collection(p('circles', PRIVATE, 'activityFeed')).get());
    });
  }

  it('a stranger cannot read a private circle doc, but can read a public one', async () => {
    await assertFails(as(STRANGER).doc(p('circles', PRIVATE)).get());
    await assertSucceeds(as(STRANGER).doc(p('circles', PUBLIC)).get());
    await assertSucceeds(as(MEMBER).doc(p('circles', PRIVATE)).get());
  });

  it('discovery query (visibility == public) works; an unfiltered list does not', async () => {
    await assertSucceeds(
      as(STRANGER).collection('circles').where('visibility', '==', 'public').get(),
    );
    await assertFails(as(STRANGER).collection('circles').get());
  });

  it('member list: public circles are browsable, private ones are member-only', async () => {
    await assertSucceeds(as(STRANGER).collection(p('circles', PUBLIC, 'members')).get());
    await assertFails(as(STRANGER).collection(p('circles', PRIVATE, 'members')).get());
    await assertSucceeds(as(MEMBER).collection(p('circles', PRIVATE, 'members')).get());
  });

  it('anyone can read their OWN member doc (join-state check)', async () => {
    await assertSucceeds(as(PENDING).doc(p('circles', PRIVATE, 'members', PENDING)).get());
    await assertFails(as(PENDING).doc(p('circles', PRIVATE, 'members', MOD)).get());
  });

  it('a removed member cannot post', async () => {
    await assertFails(
      as(REMOVED)
        .doc(p('circles', PRIVATE, 'messages', 'm2'))
        .set({ senderId: REMOVED, type: 'text', content: 'hi', createdAtMs: 2 }),
    );
    await assertSucceeds(
      as(MEMBER)
        .doc(p('circles', PRIVATE, 'messages', 'm2'))
        .set({ senderId: MEMBER, type: 'text', content: 'hi', createdAtMs: 2 }),
    );
  });
});

describe('M2 — circle doc: memberCount / create / delete are server-owned', () => {
  it('nobody can bump memberCount, not even ±1', async () => {
    await assertFails(as(STRANGER).doc(p('circles', PUBLIC)).update({ memberCount: 3 }));
    await assertFails(as(MEMBER).doc(p('circles', PUBLIC)).update({ memberCount: 1 }));
    await assertFails(as(MOD).doc(p('circles', PUBLIC)).update({ memberCount: 3 }));
  });

  it('a moderator may edit metadata but not the creator', async () => {
    await assertSucceeds(as(MOD).doc(p('circles', PUBLIC)).update({ name: 'Renamed' }));
    await assertFails(as(MOD).doc(p('circles', PUBLIC)).update({ creatorId: MEMBER }));
    await assertFails(as(MEMBER).doc(p('circles', PUBLIC)).update({ name: 'Nope' }));
  });

  it('no client creates or deletes circle docs', async () => {
    await assertFails(
      as(STRANGER).doc(p('circles', 'new_circle')).set({ creatorId: STRANGER, name: 'x' }),
    );
    await assertFails(as(MOD).doc(p('circles', PUBLIC)).delete());
  });
});

describe('M1 — legacy challenges: own progress only, status is server-written', () => {
  it('a member may change only their own memberProgress entry (+ teamTotal)', async () => {
    await assertSucceeds(
      as(MEMBER)
        .doc(p('circles', PUBLIC, 'challenges', CH))
        .update({ memberProgress: { [MOD]: 1, [MEMBER]: 5 }, teamTotal: 6, updatedAtMs: 2 }),
    );
  });

  it("a member cannot touch another member's progress", async () => {
    await assertFails(
      as(MEMBER)
        .doc(p('circles', PUBLIC, 'challenges', CH))
        .update({ memberProgress: { [MOD]: 99, [MEMBER]: 2 }, teamTotal: 101, updatedAtMs: 2 }),
    );
  });

  it('nobody flips status from the client — member, creator, or moderator', async () => {
    for (const uid of [MEMBER, MOD]) {
      await assertFails(
        as(uid).doc(p('circles', PUBLIC, 'challenges', CH)).update({ status: 'active' }),
      );
      await assertFails(
        as(uid).doc(p('circles', PUBLIC, 'challenges', CH)).update({ status: 'completed' }),
      );
    }
  });

  it('votes stay own-uid, member-only', async () => {
    await assertSucceeds(
      as(MEMBER)
        .doc(p('circles', PUBLIC, 'challenges', CH, 'votes', MEMBER))
        .set({ userId: MEMBER, approve: true, createdAtMs: 2 }),
    );
    await assertFails(
      as(MEMBER)
        .doc(p('circles', PUBLIC, 'challenges', CH, 'votes', MOD))
        .set({ userId: MOD, approve: true, createdAtMs: 2 }),
    );
    await assertFails(
      as(PENDING)
        .doc(p('circles', PUBLIC, 'challenges', CH, 'votes', PENDING))
        .set({ userId: PENDING, approve: true, createdAtMs: 2 }),
    );
  });
});

describe('L2 — reactions: a member may change only their own entry', () => {
  const msg = () => as(MEMBER).doc(p('circles', PUBLIC, 'messages', MSG));

  it('own reactionsByUser key: add, change, clear', async () => {
    await assertSucceeds(msg().update({ [`reactionsByUser.${MEMBER}`]: ['🔥', '👍'] }));
    await assertSucceeds(msg().update({ [`reactionsByUser.${MEMBER}`]: [] }));
  });

  it("another member's key is refused, even alongside one's own", async () => {
    await assertFails(msg().update({ [`reactionsByUser.${MOD}`]: ['💀'] }));
    await assertFails(
      msg().update({
        [`reactionsByUser.${MEMBER}`]: ['🔥'],
        [`reactionsByUser.${MOD}`]: [],
      }),
    );
  });

  it('the legacy emoji→uids map is read-only for everyone', async () => {
    await assertFails(msg().update({ reactions: {} }));
    await assertFails(msg().update({ reactions: { '👍': [MOD, MEMBER] } }));
    await assertFails(as(MOD).doc(p('circles', PUBLIC, 'messages', MSG)).update({ reactions: {} }));
  });

  it('a sender edit may not smuggle a reactions change', async () => {
    await assertSucceeds(
      as(MOD).doc(p('circles', PUBLIC, 'messages', MSG)).update({ content: 'edited' }),
    );
    await assertFails(
      as(MOD)
        .doc(p('circles', PUBLIC, 'messages', MSG))
        .update({ content: 'edited', reactions: {} }),
    );
  });

  it('a message with no reactionsByUser field accepts the first own entry', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(p('circles', PUBLIC, 'messages', 'bare'))
        .set({ senderId: MOD, type: 'text', content: 'x', createdAtMs: 1 });
    });
    await assertSucceeds(
      as(MEMBER)
        .doc(p('circles', PUBLIC, 'messages', 'bare'))
        .update({ [`reactionsByUser.${MEMBER}`]: ['🔥'] }),
    );
  });
});
