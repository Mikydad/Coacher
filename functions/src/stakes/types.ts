/**
 * Accountability Stakes — core types and constants.
 *
 * PRD: PRD/Accountability_feature/prd-accountability-stakes.md (§6, §7).
 * This module is PURE: no firebase imports. The outcome engine
 * (measurement.ts, decisions.ts, state_machine.ts) operates on these types
 * so it can be exhaustively unit-tested without an emulator. Firestore
 * wiring lives in callables.ts / sweep.ts and converts docs to/from these
 * shapes.
 *
 * All *_MS / *_FRACTION constants are launch defaults, Remote Config-tunable
 * later (PRD D-numbers referenced inline).
 */

export type ChallengeType =
  | 'solo_photo'
  | 'solo_money'
  | 'h2h_points'
  | 'h2h_money'
  | 'team_points'
  | 'team_money'
  | 'practice';

/**
 * CC-2 status machine. For multi-party challenges the terminal status is
 * challenge-level: `completed_success` only when EVERY participant passed;
 * `completed_forfeit` when at least one forfeited (split 1v1 outcomes land
 * here — per-participant results live in outcome.perParticipant).
 * `vetoed` is solo-photo only (M-6): a recorded loss with no reveal.
 */
export type ChallengeStatus =
  | 'draft'
  | 'pending_accept'
  | 'active'
  | 'pending_verification'
  | 'completed_success'
  | 'completed_forfeit'
  | 'cancelled'
  | 'vetoed';

/** D3 — solo/h2h strictness reuses the app's RoutineMode names. */
export type SoloMode = 'flexible' | 'disciplined' | 'extreme';

export type StakeKind = 'photo' | 'points' | 'money';

export type EvidenceSource = 'timer' | 'camera' | 'checkin';

// ─── Mercy & mode math (D1a, D3) ─────────────────────────────────────────────
// Integer percentages, never floats: 30 × 0.7 is 21.000000000000004 in IEEE
// double and Math.ceil would turn that into 22 — a user forfeiting a photo
// over a float artifact is the exact class of bug this engine must not have.

/** A unit passes at ≥75% of its target (25% within-unit mercy, all types). */
export const UNIT_MERCY_PERCENT = 75;

/** Fraction of units required to pass a solo/h2h challenge, by mode. */
export const MODE_REQUIRED_PERCENT: Record<SoloMode, number> = {
  flexible: 70,
  disciplined: 85,
  extreme: 100,
};

// ─── Timing (CC-5, V-2, V-3, M-6, D8, D9) ────────────────────────────────────

const HOUR_MS = 3_600_000;
const DAY_MS = 24 * HOUR_MS;

/** CC-5 — offline evidence may sync in for 12h past the deadline. */
export const EVIDENCE_GRACE_MS = 12 * HOUR_MS;

/** V-2 — multi-party confirm/dispute window after the deadline. */
export const CONFIRM_WINDOW_MS = 24 * HOUR_MS;

/** V-3 — circle vote stays open 48h from the dispute. */
export const VOTE_WINDOW_MS = 48 * HOUR_MS;

/** M-6 — one mercy veto per rolling 30 days. */
export const VETO_COOLDOWN_MS = 30 * DAY_MS;

/** D8 — owner-chosen reveal window bounds. */
export const REVEAL_WINDOW_MIN_MINS = 5;
export const REVEAL_WINDOW_MAX_MINS = 24 * 60;

/** D9 — hard exposure floor: no removal before 30% of the window. */
export const REVEAL_FLOOR_PERCENT = 30;

/**
 * CC-5 — ≥3 units whose evidence first arrived within the final hour before
 * decision get the challenge flagged for circle review (not auto-failed).
 */
export const BACKFILL_FLAG_MIN_UNITS = 3;
export const BACKFILL_FLAG_WINDOW_MS = 1 * HOUR_MS;

// ─── Entities ────────────────────────────────────────────────────────────────

/** Challenge rhythm (2026-07-22): units are ACTION DAYS, not every day. */
export type ChallengeCadence = 'daily' | 'weekly' | 'monthly';

/** CC-6 — goal criteria frozen at creation; later goal edits change nothing. */
export interface FrozenGoal {
  title: string;
  /** What a unit measures: 'minutes' (timer) or 'count' (reps/pages/…). */
  unitKind: 'minutes' | 'count';
  /** Per-ACTION-DAY target in unitKind units. Must be > 0. */
  unitTarget: number;
  /**
   * Number of ACTION DAYS between the start date and the deadline — the
   * unit-index space evidence logs against. Must be > 0. Measurement is
   * pure index math; the calendar→index mapping lives client-side (the
   * day boundary is the user's own clock, CC-5).
   */
  totalUnits: number;
  /** Absent on legacy docs → 'daily'. */
  cadence?: ChallengeCadence;
  /** Daily cadence: every N days (1 = every day). Absent → 1. */
  interval?: number;
  /** Weekly cadence: ISO weekdays 1 (Mon) – 7 (Sun), non-empty. */
  scheduledWeekdays?: number[];
  /** Monthly cadence: days of month 1–31, non-empty. */
  repeatDaysOfMonth?: number[];
  /**
   * Local-midnight ms of day 0 on the CREATOR's clock. May be in the
   * future (challenge arms at creation, measurement starts here). Absent
   * on legacy docs → the creation day.
   */
  startDateMs?: number;
  /** The linked live UserGoal this snapshot was frozen from (staked badge). */
  linkedGoalId?: string;
}

