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

const projectId = 'demo-arptc-connect-itsm';
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
      setDoc(doc(firestore, 'changeRequests/own'), change('user-1')),
      setDoc(doc(firestore, 'changeRequests/other'), change('user-2')),
      setDoc(doc(firestore, 'changeRequests/admin-own'), change('admin-1')),
      setDoc(
        doc(firestore, 'changeRequests/closed-own'),
        change('user-1', { lifecycleState: 'closed', status: 'closed' }),
      ),
    ]);
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    await Promise.all([
      upload(
        context.storage(),
        attachmentPath('own', 'public'),
        metadata('own', 'public', 'user-1', false),
      ),
      upload(
        context.storage(),
        attachmentPath('own', 'internal'),
        metadata('own', 'internal', 'manager-1', true),
      ),
      upload(
        context.storage(),
        attachmentPath('other', 'public'),
        metadata('other', 'public', 'user-2', false),
      ),
      upload(
        context.storage(),
        attachmentPath('admin-own', 'public'),
        metadata('admin-own', 'public', 'admin-1', false),
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('attachment reads follow the parent change and internal visibility', async () => {
  const user = storageFor('user-1');
  await assertSucceeds(getBytes(ref(user, attachmentPath('own', 'public'))));
  await assertFails(getBytes(ref(user, attachmentPath('own', 'internal'))));
  await assertFails(getBytes(ref(user, attachmentPath('other', 'public'))));

  const admin = storageFor('admin-1');
  await assertSucceeds(getBytes(ref(admin, attachmentPath('admin-own', 'public'))));
  await assertFails(getBytes(ref(admin, attachmentPath('other', 'public'))));

  const manager = storageFor('manager-1');
  await assertSucceeds(getBytes(ref(manager, attachmentPath('other', 'public'))));
  await assertSucceeds(getBytes(ref(manager, attachmentPath('own', 'internal'))));
});

test('self-service uploads only public evidence to an owned active change', async () => {
  const user = storageFor('user-1');
  await assertSucceeds(upload(
    user,
    attachmentPath('own', 'new-public'),
    metadata('own', 'new-public', 'user-1', false),
  ));
  await assertFails(upload(
    user,
    attachmentPath('own', 'new-internal'),
    metadata('own', 'new-internal', 'user-1', true),
  ));
  await assertFails(upload(
    user,
    attachmentPath('other', 'cross-user'),
    metadata('other', 'cross-user', 'user-1', false),
  ));
  await assertFails(upload(
    user,
    attachmentPath('closed-own', 'closed'),
    metadata('closed-own', 'closed', 'user-1', false),
  ));
  await assertFails(upload(
    user,
    attachmentPath('own', 'forged-parent'),
    metadata('other', 'forged-parent', 'user-1', false),
  ));
});

test('MANAGER can add internal evidence, while ADMIN remains owner-scoped', async () => {
  const manager = storageFor('manager-1');
  await assertSucceeds(upload(
    manager,
    attachmentPath('other', 'manager-internal'),
    metadata('other', 'manager-internal', 'manager-1', true),
  ));

  const admin = storageFor('admin-1');
  await assertSucceeds(upload(
    admin,
    attachmentPath('admin-own', 'admin-public'),
    metadata('admin-own', 'admin-public', 'admin-1', false),
  ));
  await assertFails(upload(
    admin,
    attachmentPath('other', 'admin-cross-user'),
    metadata('other', 'admin-cross-user', 'admin-1', false),
  ));
});

test('change evidence is immutable and unknown storage paths are denied', async () => {
  const manager = storageFor('manager-1');
  await assertFails(upload(
    manager,
    attachmentPath('own', 'public'),
    metadata('own', 'public', 'manager-1', false),
  ));
  await assertFails(deleteObject(ref(
    manager,
    attachmentPath('own', 'public'),
  )));
  await assertFails(upload(
    manager,
    'itsm/changeRequests/own/privateNotes/note.txt',
    metadata('own', 'unknown', 'manager-1', false),
  ));
});

function storageFor(uid) {
  return environment
    .authenticatedContext(uid, { email: `${uid}@arptc.cd` })
    .storage();
}

function upload(storage, objectPath, customMetadata) {
  return uploadBytes(
    ref(storage, objectPath),
    new Uint8Array([1, 2, 3]),
    {
      contentType: 'application/pdf',
      customMetadata,
    },
  );
}

function attachmentPath(changeId, attachmentId) {
  return `itsm/changeRequests/${changeId}/attachments/${attachmentId}/file.pdf`;
}

function metadata(changeId, attachmentId, uploadedBy, internal) {
  return {
    workItemCollection: 'changeRequests',
    workItemId: changeId,
    attachmentId,
    uploadedByUserId: uploadedBy,
    documentRequirementKey: 'change_evidence',
    isInternal: String(internal),
  };
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function change(requesterId, overrides = {}) {
  return {
    requesterId,
    status: 'submitted',
    lifecycleState: 'active',
    confidentiality: 'internal',
    selfServiceVisible: true,
    ...overrides,
  };
}
