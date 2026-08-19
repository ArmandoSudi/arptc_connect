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
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'assets/asset-1'), { assetTag: 'ARPTC-001' }),
      setDoc(
        doc(firestore, 'assets/asset-1/attachments/registered-asset'),
        registeredMetadata({
          parentKey: 'assetId',
          parentId: 'asset-1',
          idKey: 'resourceId',
          id: 'registered-asset',
          storagePath: assetPath('asset-1', 'attachments', 'registered-asset'),
          extra: { resourceKind: 'attachments' },
        }),
      ),
      setDoc(doc(firestore, 'stockItems/laptop'), { name: 'Laptop' }),
      setDoc(
        doc(firestore, 'stockSupportingDocuments/registered-stock'),
        registeredMetadata({
          parentKey: 'stockItemId',
          parentId: 'laptop',
          idKey: 'attachmentId',
          id: 'registered-stock',
          storagePath: stockPath('laptop', 'registered-stock'),
        }),
      ),
      setDoc(doc(firestore, 'supplierContracts/contract-1'), {
        contractNumber: 'CON-001',
      }),
      setDoc(
        doc(
          firestore,
          'supplierContracts/contract-1/attachments/registered-contract',
        ),
        registeredMetadata({
          parentKey: 'contractId',
          parentId: 'contract-1',
          idKey: 'attachmentId',
          id: 'registered-contract',
          storagePath: contractPath('contract-1', 'registered-contract'),
        }),
      ),
      setDoc(doc(firestore, 'warranties/warranty-1'), {
        warrantyNumber: 'WAR-001',
      }),
      setDoc(
        doc(
          firestore,
          'warranties/warranty-1/attachments/registered-warranty',
        ),
        registeredMetadata({
          parentKey: 'warrantyId',
          parentId: 'warranty-1',
          idKey: 'attachmentId',
          id: 'registered-warranty',
          storagePath: warrantyPath('warranty-1', 'registered-warranty'),
        }),
      ),
    ]);
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    const storage = context.storage();
    await Promise.all([
      upload(
        storage,
        assetPath('asset-1', 'attachments', 'registered-asset'),
        assetMetadata('asset-1', 'attachments', 'registered-asset'),
      ),
      upload(
        storage,
        assetPath('asset-1', 'attachments', 'unregistered-asset'),
        assetMetadata('asset-1', 'attachments', 'unregistered-asset'),
      ),
      upload(
        storage,
        stockPath('laptop', 'registered-stock'),
        stockMetadata('laptop', 'registered-stock'),
      ),
      upload(
        storage,
        contractPath('contract-1', 'registered-contract'),
        contractMetadata('contract-1', 'registered-contract'),
      ),
      upload(
        storage,
        warrantyPath('warranty-1', 'registered-warranty'),
        warrantyMetadata('warranty-1', 'registered-warranty'),
      ),
    ]);
  });
});

after(async () => environment.cleanup());

test('asset files are MANAGER-only and unreadable before registration', async () => {
  const registeredPath = assetPath(
    'asset-1',
    'attachments',
    'registered-asset',
  );
  await assertSucceeds(
    getBytes(ref(storageFor('manager-1'), registeredPath)),
  );
  await assertFails(getBytes(ref(storageFor('user-1'), registeredPath)));
  await assertFails(getBytes(ref(storageFor('admin-1'), registeredPath)));
  await assertFails(getBytes(ref(
    storageFor('manager-1'),
    assetPath('asset-1', 'attachments', 'unregistered-asset'),
  )));
});

test('asset create verifies role, parent, path metadata, and photograph type', async () => {
  await assertSucceeds(upload(
    storageFor('manager-1'),
    assetPath('asset-1', 'attachments', 'new-asset'),
    assetMetadata('asset-1', 'attachments', 'new-asset'),
  ));
  await assertFails(upload(
    storageFor('user-1'),
    assetPath('asset-1', 'attachments', 'user-forgery'),
    assetMetadata('asset-1', 'attachments', 'user-forgery', 'user-1'),
  ));
  await assertFails(upload(
    storageFor('manager-1'),
    assetPath('missing-asset', 'attachments', 'missing-parent'),
    assetMetadata('missing-asset', 'attachments', 'missing-parent'),
  ));
  await assertFails(upload(
    storageFor('manager-1'),
    assetPath('asset-1', 'attachments', 'forged-parent'),
    assetMetadata('other-asset', 'attachments', 'forged-parent'),
  ));
  await assertFails(upload(
    storageFor('manager-1'),
    assetPath('asset-1', 'photographs', 'not-an-image'),
    assetMetadata('asset-1', 'photographs', 'not-an-image'),
  ));
});

