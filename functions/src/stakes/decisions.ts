/**
 * CC-4/CC-5, V-1..V-3, D5/D6, M-6, D9 — the decision core.
 *
 * Pure functions. The scheduled sweep (sweep.ts) loads a challenge + its
 * evidence/confirmations/votes, calls these, then applies the returned
 * transition + events + stake resolutions transactionally. NOTHING outside
 * this module decides an outcome (Critical security rule, spec §2.2).
 */

import { measureParticipant, isBackfillSuspicious } from './measurement';
import { assertTransition } from './state_machine';
import {
  ChallengeDecision,
  Confirmation,
  CONFIRM_WINDOW_MS,
  DecisionEvent,
  EVIDENCE_GRACE_MS,
  EvidenceRecord,
  isMultiParty,
  Participant,
  ParticipantResult,
  REVEAL_FLOOR_PERCENT,
  StakeChallenge,
  StakeResolution,
  VETO_COOLDOWN_MS,
  VetoRequest,
  Vote,
  VOTE_WINDOW_MS,
} from './types';

// ─── Timing ──────────────────────────────────────────────────────────────────

/**
 * When the final decision runs. Solo: deadline + 12h evidence grace.
 * Multi-party: the 24h confirm/dispute window contains the grace, so the
 * decision waits for the longer of the two. An open dispute vote extends
 * the decision further (see voteClosesAtMs).
 */
export function decisionDueAtMs(challenge: StakeChallenge): number {
  const wait = isMultiParty(challenge.type)
    ? Math.max(EVIDENCE_GRACE_MS, CONFIRM_WINDOW_MS)
    : EVIDENCE_GRACE_MS;
  return challenge.deadlineMs + wait;
}

/** V-3 — a dispute opens a 48h vote window from the dispute moment. */
export function voteClosesAtMs(dispute: Confirmation): number {
  return dispute.atMs + VOTE_WINDOW_MS;
}

export type SweepAction =
  | { kind: 'none' }
  | { kind: 'expire_invite' } // pending_accept past deadline → cancelled
  | { kind: 'to_pending_verification' }
  | { kind: 'wait_vote'; untilMs: number }
  | { kind: 'decide'; atMs: number };

/**
 * What the 15-minute sweep (CC-4) should do with one challenge right now.
 * Deliberately dumb-simple: the sweep can be re-run at any time and reach
 * the same conclusion (crash-safe idempotence comes from the transaction
 * in sweep.ts re-checking status).
 */
export function sweepAction(
  challenge: StakeChallenge,
  confirmations: readonly Confirmation[],
  nowMs: number,
): SweepAction {
  switch (challenge.status) {
    case 'pending_accept':
      return nowMs >= challenge.deadlineMs
        ? { kind: 'expire_invite' }
        : { kind: 'none' };
    case 'active':
      return nowMs >= challenge.deadlineMs
        ? { kind: 'to_pending_verification' }
        : { kind: 'none' };
    case 'pending_verification': {
      const due = decisionDueAtMs(challenge);
      // The latest vote-close instant among open disputes gates the decision.
      let waitUntil = due;
      for (const c of confirmations) {
        if (c.kind !== 'dispute') continue;
        const closes = voteClosesAtMs(c);
        if (closes > waitUntil) waitUntil = closes;
      }
      if (nowMs < waitUntil) {
        return waitUntil === due
          ? { kind: 'none' }
          : { kind: 'wait_vote', untilMs: waitUntil };
      }
      return { kind: 'decide', atMs: waitUntil };
    }
    default:
      return { kind: 'none' };
  }
}

// ─── Dispute resolution (V-2/V-3) ────────────────────────────────────────────

interface DisputeVerdict {
  disputed: boolean;
  passed: boolean;
  event?: DecisionEvent;
}

/**
 * Undisputed → the evidence verdict stands. Disputed → the circle vote
 * decides IF a majority of eligible (non-participant) members voted;
 * tie or no quorum → user-favorable: the evidence verdict stands, except
 * a disputed evidence-PASS can only be overturned by a real majority.
 */
