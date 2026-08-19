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

// Storage rules resolve Firestore parent lookups in the emulator CLI project.
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
      setDoc(doc(firestore, 'agents/manager-2'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'agents/legacy-manager@arptc.cd'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/inactive-manager'), {
        ...agent('MANAGER'),
        isActive: false,
      }),
      setDoc(doc(firestore, 'agents/missing-active-manager'), {
        modulePermissions: { ticketing: 'MANAGER' },
      }),
      setDoc(doc(firestore, 'agents/unverified-manager'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/password-change-user'), {
        ...agent('USER'),
        mustChangePassword: true,
      }),
      setDoc(
        doc(firestore, 'serviceRequests/request-1'),
        workItem('user-1'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/request-2'),
        workItem('user-2'),
      ),
      setDoc(
        doc(firestore, 'serviceRequests/admin-request'),
        workItem('admin-1'),
      ),
      setDoc(
        doc(firestore, 'securityFindings/finding-1'),
        workItem('user-2', {
          confidentiality: 'RESTRICTED',
          authorizedUserIds: ['manager-1'],
        }),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/incident-1'),
        incident('user-1'),
      ),
      setDoc(
        doc(firestore, 'incidentTickets/admin-incident'),
        incident('admin-1'),
      ),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('storage requires a verified active profile at the authenticated UID', async () => {
  for (const [storage, userId, attachmentId] of [
    [legacyManagerStorage(), 'legacy-manager-uid', 'legacy-email-profile'],
    [storageFor('inactive-manager'), 'inactive-manager', 'inactive-profile'],
    [
      storageFor('missing-active-manager'),
      'missing-active-manager',
      'missing-active',
    ],
    [
      storageFor('unverified-manager', { emailVerified: false }),
      'unverified-manager',
      'unverified-email',
    ],
    [
      storageFor('password-change-user'),
      'password-change-user',
      'initial-password-change',
    ],
  ]) {
    await assertFails(
      uploadAttachment(storage, {
        collectionName: 'serviceRequests',
        workItemId: 'request-1',
        attachmentId,
        uploadedByUserId: userId,
        isInternal: true,
      }),
    );
  }
});

test('USER uploads only public attachments to an owned active parent', async () => {
  const storage = userStorage('user-1');

  await assertSucceeds(
    uploadAttachment(storage, {
      collectionName: 'serviceRequests',
      workItemId: 'request-1',
      attachmentId: 'public-user',
      uploadedByUserId: 'user-1',
      isInternal: false,
    }),
  );
  await assertFails(
    uploadAttachment(storage, {
      collectionName: 'serviceRequests',
      workItemId: 'request-1',
      attachmentId: 'internal-user',
      uploadedByUserId: 'user-1',
      isInternal: true,
    }),
  );
  await assertFails(
    uploadAttachment(storage, {
      collectionName: 'serviceRequests',
      workItemId: 'request-2',
      attachmentId: 'cross-user',
      uploadedByUserId: 'user-1',
      isInternal: false,
    }),
  );
});

test('ADMIN has USER-level attachment rights and cannot mutate another owner', async () => {
  const storage = userStorage('admin-1');

  await assertSucceeds(
    uploadAttachment(storage, {
      collectionName: 'serviceRequests',
      workItemId: 'admin-request',
      attachmentId: 'admin-own',
      uploadedByUserId: 'admin-1',
      isInternal: false,
    }),
  );
  await assertFails(
    uploadAttachment(storage, {
      collectionName: 'serviceRequests',
      workItemId: 'request-2',
      attachmentId: 'admin-cross-user',
      uploadedByUserId: 'admin-1',
      isInternal: false,
    }),
  );
  await assertFails(
    uploadAttachment(storage, {
      collectionName: 'incidentTickets',
      workItemId: 'incident-1',
      attachmentId: 'admin-incident-mutation',
      uploadedByUserId: 'admin-1',
      isInternal: false,
    }),
  );
  await assertSucceeds(
    uploadAttachment(storage, {
      collectionName: 'incidentTickets',
      workItemId: 'admin-incident',
      attachmentId: 'admin-own-incident',
      uploadedByUserId: 'admin-1',
      isInternal: false,
    }),
  );
});

test('MANAGER can create internal attachments but USER cannot read them', async () => {
  const managerStorage = userStorage('manager-1');
  const object = attachmentRef(managerStorage, {
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    attachmentId: 'internal-manager',
  });

  await assertSucceeds(
    uploadAttachment(managerStorage, {
      collectionName: 'serviceRequests',
      workItemId: 'request-1',
      attachmentId: 'internal-manager',
      uploadedByUserId: 'manager-1',
      isInternal: true,
    }),
  );
  await assertSucceeds(getBytes(object));

  const userObject = attachmentRef(userStorage('user-1'), {
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    attachmentId: 'internal-manager',
  });
  await assertFails(getBytes(userObject));
  await assertFails(deleteObject(object));
});

test('restricted evidence requires explicit MANAGER authorization', async () => {
  const authorized = userStorage('manager-1');
  const evidence = securityFindingEvidence({
    findingId: 'finding-1',
    attachmentId: 'evidence',
    uploadedByUserId: 'manager-1',
  });
  await assertSucceeds(
    uploadSecurityFindingEvidence(authorized, evidence),
  );

  // Phase 5 evidence is not readable until its immutable metadata is indexed.
  await assertFails(getBytes(ref(authorized, evidence.storagePath)));
  await registerSecurityFindingEvidence(evidence);
  await assertSucceeds(getBytes(ref(authorized, evidence.storagePath)));

  const unauthorizedObject = ref(
    userStorage('manager-2'),
    evidence.storagePath,
  );
  await assertFails(getBytes(unauthorizedObject));
  await assertFails(
    uploadSecurityFindingEvidence(
      userStorage('manager-2'),
      securityFindingEvidence({
        findingId: 'finding-1',
        attachmentId: 'unauthorized-evidence',
        uploadedByUserId: 'manager-2',
      }),
    ),
  );
});

test('attachment metadata must match its parent-aware storage path', async () => {
  const storage = userStorage('manager-1');
  const object = attachmentRef(storage, {
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    attachmentId: 'mismatched',
  });

  await assertFails(
    uploadBytes(object, new Uint8Array([1, 2, 3]), {
      contentType: 'application/pdf',
      customMetadata: {
        workItemCollection: 'serviceRequests',
        workItemId: 'request-2',
        attachmentId: 'mismatched',
        uploadedByUserId: 'manager-1',
        isInternal: 'false',
      },
    }),
  );
});

test('unauthenticated and unknown-path access is denied', async () => {
  const anonymous = environment.unauthenticatedContext().storage();
  const unknown = ref(anonymous, 'itsm/unknown/item/attachments/a/file.pdf');
  await assertFails(getBytes(unknown));
  await assertFails(
    uploadBytes(unknown, new Uint8Array([1]), {
      contentType: 'application/pdf',
    }),
  );
});

function userStorage(uid) {
  return storageFor(uid);
}

function legacyManagerStorage() {
  return storageFor(
    'legacy-manager-uid',
    { email: 'legacy-manager@arptc.cd' },
  );
}

function storageFor(
  uid,
  {
    email = `${uid}@arptc.cd`,
    emailVerified = true,
  } = {},
) {
  return environment
    .authenticatedContext(uid, {
      email,
      email_verified: emailVerified,
    })
    .storage();
}

function attachmentRef(
  storage,
  { collectionName, workItemId, attachmentId },
) {
  return ref(
    storage,
    `itsm/${collectionName}/${workItemId}/attachments/${attachmentId}/file.pdf`,
  );
}

function uploadAttachment(
  storage,
  {
    collectionName,
    workItemId,
    attachmentId,
    uploadedByUserId,
    isInternal,
  },
) {
  return uploadBytes(
    attachmentRef(storage, {
      collectionName,
      workItemId,
      attachmentId,
    }),
    new Uint8Array([1, 2, 3]),
    {
      contentType: 'application/pdf',
      customMetadata: {
        workItemCollection: collectionName,
        workItemId,
        attachmentId,
        uploadedByUserId,
        documentRequirementKey: 'supporting_document',
        isInternal: String(isInternal),
      },
    },
  );
}

function securityFindingEvidence({
  findingId,
  attachmentId,
  uploadedByUserId,
}) {
  const fileName = 'file.pdf';
  const storagePath =
    `itsm/securityFindings/${findingId}/attachments/${attachmentId}/${fileName}`;
  return {
    findingId,
    attachmentId,
    fileName,
    storagePath,
    uploadedByUserId,
  };
}

function uploadSecurityFindingEvidence(storage, evidence) {
  return uploadBytes(
    ref(storage, evidence.storagePath),
    new Uint8Array([1, 2, 3]),
    {
      contentType: 'application/pdf',
      customMetadata: {
        parentCollection: 'securityFindings',
        parentId: evidence.findingId,
        attachmentId: evidence.attachmentId,
        fileName: evidence.fileName,
        storagePath: evidence.storagePath,
        uploadedByUserId: evidence.uploadedByUserId,
        confidentiality: 'restricted',
        requesterVisible: 'false',
        isInternal: 'true',
        authorizedManagerId: evidence.uploadedByUserId,
      },
    },
  );
}

async function registerSecurityFindingEvidence(evidence) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        `securityFindings/${evidence.findingId}/attachments/${evidence.attachmentId}`,
      ),
      {
        parentCollection: 'securityFindings',
        parentId: evidence.findingId,
        attachmentId: evidence.attachmentId,
        storagePath: evidence.storagePath,
        fileName: evidence.fileName,
        contentType: 'application/pdf',
        sizeBytes: 3,
        uploadedByUserId: evidence.uploadedByUserId,
        confidentiality: 'restricted',
        requesterVisible: false,
        isInternal: true,
        authorizedManagerIds: [evidence.uploadedByUserId],
      },
    );
  });
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function workItem(requesterId, overrides = {}) {
  return {
    requesterId,
    requesterEmail: `${requesterId}@arptc.cd`,
    lifecycleState: 'active',
    status: 'draft',
    confidentiality: 'INTERNAL',
    authorizedUserIds: [],
    ...overrides,
  };
}

function incident(ownerId) {
  return {
    createdByUserId: ownerId,
    createdByEmail: `${ownerId}@arptc.cd`,
    affectedUserId: ownerId,
    affectedUserEmail: `${ownerId}@arptc.cd`,
    lifecycleState: 'active',
    status: 'open',
  };
}
