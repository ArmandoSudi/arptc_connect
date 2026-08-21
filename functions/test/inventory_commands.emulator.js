'use strict';

const assert = require('node:assert/strict');
const { after, test } = require('node:test');
const { deleteApp, initializeApp } = require('firebase-admin/app');
const {
  FieldValue,
  Timestamp,
  getFirestore,
} = require('firebase-admin/firestore');

const {
  INVENTORY_COMMANDS,
  InventoryCommandError,
  balanceDocumentId,
  executeInventoryCommand,
} = require('../src/inventory_service');

const projectId = process.env.GCLOUD_PROJECT ||
  'demo-arptc-connect-inventory-commands';
const app = initializeApp({ projectId }, 'inventory-commands-emulator');
const db = getFirestore(app);

after(async () => deleteApp(app));

test('warehouse configuration creates and updates through a real transaction',
  async () => {
    const created = await executeInventoryCommand(commandContext({
      commandId: 'warehouse-create-command',
      code: 'MAIN',
      name: 'Main warehouse',
      address: 'Head office',
      isActive: true,
    }));

    assert.ok(created.entityId);
    const reference = db.collection('inventoryWarehouses').doc(created.entityId);
    const first = await reference.get();
    assert.equal(first.data().code, 'MAIN');
    assert.equal(first.data().name, 'Main warehouse');
    assert.equal(first.data().address, 'Head office');

    const updated = await executeInventoryCommand(commandContext({
      commandId: 'warehouse-update-command',
      id: created.entityId,
      code: 'MAIN',
      name: 'Central warehouse',
      address: 'Head office, building A',
      isActive: false,
    }));

    assert.equal(updated.entityId, created.entityId);
    const second = await reference.get();
    assert.equal(second.data().name, 'Central warehouse');
    assert.equal(second.data().isActive, false);
  });

test('inventory parameter types create and update through real transactions',
  async () => {
    const parameterTypes = [
      ['category', 'Office supplies'],
      ['unit_of_measure', 'Box'],
      ['item_type', 'Consumable'],
    ];

    for (const [type, name] of parameterTypes) {
      const created = await executeInventoryCommand(parameterContext({
        commandId: `${type}-create-command`,
        type,
        name,
        isActive: true,
      }));

      assert.ok(created.entityId);
      const reference = db.collection('inventoryParameters').doc(created.entityId);
      const first = await reference.get();
      assert.equal(first.data().type, type);
      assert.equal(first.data().name, name);
      assert.equal(first.data().nameLower, name.toLowerCase());
      assert.equal(first.data().isActive, true);

      const updated = await executeInventoryCommand(parameterContext({
        commandId: `${type}-update-command`,
        id: created.entityId,
        type,
        name: `${name} updated`,
        isActive: false,
      }));

      assert.equal(updated.entityId, created.entityId);
      const second = await reference.get();
      assert.equal(second.data().type, type);
      assert.equal(second.data().name, `${name} updated`);
      assert.equal(second.data().isActive, false);
    }
  });

test('location configuration retains its warehouse relationship', async () => {
  const warehouseId = 'location-test-warehouse';
  await db.collection('inventoryWarehouses').doc(warehouseId).set({
    code: 'MAIN',
    name: 'Main warehouse',
    address: 'Head office',
    isActive: true,
  });

  const created = await executeInventoryCommand(locationContext({
    commandId: 'location-create-command',
    warehouseId,
    code: 'A-01',
    name: 'Shelf A-01',
    isActive: true,
  }));

  assert.ok(created.entityId);
  const reference = db.collection('inventoryLocations').doc(created.entityId);
  const location = await reference.get();
  assert.equal(location.data().warehouseId, warehouseId);
  assert.equal(location.data().warehouseName, 'Main warehouse');
  assert.equal(location.data().code, 'A-01');
  assert.equal(location.data().name, 'Shelf A-01');
  assert.equal(location.data().isActive, true);
});

