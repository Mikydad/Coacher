import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  canRemoveRevealedPhoto,
  decideChallenge,
  DecisionInputs,
  decisionDueAtMs,
  revealExpiresAtMs,
  sweepAction,
  vetoEligible,
} from './decisions';
import {
  Confirmation,
  EvidenceRecord,
  Participant,
  StakeChallenge,
  Vote,
} from './types';

// ─── Fixtures ────────────────────────────────────────────────────────────────

const DEADLINE = 1_000_000_000_000;
const HOUR = 3_600_000;
const DAY = 24 * HOUR;

function participant(partial: Partial<Participant>): Participant {
  const uid = partial.uid ?? 'u1';
  return {
    uid,
    teamId: uid,
    stakeKind: 'photo',
    accepted: true,
    ...partial,
  };
}

function challenge(partial: Partial<StakeChallenge>): StakeChallenge {
  return {
    id: 'ch1',
    type: 'solo_photo',
    status: 'pending_verification',
    creatorUid: 'u1',
    circleId: 'c1',
    participants: [
      participant({
        photo: { storagePath: 'p', revealWindowMins: 60, consentAtMs: 1 },
      }),
    ],
    frozenGoal: { title: 'Read', unitKind: 'minutes', unitTarget: 60, totalUnits: 7 },
    mode: 'disciplined', // 6 of 7 required
    deadlineMs: DEADLINE,
    createdAtMs: DEADLINE - 7 * DAY,
    updatedAtMs: DEADLINE - 7 * DAY,
    ...partial,
  };
}

/** Evidence giving `uid` a passing amount on each listed unit, synced early. */
function passingUnits(uid: string, units: number[], amount = 60): EvidenceRecord[] {
  return units.map((unitIndex) => ({
    uid,
    unitIndex,
    amount,
    source: 'timer' as const,
    recordedAtMs: DEADLINE - DAY,
    arrivedAtMs: DEADLINE - DAY,
  }));
}

function inputs(partial: Partial<DecisionInputs>): DecisionInputs {
  return {
    evidence: [],
    confirmations: [],
    votes: [],
    eligibleVoterCount: 0,
    vetoRequests: [],
    lastVetoAtMsByUid: {},
    ...partial,
  };
}

const soloDecideAt = DEADLINE + 12 * HOUR; // solo decision moment
const h2h = (over: Partial<StakeChallenge> = {}) =>
  challenge({
    type: 'h2h_points',
    participants: [
      participant({ uid: 'u1', stakeKind: 'points', stakeAmount: 100, photo: undefined }),
      participant({ uid: 'u2', stakeKind: 'points', stakeAmount: 100, photo: undefined }),
    ],
    sideCharities: { u1: 'charity_u1_loves', u2: 'charity_u2_loves' },
    bothLoseCharityId: 'charity_all_hate',
    ...over,
  });
const h2hDecideAt = DEADLINE + 24 * HOUR;

function resolutionOf(d: ReturnType<typeof decideChallenge>, uid: string) {
  const r = d.perParticipant.find((p) => p.uid === uid);
  assert.ok(r, `no result for ${uid}`);
  return r;
}

// ─── Timing ──────────────────────────────────────────────────────────────────

describe('decisionDueAtMs (CC-5/V-2)', () => {
  it('solo: deadline + 12h evidence grace', () => {
    assert.equal(decisionDueAtMs(challenge({})), DEADLINE + 12 * HOUR);
  });
  it('multi-party: deadline + 24h (confirm window contains the grace)', () => {
    assert.equal(decisionDueAtMs(h2h()), DEADLINE + 24 * HOUR);
  });
});

