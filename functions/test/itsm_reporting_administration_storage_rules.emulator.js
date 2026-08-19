'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { Timestamp, doc, setDoc } = require('firebase/firestore');
const { deleteObject, getBytes, ref, uploadBytes } = require('firebase/storage');

const projectId = 'demo-arptc-connect-itsm';
const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);
const storageRules = fs.readFileSync(
  path.resolve(__dirname, '../../storage.rules'),
  'utf8',
);

const futureTime = Timestamp.fromDate(new Date('2030-07-01T08:00:00Z'));
const expiredTime = Timestamp.fromDate(new Date('2020-07-01T08:00:00Z'));
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { rules: firestoreRules },
    storage: { rules: storageRules },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.clearStorage();
  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, 'agents/user-1'), agent('USER')),
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/manager-2'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'agents/admin-2'), agent('ADMIN')),
      setDoc(
        doc(firestore, 'itsmAuditExports/manager-completed'),
        exportMetadata('manager-1', 'manager-completed', 'completed', futureTime),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/admin-completed'),
        exportMetadata('admin-1', 'admin-completed', 'completed', futureTime),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/manager-pending'),
        exportMetadata('manager-1', 'manager-pending', 'pending', futureTime),
      ),
      setDoc(
        doc(firestore, 'itsmAuditExports/manager-expired'),
        exportMetadata('manager-1', 'manager-expired', 'completed', expiredTime),
      ),
    ]);

    await Promise.all([
      seedExportObject(context.storage(), 'manager-1', 'manager-completed'),
      seedExportObject(context.storage(), 'admin-1', 'admin-completed'),
      seedExportObject(context.storage(), 'manager-1', 'manager-pending'),
      seedExportObject(context.storage(), 'manager-1', 'manager-expired'),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('completed unexpired exports are readable only by their requester', async () => {
  await assertSucceeds(readExport('manager-1', 'manager-1', 'manager-completed'));
  await assertSucceeds(readExport('admin-1', 'admin-1', 'admin-completed'));

  await assertFails(readExport('manager-2', 'manager-1', 'manager-completed'));
  await assertFails(readExport('admin-2', 'admin-1', 'admin-completed'));
  await assertFails(readExport('admin-1', 'manager-1', 'manager-completed'));
  await assertFails(readExport('user-1', 'manager-1', 'manager-completed'));
});

test('pending and expired exports remain private', async () => {
  await assertFails(readExport('manager-1', 'manager-1', 'manager-pending'));
  await assertFails(readExport('manager-1', 'manager-1', 'manager-expired'));
});

test('all export objects are trusted-write-only and immutable', async () => {
  const object = exportObject('manager-1', 'manager-completed');
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const storage = storageFor(uid);
    await assertFails(uploadBytes(
      ref(storage, object.storagePath),
      new Uint8Array([9, 9, 9]),
      object.options,
    ));
    await assertFails(deleteObject(ref(storage, object.storagePath)));
  }
});

test('path or object metadata mismatches cannot expose an export', async () => {
  const mismatchedPath =
    'itsm/reporting-exports/manager-1/manager-completed/renamed.csv';
  await environment.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(
      ref(context.storage(), mismatchedPath),
      new Uint8Array([1, 2, 3]),
      exportObject('manager-1', 'manager-completed').options,
    );
  });
  await assertFails(getBytes(ref(storageFor('manager-1'), mismatchedPath)));

  const forgedMetadata = exportObject('manager-1', 'manager-completed');
  const forgedPath =
    'itsm/reporting-exports/manager-1/manager-completed/forged.csv';
  forgedMetadata.options.customMetadata.storagePath = forgedPath;
  await environment.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(
      ref(context.storage(), forgedPath),
      new Uint8Array([1, 2, 3]),
      forgedMetadata.options,
    );
  });
  await assertFails(getBytes(ref(storageFor('manager-1'), forgedPath)));
});

test('configuration and report-internal storage prefixes stay deny-by-default', async () => {
  const paths = [
    'itsm/report-snapshots/admin/raw.json',
    'itsm/report-contributions/source-1/raw.json',
    'itsm/service-catalogue/draft/config.json',
    'itsm/workflows/draft/config.json',
    'itsm/sla/draft/config.json',
    'itsm/audit-events/event-1/raw.json',
  ];
  for (const uid of ['manager-1', 'admin-1']) {
    const storage = storageFor(uid);
    for (const objectPath of paths) {
      await assertFails(uploadBytes(
        ref(storage, objectPath),
        new Uint8Array([1]),
        { contentType: 'application/json' },
      ));
      await assertFails(getBytes(ref(storage, objectPath)));
    }
  }
});

function storageFor(uid) {
  return environment
    .authenticatedContext(uid, {
      email: `${uid}@arptc.cd`,
      email_verified: true,
    })
    .storage();
}

function readExport(uid, requesterUserId, exportId) {
  return getBytes(ref(
    storageFor(uid),
    exportObject(requesterUserId, exportId).storagePath,
  ));
}

function seedExportObject(storage, requesterUserId, exportId) {
  const object = exportObject(requesterUserId, exportId);
  return uploadBytes(
    ref(storage, object.storagePath),
    new Uint8Array([1, 2, 3]),
    object.options,
  );
}

function exportObject(requesterUserId, exportId) {
  const fileName = 'audit.csv';
  const storagePath =
    `itsm/reporting-exports/${requesterUserId}/${exportId}/${fileName}`;
  return {
    storagePath,
    options: {
      contentType: 'text/csv',
      customMetadata: {
        requesterUserId,
        exportId,
        storagePath,
      },
    },
  };
}

function exportMetadata(requesterUserId, exportId, status, expiresAt) {
  const fileName = 'audit.csv';
  return {
    requesterUserId,
    status,
    expiresAt,
    fileName,
    storagePath:
      `itsm/reporting-exports/${requesterUserId}/${exportId}/${fileName}`,
  };
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}
