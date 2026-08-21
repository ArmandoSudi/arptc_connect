'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');
const {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} = require('firebase/storage');

const projectId = 'demo-arptc-connect-inventory';
const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);
const storageRules = fs.readFileSync(
  path.resolve(__dirname, '../../storage.rules'),
  'utf8',
);

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
      setDoc(doc(firestore, 'agents/user-2'), agent('USER')),
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'agents/legacy-manager'), {
        isActive: true,
        modulePermissions: { inventaire: 'MANAGER' },
      }),
      setDoc(doc(firestore, 'agents/inactive-user'), {
        ...agent('USER'),
        isActive: false,
      }),
      setDoc(doc(firestore, 'materialRequests/own'), request('user-1')),
      setDoc(doc(firestore, 'materialRequests/other'), request('user-2')),
      setDoc(doc(firestore, 'materialRequests/admin-own'), request('admin-1')),
    ]);
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    await Promise.all([
      upload(
        context.storage(),
        attachmentPath('own', 'existing-own'),
        attachmentMetadata('own', 'existing-own', 'user-1'),
      ),
      upload(
        context.storage(),
        attachmentPath('other', 'existing-other'),
        attachmentMetadata('other', 'existing-other', 'user-2'),
      ),
      upload(
        context.storage(),
        attachmentPath('admin-own', 'existing-admin'),
        attachmentMetadata('admin-own', 'existing-admin', 'admin-1'),
      ),
    ]);
  });
});

after(async () => environment.cleanup());

test('attachment reads follow USER ownership and operational read roles', async () => {
  await assertSucceeds(getBytes(ref(
    storageFor('user-1'),
    attachmentPath('own', 'existing-own'),
  )));
  await assertFails(getBytes(ref(
    storageFor('user-1'),
    attachmentPath('other', 'existing-other'),
  )));

  for (const uid of ['manager-1', 'legacy-manager', 'admin-1']) {
    await assertSucceeds(getBytes(ref(
      storageFor(uid),
      attachmentPath('other', 'existing-other'),
    )));
  }
  await assertFails(getBytes(ref(
    storageFor('inactive-user'),
    attachmentPath('own', 'existing-own'),
  )));
  await assertFails(getBytes(ref(
    environment.unauthenticatedContext().storage(),
    attachmentPath('own', 'existing-own'),
  )));
  await assertFails(getBytes(ref(
    storageFor('manager-1', false),
    attachmentPath('own', 'existing-own'),
  )));
});

test('USER uploads only to owned requests with canonical metadata', async () => {
  const user = storageFor('user-1');
  await assertSucceeds(upload(
    user,
    attachmentPath('own', 'new-own'),
    attachmentMetadata('own', 'new-own', 'user-1'),
  ));
  await assertFails(upload(
    user,
    attachmentPath('other', 'cross-user'),
    attachmentMetadata('other', 'cross-user', 'user-1'),
  ));
  await assertFails(upload(
    user,
    attachmentPath('missing', 'missing-parent'),
    attachmentMetadata('missing', 'missing-parent', 'user-1'),
  ));
  await assertFails(upload(
    user,
    attachmentPath('own', 'forged-request'),
    attachmentMetadata('other', 'forged-request', 'user-1'),
  ));
  await assertFails(upload(
    user,
    attachmentPath('own', 'forged-id'),
    attachmentMetadata('own', 'different-id', 'user-1'),
  ));
  await assertFails(upload(
    user,
    attachmentPath('own', 'forged-uploader'),
    attachmentMetadata('own', 'forged-uploader', 'user-2'),
  ));
});

test('MANAGER can upload operational evidence while ADMIN remains read-only', async () => {
  await assertSucceeds(upload(
    storageFor('manager-1'),
    attachmentPath('other', 'manager-upload'),
    attachmentMetadata('other', 'manager-upload', 'manager-1'),
  ));
  await assertSucceeds(upload(
    storageFor('legacy-manager'),
    attachmentPath('other', 'legacy-upload'),
    attachmentMetadata('other', 'legacy-upload', 'legacy-manager'),
  ));
  await assertFails(upload(
    storageFor('admin-1'),
    attachmentPath('other', 'admin-upload'),
    attachmentMetadata('other', 'admin-upload', 'admin-1'),
  ));
  await assertFails(upload(
    storageFor('inactive-user'),
    attachmentPath('own', 'inactive-upload'),
    attachmentMetadata('own', 'inactive-upload', 'inactive-user'),
  ));
});

test('uploads enforce non-empty supported files', async () => {
  const user = storageFor('user-1');
  await assertFails(upload(
    user,
    attachmentPath('own', 'unsupported'),
    attachmentMetadata('own', 'unsupported', 'user-1'),
    'application/x-msdownload',
  ));
  await assertFails(upload(
    user,
    attachmentPath('own', 'empty'),
    attachmentMetadata('own', 'empty', 'user-1'),
    'application/pdf',
    new Uint8Array(),
  ));
});

test('Inventory request attachments are immutable for every role', async () => {
  const existingPath = attachmentPath('own', 'existing-own');
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const storage = storageFor(uid);
    await assertFails(upload(
      storage,
      existingPath,
      attachmentMetadata('own', 'existing-own', uid),
    ));
    await assertFails(deleteObject(ref(storage, existingPath)));
  }
});

function storageFor(uid, emailVerified = true) {
  return environment.authenticatedContext(uid, {
    email: `${uid}@arptc.cd`,
    email_verified: emailVerified,
  }).storage();
}

function upload(
  storage,
  objectPath,
  customMetadata,
  contentType = 'application/pdf',
  data = new Uint8Array([1, 2, 3]),
) {
  return uploadBytes(ref(storage, objectPath), data, {
    contentType,
    customMetadata,
  });
}

function attachmentPath(requestId, attachmentId) {
  return `inventory/requests/${requestId}/attachments/${attachmentId}/file.pdf`;
}

function attachmentMetadata(requestId, attachmentId, uploadedByUserId) {
  return { requestId, attachmentId, uploadedByUserId };
}

function agent(role) {
  return {
    isActive: true,
    modulePermissions: { inventory: role },
  };
}

function request(userId) {
  return {
    requestedFor: {
      userId,
      email: `${userId}@arptc.cd`,
    },
    status: 'submitted',
  };
}