describe('sweepAction (CC-4)', () => {
  it('pending_accept past deadline → expire_invite', () => {
    const ch = challenge({ status: 'pending_accept' });
    assert.deepEqual(sweepAction(ch, [], DEADLINE + 1), { kind: 'expire_invite' });
    assert.deepEqual(sweepAction(ch, [], DEADLINE - 1), { kind: 'none' });
  });

  it('active past deadline → to_pending_verification', () => {
    const ch = challenge({ status: 'active' });
    assert.deepEqual(sweepAction(ch, [], DEADLINE + 1), {
      kind: 'to_pending_verification',
    });
    assert.deepEqual(sweepAction(ch, [], DEADLINE - 1), { kind: 'none' });
  });

  it('pending_verification before due → none; after due → decide at due', () => {
    const ch = challenge({});
    assert.deepEqual(sweepAction(ch, [], soloDecideAt - 1), { kind: 'none' });
    assert.deepEqual(sweepAction(ch, [], soloDecideAt + 5), {
      kind: 'decide',
      atMs: soloDecideAt,
    });
  });

  it('an open dispute vote extends the decision to dispute + 48h', () => {
    const ch = h2h();
    const dispute: Confirmation = {
      byUid: 'u1',
      aboutUid: 'u2',
      kind: 'dispute',
      atMs: DEADLINE + 2 * HOUR,
    };
    const voteCloses = dispute.atMs + 48 * HOUR;
    assert.deepEqual(sweepAction(ch, [dispute], h2hDecideAt + 1), {
      kind: 'wait_vote',
      untilMs: voteCloses,
    });
    assert.deepEqual(sweepAction(ch, [dispute], voteCloses + 1), {
      kind: 'decide',
      atMs: voteCloses,
    });
  });

  it('terminal statuses → none', () => {
    for (const status of ['completed_success', 'cancelled', 'vetoed'] as const) {
      assert.deepEqual(sweepAction(challenge({ status }), [], DEADLINE + DAY), {
        kind: 'none',
      });
    }
  });
});

// ─── Solo photo (P-*, M-6) ───────────────────────────────────────────────────

