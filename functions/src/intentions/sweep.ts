/**
 * The intention rescue-net cron (humanizing Phase 5b, PRD §8) — cloned
 * from stakeSweep's shape: every 15 minutes, maxInstances 1, a testable
 * `runIntentionSweepOnce(now)`, pure rules (rescue_rules.ts), no LLM.
 *
 * Reads three client-written surfaces: the synced intention docs (truth),
 * the Phase 5a coarse projections (slot coverage), and the deviceTokens
 * heartbeats (freshness). Writes ONE server-owned surface:
 * `users/{uid}/rescueState/{intentionId}` — bookkeeping the client never
 * touches, so outbox upserts can't clobber it.
 *
 * Index note (errors.md #10/#16/#18): the collection-group query uses a
 * SINGLE range field (windowEndMs) with a declared field override in
 * firestore.indexes.json — status/active filter in memory. No composite.
 *
 * Idempotency: the state doc is written after a successful send; a crash
 * in between can at worst duplicate one push, which the APNs collapse-id
 * turns into a replace, not a stack.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { Message } from 'firebase-admin/messaging';

import {
  CLOSING_HORIZON_MS,
  IntentionSnapshot,
  ProjectionSnapshot,
  RescueState,
  rescueAction,
} from './rescue_rules';
import { DeviceToken, sendToTokens } from './push_send';

const BATCH_LIMIT = 200;

/** Pagination bound (P1-03): pages per run × BATCH_LIMIT is the per-run
 * ceiling; anything beyond is picked up by the next 15-minute run. The
 * old single `.limit(200)` silently ignored user 201's closing promise
 * FOREVER once the backlog crossed the limit. */
const MAX_PAGES = 10;

interface UserDevices {
  tokens: DeviceToken[];
  lastSeenMs: number | null;
  tzOffsetMinutes: number;
}

/** One full sweep pass — extracted so tests/dev tools can run it on demand. */
export async function runIntentionSweepOnce(
  now: number,
): Promise<Record<string, number>> {
  const db = getFirestore();
  const counts = {
    scanned: 0,
    dataPushes: 0,
    rescues: 0,
    skipped: 0,
    sendFailures: 0,
    tokensPruned: 0,
  };

  const deviceCache = new Map<string, UserDevices>();

  let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (let page = 0; page < MAX_PAGES; page += 1) {
    let query = db
      .collectionGroup('intentions')
      .where('windowEndMs', '>', now)
      .where('windowEndMs', '<=', now + CLOSING_HORIZON_MS)
      .orderBy('windowEndMs')
      .limit(BATCH_LIMIT);
    if (cursor) query = query.startAfter(cursor);
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      counts.scanned += 1;
      const uid = doc.ref.parent.parent?.id;
      if (!uid) continue;

      const data = doc.data();
      const intention: IntentionSnapshot = {
        id: doc.id,
        title: (data.title as string | undefined) ?? 'a promise',
        status: (data.status as string | undefined) ?? '',
        active: data.active !== false,
        windowEndMs: (data.windowEndMs as number | undefined) ?? 0,
      };
      // Cheap in-memory pre-filter before any extra reads (the pure rules
      // re-check — this only saves Firestore round-trips). `nudged` is a
      // live status (P1-05) — an intention the user deferred still
      // deserves the rescue net.
      if (
        (intention.status !== 'open' && intention.status !== 'nudged') ||
        !intention.active
      ) {
        counts.skipped += 1;
        continue;
      }

      const devices = await devicesFor(uid, deviceCache);
      const projection = await projectionFor(uid, doc.id);
      const stateRef = db.doc(`users/${uid}/rescueState/${doc.id}`);
      const state = ((await stateRef.get()).data() ??
        null) as RescueState | null;

      const action = rescueAction({
        intention,
        projection,
        lastSeenMs: devices.lastSeenMs,
        tzOffsetMinutes: devices.tzOffsetMinutes,
        state,
        nowMs: now,
      });

      if (action.kind === 'skip') {
        counts.skipped += 1;
        continue;
      }

      const result = await sendToTokens(uid, devices.tokens, (token) =>
        rescueMessage(token, intention.id, action),
      );
      counts.tokensPruned += result.pruned;
      if (result.delivered === 0) {
        // Honest bookkeeping (P2-02): nothing reached FCM, so the state
        // stays untouched and the next run retries — stamping here would
        // record a rescue the user never received.
        counts.sendFailures += 1;
        continue;
      }

      if (action.kind === 'data') {
        counts.dataPushes += 1;
        await stateRef.set(
          { lastDataPushAtMs: now, updatedAtMs: now },
          { merge: true },
        );
      } else {
        counts.rescues += 1;
        await stateRef.set(
          {
            lastRescueAtMs: now,
            rescuedWindowEndMs: intention.windowEndMs,
            updatedAtMs: now,
          },
          { merge: true },
        );
      }
    }

    if (snap.docs.length < BATCH_LIMIT) break;
    cursor = snap.docs[snap.docs.length - 1];
  }

  logger.info('intentionSweep done', counts);
  return counts;
}

export const intentionSweep = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: 'us-central1',
    timeoutSeconds: 300,
    memory: '256MiB',
    maxInstances: 1,
  },
  async () => {
    await runIntentionSweepOnce(Date.now());
  },
);

async function devicesFor(
  uid: string,
  cache: Map<string, UserDevices>,
): Promise<UserDevices> {
  const cached = cache.get(uid);
  if (cached) return cached;
  const db = getFirestore();
  const snap = await db.collection(`users/${uid}/deviceTokens`).get();
  let lastSeenMs: number | null = null;
  let tzOffsetMinutes = 0;
  const tokens: DeviceToken[] = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const token = data.token as string | undefined;
    if (token) tokens.push({ docId: doc.id, token });
    const seen = data.lastSeenMs as number | undefined;
    if (typeof seen === 'number' && (lastSeenMs === null || seen > lastSeenMs)) {
      lastSeenMs = seen;
      // Polite hours follow the most recently seen device's clock.
      const tz = data.tzOffsetMinutes as number | undefined;
      if (typeof tz === 'number') tzOffsetMinutes = tz;
    }
  }
  const devices: UserDevices = {
    tokens,
    lastSeenMs: tokens.length === 0 ? null : lastSeenMs,
    tzOffsetMinutes,
  };
  cache.set(uid, devices);
  return devices;
}

async function projectionFor(
  uid: string,
  intentionId: string,
): Promise<ProjectionSnapshot | null> {
  const db = getFirestore();
  const snap = await db
    .doc(`users/${uid}/intentionProjections/${intentionId}`)
    .get();
  const data = snap.data();
  if (!data) return null;
  return {
    covered: data.covered === true,
    nextSlotMs:
      typeof data.nextSlotMs === 'number' ? (data.nextSlotMs as number) : null,
  };
}

function rescueMessage(
  token: string,
  intentionId: string,
  action: { kind: 'data' } | { kind: 'notification'; title: string; body: string },
): Message {
  if (action.kind === 'data') {
    return {
      token,
      data: { type: 'intention_replan' },
      apns: {
        headers: {
          'apns-push-type': 'background',
          'apns-priority': '5',
        },
        payload: { aps: { 'content-available': 1 } },
      },
    };
  }
  return {
    token,
    notification: { title: action.title, body: action.body },
    data: { type: 'intention_rescue', intentionId },
    apns: {
      // Repeated rescues replace, never stack.
      headers: { 'apns-collapse-id': `rescue_${intentionId}` },
    },
  };
}
