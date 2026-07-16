/**
 * Firestore layout for stakes (PRD §7.2/§7.4) + thin converters.
 *
 * Client write access (enforced by firestore.rules, tested in Step 1.2):
 *   - stake_challenges/**            read: participants + circle members
 *   - stake_challenges/{id}          write: NONE (callables/sweep only)
 *   - …/{id}/evidence/{recordId}     create: that participant, shape-checked,
 *                                    arrivedAtMs == request.time (CC-5 stamp)
 *   - …/{id}/events|confirmations|votes|vetoRequests: client write NONE
 *   - enforcement/{uid}              read own; write NONE
 */

import { DocumentSnapshot, FieldValue } from 'firebase-admin/firestore';

import { DecisionEvent, EvidenceRecord, StakeChallenge } from './types';

export const CHALLENGES = 'stake_challenges';
export const ENFORCEMENT = 'enforcement';

/** Extra photo lifecycle fields carried on the challenge doc (P-3..P-5). */
export type PhotoState =
  | 'pending_screen'
  | 'approved'
  | 'rejected'
  | 'revealed'
  | 'hidden_pending_review'
  | 'expired'
  | 'removed'
  | 'deleted';

export function challengeFromSnap(snap: DocumentSnapshot): StakeChallenge {
  const data = snap.data();
  if (!data) throw new Error(`challenge ${snap.id} has no data`);
  // Server-written docs are trusted; this is a cast point, not a validator.
  return { ...(data as Omit<StakeChallenge, 'id'>), id: snap.id };
}

export function evidenceFromSnap(snap: DocumentSnapshot): EvidenceRecord | null {
  const d = snap.data();
  if (!d) return null;
  // Client-written (outbox) — tolerate malformed docs by skipping them;
  // rules keep honest clients honest, this keeps the sweep un-crashable.
  if (
    typeof d.uid !== 'string' ||
    typeof d.unitIndex !== 'number' ||
    typeof d.amount !== 'number' ||
    typeof d.recordedAtMs !== 'number' ||
    typeof d.arrivedAtMs !== 'number'
  ) {
    return null;
  }
  return {
    uid: d.uid,
    unitIndex: d.unitIndex,
    amount: d.amount,
    source: d.source === 'camera' || d.source === 'checkin' ? d.source : 'timer',
    recordedAtMs: d.recordedAtMs,
    arrivedAtMs: d.arrivedAtMs,
  };
}

/** CC-3 — append one immutable event doc. Never updated, never deleted. */
export function eventDoc(event: DecisionEvent | AuditEvent): Record<string, unknown> {
  return { ...event, serverAt: FieldValue.serverTimestamp() };
}

/**
 * Circle feed post in the client's ActivityFeedItem shape
 * (lib/features/community/domain/models/activity_feed_item.dart) so the
 * existing feed renders server-written stake events natively.
 */
export function activityFeedItemDoc(args: {
  id: string;
  circleId: string;
  userId: string;
  displayName: string;
  eventType: 'stakePhotoRevealed' | 'screenshotStrike';
  entityId: string;
  entityTitle?: string;
  value?: string;
  nowMs: number;
}): Record<string, unknown> {
  const d = new Date(args.nowMs);
  const dateKey = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(d.getUTCDate()).padStart(2, '0')}`;
  return {
    id: args.id,
    circleId: args.circleId,
    userId: args.userId,
    displayName: args.displayName,
    eventType: args.eventType,
    entityId: args.entityId,
    ...(args.entityTitle !== undefined ? { entityTitle: args.entityTitle } : {}),
    ...(args.value !== undefined ? { value: args.value } : {}),
    dateKey,
    createdAtMs: args.nowMs,
  };
}

/** Lifecycle events emitted by callables (decision events come from the engine). */
export interface AuditEvent {
  type:
    | 'created'
    | 'pledge_signed'
    | 'photo_screen_pending'
    | 'activated'
    | 'invited'
    | 'accepted'
    | 'declined'
    | 'invite_expired'
    | 'cancelled'
    | 'photo_removed'
    | 'stake_charged'
    | 'donation_receipt'
    | 'deadline_reached'
    | 'evidence_window_closed'
    | 'veto_requested'
    | 'confirmation_recorded'
    | 'vote_cast'
    | 'photo_revealed'
    | 'photo_expired'
    | 'photo_reported'
    | 'photo_deleted'
    | 'screenshot_strike';
  uid?: string;
  atMs: number;
  data?: Record<string, string | number | boolean>;
}