test('asset reads begin only after exact immutable metadata registration', async () => {
  const objectPath = assetPath('asset-1', 'attachments', 'pending');
  const managerStorage = storageFor('manager-1');
  await assertSucceeds(upload(
    managerStorage,
    objectPath,
    assetMetadata('asset-1', 'attachments', 'pending'),
  ));
  await assertFails(getBytes(ref(managerStorage, objectPath)));

  await writeTrustedMetadata(
    'assets/asset-1/attachments/pending',
    registeredMetadata({
      parentKey: 'assetId',
      parentId: 'asset-1',
      idKey: 'resourceId',
      id: 'pending',
      storagePath: objectPath,
      extra: { resourceKind: 'attachments' },
    }),
  );
  await assertSucceeds(getBytes(ref(managerStorage, objectPath)));

  await writeTrustedMetadata(
    'assets/asset-1/attachments/pending',
    registeredMetadata({
      parentKey: 'assetId',
      parentId: 'asset-1',
      idKey: 'resourceId',
      id: 'pending',
      storagePath: assetPath('asset-1', 'attachments', 'other'),
      extra: { resourceKind: 'attachments' },
    }),
  );
  await assertFails(getBytes(ref(managerStorage, objectPath)));
});

test('stock, contract, and warranty files require exact registered metadata', async () => {
  const manager = storageFor('manager-1');
  const governedPaths = [
    stockPath('laptop', 'registered-stock'),
    contractPath('contract-1', 'registered-contract'),
    warrantyPath('warranty-1', 'registered-warranty'),
  ];
  for (const objectPath of governedPaths) {
    await assertSucceeds(getBytes(ref(manager, objectPath)));
    await assertFails(getBytes(ref(storageFor('user-1'), objectPath)));
    await assertFails(getBytes(ref(storageFor('admin-1'), objectPath)));
  }

  const pendingStockPath = stockPath('laptop', 'pending-stock');
  await assertSucceeds(upload(
    manager,
    pendingStockPath,
    stockMetadata('laptop', 'pending-stock'),
  ));
  await assertFails(getBytes(ref(manager, pendingStockPath)));

  await assertFails(upload(
    manager,
    contractPath('missing-contract', 'missing-parent'),
    contractMetadata('missing-contract', 'missing-parent'),
  ));
  await assertFails(upload(
    manager,
    warrantyPath('missing-warranty', 'missing-parent'),
    warrantyMetadata('missing-warranty', 'missing-parent'),
  ));
  await assertFails(upload(
    manager,
    contractPath('contract-1', 'forged-contract'),
    contractMetadata('other-contract', 'forged-contract'),
  ));
  await assertFails(upload(
    manager,
    warrantyPath('warranty-1', 'forged-warranty'),
    warrantyMetadata('other-warranty', 'forged-warranty'),
  ));
});

test('all governed files are immutable after upload', async () => {
  const manager = storageFor('manager-1');
  const objects = [
    [
      assetPath('asset-1', 'attachments', 'registered-asset'),
      assetMetadata('asset-1', 'attachments', 'registered-asset'),
    ],
    [
      stockPath('laptop', 'registered-stock'),
      stockMetadata('laptop', 'registered-stock'),
    ],
    [
      contractPath('contract-1', 'registered-contract'),
      contractMetadata('contract-1', 'registered-contract'),
    ],
    [
      warrantyPath('warranty-1', 'registered-warranty'),
      warrantyMetadata('warranty-1', 'registered-warranty'),
    ],
  ];
  for (const [objectPath, metadata] of objects) {
    await assertFails(upload(manager, objectPath, metadata));
    await assertFails(deleteObject(ref(manager, objectPath)));
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

function upload(storage, objectPath, customMetadata) {
  return uploadBytes(
    ref(storage, objectPath),
    new Uint8Array([1, 2, 3]),
    { contentType: 'application/pdf', customMetadata },
  );
}

function assetPath(assetId, resourceKind, resourceId) {
  return `itsm/assets/${assetId}/${resourceKind}/${resourceId}/file.pdf`;
}

function stockPath(stockItemId, attachmentId) {
  return `itsm/stock/${stockItemId}/supportingDocuments/${attachmentId}/file.pdf`;
}

function contractPath(contractId, attachmentId) {
  return `itsm/contracts/${contractId}/attachments/${attachmentId}/file.pdf`;
}

function warrantyPath(warrantyId, attachmentId) {
  return `itsm/warranties/${warrantyId}/attachments/${attachmentId}/file.pdf`;
}

function assetMetadata(
  assetId,
  resourceKind,
  resourceId,
  uploadedByUserId = 'manager-1',
) {
  return {
    assetId,
    resourceKind,
    resourceId,
    uploadedByUserId,
    isInternal: 'true',
  };
}

function stockMetadata(stockItemId, attachmentId) {
  return { stockItemId, attachmentId, uploadedByUserId: 'manager-1' };
}

function contractMetadata(contractId, attachmentId) {
  return { contractId, attachmentId, uploadedByUserId: 'manager-1' };
}

function warrantyMetadata(warrantyId, attachmentId) {
  return { warrantyId, attachmentId, uploadedByUserId: 'manager-1' };
}

function registeredMetadata({
  parentKey,
  parentId,
  idKey,
  id,
  storagePath,
  extra = {},
}) {
  return {
    [parentKey]: parentId,
    [idKey]: id,
    ...extra,
    storagePath,
    fileName: 'file.pdf',
    contentType: 'application/pdf',
    sizeBytes: 3,
    uploadedByUserId: 'manager-1',
    storageGeneration: '1',
    registrationKey: `registered-${id}`,
  };
}

async function writeTrustedMetadata(documentPath, data) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), documentPath), data);
  });
}

function agent(role) {
  return {
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}
