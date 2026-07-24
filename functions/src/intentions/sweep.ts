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
import { getMessaging, Message } from 'firebase-admin/messaging';

import {
  CLOSING_HORIZON_MS,
  IntentionSnapshot,
  ProjectionSnapshot,
  RescueState,
  rescueAction,
} from './rescue_rules';

const BATCH_LIMIT = 200;

interface UserDevices {
  tokens: { docId: string; token: string }[];
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
    tokensPruned: 0,
  };

  const snap = await db
    .collectionGroup('intentions')
    .where('windowEndMs', '>', now)
    .where('windowEndMs', '<=', now + CLOSING_HORIZON_MS)
    .limit(BATCH_LIMIT)
    .get();

  const deviceCache = new Map<string, UserDevices>();

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
    // re-check — this only saves Firestore round-trips).
    if (intention.status !== 'open' || !intention.active) {
      counts.skipped += 1;
      continue;
    }

    const devices = await devicesFor(uid, deviceCache);
    const projection = await projectionFor(uid, doc.id);
    const stateRef = db.doc(`users/${uid}/rescueState/${doc.id}`);
    const state = ((await stateRef.get()).data() ?? null) as RescueState | null;

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

    const pruned = await sendToDevices(uid, devices, intention.id, action);
    counts.tokensPruned += pruned;

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
  const tokens: { docId: string; token: string }[] = [];
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

/** Sends to every device; returns how many dead tokens were pruned. */
async function sendToDevices(
  uid: string,
  devices: UserDevices,
  intentionId: string,
  action: { kind: 'data' } | { kind: 'notification'; title: string; body: string },
): Promise<number> {
  const db = getFirestore();
  const messaging = getMessaging();
  let pruned = 0;
  for (const { docId, token } of devices.tokens) {
    let message: Message;
    if (action.kind === 'data') {
      message = {
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
    } else {
      message = {
        token,
        notification: { title: action.title, body: action.body },
        data: { type: 'intention_rescue', intentionId },
        apns: {
          // Repeated rescues replace, never stack.
          headers: { 'apns-collapse-id': `rescue_${intentionId}` },
        },
      };
    }
    try {
      await messaging.send(message);
    } catch (e) {
      const code = (e as { code?: string }).code ?? '';
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/invalid-argument'
      ) {
        await db.doc(`users/${uid}/deviceTokens/${docId}`).delete();
        pruned += 1;
      } else {
        logger.warn('intentionSweep send failed', { uid, code });
      }
    }
  }
  return pruned;
}
