/**
 * Emulator-only test hooks. The scheduled sweep never fires on cron inside
 * the Functions emulator, so integration tests poke this endpoint instead.
 *
 * Hard-gated on FUNCTIONS_EMULATOR: deployed to production it exists but
 * answers 403 to everything — it can never move real state.
 */

import { onRequest } from 'firebase-functions/v2/https';

import { runSweepOnce } from './sweep';

export const devRunSweep = onRequest(
  { region: 'us-central1', memory: '256MiB', maxInstances: 1 },
  async (req, res) => {
    if (process.env.FUNCTIONS_EMULATOR !== 'true') {
      res.status(403).send('emulator only');
      return;
    }
    const counts = await runSweepOnce(Date.now());
    res.json(counts);
  },
);
