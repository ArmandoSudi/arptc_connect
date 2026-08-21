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
  deleteDoc,
  doc,
  documentId,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  setDoc,
  where,
} = require('firebase/firestore');

const projectId = 'demo-arptc-connect-inventory-firestore';
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
    const updatedAt = Timestamp.fromDate(new Date('2026-08-19T10:00:00Z'));
    await Promise.all([
      setDoc(doc(firestore, 'agents/user-1'), agent('USER')),
      setDoc(doc(firestore, 'agents/user-2'), agent('USER')),
      setDoc(doc(firestore, 'agents/manager-1'), agent('MANAGER')),
      setDoc(doc(firestore, 'agents/admin-1'), agent('ADMIN')),
      setDoc(doc(firestore, 'agents/legacy-manager'), {
        isActive: true,
        modulePermissions: { inventaire: 'MANAGER' },
      }),
      setDoc(doc(firestore, 'agents/unrelated-manager'), {
        isActive: true,
        modulePermissions: { ticketing: 'MANAGER' },
      }),
      setDoc(doc(firestore, 'agents/inactive-manager'), {
        ...agent('MANAGER'),
        isActive: false,
      }),
      setDoc(doc(firestore, 'inventoryCatalogProjections/available'), {
        isActive: true,
        isRequestable: true,
        nameLower: 'paper',
        categoryId: 'office',
      }),
      setDoc(doc(firestore, 'inventoryCatalogProjections/inactive'), {
        isActive: false,
        isRequestable: true,
        nameLower: 'retired paper',
        categoryId: 'office',
      }),
      setDoc(doc(firestore, 'inventoryCatalogProjections/internal'), {
        isActive: true,
        isRequestable: false,
        nameLower: 'internal stock',
        categoryId: 'office',
      }),
      setDoc(doc(firestore, 'inventoryItems/item-1'), {
        name: 'Paper',
        nameLower: 'paper',
        isActive: true,
      }),
      setDoc(doc(firestore, 'inventoryWarehouses/main'), {
        name: 'Main warehouse',
        nameLower: 'main warehouse',
        isActive: true,
      }),
      setDoc(doc(firestore, 'inventoryLocations/shelf-a'), {
        name: 'Shelf A',
        nameLower: 'shelf a',
        warehouseId: 'main',
        isActive: true,
      }),
      setDoc(doc(firestore, 'inventoryParameters/category-office'), {
        type: 'category',
        name: 'Office',
        nameLower: 'office',
        isActive: true,
      }),
      setDoc(doc(firestore, 'inventoryBalances/item-1-shelf-a'), {
        itemId: 'item-1',
        itemNameLower: 'paper',
        warehouseId: 'main',
        onHandMilli: 10000,
        reservedMilli: 2000,
        updatedAt,
      }),
      setDoc(doc(firestore, 'inventoryStockMovements/movement-1'), {
        itemId: 'item-1',
        type: 'receipt',
        quantityMilli: 10000,
        createdAt: updatedAt,
      }),
      setDoc(doc(firestore, 'materialRequests/own'), materialRequest('user-1', updatedAt)),
      setDoc(doc(firestore, 'materialRequests/other'), materialRequest('user-2', updatedAt)),
      setDoc(doc(firestore, 'materialRequests/admin-own'), materialRequest('admin-1', updatedAt)),
      setDoc(doc(firestore, 'materialRequests/own/lines/line-1'), {
        itemId: 'item-1',
        itemNameLower: 'paper',
      }),
      setDoc(doc(firestore, 'materialRequests/other/allocations/allocation-1'), {
        itemId: 'item-1',
        balanceId: 'item-1-shelf-a',
      }),
      setDoc(doc(firestore, 'materialRequests/other/auditLogs/audit-1'), {
        action: 'request.submitted',
        createdAt: updatedAt,
      }),
      setDoc(doc(firestore, 'inventoryAlerts/alert-1'), {
        isActive: true,
        triggeredAt: updatedAt,
      }),
      setDoc(doc(firestore, 'inventoryAuditEvents/audit-1'), {
        action: 'stock.received',
        createdAt: updatedAt,
      }),
      setDoc(doc(firestore, 'inventoryDashboardSnapshots/manager'), {
        submittedCount: 1,
        updatedAt,
      }),
      setDoc(doc(firestore, 'inventorySupportingDocuments/own-document'), {
        requestId: 'own',
        storagePath: 'inventory/requests/own/attachments/a/file.pdf',
      }),
      setDoc(doc(firestore, 'inventorySupportingDocuments/other-document'), {
        requestId: 'other',
        storagePath: 'inventory/requests/other/attachments/b/file.pdf',
      }),
      setDoc(doc(firestore, 'inventoryCommandReceipts/command-1'), {
        command: 'inventoryReceiveStock',
      }),
      setDoc(doc(firestore, 'inventoryItemSkuLocks/paper-a4'), {
        itemId: 'item-1',
      }),
    ]);
  });
});

