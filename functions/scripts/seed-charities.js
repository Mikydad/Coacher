#!/usr/bin/env node
/**
 * D7 — seed/update the curated `charities` collection from
 * charities.seed.json (the versioned source of truth). Clients can never
 * write charities (firestore.rules denies), so this Admin-SDK script IS
 * the admin path.
 *
 * Idempotent: upserts by doc id with merge, stamps updatedAtMs, never
 * deletes (deactivate via active:false in the JSON and re-run).
 *
 * Dry-run by default — prints the target project and what would change.
 * Pass --yes to actually write.
 *
 * Auth, in order of what the SDK picks up:
 *   - FIRESTORE_EMULATOR_HOST=localhost:8080  → emulator, no creds needed
 *   - GOOGLE_APPLICATION_CREDENTIALS=key.json → live project
 *     (Firebase console → Project settings → Service accounts → generate
 *      key; delete the key file after seeding)
 *
 * Run from functions/:  node scripts/seed-charities.js [--yes]
 */

const path = require('path');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const COMMIT = process.argv.includes('--yes');

async function main() {
  const seedPath = path.join(__dirname, 'charities.seed.json');
  // eslint-disable-next-line global-require
  const raw = require(seedPath);
  const entries = Object.entries(raw).filter(([id]) => !id.startsWith('_'));

  initializeApp();
  const db = getFirestore();
  const projectId =
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    '(from credentials)';
  const emulator = process.env.FIRESTORE_EMULATOR_HOST;

  console.log(
    `Target: ${emulator ? `EMULATOR ${emulator}` : `LIVE project ${projectId}`}`,
  );
  console.log(`Seed entries: ${entries.length}`);

  const now = Date.now();
  let writes = 0;
  for (const [id, data] of entries) {
    if (!data.name || typeof data.active !== 'boolean') {
      throw new Error(`Seed entry '${id}' missing required name/active`);
    }
    const doc = { ...data, updatedAtMs: now, seededAtMs: FieldValue.serverTimestamp() };
    if (COMMIT) {
      await db.collection('charities').doc(id).set(doc, { merge: true });
    }
    writes++;
    console.log(
      `${COMMIT ? 'upserted' : 'would upsert'}: charities/${id} ` +
        `(${data.name}, active=${data.active})`,
    );
  }

  if (!COMMIT) {
    console.log(`\nDry run — ${writes} docs NOT written. Re-run with --yes.`);
  } else {
    console.log(`\nDone: ${writes} docs upserted.`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
