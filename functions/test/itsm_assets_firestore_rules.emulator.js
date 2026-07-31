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
  Timestamp,
  collection,
  doc,
  documentId,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const projectId = 'demo-arptc-connect-itsm';
const rules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const occurredAt = Timestamp.fromDate(new Date('2026-07-01T10:00:00Z'));
    await Promise.all([
      setDoc(doc(firestore, 'agents/user-1'), agent('USER')),
      setDoc(doc(firestore, 'agents/user-2'), agent('USER')),
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'assets/asset-user-1'), asset('user-1')),
      setDoc(doc(firestore, 'assets/asset-user-2'), asset('user-2')),
      setDoc(doc(firestore, 'assets/asset-admin'), asset('admin-1')),
      setDoc(doc(firestore, 'assetSelfServiceProjections/projection-user-1'), {
        assetId: 'asset-user-1',
        assetTag: 'TAG-user-1',
        displayName: 'Assigned laptop',
        assignedUserId: 'user-1',
        isCurrent: true,
        assignedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'assetSelfServiceProjections/projection-user-2'), {
        assetId: 'asset-user-2',
        assetTag: 'TAG-user-2',
        displayName: 'Other laptop',
        assignedUserId: 'user-2',
        isCurrent: true,
        assignedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'assetSelfServiceProjections/projection-admin'), {
        assetId: 'asset-admin',
        assetTag: 'TAG-admin-1',
        displayName: 'Admin laptop',
        assignedUserId: 'admin-1',
        isCurrent: true,
        assignedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'assetSelfServiceProjections/projection-history'), {
        assetId: 'retired-asset',
        assetTag: 'TAG-retired',
        displayName: 'Returned laptop',
        assignedUserId: 'user-1',
        isCurrent: false,
        assignedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'assetAssignments/current-user-1'), {
        assetId: 'asset-user-1',
        assignedUserId: 'user-1',
        isCurrent: true,
        assignedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'assetAssignments/history-user-1'), {
        assetId: 'retired-asset',
        assignedUserId: 'user-1',
        isCurrent: false,
        assignedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'assetLifecycleEvents/event-1'), {
        assetId: 'asset-user-1',
        fromStatus: 'configured',
        toStatus: 'assigned',
        occurredAt,
      }),
      setDoc(doc(firestore, 'stockLocations/main'), { name: 'Main' }),
      setDoc(doc(firestore, 'stockItems/laptop'), {
        name: 'Laptop',
        quantityOnHand: 4,
      }),
      setDoc(doc(firestore, 'stockMovements/movement-1'), {
        stockItemId: 'laptop',
        movementType: 'receipt',
        quantity: 4,
        occurredAt,
      }),
      setDoc(doc(firestore, 'stockSupportingDocuments/evidence-1'), {
        attachmentId: 'evidence-1',
        stockItemId: 'laptop',
        storagePath:
          'itsm/stock/laptop/supportingDocuments/evidence-1/file.pdf',
        fileName: 'file.pdf',
        contentType: 'application/pdf',
        sizeBytes: 3,
        checksum: 'fixture-checksum',
      }),
      setDoc(doc(firestore, 'softwareLicences/licence-1'), {
        productName: 'Office',
        purchasedQuantity: 20,
        allocatedQuantity: 3,
        updatedAt: occurredAt,
        expiryDate: occurredAt,
      }),
      setDoc(
        doc(firestore, 'softwareLicences/licence-1/allocations/allocation-1'),
        {
          licenceId: 'licence-1',
          assigneeId: 'user-1',
          status: 'active',
          allocatedAt: occurredAt,
        },
      ),
      setDoc(doc(firestore, 'softwareLicences/licence-1/history/history-1'), {
        action: 'allocated',
        actor: { userId: 'manager-1' },
        occurredAt,
      }),
      setDoc(
        doc(firestore, 'softwareLicences/licence-1/assignments/legacy-1'),
        { assignedUserId: 'user-1', assignedAt: occurredAt },
      ),
      setDoc(doc(firestore, 'suppliers/supplier-1'), { name: 'Vendor' }),
      setDoc(doc(firestore, 'supplierContracts/contract-1'), {
        supplierId: 'supplier-1',
        updatedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'warranties/warranty-1'), {
        supplierId: 'supplier-1',
        status: 'active',
        isActive: true,
        expirationDate: occurredAt,
      }),
      setDoc(doc(firestore, 'warranties/warranty-1/claims/claim-1'), {
        warrantyId: 'warranty-1',
        assetId: 'asset-user-1',
        status: 'submitted',
        updatedAt: occurredAt,
      }),
      setDoc(
        doc(
          firestore,
          'warranties/warranty-1/claims/claim-1/history/history-1',
        ),
        {
          action: 'submitted',
          actor: { userId: 'manager-1' },
          occurredAt,
        },
      ),
      setDoc(doc(firestore, 'warrantyClaims/legacy-claim'), {
        warrantyId: 'warranty-1',
      }),
      setDoc(doc(firestore, 'configurationItems/server-1'), {
        name: 'Server 1',
        ciType: 'server',
        updatedAt: occurredAt,
      }),
      setDoc(doc(firestore, 'ciRelationships/relationship-1'), {
        sourceEntityType: 'configuration_item',
        sourceEntityId: 'server-1',
        relationshipType: 'connected_to',
        targetEntityType: 'configuration_item',
        targetEntityId: 'switch-1',
        createdAt: occurredAt,
      }),
    ]);
  });
});

