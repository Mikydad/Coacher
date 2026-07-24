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

const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/** Sends `build(token)` to every device; returns how many dead tokens
 * were pruned. Non-token send failures are logged and swallowed — a
 * later sweep pass retries. */
export async function sendToTokens(
  uid: string,
  tokens: DeviceToken[],
  build: (token: string) => Message,
): Promise<number> {
  const db = getFirestore();
  const messaging = getMessaging();
  let pruned = 0;
  for (const { docId, token } of tokens) {
    try {
      await messaging.send(build(token));
    } catch (e) {
      const code = (e as { code?: string }).code ?? '';
      if (DEAD_TOKEN_CODES.has(code)) {
        await db.doc(`users/${uid}/deviceTokens/${docId}`).delete();
        pruned += 1;
      } else {
        logger.warn('push send failed', { uid, code });
      }
    }
  }
  return pruned;
}
