/**
 * Shared FCM send-with-pruning used by both Phase 5 crons
 * (intentionSweep + morningBrief): sends one message per device token
 * and deletes token docs FCM reports as dead.
 */

import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging, Message } from 'firebase-admin/messaging';

export interface DeviceToken {
  docId: string;
  token: string;
}

export interface SendResult {
  /** Messages FCM accepted. Callers must stamp "sent" bookkeeping ONLY
   * when this is > 0 (P2-02): a transient outage with a stamped state
   * would silently swallow the send until the next scheduling change. */
  delivered: number;
  /** Dead token docs removed. */
  pruned: number;
}

/** Test seams — production uses the real Admin SDK. */
export interface SendDeps {
  send?: (message: Message) => Promise<unknown>;
  removeToken?: (docId: string) => Promise<unknown>;
}

const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** Sends `build(token)` to every device; returns how many sends FCM
 * accepted and how many dead tokens were pruned. Non-token send failures
 * are logged and swallowed — with delivered = 0 the caller leaves its
 * state untouched, so a later pass retries. */
export async function sendToTokens(
  uid: string,
  tokens: DeviceToken[],
  build: (token: string) => Message,
  deps: SendDeps = {},
): Promise<SendResult> {
  const send = deps.send ?? ((message: Message) => getMessaging().send(message));
  const removeToken =
    deps.removeToken ??
    ((docId: string) =>
      getFirestore().doc(`users/${uid}/deviceTokens/${docId}`).delete());

  let delivered = 0;
  let pruned = 0;
  for (const { docId, token } of tokens) {
    try {
      await send(build(token));
      delivered += 1;
    } catch (e) {
      const code = (e as { code?: string }).code ?? '';
      if (DEAD_TOKEN_CODES.has(code)) {
        await removeToken(docId);
        pruned += 1;
      } else {
        logger.warn('push send failed', { uid, code });
      }
    }
  }
  return { delivered, pruned };
}