describe('decideChallenge — solo photo', () => {
  it('6 mercy days of 7 under disciplined → success, photo resolution none', () => {
    const d = decideChallenge(
      challenge({}),
      inputs({ evidence: passingUnits('u1', [0, 1, 2, 3, 4, 5], 45) }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_success');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'none' });
  });

  it('5 days of 7 → forfeit, photo reveal scheduled', () => {
    const d = decideChallenge(
      challenge({}),
      inputs({ evidence: passingUnits('u1', [0, 1, 2, 3, 4]) }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'reveal_photo' });
    assert.ok(d.events.some((e) => e.type === 'photo_reveal_scheduled'));
  });

  it('forfeit + eligible veto → vetoed, photo blocked, loss recorded', () => {
    const d = decideChallenge(
      challenge({}),
      inputs({ vetoRequests: [{ uid: 'u1', atMs: soloDecideAt - 1 }] }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'vetoed');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'veto_blocked' });
    assert.equal(resolutionOf(d, 'u1').passed, false); // still a loss
    assert.ok(d.events.some((e) => e.type === 'veto_applied'));
  });

  it('veto on cooldown (29 days ago) → reveal proceeds', () => {
    const d = decideChallenge(
      challenge({}),
      inputs({
        vetoRequests: [{ uid: 'u1', atMs: soloDecideAt - 1 }],
        lastVetoAtMsByUid: { u1: soloDecideAt - 29 * DAY },
      }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'reveal_photo' });
  });

  it('veto past cooldown (31 days ago) → vetoed', () => {
    const d = decideChallenge(
      challenge({}),
      inputs({
        vetoRequests: [{ uid: 'u1', atMs: soloDecideAt - 1 }],
        lastVetoAtMsByUid: { u1: soloDecideAt - 31 * DAY },
      }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'vetoed');
  });

  it('CC-5: evidence arriving after the decision moment does not count', () => {
    const late = passingUnits('u1', [0, 1, 2, 3, 4, 5]).map((e) => ({
      ...e,
      arrivedAtMs: soloDecideAt + 1,
    }));
    const d = decideChallenge(challenge({}), inputs({ evidence: late }), soloDecideAt);
    assert.equal(d.statusAfter, 'completed_forfeit');
  });

  it('requires pending_verification', () => {
    assert.throws(() =>
      decideChallenge(challenge({ status: 'active' }), inputs({}), soloDecideAt),
    );
  });
});

// ─── Money / veto guards (D10) ───────────────────────────────────────────────

describe('D10 — no mercy on money', () => {
  it('vetoEligible is false for every non-photo type, even fresh', () => {
    for (const type of ['solo_money', 'h2h_points', 'h2h_money', 'team_money'] as const) {
      assert.equal(vetoEligible(challenge({ type }), null, soloDecideAt), false, type);
    }
    assert.equal(vetoEligible(challenge({}), null, soloDecideAt), true);
  });

  it('solo money forfeit routes to the anti-charity', () => {
    const d = decideChallenge(
      challenge({
        type: 'solo_money',
        antiCharityId: 'rival_foundation',
        participants: [
          participant({ uid: 'u1', stakeKind: 'money', stakeAmount: 2000, photo: undefined }),
        ],
        // veto request present but MUST be ignored on money
        }),
      inputs({ vetoRequests: [{ uid: 'u1', atMs: soloDecideAt - 1 }] }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, {
      kind: 'forfeit',
      toCharityId: 'rival_foundation',
    });
  });

  it('solo money success → refund', () => {
    const d = decideChallenge(
      challenge({
        type: 'solo_money',
        antiCharityId: 'rival_foundation',
        participants: [
          participant({ uid: 'u1', stakeKind: 'money', stakeAmount: 2000, photo: undefined }),
        ],
      }),
      inputs({ evidence: passingUnits('u1', [0, 1, 2, 3, 4, 5]) }),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_success');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'refund' });
  });
});

// ─── H2H cells (D5/D6) ───────────────────────────────────────────────────────

describe('decideChallenge — 1v1 h2h, all four cells', () => {
  const bothPass = () =>
    inputs({
      evidence: [
        ...passingUnits('u1', [0, 1, 2, 3, 4, 5]),
        ...passingUnits('u2', [0, 1, 2, 3, 4, 5]),
      ],
    });

  it('win/win → both refunded, nothing moves', () => {
    const d = decideChallenge(h2h(), bothPass(), h2hDecideAt);
    assert.equal(d.statusAfter, 'completed_success');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'refund' });
    assert.deepEqual(resolutionOf(d, 'u2').resolution, { kind: 'refund' });
  });

  it("win/lose → winner refunded, loser funds the WINNER's charity (D5)", () => {
    const d = decideChallenge(
      h2h(),
      inputs({ evidence: passingUnits('u1', [0, 1, 2, 3, 4, 5]) }),
      h2hDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'refund' });
    assert.deepEqual(resolutionOf(d, 'u2').resolution, {
      kind: 'forfeit',
      toCharityId: 'charity_u1_loves',
    });
  });

  it('lose/win → mirror image', () => {
    const d = decideChallenge(
      h2h(),
      inputs({ evidence: passingUnits('u2', [0, 1, 2, 3, 4, 5]) }),
      h2hDecideAt,
    );
    assert.deepEqual(resolutionOf(d, 'u1').resolution, {
      kind: 'forfeit',
      toCharityId: 'charity_u2_loves',
    });
    assert.deepEqual(resolutionOf(d, 'u2').resolution, { kind: 'refund' });
  });

  it('lose/lose → both stakes to the mutually disliked charity (D6)', () => {
    const d = decideChallenge(h2h(), inputs({}), h2hDecideAt);
    assert.equal(d.statusAfter, 'completed_forfeit');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, {
      kind: 'forfeit',
      toCharityId: 'charity_all_hate',
    });
    assert.deepEqual(resolutionOf(d, 'u2').resolution, {
      kind: 'forfeit',
      toCharityId: 'charity_all_hate',
    });
  });
});