after(async () => environment.cleanup());

test('authoritative assets are MANAGER-only', async () => {
  const user = firestoreFor('user-1');
  await assertFails(getDoc(doc(user, 'assets/asset-user-1')));
  await assertFails(getDoc(doc(user, 'assets/asset-user-2')));
  await assertFails(getDocs(query(collection(user, 'assets'), limit(25))));

  const admin = firestoreFor('admin-1');
  await assertFails(getDoc(doc(admin, 'assets/asset-admin')));
  await assertFails(getDoc(doc(admin, 'assets/asset-user-1')));

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDoc(doc(manager, 'assets/asset-user-1')));
  await assertSucceeds(getDocs(query(collection(manager, 'assets'), limit(25))));
});

test('self-service asset projections are current and owner scoped', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(
    getDoc(doc(user, 'assetSelfServiceProjections/projection-user-1')),
  );
  await assertFails(
    getDoc(doc(user, 'assetSelfServiceProjections/projection-user-2')),
  );
  await assertFails(
    getDoc(doc(user, 'assetSelfServiceProjections/projection-history')),
  );
  const ownResults = await assertSucceeds(getDocs(query(
    collection(user, 'assetSelfServiceProjections'),
    where('assignedUserId', '==', 'user-1'),
    where('isCurrent', '==', true),
    orderBy('assignedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  if (ownResults.size !== 1) {
    throw new Error(`Expected one safe projection, got ${ownResults.size}`);
  }
  await assertFails(getDocs(query(
    collection(user, 'assetSelfServiceProjections'),
    where('assignedUserId', '==', 'user-1'),
    limit(25),
  )));
  await assertFails(getDocs(query(
    collection(user, 'assetSelfServiceProjections'),
    where('isCurrent', '==', true),
    limit(25),
  )));

  const admin = firestoreFor('admin-1');
  await assertSucceeds(
    getDoc(doc(admin, 'assetSelfServiceProjections/projection-admin')),
  );
  await assertFails(
    getDoc(doc(admin, 'assetSelfServiceProjections/projection-user-1')),
  );

  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDocs(query(
    collection(manager, 'assetSelfServiceProjections'),
    orderBy('assignedAt', 'desc'),
    limit(25),
  )));
});

test('self-service assignment access is current and owner scoped', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(
    getDoc(doc(user, 'assetAssignments/current-user-1')),
  );
  await assertFails(
    getDoc(doc(user, 'assetAssignments/history-user-1')),
  );
  await assertSucceeds(
    getDocs(query(
      collection(user, 'assetAssignments'),
      where('assignedUserId', '==', 'user-1'),
      where('isCurrent', '==', true),
      orderBy('assignedAt', 'desc'),
      orderBy(documentId(), 'desc'),
      limit(25),
    )),
  );
});