function resolveDispute(
  uid: string,
  evidencePassed: boolean,
  confirmations: readonly Confirmation[],
  votes: readonly Vote[],
  eligibleVoterCount: number,
  nowMs: number,
): DisputeVerdict {
  const disputed = confirmations.some(
    (c) => c.kind === 'dispute' && c.aboutUid === uid,
  );
  if (!disputed) return { disputed: false, passed: evidencePassed };

  const cast = votes.filter((v) => v.aboutUid === uid);
  const passVotes = cast.filter((v) => v.pass).length;
  const failVotes = cast.length - passVotes;
  const hasQuorum =
    eligibleVoterCount > 0 && cast.length * 2 > eligibleVoterCount;

  if (hasQuorum && passVotes !== failVotes) {
    const passed = passVotes > failVotes;
    return {
      disputed: true,
      passed,
      event: {
        type: 'dispute_resolved_by_vote',
        uid,
        atMs: nowMs,
        data: { passVotes, failVotes, eligibleVoterCount },
      },
    };
  }
  return {
    disputed: true,
    passed: evidencePassed,
    event: {
      type: 'dispute_defaulted_no_quorum',
      uid,
      atMs: nowMs,
      data: { passVotes, failVotes, eligibleVoterCount },
    },
  };
}

// ─── Stake routing (D5/D6) ───────────────────────────────────────────────────

/**
 * D4/D5 — stakes follow the SIDE outcome, not the individual's: a
 * personally-passing member of a losing team still forfeits ("if I slack,
 * all four of us lose $20 to their cause"). §1.1 holds: "winner" is the
 * winning side, its members get their own stakes back, and no user ever
 * receives another user's money. Solo/1v1: side == individual.
 */
function routeStake(
  challenge: StakeChallenge,
  participant: Participant,
  sideWon: boolean,
  vetoApplied: boolean,
  winningTeamIds: readonly string[],
  anySidePassed: boolean,
): StakeResolution {
  if (challenge.type === 'practice') return { kind: 'none' };

  if (participant.stakeKind === 'photo') {
    if (sideWon) return { kind: 'none' }; // photo deleted (P-3)
    return vetoApplied ? { kind: 'veto_blocked' } : { kind: 'reveal_photo' };
  }

  // Points and money route identically; only the rail differs (ledger vs
  // Stripe), which is sweep.ts's concern, not the decision's.
  if (sideWon) return { kind: 'refund' };

  if (!isMultiParty(challenge.type)) {
    // Solo money: forfeit to the anti-charity picked at creation.
    const to = challenge.antiCharityId;
    if (!to) throw new Error(`solo money challenge ${challenge.id} missing antiCharityId`);
    return { kind: 'forfeit', toCharityId: to };
  }

  if (!anySidePassed) {
    // D6 — everyone lost: the whole pool goes to the mutually disliked pick.
    const to = challenge.bothLoseCharityId;
    if (!to) throw new Error(`challenge ${challenge.id} missing bothLoseCharityId`);
    return { kind: 'forfeit', toCharityId: to };
  }

  // D5 — loser's stake funds the winning side's chosen charity. Exactly two
  // sides are validated at creation, so a loser has exactly one winner side.
  const winnerTeamId = winningTeamIds.find((t) => t !== participant.teamId);
  const to = winnerTeamId
    ? challenge.sideCharities?.[winnerTeamId]
    : undefined;
  if (!to) {
    throw new Error(
      `challenge ${challenge.id}: no winning-side charity for loser ${participant.uid}`,
    );
  }
  return { kind: 'forfeit', toCharityId: to };
}

// ─── Veto (M-6) ──────────────────────────────────────────────────────────────

export function vetoEligible(
  challenge: StakeChallenge,
  lastVetoAtMs: number | null,
  nowMs: number,
): boolean {
  if (challenge.type !== 'solo_photo') return false; // D10 — never on money
  if (lastVetoAtMs === null) return true;
  return nowMs - lastVetoAtMs >= VETO_COOLDOWN_MS;
}

// ─── Photo reveal window (D8/D9) ─────────────────────────────────────────────

export function revealExpiresAtMs(
  revealedAtMs: number,
  revealWindowMins: number,
): number {
  return revealedAtMs + revealWindowMins * 60_000;
}

/** D9 — point-removal allowed only after 30% of the window. Integer math. */
export function canRemoveRevealedPhoto(
  revealedAtMs: number,
  revealWindowMins: number,
  nowMs: number,
): boolean {
  const floorMs = (revealWindowMins * 60_000 * REVEAL_FLOOR_PERCENT) / 100;
  return nowMs >= revealedAtMs + floorMs;
}

// ─── The decision ────────────────────────────────────────────────────────────

export interface DecisionInputs {
  evidence: readonly EvidenceRecord[];
  confirmations: readonly Confirmation[];
  votes: readonly Vote[];
  /** Non-participant circle members entitled to vote (V-3). */
  eligibleVoterCount: number;
  /** Veto requests submitted during pending_verification (M-6). */
  vetoRequests: readonly VetoRequest[];
  /** uid → last veto timestamp (server-tracked, enforcement doc). */
  lastVetoAtMsByUid: Readonly<Record<string, number>>;
}

