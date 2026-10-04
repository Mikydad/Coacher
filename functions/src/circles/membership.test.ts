import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  decideApprove,
  decideJoin,
  decideRemove,
  tallyChallengeVotes,
} from './membership';

const base = {
  exists: true,
  visibility: 'public',
  joinPolicy: 'open',
  memberCount: 2,
  existingStatus: undefined,
  joinedCount: 0,
  maxCircles: 3,
};

describe('decideJoin (C1 — discovery join is server-owned)', () => {
  it('activates an open public circle', () => {
    assert.deepEqual(decideJoin(base), { kind: 'activate' });
  });
  it('never admits to a private circle without the key', () => {
    assert.deepEqual(decideJoin({ ...base, visibility: 'private' }), {
      kind: 'reject',
      reason: 'invite_only',
    });
  });
  it('rejects a missing circle', () => {
    assert.equal(decideJoin({ ...base, exists: false }).kind, 'reject');
  });
  it('goes pending for request-approval circles', () => {
    assert.deepEqual(decideJoin({ ...base, joinPolicy: 'requestApproval' }), {
      kind: 'pending',
    });
  });
  it('is idempotent for existing active / pending members', () => {
    assert.equal(decideJoin({ ...base, existingStatus: 'active' }).kind, 'already_active');
    assert.equal(decideJoin({ ...base, existingStatus: 'pending' }).kind, 'already_pending');
  });
  it('lets a removed member re-join', () => {
    assert.equal(decideJoin({ ...base, existingStatus: 'removed' }).kind, 'activate');
  });
  it('enforces the 8-member cap', () => {
    assert.deepEqual(decideJoin({ ...base, memberCount: 8 }), {
      kind: 'reject',
      reason: 'circle_full',
    });
  });
  it('enforces the per-user circle limit, and -1 means unlimited', () => {
    assert.deepEqual(decideJoin({ ...base, joinedCount: 3 }), {
      kind: 'reject',
      reason: 'circle_limit',
    });
    assert.equal(decideJoin({ ...base, joinedCount: 30, maxCircles: -1 }).kind, 'activate');
  });
  it('checks the limit before parking a request as pending', () => {
    assert.equal(
      decideJoin({ ...base, joinPolicy: 'requestApproval', joinedCount: 3 }).kind,
      'reject',
    );
  });
});

describe('decideApprove', () => {
  it('activates a pending member with room', () => {
    assert.deepEqual(decideApprove({ existingStatus: 'pending', memberCount: 7 }), {
      kind: 'activate',
    });
  });
  it('refuses when full', () => {
    assert.deepEqual(decideApprove({ existingStatus: 'pending', memberCount: 8 }), {
      kind: 'reject',
      reason: 'circle_full',
    });
  });
  it('is a no-op for already active, rejects anything else', () => {
    assert.equal(decideApprove({ existingStatus: 'active', memberCount: 1 }).kind, 'noop');
    assert.equal(decideApprove({ existingStatus: undefined, memberCount: 1 }).kind, 'reject');
    assert.equal(decideApprove({ existingStatus: 'removed', memberCount: 1 }).kind, 'reject');
  });
});

describe('decideRemove', () => {
  it('soft-removes active, deletes pending, ignores the rest', () => {
    assert.equal(decideRemove('active').kind, 'remove');
    assert.equal(decideRemove('pending').kind, 'delete_pending');
    assert.equal(decideRemove('removed').kind, 'noop');
    assert.equal(decideRemove(undefined).kind, 'noop');
  });
});

describe('tallyChallengeVotes (M1 — server-side majority)', () => {
  it('needs strictly more than half of active members', () => {
    assert.equal(tallyChallengeVotes([true, true], 4), null);
    assert.equal(tallyChallengeVotes([true, true, true], 4), 'active');
    assert.equal(tallyChallengeVotes([false, false, false], 4), 'rejected');
    assert.equal(tallyChallengeVotes([true, false], 2), null);
  });
  it('a single-member circle resolves on one vote', () => {
    assert.equal(tallyChallengeVotes([true], 1), 'active');
    assert.equal(tallyChallengeVotes([false], 0), 'rejected');
  });
});