test('MANAGER reads operational collections while USER and ADMIN cannot', async () => {
  const manager = firestoreFor('manager-1');
  const protectedPaths = [
    'assetLifecycleEvents/event-1',
    'stockLocations/main',
    'stockItems/laptop',
    'stockMovements/movement-1',
    'stockSupportingDocuments/evidence-1',
    'softwareLicences/licence-1',
    'softwareLicences/licence-1/allocations/allocation-1',
    'softwareLicences/licence-1/history/history-1',
    'suppliers/supplier-1',
    'supplierContracts/contract-1',
    'warranties/warranty-1',
    'warranties/warranty-1/claims/claim-1',
    'warranties/warranty-1/claims/claim-1/history/history-1',
    'configurationItems/server-1',
    'ciRelationships/relationship-1',
  ];
  for (const resourcePath of protectedPaths) {
    await assertSucceeds(getDoc(doc(manager, resourcePath)));
    await assertFails(getDoc(doc(firestoreFor('user-1'), resourcePath)));
    await assertFails(getDoc(doc(firestoreFor('admin-1'), resourcePath)));
  }
  await assertFails(
    getDoc(doc(manager, 'softwareLicences/licence-1/assignments/legacy-1')),
  );
  await assertFails(getDoc(doc(manager, 'warrantyClaims/legacy-claim')));
});

test('MANAGER bounded queries match canonical fields and index order', async () => {
  const manager = firestoreFor('manager-1');
  await assertSucceeds(getDocs(query(
    collection(manager, 'assetLifecycleEvents'),
    where('assetId', '==', 'asset-user-1'),
    orderBy('occurredAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'ciRelationships'),
    where('sourceEntityId', '==', 'server-1'),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'ciRelationships'),
    where('targetEntityId', '==', 'switch-1'),
    orderBy('createdAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'assets'),
    where('searchTokens', 'array-contains', 'user'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  await assertSucceeds(getDocs(query(
    collection(manager, 'warranties'),
    orderBy('expirationDate', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
});

test('all Phase 3 client mutations are denied, including MANAGER writes', async () => {
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertFails(updateDoc(doc(firestore, 'assets/asset-user-1'), {
      status: 'disposed',
    }));
    await assertFails(setDoc(doc(
      firestore,
      'assetSelfServiceProjections/forged',
    ), {
      assetId: 'asset-user-1',
      assignedUserId: uid,
      isCurrent: true,
    }));
    await assertFails(setDoc(doc(
      firestore,
      'assets/asset-user-1/attachments/forged',
    ), {
      assetId: 'asset-user-1',
      storagePath: 'itsm/assets/asset-user-1/attachments/forged/file.pdf',
    }));
    await assertFails(setDoc(doc(
      firestore,
      'supplierContracts/contract-1/attachments/forged',
    ), {
      contractId: 'contract-1',
      storagePath:
        'itsm/contracts/contract-1/attachments/forged/file.pdf',
    }));
    await assertFails(setDoc(doc(
      firestore,
      'warranties/warranty-1/attachments/forged',
    ), {
      warrantyId: 'warranty-1',
      storagePath:
        'itsm/warranties/warranty-1/attachments/forged/file.pdf',
    }));
    await assertFails(updateDoc(doc(firestore, 'stockItems/laptop'), {
      quantityOnHand: 999,
    }));
    await assertFails(setDoc(doc(firestore, 'stockMovements/forged'), {
      movementType: 'adjustment',
      quantity: 999,
      actorUserId: uid,
    }));
    await assertFails(setDoc(doc(
      firestore,
      'stockSupportingDocuments/forged',
    ), {
      stockItemId: 'laptop',
      storagePath: 'itsm/stock/laptop/forged.pdf',
    }));
    await assertFails(setDoc(doc(
      firestore,
      'softwareLicences/licence-1/allocations/forged',
    ), {
      licenceId: 'licence-1',
      assigneeId: uid,
    }));
    await assertFails(setDoc(doc(
      firestore,
      'warranties/warranty-1/claims/claim-1/history/forged',
    ), {
      action: 'forged',
    }));
    await assertFails(setDoc(doc(firestore, 'ciRelationships/forged'), {
      sourceEntityId: 'server-1',
      relationshipType: 'depends_on',
      targetEntityId: 'server-1',
    }));
  }
});

function firestoreFor(uid) {
  return environment
    .authenticatedContext(uid, { email: `${uid}@arptc.cd` })
    .firestore();
}

function agent(role) {
  return {
    email: '',
    modulePermissions: { ticketing: role },
  };
}

function asset(assignedUserId) {
  return {
    assetTag: `TAG-${assignedUserId}`,
    assignedUserId,
    assignedUserEmail: `${assignedUserId}@arptc.cd`,
    status: 'assigned',
    categoryId: 'computer',
    locationId: 'head-office',
    searchTokens: ['user', assignedUserId],
    updatedAt: Timestamp.fromDate(new Date('2026-07-01T10:00:00Z')),
  };
}