/**
 * Decides a challenge in pending_verification. Evidence is cut off at the
 * decision moment (`decideAtMs` — pass sweepAction's `atMs` for
 * determinism: re-running the sweep later yields the identical decision).
 */
export function decideChallenge(
  challenge: StakeChallenge,
  inputs: DecisionInputs,
  decideAtMs: number,
): ChallengeDecision {
  if (challenge.status !== 'pending_verification') {
    throw new Error(
      `decideChallenge requires pending_verification, got ${challenge.status}`,
    );
  }

  const events: DecisionEvent[] = [];

  // 1 — evidence verdict + dispute resolution per participant.
  const verdicts = challenge.participants.map((p) => {
    const measured = measureParticipant(
      challenge.frozenGoal,
      // Teams are unanimous (M-3): no mode, every unit required.
      isTeamType(challenge) ? undefined : challenge.mode,
      inputs.evidence,
      p.uid,
      decideAtMs,
    );
    const dispute = resolveDispute(
      p.uid,
      measured.passed,
      inputs.confirmations,
      inputs.votes,
      inputs.eligibleVoterCount,
      decideAtMs,
    );
    if (dispute.event) events.push(dispute.event);
    const backfillFlagged = isBackfillSuspicious(
      inputs.evidence,
      p.uid,
      decideAtMs,
    );
    if (backfillFlagged) {
      events.push({ type: 'backfill_flagged', uid: p.uid, atMs: decideAtMs });
    }
    return { participant: p, measured, dispute, backfillFlagged };
  });

  // 2 — side outcomes: a side passes when every member passed (trivially the
  // single member for solo/1v1).
  const sidePassed = new Map<string, boolean>();
  for (const v of verdicts) {
    const teamId = v.participant.teamId;
    sidePassed.set(
      teamId,
      (sidePassed.get(teamId) ?? true) && v.dispute.passed,
    );
  }
  const winningTeamIds = [...sidePassed.entries()]
    .filter(([, passed]) => passed)
    .map(([teamId]) => teamId);
  const anySidePassed = winningTeamIds.length > 0;

  // 3 — stake resolutions + events. Resolution follows the SIDE outcome
  // (see routeStake doc); `passed` stays individual for records/badges.
  const perParticipant: ParticipantResult[] = verdicts.map((v) => {
    const passed = v.dispute.passed;
    const sideWon = sidePassed.get(v.participant.teamId) ?? false;
    const vetoRequested = inputs.vetoRequests.some(
      (r) => r.uid === v.participant.uid,
    );
    const vetoApplied =
      !sideWon &&
      vetoRequested &&
      vetoEligible(
        challenge,
        inputs.lastVetoAtMsByUid[v.participant.uid] ?? null,
        decideAtMs,
      );
    const resolution = routeStake(
      challenge,
      v.participant,
      sideWon,
      vetoApplied,
      winningTeamIds,
      anySidePassed,
    );

    events.push({
      type: passed ? 'participant_passed' : 'participant_forfeited',
      uid: v.participant.uid,
      atMs: decideAtMs,
      data: {
        unitsPassed: v.measured.unitsPassed,
        unitsRequired: v.measured.unitsRequired,
        disputed: v.dispute.disputed,
      },
    });
    if (vetoApplied) {
      events.push({ type: 'veto_applied', uid: v.participant.uid, atMs: decideAtMs });
    }
    if (resolution.kind === 'reveal_photo') {
      events.push({
        type: 'photo_reveal_scheduled',
        uid: v.participant.uid,
        atMs: decideAtMs,
      });
    }

    return {
      uid: v.participant.uid,
      teamId: v.participant.teamId,
      unitsPassed: v.measured.unitsPassed,
      unitsRequired: v.measured.unitsRequired,
      evidencePassed: v.measured.passed,
      passed,
      sideWon,
      disputed: v.dispute.disputed,
      backfillFlagged: v.backfillFlagged,
      resolution,
    };
  });

  // 4 — challenge-level terminal status (see ChallengeStatus doc note).
  const allPassed = perParticipant.every((r) => r.passed);
  const anyVeto = perParticipant.some(
    (r) => r.resolution.kind === 'veto_blocked',
  );
  const statusAfter = allPassed
    ? 'completed_success'
    : anyVeto
      ? 'vetoed'
      : 'completed_forfeit';
  assertTransition(challenge.status, statusAfter);

  events.push({ type: 'decided', atMs: decideAtMs, data: { statusAfter } });

  return { statusAfter, decidedAtMs: decideAtMs, perParticipant, events };
}

function isTeamType(challenge: StakeChallenge): boolean {
  return challenge.type === 'team_points' || challenge.type === 'team_money';
}
