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
      setDoc(doc(firestore, 'securityFindings/internal'), {
        confidentiality: 'internal',
      }),
      setDoc(doc(firestore, 'securityFindings/restricted'), {
        confidentiality: 'restricted',
        authorizedManagerIds: ['manager-1'],
      }),
      setDoc(doc(firestore, 'securityExceptions/own-restricted'), {
        requester: { userId: 'user-1' },
        confidentiality: 'restricted',
        authorizedManagerIds: ['manager-1'],
      }),
      setDoc(doc(firestore, 'securityExceptions/other'), {
        requester: { userId: 'user-2' },
        confidentiality: 'internal',
      }),
      setDoc(doc(firestore, 'securityExceptions/admin-own'), {
        requester: { userId: 'admin-1' },
        confidentiality: 'internal',
      }),
      setDoc(doc(firestore, 'assetComplianceAssessments/assessment-1'), {
        assignedUserId: 'user-1',
      }),
      setDoc(doc(firestore, 'accessReviewItems/item-1'), {
        subjectUser: { userId: 'user-1' },
      }),
    ]);
  });
});

after(async () => {
  await environment.cleanup();
});

test('uploads remain unreadable until exact immutable metadata is registered', async () => {
  const managerObject = attachment(
    'securityFindings',
    'internal',
    'manager-upload',
    'manager-1',
    'internal',
  );
  const manager = storageFor('manager-1');
  await assertSucceeds(upload(manager, managerObject));
  await assertFails(getBytes(ref(manager, managerObject.path)));

  const requesterObject = attachment(
    'securityExceptions',
    'own-restricted',
    'requester-upload',
    'user-1',
    'internal',
    true,
  );
  const user = storageFor('user-1');
  await assertSucceeds(upload(user, requesterObject));
  await assertFails(getBytes(ref(user, requesterObject.path)));

  await registerMetadata(managerObject);
  await registerMetadata(requesterObject);
  await assertSucceeds(getBytes(ref(manager, managerObject.path)));
  await assertSucceeds(getBytes(ref(user, requesterObject.path)));
});

test('MANAGER uploads are parent-aware and confidentiality-bound', async () => {
  const manager = storageFor('manager-1');
  const allowed = [
    attachment(
      'securityFindings',
      'internal',
      'finding-internal',
      'manager-1',
      'internal',
    ),
    attachment(
      'securityFindings',
      'restricted',
      'finding-restricted',
      'manager-1',
      'restricted',
    ),
    attachment(
      'securityExceptions',
      'own-restricted',
      'exception-internal',
      'manager-1',
      'internal',
    ),
    attachment(
      'assetComplianceAssessments',
      'assessment-1',
      'assessment-evidence',
      'manager-1',
      'restricted',
    ),
    attachment(
      'accessReviewItems',
      'item-1',
      'access-evidence',
      'manager-1',
      'restricted',
    ),
  ];
  for (const object of allowed) {
    await assertSucceeds(upload(manager, object));
  }

  const unauthorizedManager = storageFor('manager-2');
  await assertFails(upload(
    unauthorizedManager,
    attachment(
      'securityFindings',
      'restricted',
      'unauthorized-finding',
      'manager-2',
      'restricted',
    ),
  ));
  await assertFails(upload(
    unauthorizedManager,
    attachment(
      'securityExceptions',
      'own-restricted',
      'unauthorized-exception',
      'manager-2',
      'internal',
    ),
  ));

  const forgedActor = attachment(
    'securityFindings',
    'internal',
    'forged-actor',
    'manager-2',
    'internal',
  );
  await assertFails(upload(manager, forgedActor));

  const forgedPath = attachment(
    'securityFindings',
    'internal',
    'forged-path',
    'manager-1',
    'internal',
  );
  forgedPath.customMetadata.storagePath =
    'itsm/securityFindings/other/attachments/forged-path/file.pdf';
  await assertFails(upload(manager, forgedPath));

  const unsupported = attachment(
    'securityFindings',
    'internal',
    'unsupported',
    'manager-1',
    'internal',
  );
  unsupported.contentType = 'application/x-msdownload';
  await assertFails(upload(manager, unsupported));
});

test('USER and ADMIN upload only requester-visible evidence to their own exception', async () => {
  const user = storageFor('user-1');
  await assertSucceeds(upload(
    user,
    attachment(
      'securityExceptions',
      'own-restricted',
      'own-requester-visible',
      'user-1',
      'internal',
      true,
    ),
  ));
  await assertFails(upload(
    user,
    attachment(
      'securityExceptions',
      'own-restricted',
      'own-internal',
      'user-1',
      'internal',
    ),
  ));
  await assertFails(upload(
    user,
    attachment(
      'securityExceptions',
      'own-restricted',
      'own-restricted',
      'user-1',
      'restricted',
    ),
  ));
  await assertFails(upload(
    user,
    attachment(
      'securityExceptions',
      'other',
      'cross-user',
      'user-1',
      'internal',
      true,
    ),
  ));
  await assertFails(upload(
    user,
    attachment(
      'securityFindings',
      'internal',
      'raw-finding',
      'user-1',
      'internal',
      true,
    ),
  ));

  const admin = storageFor('admin-1');
  await assertSucceeds(upload(
    admin,
    attachment(
      'securityExceptions',
      'admin-own',
      'admin-requester-visible',
      'admin-1',
      'internal',
      true,
    ),
  ));
  await assertFails(upload(
    admin,
    attachment(
      'securityExceptions',
      'other',
      'admin-cross-user',
      'admin-1',
      'internal',
      true,
    ),
  ));
});