after(async () => environment.cleanup());

test('catalogue reads expose only active requestable projections', async () => {
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertSucceeds(
      getDoc(doc(firestore, 'inventoryCatalogProjections/available')),
    );
    await assertFails(
      getDoc(doc(firestore, 'inventoryCatalogProjections/inactive')),
    );
    await assertFails(
      getDoc(doc(firestore, 'inventoryCatalogProjections/internal')),
    );
    await assertSucceeds(getDocs(query(
      collection(firestore, 'inventoryCatalogProjections'),
      where('isActive', '==', true),
      where('isRequestable', '==', true),
      orderBy('nameLower'),
      orderBy(documentId()),
      limit(100),
    )));
    await assertFails(getDocs(query(
      collection(firestore, 'inventoryCatalogProjections'),
      limit(100),
    )));
  }
});

test('raw inventory data is bounded and limited to MANAGER and read-only ADMIN', async () => {
  const operationalPaths = [
    'inventoryItems/item-1',
    'inventoryWarehouses/main',
    'inventoryLocations/shelf-a',
    'inventoryParameters/category-office',
    'inventoryBalances/item-1-shelf-a',
    'inventoryStockMovements/movement-1',
    'inventoryAlerts/alert-1',
    'inventoryAuditEvents/audit-1',
  ];
  for (const resourcePath of operationalPaths) {
    await assertFails(getDoc(doc(firestoreFor('user-1'), resourcePath)));
    await assertSucceeds(getDoc(doc(firestoreFor('manager-1'), resourcePath)));
    await assertSucceeds(getDoc(doc(firestoreFor('admin-1'), resourcePath)));
  }

  for (const uid of ['manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertSucceeds(getDocs(query(
      collection(firestore, 'inventoryItems'),
      orderBy('nameLower'),
      limit(100),
    )));
    await assertFails(getDocs(query(
      collection(firestore, 'inventoryItems'),
      orderBy('nameLower'),
      limit(101),
    )));
    await assertFails(getDocs(collection(firestore, 'inventoryItems')));
  }
});

