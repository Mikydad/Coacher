/**
 * CC-2 — the challenge status machine. Server-enforced: every transition a
 * callable or the sweep performs goes through assertTransition, and every
 * transition is recorded as an append-only event by the caller (CC-3).
 */

import { ChallengeStatus } from './types';

const LEGAL: Record<ChallengeStatus, readonly ChallengeStatus[]> = {
  draft: ['pending_accept', 'active', 'cancelled'],
  pending_accept: ['active', 'cancelled'],
  active: ['pending_verification', 'cancelled'],
  // 'cancelled' from pending_verification covers account deletion mid-decision.
  pending_verification: [
    'completed_success',
    'completed_forfeit',
    'vetoed',
    'cancelled',
  ],
  completed_success: [],
  completed_forfeit: [],
  cancelled: [],
  vetoed: [],
};

export function canTransition(
  from: ChallengeStatus,
  to: ChallengeStatus,
): boolean {
  return LEGAL[from].includes(to);
}

export class IllegalTransitionError extends Error {
  constructor(
    readonly from: ChallengeStatus,
    readonly to: ChallengeStatus,
  ) {
    super(`illegal challenge transition: ${from} -> ${to}`);
  }
}

export function assertTransition(
  from: ChallengeStatus,
  to: ChallengeStatus,
): void {
  if (!canTransition(from, to)) throw new IllegalTransitionError(from, to);
}

export function isTerminal(status: ChallengeStatus): boolean {
  return LEGAL[status].length === 0;
}
