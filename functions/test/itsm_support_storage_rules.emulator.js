'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  setDoc,
} = require('firebase/firestore');
const {
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
      setDoc(
        doc(firestore, 'serviceRequests/own'),
        request('user-1'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/other'),
        request('user-2'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/admin-own'),
        request('admin-1'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee'),
        article('published', 'employee'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/draft'),
        article('draft', 'employee'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/dsi'),
        article('published', 'dsi_only'),
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/employee/versions/000001'),
        { state: 'published' },
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/draft/versions/000002'),
        { state: 'draft' },
      ),
      setDoc(
        doc(firestore, 'knowledgeArticles/dsi/versions/000001'),
        { state: 'published' },
      ),
    ]);
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    await Promise.all([
      upload(
        context.storage(),
        requestPath('own', 'public'),
        requestMetadata('own', 'public', 'user-1', false),
      ),
      upload(
        context.storage(),
        requestPath('other', 'public'),
        requestMetadata('other', 'public', 'user-2', false),
      ),
      upload(
        context.storage(),
        requestPath('admin-own', 'public'),
        requestMetadata('admin-own', 'public', 'admin-1', false),
      ),
      upload(
        context.storage(),
        knowledgePath('employee', 'public'),
        knowledgeMetadata('employee', 'public', 'manager-1', false),
      ),
      upload(
        context.storage(),
        knowledgePath('employee', 'internal'),
        knowledgeMetadata('employee', 'internal', 'manager-1', true),
      ),
      upload(
        context.storage(),
        knowledgePath('draft', 'public'),
        knowledgeMetadata('draft', 'public', 'manager-1', false),
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('request attachment access follows the parent owner and MANAGER role', async () => {
  const userStorage = storageFor('user-1');
  await assertSucceeds(
    getBytes(ref(userStorage, requestPath('own', 'public'))),
  );
  await assertFails(
    getBytes(ref(userStorage, requestPath('other', 'public'))),
  );

  const managerStorage = storageFor('manager-1');
  await assertSucceeds(
    getBytes(ref(managerStorage, requestPath('other', 'public'))),
  );

  const adminStorage = storageFor('admin-1');
  await assertSucceeds(
    getBytes(ref(adminStorage, requestPath('admin-own', 'public'))),
  );
  await assertFails(
    getBytes(ref(adminStorage, requestPath('other', 'public'))),
  );
});

test('knowledge files expose only published employee-visible public content', async () => {
  for (const uid of ['user-1', 'admin-1']) {
    const storage = storageFor(uid);
    await assertSucceeds(
      getBytes(ref(storage, knowledgePath('employee', 'public'))),
    );
    await assertFails(
      getBytes(ref(storage, knowledgePath('employee', 'internal'))),
    );
    await assertFails(
      getBytes(ref(storage, knowledgePath('draft', 'public'))),
    );
  }

  const managerStorage = storageFor('manager-1');
  await assertSucceeds(
    getBytes(ref(
      managerStorage,
      knowledgePath('employee', 'internal'),
    )),
  );
  await assertSucceeds(
    getBytes(ref(managerStorage, knowledgePath('draft', 'public'))),
  );
});

test('only MANAGER uploads canonical knowledge attachments', async () => {
  const managerStorage = storageFor('manager-1');
  const managerPath = knowledgePath('draft', 'manager-upload');
  await assertSucceeds(
    upload(
      managerStorage,
      managerPath,
      knowledgeMetadata(
        'draft',
        'manager-upload',
        'manager-1',
        false,
      ),
    ),
  );

  const userStorage = storageFor('user-1');
  await assertFails(
    upload(
      userStorage,
      knowledgePath('draft', 'user-upload'),
      knowledgeMetadata(
        'draft',
        'user-upload',
        'user-1',
        false,
      ),
    ),
  );
});

test('request uploads require canonical metadata and an accessible active parent', async () => {
  const userStorage = storageFor('user-1');
  await assertSucceeds(
    upload(
      userStorage,
      requestPath('own', 'new-public'),
      requestMetadata('own', 'new-public', 'user-1', false),
    ),
  );
  await assertFails(
    upload(
      userStorage,
      requestPath('own', 'forged'),
      requestMetadata('other', 'forged', 'user-1', false),
    ),
  );
  await assertFails(
    upload(
      userStorage,
      requestPath('other', 'cross-user'),
      requestMetadata('other', 'cross-user', 'user-1', false),
    ),
  );
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

function requestPath(requestId, attachmentId) {
  return `itsm/serviceRequests/${requestId}/attachments/${attachmentId}/file.pdf`;
}

function knowledgePath(articleId, attachmentId) {
  const versionId = articleId === 'draft' ? '000002' : '000001';
  return `itsm/knowledgeArticles/${articleId}/versions/${versionId}/attachments/${attachmentId}/file.pdf`;
}

function requestMetadata(requestId, attachmentId, uploadedBy, internal) {
  return {
    workItemCollection: 'serviceRequests',
    workItemId: requestId,
    attachmentId,
    uploadedByUserId: uploadedBy,
    documentRequirementKey: 'supporting_document',
    isInternal: String(internal),
  };
}

function knowledgeMetadata(articleId, attachmentId, uploadedBy, internal) {
  const versionId = articleId === 'draft' ? '000002' : '000001';
  return {
    articleId,
    versionId,
    attachmentId,
    uploadedByUserId: uploadedBy,
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

function request(requesterId) {
  return {
    requesterId,
    status: 'draft',
    lifecycleState: 'active',
    confidentiality: 'INTERNAL',
    selfServiceVisible: true,
  };
}

function article(status, visibility) {
  return {
    state: status,
    visibility,
    currentVersionId: status === 'draft' ? '000002' : '000001',
  };
}