test('post-registration reads preserve requester and restricted evidence isolation', async () => {
  const objects = [
    attachment(
      'securityExceptions',
      'own-restricted',
      'requester-visible-evidence',
      'user-1',
      'internal',
      true,
    ),
    attachment(
      'securityExceptions',
      'own-restricted',
      'internal-evidence',
      'manager-1',
      'internal',
    ),
    attachment(
      'securityFindings',
      'restricted',
      'restricted-evidence',
      'manager-1',
      'restricted',
    ),
    attachment(
      'assetComplianceAssessments',
      'assessment-1',
      'compliance-evidence',
      'manager-1',
      'restricted',
    ),
  ];
  await seedFinalizedObjects(objects);

  const user = storageFor('user-1');
  await assertSucceeds(getBytes(ref(user, objects[0].path)));
  await assertFails(getBytes(ref(user, objects[1].path)));
  await assertFails(getBytes(ref(user, objects[2].path)));
  await assertFails(getBytes(ref(user, objects[3].path)));

  const otherUser = storageFor('user-2');
  await assertFails(getBytes(ref(otherUser, objects[0].path)));

  const admin = storageFor('admin-1');
  await assertFails(getBytes(ref(admin, objects[0].path)));
  await assertFails(getBytes(ref(admin, objects[2].path)));

  const authorizedManager = storageFor('manager-1');
  for (const object of objects) {
    await assertSucceeds(getBytes(ref(authorizedManager, object.path)));
  }

  const unauthorizedManager = storageFor('manager-2');
  await assertFails(getBytes(ref(unauthorizedManager, objects[2].path)));
  await assertFails(getBytes(ref(unauthorizedManager, objects[3].path)));
});

test('registered metadata must match exactly and attachment objects are immutable', async () => {
  const valid = attachment(
    'securityFindings',
    'internal',
    'immutable',
    'manager-1',
    'internal',
  );
  await seedFinalizedObjects([valid]);
  const manager = storageFor('manager-1');
  await assertSucceeds(getBytes(ref(manager, valid.path)));
  await assertFails(upload(manager, valid));
  await assertFails(deleteObject(ref(manager, valid.path)));

  const tampered = attachment(
    'securityFindings',
    'internal',
    'tampered',
    'manager-1',
    'internal',
  );
  await environment.withSecurityRulesDisabled(async (context) => {
    await upload(context.storage(), tampered);
  });
  const metadata = firestoreMetadata(tampered);
  metadata.sizeBytes = 999;
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), metadataPath(tampered)),
      metadata,
    );
  });
  await assertFails(getBytes(ref(manager, tampered.path)));

  await assertFails(upload(
    manager,
    {
      ...valid,
      path: 'itsm/securityFindings/internal/privateNotes/note.txt',
    },
  ));
});

function storageFor(uid) {
  return environment
    .authenticatedContext(uid, { email: `${uid}@arptc.cd` })
    .storage();
}

async function seedFinalizedObjects(objects) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await Promise.all(objects.map((object) => upload(context.storage(), object)));
  });
  for (const object of objects) await registerMetadata(object);
}

async function registerMetadata(object) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), metadataPath(object)),
      firestoreMetadata(object),
    );
  });
}

function upload(storage, object) {
  return uploadBytes(
    ref(storage, object.path),
    new Uint8Array([1, 2, 3]),
    {
      contentType: object.contentType,
      customMetadata: object.customMetadata,
    },
  );
}

function attachment(
  parentCollection,
  parentId,
  attachmentId,
  uploadedByUserId,
  confidentiality,
  requesterVisible = false,
) {
  const fileName = 'file.pdf';
  const storagePath =
    `itsm/${parentCollection}/${parentId}/attachments/${attachmentId}/${fileName}`;
  const restricted = confidentiality === 'restricted';
  return {
    parentCollection,
    parentId,
    attachmentId,
    fileName,
    path: storagePath,
    contentType: 'application/pdf',
    customMetadata: {
      parentCollection,
      parentId,
      attachmentId,
      fileName,
      storagePath,
      uploadedByUserId,
      confidentiality,
      requesterVisible: String(requesterVisible),
      isInternal: String(!requesterVisible),
      authorizedManagerId: restricted ? uploadedByUserId : '',
    },
  };
}

function metadataPath(object) {
  return `${object.parentCollection}/${object.parentId}/attachments/${object.attachmentId}`;
}

function firestoreMetadata(object) {
  const restricted = object.customMetadata.confidentiality === 'restricted';
  return {
    parentCollection: object.parentCollection,
    parentId: object.parentId,
    attachmentId: object.attachmentId,
    storagePath: object.path,
    fileName: object.fileName,
    contentType: object.contentType,
    sizeBytes: 3,
    uploadedByUserId: object.customMetadata.uploadedByUserId,
    confidentiality: object.customMetadata.confidentiality,
    requesterVisible: object.customMetadata.requesterVisible === 'true',
    isInternal: object.customMetadata.isInternal === 'true',
    authorizedManagerIds: restricted
      ? [object.customMetadata.authorizedManagerId]
      : [],
  };
}

function agent(role) {
  return {
    email: `${role.toLowerCase()}@arptc.cd`,
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}