// ─── Teams (D4, M-3) ─────────────────────────────────────────────────────────

describe('decideChallenge — teams: unanimous, no modes', () => {
  const team = () =>
    challenge({
      type: 'team_points',
      mode: 'flexible', // MUST be ignored for teams
      participants: [
        participant({ uid: 'a1', teamId: 'A', stakeKind: 'points', stakeAmount: 100, photo: undefined }),
        participant({ uid: 'a2', teamId: 'A', stakeKind: 'points', stakeAmount: 100, photo: undefined }),
        participant({ uid: 'b1', teamId: 'B', stakeKind: 'points', stakeAmount: 100, photo: undefined }),
        participant({ uid: 'b2', teamId: 'B', stakeKind: 'points', stakeAmount: 100, photo: undefined }),
      ],
      sideCharities: { A: 'charity_A_loves', B: 'charity_B_loves' },
      bothLoseCharityId: 'charity_all_hate',
    });
  const allUnits = [0, 1, 2, 3, 4, 5, 6];

  it("one member missing one unit sinks their whole side (mode ignored, D4)", () => {
    // a2 passes 6 of 7 — enough under 'flexible', but teams are unanimous.
    const d = decideChallenge(
      team(),
      inputs({
        evidence: [
          ...passingUnits('a1', allUnits),
          ...passingUnits('a2', [0, 1, 2, 3, 4, 5]),
          ...passingUnits('b1', allUnits),
          ...passingUnits('b2', allUnits),
        ],
      }),
      h2hDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    // D4/D5 — the WHOLE losing side forfeits to side B's charity, including
    // a1 who personally passed ("if I slack, all four of us lose to their
    // cause"). a1's individual record still shows a personal pass.
    for (const uid of ['a1', 'a2']) {
      assert.deepEqual(resolutionOf(d, uid).resolution, {
        kind: 'forfeit',
        toCharityId: 'charity_B_loves',
      });
    }
    assert.equal(resolutionOf(d, 'a1').passed, true); // personal record intact
    assert.equal(resolutionOf(d, 'a1').sideWon, false);
    assert.deepEqual(resolutionOf(d, 'b1').resolution, { kind: 'refund' });
    assert.deepEqual(resolutionOf(d, 'b2').resolution, { kind: 'refund' });
  });

  it('both teams fully pass → everyone refunded', () => {
    const d = decideChallenge(
      team(),
      inputs({
        evidence: ['a1', 'a2', 'b1', 'b2'].flatMap((u) => passingUnits(u, allUnits)),
      }),
      h2hDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_success');
    for (const uid of ['a1', 'a2', 'b1', 'b2']) {
      assert.deepEqual(resolutionOf(d, uid).resolution, { kind: 'refund' });
    }
  });

  it('both teams lose → every stake to the both-lose charity, even personal passers', () => {
    const d = decideChallenge(
      team(),
      inputs({
        evidence: [
          ...passingUnits('a1', allUnits), // a1 passes but side A still loses
        ],
      }),
      h2hDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    for (const uid of ['a1', 'a2', 'b1', 'b2']) {
      assert.deepEqual(resolutionOf(d, uid).resolution, {
        kind: 'forfeit',
        toCharityId: 'charity_all_hate',
      });
    }
    assert.equal(resolutionOf(d, 'a1').passed, true); // record still honest
  });
});

// ─── Disputes & votes (V-2/V-3) ──────────────────────────────────────────────

describe('disputes and circle votes', () => {
  const disputeU1: Confirmation = {
    byUid: 'u2',
    aboutUid: 'u1',
    kind: 'dispute',
    atMs: DEADLINE + HOUR,
  };
  const votesAgainstU1 = (n: number, of: number): Vote[] =>
    Array.from({ length: of }, (_, i) => ({
      byUid: `v${i}`,
      aboutUid: 'u1',
      pass: i >= n,
      atMs: DEADLINE + 2 * HOUR,
    }));

  it('disputed evidence-pass overturned by a real majority (4 of 6 vote fail)', () => {
    const d = decideChallenge(
      h2h(),
      inputs({
        evidence: passingUnits('u1', [0, 1, 2, 3, 4, 5]),
        confirmations: [disputeU1],
        votes: votesAgainstU1(4, 6),
        eligibleVoterCount: 6,
      }),
      h2hDecideAt,
    );
    assert.equal(resolutionOf(d, 'u1').passed, false);
    assert.ok(d.events.some((e) => e.type === 'dispute_resolved_by_vote'));
  });

  it('disputed evidence-pass with no quorum → evidence stands (no forfeit, V-3)', () => {
    const d = decideChallenge(
      h2h(),
      inputs({
        evidence: passingUnits('u1', [0, 1, 2, 3, 4, 5]),
        confirmations: [disputeU1],
        votes: votesAgainstU1(2, 2), // only 2 of 6 voted
        eligibleVoterCount: 6,
      }),
      h2hDecideAt,
    );
    assert.equal(resolutionOf(d, 'u1').passed, true);
    assert.ok(d.events.some((e) => e.type === 'dispute_defaulted_no_quorum'));
  });

  it('tie vote → evidence verdict stands', () => {
    const d = decideChallenge(
      h2h(),
      inputs({
        evidence: passingUnits('u1', [0, 1, 2, 3, 4, 5]),
        confirmations: [disputeU1],
        votes: votesAgainstU1(2, 4),
        eligibleVoterCount: 6,
      }),
      h2hDecideAt,
    );
    assert.equal(resolutionOf(d, 'u1').passed, true);
  });

  it('vote can rescue an evidence-fail (majority pass)', () => {
    const d = decideChallenge(
      h2h(),
      inputs({
        confirmations: [disputeU1],
        votes: votesAgainstU1(1, 6), // 5 pass, 1 fail
        eligibleVoterCount: 6,
      }),
      h2hDecideAt,
    );
    assert.equal(resolutionOf(d, 'u1').passed, true);
    // u2 still failed on evidence → u2 forfeits to u1's charity.
    assert.deepEqual(resolutionOf(d, 'u2').resolution, {
      kind: 'forfeit',
      toCharityId: 'charity_u1_loves',
    });
  });
});

// ─── Practice (CC-7) ─────────────────────────────────────────────────────────

describe('practice challenges', () => {
  it('failing a practice challenge moves nothing', () => {
    const d = decideChallenge(
      challenge({
        type: 'practice',
        participants: [participant({ uid: 'u1', photo: undefined })],
      }),
      inputs({}),
      soloDecideAt,
    );
    assert.equal(d.statusAfter, 'completed_forfeit');
    assert.deepEqual(resolutionOf(d, 'u1').resolution, { kind: 'none' });
  });
});

// ─── Reveal window (D8/D9) ───────────────────────────────────────────────────

describe('photo reveal window', () => {
  const revealedAt = 5_000_000;

  it('expiry = revealedAt + window', () => {
    assert.equal(revealExpiresAtMs(revealedAt, 60), revealedAt + 60 * 60_000);
  });

  it('removal blocked before 30% of the window, allowed at/after (D9)', () => {
    const floor = revealedAt + 18 * 60_000; // 30% of 60 min
    assert.equal(canRemoveRevealedPhoto(revealedAt, 60, floor - 1), false);
    assert.equal(canRemoveRevealedPhoto(revealedAt, 60, floor), true);
    assert.equal(canRemoveRevealedPhoto(revealedAt, 60, floor + 1), true);
  });

  it('5-minute window floor is 90 seconds', () => {
    const floor = revealedAt + 90_000;
    assert.equal(canRemoveRevealedPhoto(revealedAt, 5, floor - 1), false);
    assert.equal(canRemoveRevealedPhoto(revealedAt, 5, floor), true);
  });
});