test('material requests and child records enforce owner isolation', async () => {
  const user = firestoreFor('user-1');
  await assertSucceeds(getDoc(doc(user, 'materialRequests/own')));
  await assertFails(getDoc(doc(user, 'materialRequests/other')));
  await assertSucceeds(getDocs(query(
    collection(user, 'materialRequests'),
    where('requestedFor.userId', '==', 'user-1'),
    orderBy('updatedAt', 'desc'),
    orderBy(documentId(), 'desc'),
    limit(25),
  )));
  await assertFails(getDocs(query(
    collection(user, 'materialRequests'),
    orderBy('updatedAt', 'desc'),
    limit(25),
  )));
  await assertSucceeds(
    getDoc(doc(user, 'materialRequests/own/lines/line-1')),
  );
  await assertFails(
    getDoc(doc(user, 'materialRequests/other/allocations/allocation-1')),
  );
  await assertSucceeds(getDocs(query(
    collection(user, 'materialRequests/own/lines'),
    limit(25),
  )));
  await assertFails(getDocs(collection(user, 'materialRequests/own/lines')));

  for (const uid of ['manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertSucceeds(getDoc(doc(firestore, 'materialRequests/other')));
    await assertSucceeds(
      getDoc(doc(firestore, 'materialRequests/other/auditLogs/audit-1')),
    );
    await assertSucceeds(getDocs(query(
      collection(firestore, 'materialRequests'),
      orderBy('updatedAt', 'desc'),
      limit(100),
    )));
  }
});

test('dashboard and supporting-document metadata follow read-only role scope', async () => {
  await assertFails(
    getDoc(doc(firestoreFor('user-1'), 'inventoryDashboardSnapshots/manager')),
  );
  for (const uid of ['manager-1', 'admin-1']) {
    await assertSucceeds(getDoc(doc(
      firestoreFor(uid),
      'inventoryDashboardSnapshots/manager',
    )));
    await assertFails(getDocs(query(
      collection(firestoreFor(uid), 'inventoryDashboardSnapshots'),
      limit(10),
    )));
  }

  await assertSucceeds(getDoc(doc(
    firestoreFor('user-1'),
    'inventorySupportingDocuments/own-document',
  )));
  await assertFails(getDoc(doc(
    firestoreFor('user-1'),
    'inventorySupportingDocuments/other-document',
  )));
  await assertSucceeds(getDoc(doc(
    firestoreFor('manager-1'),
    'inventorySupportingDocuments/other-document',
  )));
  await assertSucceeds(getDoc(doc(
    firestoreFor('admin-1'),
    'inventorySupportingDocuments/other-document',
  )));
  await assertFails(getDocs(query(
    collection(firestoreFor('manager-1'), 'inventorySupportingDocuments'),
    limit(10),
  )));
});

test('all authoritative Inventory documents reject direct client mutation', async () => {
  const mutationPaths = [
    'inventoryCatalogProjections/available',
    'inventoryItems/item-1',
    'inventoryWarehouses/main',
    'inventoryLocations/shelf-a',
    'inventoryParameters/category-office',
    'inventoryBalances/item-1-shelf-a',
    'inventoryStockMovements/movement-1',
    'materialRequests/own',
    'materialRequests/own/lines/line-1',
    'inventoryAlerts/alert-1',
    'inventoryAuditEvents/audit-1',
    'inventoryDashboardSnapshots/manager',
    'inventorySupportingDocuments/own-document',
    'inventoryCommandReceipts/command-1',
    'inventoryItemSkuLocks/paper-a4',
  ];
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    for (const resourcePath of mutationPaths) {
      await assertFails(setDoc(
        doc(firestore, resourcePath),
        { forgedBy: uid },
        { merge: true },
      ));
    }
    await assertFails(deleteDoc(doc(firestore, 'inventoryItems/item-1')));
  }
});

test('command receipts and SKU locks are server-only', async () => {
  for (const uid of ['user-1', 'manager-1', 'admin-1']) {
    const firestore = firestoreFor(uid);
    await assertFails(
      getDoc(doc(firestore, 'inventoryCommandReceipts/command-1')),
    );
    await assertFails(
      getDoc(doc(firestore, 'inventoryItemSkuLocks/paper-a4')),
    );
  }
});

test('legacy role aliases work while unrelated, inactive, and missing profiles fail', async () => {
  await assertSucceeds(getDoc(doc(
    firestoreFor('legacy-manager'),
    'inventoryItems/item-1',
  )));
  for (const uid of ['unrelated-manager', 'inactive-manager', 'missing-agent']) {
    await assertFails(getDoc(doc(
      firestoreFor(uid),
      'inventoryCatalogProjections/available',
    )));
    await assertFails(getDoc(doc(
      firestoreFor(uid),
      'inventoryItems/item-1',
    )));
  }
  await assertFails(getDoc(doc(
    firestoreFor('manager-1', false),
    'inventoryItems/item-1',
  )));
});

function firestoreFor(uid, emailVerified = true) {
  return environment.authenticatedContext(uid, {
    email: `${uid}@arptc.cd`,
    email_verified: emailVerified,
  }).firestore();
}

function agent(role) {
  return {
    email: '',
    isActive: true,
    modulePermissions: { inventory: role },
  };
}

function materialRequest(userId, updatedAt) {
  return {
    requestNumber: `REQ-${userId}`,
    requestedFor: {
      userId,
      name: userId,
      email: `${userId}@arptc.cd`,
    },
    status: 'submitted',
    updatedAt,
  };
}