test('item creation writes its projection, opening balance, and SKU lock',
  async () => {
    const locationId = 'item-test-location';
    await db.collection('inventoryLocations').doc(locationId).set({
      warehouseId: 'location-test-warehouse',
      warehouseName: 'Main warehouse',
      code: 'A-02',
      name: 'Shelf A-02',
      nameLower: 'shelf a-02',
      isActive: true,
    });

    const created = await executeInventoryCommand(itemContext({
      commandId: 'item-create-command',
      sku: 'PAPER-A4',
      name: 'A4 paper',
      description: 'A4 printing paper',
      categoryId: 'office-supplies',
      categoryName: 'Office supplies',
      unitOfMeasureId: 'ream',
      unitOfMeasureName: 'Ream',
      itemTypeId: 'consumable',
      itemTypeName: 'Consumable',
      isRequestable: true,
      isActive: true,
      openingBalances: [{
        locationId,
        quantityMilli: 10000,
        thresholdMilli: 2000,
        reason: 'Opening balance',
      }],
    }));

    assert.ok(created.itemId);
    const item = await db.collection('inventoryItems').doc(created.itemId).get();
    assert.equal(item.data().sku, 'PAPER-A4');
    assert.equal(item.data().categoryName, 'Office supplies');

    const balance = await db.collection('inventoryBalances')
      .doc(balanceDocumentId(created.itemId, locationId)).get();
    assert.equal(balance.data().onHandMilli, 10000);
    assert.equal(balance.data().availableMilli, 10000);
    assert.equal(balance.data().thresholdMilli, 2000);

    const projection = await db.collection('inventoryCatalogProjections')
      .doc(created.itemId).get();
    assert.equal(projection.data().availability, 'available');
    assert.equal(projection.data().isRequestable, true);

    const duplicatePayload = {
      commandId: 'item-duplicate-sku-command',
      sku: 'paper-a4',
      name: 'Duplicate A4 paper',
      description: '',
      categoryId: 'office-supplies',
      categoryName: 'Office supplies',
      unitOfMeasureId: 'ream',
      unitOfMeasureName: 'Ream',
      itemTypeId: 'consumable',
      itemTypeName: 'Consumable',
      isRequestable: true,
      isActive: true,
      openingBalances: [],
    };
    await assert.rejects(
      executeInventoryCommand(itemContext(duplicatePayload)),
      (error) => error instanceof InventoryCommandError &&
        error.code === 'already-exists',
    );
  });

test('starting review assigns the manager and advances the request', async () => {
  const requestId = 'start-review-request';
  await db.collection('materialRequests').doc(requestId).set({
    requestNumber: 'MAT-2026-000001',
    status: 'submitted',
    assignedManager: null,
    requestedFor: {
      userId: 'user-1',
      name: 'Inventory User',
      email: 'user@example.com',
    },
  });

  const result = await executeInventoryCommand(startReviewContext({
    commandId: 'start-review-command',
    requestId,
  }));

  assert.equal(result.requestId, requestId);
  assert.equal(result.status, 'under_review');
  const request = await db.collection('materialRequests').doc(requestId).get();
  assert.equal(request.data().status, 'under_review');
  assert.equal(request.data().assignedManager.userId, 'manager-1');
  assert.equal(request.data().assignedManager.role, 'MANAGER');

  const requestAudit = await db.collection('materialRequests').doc(requestId)
    .collection('auditLogs').get();
  assert.equal(requestAudit.size, 1);
  assert.equal(requestAudit.docs[0].data().action, 'REQUEST_REVIEW_STARTED');
});

function commandContext(payload) {
  return {
    command: INVENTORY_COMMANDS.saveWarehouse,
    payload,
    actor: {
      userId: 'manager-1',
      name: 'Inventory Manager',
      email: 'manager@example.com',
      role: 'MANAGER',
      organizationId: 'org-1',
      departmentId: 'department-1',
      departmentName: 'Logistics',
      serviceId: 'service-1',
      serviceName: 'Inventory',
      bureauId: 'bureau-1',
      bureauName: 'Warehouse',
    },
    db,
    fieldValue: FieldValue,
    timestamp: Timestamp,
  };
}

function parameterContext(payload) {
  return {
    ...commandContext(payload),
    command: INVENTORY_COMMANDS.saveParameter,
  };
}

function locationContext(payload) {
  return {
    ...commandContext(payload),
    command: INVENTORY_COMMANDS.saveLocation,
  };
}

function itemContext(payload) {
  return {
    ...commandContext(payload),
    command: INVENTORY_COMMANDS.saveItem,
  };
}

function startReviewContext(payload) {
  return {
    ...commandContext(payload),
    command: INVENTORY_COMMANDS.startReview,
  };
}