export interface PhotoStake {
  storagePath: string;
  /** D8 — minutes the reveal stays up, REVEAL_WINDOW_MIN/MAX bounds. */
  revealWindowMins: number;
  /** P-1 — explicit consent timestamp; challenge cannot activate without. */
  consentAtMs: number;
}

export interface Participant {
  uid: string;
  /** Side grouping: solo/1v1 → own uid; teams → shared team id. */
  teamId: string;
  stakeKind: StakeKind;
  /** Points or money minor units. Absent for photo stakes. */
  stakeAmount?: number;
  photo?: PhotoStake;
  /** pending_accept → active requires every participant accepted (CC-2). */
  accepted: boolean;
}

export interface StakeChallenge {
  id: string;
  type: ChallengeType;
  status: ChallengeStatus;
  creatorUid: string;
  circleId: string;
  participants: Participant[];
  frozenGoal: FrozenGoal;
  /** Solo + 1v1 h2h (shared mode, M-2/M-4). Teams: absent — unanimous (M-3). */
  mode?: SoloMode;
  /** D5 — teamId → curated charity that side loves (h2h/team). */
  sideCharities?: Record<string, string>;
  /** D5 — solo money: the anti-charity picked at creation. */
  antiCharityId?: string;
  /** D6 — h2h/team: mutually disliked recipient when everyone loses. */
  bothLoseCharityId?: string;
  /** Server-set at activation. */
  deadlineMs: number;
  createdAtMs: number;
  updatedAtMs: number;
}

/**
 * One evidence record for one unit. `recordedAtMs` is the client capture
 * time (offline-capable); `arrivedAtMs` is server-stamped on sync and is
 * what the grace cutoff (CC-5) is measured against.
 */
export interface EvidenceRecord {
  uid: string;
  /** 0-based unit (day) index within the challenge. */
  unitIndex: number;
  /** Amount in frozenGoal.unitKind units; multiple records per unit sum. */
  amount: number;
  source: EvidenceSource;
  recordedAtMs: number;
  arrivedAtMs: number;
}

/** V-2 — a party's statement about another participant's completion. */
export interface Confirmation {
  byUid: string;
  aboutUid: string;
  kind: 'confirm' | 'dispute';
  atMs: number;
}

/** V-3 — one circle member's vote about one disputed participant. */
export interface Vote {
  byUid: string;
  aboutUid: string;
  pass: boolean;
  atMs: number;
}

/** M-6 — veto request submitted during pending_verification. */
export interface VetoRequest {
  uid: string;
  atMs: number;
}

// ─── Outcomes ────────────────────────────────────────────────────────────────

export type StakeResolution =
  | { kind: 'none' } // practice, or photo stake that passed (photo deleted)
  | { kind: 'reveal_photo' }
  | { kind: 'veto_blocked' } // loss recorded, photo never posts
  | { kind: 'refund' } // points release / Stripe refund
  | { kind: 'forfeit'; toCharityId: string };

export interface ParticipantResult {
  uid: string;
  teamId: string;
  /** Units that met the ≥75% bar with evidence inside the grace cutoff. */
  unitsPassed: number;
  unitsRequired: number;
  /** Evidence-only verdict, before any dispute vote. */
  evidencePassed: boolean;
  /** Final verdict after disputes/votes (V-1..V-3). */
  passed: boolean;
  /**
   * D4/D5 — whether this participant's SIDE won; the stake resolution
   * follows this, not `passed` (a passing member of a losing team still
   * forfeits). Solo/1v1: identical to `passed`.
   */
  sideWon: boolean;
  disputed: boolean;
  /** CC-5 — bulk late-sync flag, surfaced to the circle, never auto-fails. */
  backfillFlagged: boolean;
  resolution: StakeResolution;
}

export interface DecisionEvent {
  type:
    | 'decided'
    | 'participant_passed'
    | 'participant_forfeited'
    | 'veto_applied'
    | 'photo_reveal_scheduled'
    | 'backfill_flagged'
    | 'dispute_resolved_by_vote'
    | 'dispute_defaulted_no_quorum';
  uid?: string;
  atMs: number;
  data?: Record<string, string | number | boolean>;
}

export interface ChallengeDecision {
  statusAfter: Extract<
    ChallengeStatus,
    'completed_success' | 'completed_forfeit' | 'vetoed'
  >;
  decidedAtMs: number;
  perParticipant: ParticipantResult[];
  events: DecisionEvent[];
}

export function isMultiParty(type: ChallengeType): boolean {
  return (
    type === 'h2h_points' ||
    type === 'h2h_money' ||
    type === 'team_points' ||
    type === 'team_money'
  );
}

export function isPhotoChallenge(type: ChallengeType): boolean {
  return type === 'solo_photo';
}
