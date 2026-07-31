#!/usr/bin/env node

'use strict';

const fs = require('node:fs');
const path = require('node:path');
const admin = require('../../functions/node_modules/firebase-admin');

const args = new Set(process.argv.slice(2));
const apply = args.has('--apply');
const overwrite = args.has('--overwrite');
const projectArg = process.argv.find((value) => value.startsWith('--project='));
const projectId = projectArg ? projectArg.substring('--project='.length) : null;
const seedPath = path.join(__dirname, '..', 'seeds', 'itsm_phase2_seed.json');
const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'));

if (!Array.isArray(seed.documents) || seed.documents.length === 0) {
  throw new Error('The Phase 2 seed contains no documents.');
}
if (!apply) {
  console.log(`[dry-run] ${seed.documents.length} deterministic documents`);
  for (const document of seed.documents) console.log(`create ${document.path}`);
  console.log('No Firebase writes were performed. Pass --apply explicitly.');
  process.exit(0);
}

admin.initializeApp(projectId ? {projectId} : undefined);
const db = admin.firestore();

async function provision() {
  let created = 0;
  let overwritten = 0;
  let skipped = 0;
  for (const document of seed.documents) {
    const reference = db.doc(document.path);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      if (snapshot.exists && !overwrite) {
        skipped += 1;
        return;
      }
      transaction.set(reference, revive(document.data), {merge: false});
      if (snapshot.exists) {
        overwritten += 1;
      } else {
        created += 1;
      }
    });
  }
  console.log(JSON.stringify({created, overwritten, skipped}, null, 2));
}

function revive(value) {
  if (Array.isArray(value)) return value.map(revive);
  if (!value || typeof value !== 'object') return value;
  if (Object.keys(value).length === 1 && typeof value['@timestamp'] === 'string') {
    return admin.firestore.Timestamp.fromDate(new Date(value['@timestamp']));
  }
  return Object.fromEntries(
    Object.entries(value).map(([key, child]) => [key, revive(child)]),
  );
}

provision().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
