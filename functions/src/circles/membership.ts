/**
 * Circle membership — pure decision logic (no firebase imports; unit-tested).
 *
 * Pre-launch audit C1/M1/M2 (decision log 2026-09-15, D8): admission,
 * approval, removal, the memberCount, and the `users/{uid}/circleIds` index
 * are SERVER-OWNED. Rules deny every client write to those paths; the
 * callables in callables.ts are the only writers, and they route through
 * the functions here so the policy lives in one tested place.
 */

/** Mirrors AccountabilityCircle.kMaxMembers on the client. */
export const MAX_MEMBERS = 8;

/**
 * Free-tier circle cap. Mirrors the client's `TierGate.maxJoinedCircles`
 * legacy limit; Pro lifts it (see `maxCirclesFor` in callables.ts, which
 * reads the server-owned `users/{uid}/entitlements/pro` doc the RevenueCat
 * webhook will write — decision log 2026-07-20).
 */
export const FREE_MAX_CIRCLES = 3;

export type MemberStatus = 'active' | 'pending' | 'removed';

export type JoinRejectReason =
  | 'not_found'
  | 'invite_only'
  | 'circle_full'
  | 'circle_limit';

export type JoinDecision =
  | { kind: 'already_active' }
  | { kind: 'already_pending' }
  | { kind: 'pending' }
  | { kind: 'activate' }
  | { kind: 'reject'; reason: JoinRejectReason };

export interface JoinInput {
  exists: boolean;
  visibility: string | undefined;
  joinPolicy: string | undefined;
  memberCount: number;
  existingStatus: string | undefined;
  /** Circles the caller is already an active member of. */
  joinedCount: number;
  /** -1 = unlimited. */
  maxCircles: number;
}

/**
 * Discovery join (no invite key). Private circles are invite-only — the key
 * IS the approval (2026-08-26) — so this path never admits to one.
 */
export function decideJoin(input: JoinInput): JoinDecision {
  if (!input.exists) return { kind: 'reject', reason: 'not_found' };
  if (input.existingStatus === 'active') return { kind: 'already_active' };
  if (input.existingStatus === 'pending') return { kind: 'already_pending' };
  if (input.visibility === 'private') {
    return { kind: 'reject', reason: 'invite_only' };
  }
  if (input.maxCircles >= 0 && input.joinedCount >= input.maxCircles) {
    return { kind: 'reject', reason: 'circle_limit' };
  }
  if (input.joinPolicy === 'requestApproval') return { kind: 'pending' };
  if (input.memberCount >= MAX_MEMBERS) {
    return { kind: 'reject', reason: 'circle_full' };
  }
  return { kind: 'activate' };
}

export type ApproveDecision =
  | { kind: 'activate' }
  | { kind: 'noop' }
  | { kind: 'reject'; reason: 'not_pending' | 'circle_full' };

/** Moderator approval of a pending request. */
export function decideApprove(input: {
  existingStatus: string | undefined;
  memberCount: number;
}): ApproveDecision {
  if (input.existingStatus === 'active') return { kind: 'noop' };
  if (input.existingStatus !== 'pending') {
    return { kind: 'reject', reason: 'not_pending' };
  }
  if (input.memberCount >= MAX_MEMBERS) {
    return { kind: 'reject', reason: 'circle_full' };
  }
  return { kind: 'activate' };
}

export type RemoveDecision =
  /** Active member leaves/removed: status→removed, count−1, index deleted. */
  | { kind: 'remove' }
  /** Pending request withdrawn/declined: doc deleted, count untouched. */
  | { kind: 'delete_pending' }
  | { kind: 'noop' };

export function decideRemove(existingStatus: string | undefined): RemoveDecision {
  if (existingStatus === 'active') return { kind: 'remove' };
  if (existingStatus === 'pending') return { kind: 'delete_pending' };
  return { kind: 'noop' };
}

/**
 * Legacy circle-challenge vote tally (M1). The client used to flip
 * `status` itself after counting votes; now the votes trigger does it.
 * Majority = strictly more than half of the ACTIVE members.
 */
export function tallyChallengeVotes(
  votes: boolean[],
  activeMemberCount: number,
): 'active' | 'rejected' | null {
  const eligible = Math.max(1, activeMemberCount);
  const half = eligible / 2;
  const approvals = votes.filter((v) => v).length;
  const rejections = votes.length - approvals;
  if (approvals > half) return 'active';
  if (rejections > half) return 'rejected';
  return null;
}
