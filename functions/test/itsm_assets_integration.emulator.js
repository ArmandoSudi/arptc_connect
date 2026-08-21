'use strict';

const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');
const { deleteApp, initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

const { executeAssetsCommand } = require('../src/itsm_assets_service');
const {
  ITSM_ASSETS_COMMANDS,
  validateAssetsCommand,
} = require('../src/itsm_assets_validation');

const projectId = 'demo-arptc-connect-itsm';
const manager = Object.freeze({
  uid: 'manager-assets-integration',
  role: 'MANAGER',
  displayName: 'Asset Integration Manager',
  email: 'assets.manager@arptc.cd',
});

let app;
let db;

before(async () => {
  assert.ok(
    process.env.FIRESTORE_EMULATOR_HOST,
    'FIRESTORE_EMULATOR_HOST is required; this suite never connects to production.',
  );
  assert.equal(
    process.env.GCLOUD_PROJECT || projectId,
    projectId,
    'Run this suite only with the demo-arptc-connect-itsm emulator project.',
  );
  app = initializeApp({ projectId }, 'itsm-assets-integration');
  db = getFirestore(app);
});

beforeEach(async () => {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
  await Promise.all([
    db.doc('agents/agent-custodian-1').set({
      firstName: 'Authoritative',
      name: 'Custodian',
      postName: 'Agent',
      email: 'authoritative.custodian@arptc.cd',
      departmentId: 'department-authoritative',
      isActive: true,
    }),
    db.doc('agents/agent-recipient-1').set({
      firstName: 'Authoritative',
      name: 'Stock Recipient',
      email: 'stock.recipient@arptc.cd',
      isActive: true,
    }),
    db.doc('agents/agent-licensed-1').set({
      firstName: 'Authoritative',
      name: 'Licensed Agent',
      email: 'licensed.agent@arptc.cd',
      isActive: true,
    }),
  ]);
});

after(async () => {
  if (app) await deleteApp(app);
});

test('asset register, lifecycle, assignment, and return persist atomically and replay safely', async () => {
  const register = command(ITSM_ASSETS_COMMANDS.registerAsset, 'emulator-asset-register', {
    assetId: 'asset-laptop-1',
    assetTag: 'ARPTC-LAP-001',
    categoryId: 'computers',
    categoryName: 'Computers',
    type: 'laptop',
    brand: 'Framework',
    model: 'Laptop 13',
    serialNumber: 'FW-0001',
    productNumber: 'FW13-2026',
    locationId: 'kinshasa-hq',
    locationName: 'Kinshasa HQ',
    stateId: 'new',
    stateName: 'New',
    acquisitionDate: '2026-08-01',
    condition: 'new',
  });
  const registered = await execute(register);
  assert.deepEqual(registered, {
    assetId: 'asset-laptop-1',
    assignmentId: null,
    status: 'in_stock',
    revision: 0,
  });

  const stateChanged = await execute(command(
    ITSM_ASSETS_COMMANDS.changeAssetState,
    'emulator-asset-state-change',
    {
      assetId: 'asset-laptop-1',
      expectedRevision: 0,
      stateId: 'ready-for-use',
      stateName: 'Ready for use',
      observation: 'Acceptance inspection and diagnostics passed.',
    },
  ));
  assert.equal(stateChanged.revision, 1);

  await assert.rejects(
    () => execute(command(
      ITSM_ASSETS_COMMANDS.transitionAsset,
      'emulator-asset-transition-assigned-bypass',
      {
        assetId: 'asset-laptop-1',
        expectedRevision: 1,
        toStatus: 'assigned',
        reason: 'Attempt to bypass the assignment workflow',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );

  const configured = await execute(command(
    ITSM_ASSETS_COMMANDS.transitionAsset,
    'emulator-asset-transition-configured',
    {
      assetId: 'asset-laptop-1',
      expectedRevision: 1,
      toStatus: 'configured',
      reason: 'Security baseline applied',
      relatedRequestId: 'request-asset-1',
    },
  ));
  assert.equal(configured.revision, 2);
  assert.equal(configured.status, 'configured');

  const assignment = await execute(command(
    ITSM_ASSETS_COMMANDS.assignAsset,
    'emulator-asset-assign',
    {
      assetId: 'asset-laptop-1',
      expectedRevision: 2,
      assignedUserId: 'agent-custodian-1',
      departmentId: 'department-finance',
      locationId: 'kinshasa-hq',
      relatedRequestId: 'request-asset-1',
      evidence: [documentMetadata('signed-handover')],
    },
  ));
  assert.equal(assignment.status, 'assigned');
  assert.equal(assignment.revision, 3);
  const activeProjection = await read(
    'assetSelfServiceProjections/agent-custodian-1_asset-laptop-1',
  );
  assert.equal(activeProjection.assignedUserName, 'Authoritative Custodian Agent');
  assert.equal(activeProjection.isCurrent, true);
  assert.equal(activeProjection.acquisitionCost, undefined);
  assert.equal(activeProjection.supplierId, undefined);
  assert.equal(activeProjection.securityBaselineId, undefined);
  assert.equal(activeProjection.attachmentIds, undefined);

  const lost = await execute(command(
    ITSM_ASSETS_COMMANDS.transitionAsset,
    'emulator-asset-report-lost',
    {
      assetId: 'asset-laptop-1',
      expectedRevision: 3,
      toStatus: 'lost',
      reason: 'Custodian reported the assigned device missing.',
    },
  ));
  assert.equal(lost.status, 'lost');
  assert.equal(lost.revision, 4);
  assert.equal((await read('assets/asset-laptop-1')).assignedUserId, 'agent-custodian-1');
  assert.equal(
    (await read('assetSelfServiceProjections/agent-custodian-1_asset-laptop-1'))
      .isCurrent,
    true,
  );
  assert.equal((await read(`assetAssignments/${assignment.assignmentId}`)).assetStatus, 'lost');

  await assert.rejects(
    () => execute(command(
      ITSM_ASSETS_COMMANDS.transitionAsset,
      'emulator-asset-transition-returned-bypass',
      {
        assetId: 'asset-laptop-1',
        expectedRevision: 4,
        toStatus: 'returned',
        reason: 'Attempt to bypass the return workflow',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );

  const returnCommand = command(ITSM_ASSETS_COMMANDS.returnAsset, 'emulator-asset-return', {
    assetId: 'asset-laptop-1',
    expectedRevision: 4,
    condition: 'good',
    locationId: 'kinshasa-hq',
    stockLocationId: 'stock-main',
    reason: 'Device returned after replacement',
    relatedRequestId: 'request-asset-1',
    evidence: [documentMetadata('return-inspection')],
  });
  const returned = await execute(returnCommand);
  assert.deepEqual(await execute(returnCommand), returned);

  const decommissioned = await execute(command(
    ITSM_ASSETS_COMMANDS.decommissionAsset,
    'emulator-asset-decommission',
    {
      assetId: 'asset-laptop-1',
      expectedRevision: 5,
      observation: 'Device is beyond economical repair.',
    },
  ));
  assert.equal(decommissioned.status, 'retired');
  assert.equal(decommissioned.revision, 6);

  const asset = await read('assets/asset-laptop-1');
  assert.equal(asset.status, 'retired');
  assert.equal(asset.revision, 6);
  assert.equal(asset.isInStock, false);
  assert.equal(asset.assignedUserId, null);
  assert.equal(asset.condition, 'good');
  assert.equal(asset.updatedBy, manager.uid);
  assertTimestamp(asset.createdAt);
  assertTimestamp(asset.updatedAt);
  assert.equal(
    (await read('assetSelfServiceProjections/agent-custodian-1_asset-laptop-1'))
      .isCurrent,
    false,
  );
  assert.equal((await read('assetAssignmentLocks/asset-laptop-1')).isActive, false);
  const assignmentNotifications = await documents('notificationEvents');
  assert.equal(assignmentNotifications.length, 1);
  assert.deepEqual(assignmentNotifications[0].target.userIds, ['agent-custodian-1']);

  const assignmentDocuments = await keyedDocuments('assetAssignments');
  const assignments = [...assignmentDocuments.values()];
  assert.equal(assignments.length, 1);
  assert.equal(assignments[0].status, 'returned');
  assert.equal(assignments[0].isCurrent, false);
  assert.equal(assignments[0].assignedUserId, 'agent-custodian-1');
  assertTimestamp(assignments[0].assignedAt);
  assertTimestamp(assignments[0].returnedAt);
  assert.equal(asset.currentAssignmentId, null);
  assert.ok(assignments.every((entry) => entry.actor.userId === manager.uid));
  assert.ok(assignments.every((entry) => entry.correlationId));

  const lifecycle = await documents('assetLifecycleEvents');
  assert.equal(lifecycle.length, 6);
  assert.deepEqual(
    lifecycle.map((entry) => entry.toStatus).sort(),
    ['assigned', 'configured', 'in_stock', 'lost', 'retired', 'returned'],
  );
  assert.ok(lifecycle.every((entry) => entry.assetId === 'asset-laptop-1'));
  assert.ok(lifecycle.every((entry) => entry.actor.userId === manager.uid));

  const stateHistory = await documents('assetStateEvents');
  assert.equal(stateHistory.length, 2);
  assert.deepEqual(
    stateHistory.map((entry) => entry.toStateId).sort(),
    ['new', 'ready-for-use'],
  );
  assert.ok(stateHistory.every((entry) => entry.observation));

  await assertTrustedArtifacts({ receipts: 7, audits: 7 });
  assert.equal((await documents('assets/asset-laptop-1/auditLogs')).length, 7);
});

test('asset registration can assign an active agent in one atomic command', async () => {
  const result = await execute(command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    'emulator-register-with-assignment',
    {
      assetId: 'asset-direct-assignment',
      assetTag: 'ARPTC-DIRECT-001',
      categoryId: 'computers',
      categoryName: 'Computers',
      type: 'laptop',
      brand: 'Dell',
      model: 'Latitude 7450',
      serialNumber: 'DIRECT-0001',
      productNumber: 'LAT-7450',
      locationId: 'kinshasa-hq',
      locationName: 'Kinshasa HQ',
      stateId: 'new',
      stateName: 'New',
      condition: 'good',
      acquisitionDate: '2026-08-01',
      assignedUserId: 'agent-custodian-1',
      assignedAt: '2026-08-14',
    },
  ));

  assert.equal(result.status, 'assigned');
  assert.equal(result.revision, 0);
  assert.ok(result.assignmentId);
  const asset = await read('assets/asset-direct-assignment');
  assert.equal(asset.status, 'assigned');
  assert.equal(asset.isInStock, false);
  assert.equal(asset.assignedUserId, 'agent-custodian-1');
  assert.equal(asset.assignedUserName, 'Authoritative Custodian Agent');
  assert.equal(asset.currentAssignmentId, result.assignmentId);
  const assignment = await read(`assetAssignments/${result.assignmentId}`);
  assert.equal(assignment.status, 'current');
  assert.equal(assignment.isCurrent, true);
  assertTimestamp(assignment.assignedAt);
  assert.equal(
    (await read('assetAssignmentLocks/asset-direct-assignment')).isActive,
    true,
  );
  const projection = await read(
    'assetSelfServiceProjections/agent-custodian-1_asset-direct-assignment',
  );
  assert.equal(projection.status, 'assigned');
  assert.equal(projection.isCurrent, true);
  assert.equal(projection.assignmentId, result.assignmentId);
  const lifecycle = await documents('assetLifecycleEvents');
  assert.equal(lifecycle.length, 1);
  assert.equal(lifecycle[0].toStatus, 'assigned');
  assert.equal((await documents('notificationEvents')).length, 1);
  await assertTrustedArtifacts({receipts: 1, audits: 1});
  assert.equal(
    (await documents('assets/asset-direct-assignment/auditLogs')).length,
    1,
  );
});

test('asset serials stay unique while product numbers can be shared', async () => {
  const registration = (assetId, serialNumber, productNumber) => command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    `emulator-register-${assetId}`,
    {
      assetId,
      assetTag: serialNumber,
      categoryId: 'computers',
      categoryName: 'Computers',
      type: 'laptop',
      brand: 'Dell',
      model: 'Latitude 7450',
      serialNumber,
      productNumber,
      stateId: 'new',
      stateName: 'New',
      acquisitionDate: '2026-08-01',
    },
  );

  await execute(registration('asset-unique-1', 'SN-UNIQUE-1', 'PN-UNIQUE-1'));
  const asset = await read('assets/asset-unique-1');
  assert.equal(asset.locationId, undefined);
  assert.equal(asset.locationName, undefined);
  assert.equal(asset.serialNumberNormalized, 'sn-unique-1');
  assert.equal(asset.productNumberNormalized, 'pn-unique-1');

  await assert.rejects(
    () => execute(registration('asset-duplicate-serial', 'sn-unique-1', 'PN-OTHER')),
    (error) => error.code === 'already-exists',
  );
  await execute(
    registration('asset-duplicate-product', 'SN-OTHER', 'pn-unique-1'),
  );

  assert.equal((await documents('assets')).length, 2);
  assert.equal((await documents('assetIdentifierLocks')).length, 2);
  await assertTrustedArtifacts({ receipts: 2, audits: 2 });
});

test('legacy assets reject duplicate serials but allow shared product numbers', async () => {
  await db.doc('assets/legacy-asset').set({
    assetTag: 'LEGACY-SN-1',
    serialNumber: 'LEGACY-SN-1',
    productNumber: 'LEGACY-PN-1',
    status: 'in_stock',
    revision: 0,
  });
  const registration = (assetId, serialNumber, productNumber) => command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    `emulator-legacy-${assetId}`,
    {
      assetId,
      assetTag: serialNumber,
      categoryId: 'computers',
      categoryName: 'Computers',
      type: 'laptop',
      brand: 'Dell',
      model: 'Latitude 7450',
      serialNumber,
      productNumber,
      stateId: 'new',
      stateName: 'New',
      acquisitionDate: '2026-08-01',
    },
  );

  await assert.rejects(
    () => execute(registration('duplicate-serial', 'legacy-sn-1', 'NEW-PN')),
    (error) => error.code === 'already-exists',
  );
  await execute(
    registration('duplicate-product', 'NEW-SN', 'legacy-pn-1'),
  );
  assert.equal((await documents('assets')).length, 2);
  assert.equal((await documents('assetIdentifierLocks')).length, 1);
  await assertTrustedArtifacts({ receipts: 1, audits: 1 });
});

test('all stock movement types preserve exact movement history and quantity consistency', async () => {
  for (const [id, name] of [['stock-main', 'Main store'], ['stock-annex', 'Annex store']]) {
    await execute(command(ITSM_ASSETS_COMMANDS.saveStockLocation, `emulator-location-${id}`, {
      id,
      name,
      siteId: 'kinshasa-hq',
      siteName: 'Kinshasa HQ',
    }));
  }
  await execute(command(ITSM_ASSETS_COMMANDS.saveStockItem, 'emulator-stock-item-save', {
    id: 'network-cable',
    sku: 'CAB-NET-001',
    name: 'Network cable',
    kind: 'consumable',
    unitOfMeasure: 'piece',
    minimumQuantity: 2,
  }));
  for (const attachmentId of ['adjustment-approval', 'cycle-count-sheet']) {
    await db.doc(`stockSupportingDocuments/${attachmentId}`).set({
      ...documentMetadata(attachmentId),
      stockItemId: 'network-cable',
      storagePath:
        `itsm/stock/network-cable/supportingDocuments/${attachmentId}/${attachmentId}.pdf`,
    });
  }

  const commands = [
    stockCommand(ITSM_ASSETS_COMMANDS.receiveStock, 'emulator-stock-receipt', {
      quantity: 20,
      destinationLocationId: 'stock-main',
    }),
    stockCommand(ITSM_ASSETS_COMMANDS.reserveStock, 'emulator-stock-reservation', {
      quantity: 5,
      sourceLocationId: 'stock-main',
      recipientUserId: 'agent-recipient-1',
      recipientName: 'Recipient Agent',
    }),
    stockCommand(ITSM_ASSETS_COMMANDS.issueStock, 'emulator-stock-issue', {
      quantity: 7,
      reservedQuantity: 5,
      sourceLocationId: 'stock-main',
      recipientUserId: 'agent-recipient-1',
      recipientName: 'Recipient Agent',
    }),
    stockCommand(ITSM_ASSETS_COMMANDS.returnStock, 'emulator-stock-return', {
      quantity: 2,
      destinationLocationId: 'stock-main',
      recipientUserId: 'agent-recipient-1',
      recipientName: 'Recipient Agent',
    }),
    stockCommand(ITSM_ASSETS_COMMANDS.transferStock, 'emulator-stock-transfer', {
      quantity: 4,
      sourceLocationId: 'stock-main',
      destinationLocationId: 'stock-annex',
    }),
    stockCommand(ITSM_ASSETS_COMMANDS.adjustStock, 'emulator-stock-adjustment', {
      sourceLocationId: 'stock-annex',
      adjustmentDelta: -1,
      supportingDocument: documentMetadata('adjustment-approval'),
    }),
    command(ITSM_ASSETS_COMMANDS.reconcileStock, 'emulator-stock-reconciliation', {
      stockItemId: 'network-cable',
      sourceLocationId: 'stock-annex',
      targetOnHand: 5,
      targetReserved: 1,
      reason: 'Deterministic cycle count',
      relatedRequestId: 'request-stock-1',
      supportingDocument: documentMetadata('cycle-count-sheet'),
      correlationId: 'cycle-count-2026-07',
    }),
  ];

  for (const value of commands) await execute(value);

  const stock = await read('stockItems/network-cable');
  assert.deepEqual(stock.balances, {
    'stock-main': { onHand: 11, reserved: 0 },
    'stock-annex': { onHand: 5, reserved: 1 },
  });
  assert.equal(stock.totalOnHand, 16);
  assert.equal(stock.totalReserved, 1);
  assert.equal(stock.availableQuantity, 15);
  assertTimestamp(stock.lastMovementAt);

  const beforeReplay = await keyedDocuments('stockMovements');
  assert.equal(beforeReplay.size, 7);
  const byType = new Map([...beforeReplay.values()].map((entry) => [entry.movementType, entry]));
  assert.deepEqual([...byType.keys()].sort(), [
    'adjustment',
    'issue',
    'receipt',
    'reconciliation',
    'reservation',
    'return',
    'transfer',
  ]);
  assert.deepEqual(byType.get('receipt').quantityChanges, {
    'stock-main': { onHand: 20, reserved: 0 },
  });
  assert.deepEqual(byType.get('reservation').quantityChanges, {
    'stock-main': { onHand: 0, reserved: 5 },
  });
  assert.deepEqual(byType.get('issue').quantityChanges, {
    'stock-main': { onHand: -7, reserved: -5 },
  });
  assert.deepEqual(byType.get('return').quantityChanges, {
    'stock-main': { onHand: 2, reserved: 0 },
  });
  assert.deepEqual(byType.get('transfer').quantityChanges, {
    'stock-main': { onHand: -4, reserved: 0 },
    'stock-annex': { onHand: 4, reserved: 0 },
  });
  assert.deepEqual(byType.get('adjustment').quantityChanges, {
    'stock-annex': { onHand: -1, reserved: 0 },
  });
  assert.deepEqual(byType.get('reconciliation').quantityChanges, {
    'stock-annex': { onHand: 2, reserved: 1 },
  });
  assert.equal(byType.get('issue').recipient.userId, 'agent-recipient-1');
  assert.equal(
    byType.get('reconciliation').supportingDocument.attachmentId,
    'cycle-count-sheet',
  );
  for (const movement of byType.values()) {
    assert.equal(movement.stockItemId, 'network-cable');
    assert.equal(movement.actorUserId, manager.uid);
    assert.equal(movement.actor.role, 'MANAGER');
    assert.equal(movement.relatedRequestId, 'request-stock-1');
    assert.ok(movement.idempotencyKey.startsWith('emulator-stock-'));
    assertTimestamp(movement.occurredAt);
    assertTimestamp(movement.createdAt);
  }

  for (const value of commands) await execute(value);
  const afterReplay = await keyedDocuments('stockMovements');
  assert.deepEqual(afterReplay, beforeReplay);
  assert.deepEqual(await read('stockItems/network-cable'), stock);
  await assertTrustedArtifacts({ receipts: 10, audits: 10 });
  assert.equal((await documents('stockItems/network-cable/auditLogs')).length, 8);
});

test('failed stock command rolls back balances, movement, receipt, and audit atomically', async () => {
  const original = {
    name: 'Laptop',
    balances: { 'stock-main': { onHand: 2, reserved: 1 } },
    totalOnHand: 2,
    totalReserved: 1,
    availableQuantity: 1,
  };
  await db.doc('stockItems/laptop').set(original);

  await assert.rejects(
    () => execute(stockCommand(ITSM_ASSETS_COMMANDS.issueStock, 'emulator-stock-overissue', {
      stockItemId: 'laptop',
      quantity: 2,
      sourceLocationId: 'stock-main',
      recipientUserId: 'agent-recipient-1',
      recipientName: 'Recipient Agent',
    })),
    (error) => error.code === 'failed-precondition',
  );

  assert.deepEqual(await read('stockItems/laptop'), original);
  await assertTrustedArtifacts({ receipts: 0, audits: 0 });
  assert.equal((await documents('stockMovements')).length, 0);
  assert.equal((await documents('stockItems/laptop/auditLogs')).length, 0);
});

test('low-stock notification is emitted once per threshold episode', async () => {
  await execute(command(ITSM_ASSETS_COMMANDS.saveStockItem, 'emulator-low-item-save', {
    id: 'low-cable',
    sku: 'LOW-CAB-1',
    name: 'Low stock cable',
    kind: 'consumable',
    unitOfMeasure: 'piece',
    minimumQuantity: 3,
  }));
  const move = (type, key, payload) => execute(command(type, key, {
    stockItemId: 'low-cable',
    reason: 'Low-stock integration check',
    ...payload,
  }));
  await move(ITSM_ASSETS_COMMANDS.receiveStock, 'emulator-low-receive-1', {
    quantity: 10,
    destinationLocationId: 'stock-main',
  });
  await move(ITSM_ASSETS_COMMANDS.issueStock, 'emulator-low-issue-1', {
    quantity: 7,
    sourceLocationId: 'stock-main',
    recipientUserId: 'agent-recipient-1',
    recipientName: 'Spoofed recipient',
  });
  await move(ITSM_ASSETS_COMMANDS.issueStock, 'emulator-low-issue-2', {
    quantity: 1,
    sourceLocationId: 'stock-main',
    recipientUserId: 'agent-recipient-1',
    recipientName: 'Spoofed recipient',
  });
  assert.equal((await documents('notificationEvents')).length, 1);
  await move(ITSM_ASSETS_COMMANDS.receiveStock, 'emulator-low-recover', {
    quantity: 10,
    destinationLocationId: 'stock-main',
  });
  await move(ITSM_ASSETS_COMMANDS.issueStock, 'emulator-low-issue-3', {
    quantity: 9,
    sourceLocationId: 'stock-main',
    recipientUserId: 'agent-recipient-1',
    recipientName: 'Spoofed recipient',
  });
  const events = await documents('notificationEvents');
  assert.equal(events.length, 2);
  assert.ok(events.every((event) => event.eventType === 'stock.low'));
  assert.ok(events.every((event) => event.target.moduleKey === 'ticketing'));
  assert.equal((await read('stockItems/low-cable')).lowStockEpisode, 2);
});

test('untrusted or disabled target identities roll back operational commands', async () => {
  await Promise.all([
    db.doc('agents/disabled-agent').set({ name: 'Disabled', isActive: false }),
    db.doc('assets/target-asset').set({
      assetTag: 'TARGET-1',
      type: 'laptop',
      status: 'configured',
      revision: 0,
    }),
    db.doc('stockItems/target-stock').set({
      name: 'Target stock',
      balances: { main: { onHand: 2, reserved: 0 } },
      minimumQuantity: 0,
      isActive: true,
    }),
    db.doc('softwareLicences/target-licence').set({
      purchasedQuantity: 2,
      allocatedQuantity: 0,
      revision: 0,
    }),
  ]);
  await assert.rejects(
    () => execute(command(ITSM_ASSETS_COMMANDS.assignAsset, 'emulator-disabled-assign', {
      assetId: 'target-asset',
      expectedRevision: 0,
      assignedUserId: 'disabled-agent',
      assignedUserName: 'Spoofed',
    })),
    (error) => error.code === 'failed-precondition',
  );
  await assert.rejects(
    () => execute(command(ITSM_ASSETS_COMMANDS.issueStock, 'emulator-missing-recipient', {
      stockItemId: 'target-stock',
      quantity: 1,
      sourceLocationId: 'main',
      recipientUserId: 'missing-agent',
      recipientName: 'Spoofed',
      reason: 'Target validation',
    })),
    (error) => error.code === 'not-found',
  );
  await assert.rejects(
    () => execute(command(ITSM_ASSETS_COMMANDS.allocateLicence, 'emulator-missing-device', {
      licenceId: 'target-licence',
      assignmentType: 'device',
      assigneeId: 'missing-device',
      assigneeName: 'Spoofed',
      quantity: 1,
    })),
    (error) => error.code === 'not-found',
  );
  assert.equal((await documents('assetAssignments')).length, 0);
  assert.equal((await documents('assetSelfServiceProjections')).length, 0);
  assert.equal((await documents('stockMovements')).length, 0);
  assert.equal((await documents('itsmCommandReceipts')).length, 0);
});

test('licence capacity, allocation, release, history, and failed rollback remain consistent', async () => {
  await execute(command(ITSM_ASSETS_COMMANDS.registerLicence, 'emulator-licence-register', {
    licenceId: 'licence-office',
    softwareProduct: 'Office Suite',
    vendor: 'Software Vendor',
    licenceType: 'subscription',
    purchasedQuantity: 3,
    purchaseDate: '2026-07-01',
    effectiveDate: '2026-07-01',
    expiryDate: '2027-06-30',
    complianceStatus: 'compliant',
  }));
  const allocationCommand = command(
    ITSM_ASSETS_COMMANDS.allocateLicence,
    'emulator-licence-allocation',
    {
      licenceId: 'licence-office',
      assignmentType: 'user',
      assigneeId: 'agent-licensed-1',
      assigneeName: 'Licensed Agent',
      quantity: 2,
      relatedRequestId: 'request-licence-1',
      notes: 'Finance team allocation',
    },
  );
  const allocation = await execute(allocationCommand);
  assert.deepEqual(await execute(allocationCommand), allocation);

  await assert.rejects(
    () => execute(command(ITSM_ASSETS_COMMANDS.allocateLicence, 'emulator-licence-overcapacity', {
      licenceId: 'licence-office',
      assignmentType: 'device',
      assigneeId: 'asset-device-1',
      assigneeName: 'Device 1',
      quantity: 2,
    })),
    (error) => error.code === 'failed-precondition',
  );
  let licence = await read('softwareLicences/licence-office');
  assert.equal(licence.purchasedQuantity, 3);
  assert.equal(licence.allocatedQuantity, 2);
  assert.equal(licence.availableQuantity, 1);
  assert.equal(licence.revision, 1);

  const releaseCommand = command(ITSM_ASSETS_COMMANDS.releaseLicence, 'emulator-licence-release', {
    licenceId: 'licence-office',
    allocationId: allocation.allocationId,
    reason: 'Agent changed role',
    relatedRequestId: 'request-licence-2',
  });
  const released = await execute(releaseCommand);
  assert.deepEqual(await execute(releaseCommand), released);
  licence = await read('softwareLicences/licence-office');
  assert.equal(licence.allocatedQuantity, 0);
  assert.equal(licence.availableQuantity, 3);
  assert.equal(licence.revision, 2);

  const allocationDocument = await read(
    `softwareLicences/licence-office/allocations/${allocation.allocationId}`,
  );
  assert.equal(allocationDocument.status, 'released');
  assert.equal(allocationDocument.releaseReason, 'Agent changed role');
  assert.equal(allocationDocument.releasedBy.userId, manager.uid);
  assertTimestamp(allocationDocument.releasedAt);

  const history = await documents('softwareLicences/licence-office/history');
  assert.equal(history.length, 3);
  assert.deepEqual(history.map((entry) => entry.action).sort(), [
    'allocated',
    'registered',
    'released',
  ]);
  assert.ok(history.every((entry) => entry.actor.userId === manager.uid));
  await assertTrustedArtifacts({ receipts: 3, audits: 3 });
});

test('supplier, contract, warranty, and claim commands enforce references and preserve history', async () => {
  await execute(command(ITSM_ASSETS_COMMANDS.registerAsset, 'emulator-reference-asset', {
    assetId: 'asset-warranty-1',
    assetTag: 'ARPTC-WAR-001',
    categoryId: 'computers',
    categoryName: 'Computers',
    type: 'laptop',
    brand: 'Dell',
    model: 'Latitude',
    serialNumber: 'WAR-001',
    locationId: 'kinshasa-hq',
    locationName: 'Kinshasa HQ',
    stateId: 'new',
    stateName: 'New',
    acquisitionDate: '2026-08-01',
  }));
  await execute(command(ITSM_ASSETS_COMMANDS.saveSupplier, 'emulator-supplier-save', {
    id: 'supplier-hardware',
    name: 'Hardware Supplier',
    legalName: 'Hardware Supplier SARL',
    supplierCode: 'SUP-001',
    contactEmail: 'support@supplier.test',
  }));

  await assert.rejects(
    () => execute(command(ITSM_ASSETS_COMMANDS.saveContract, 'emulator-contract-missing-ref', {
      id: 'contract-invalid',
      name: 'Invalid contract',
      contractNumber: 'CTR-INVALID',
      supplierId: 'supplier-missing',
      startDate: '2026-01-01',
      endDate: '2026-12-31',
    })),
    (error) => error.code === 'not-found',
  );
  assert.equal(await exists('supplierContracts/contract-invalid'), false);

  await execute(command(ITSM_ASSETS_COMMANDS.saveContract, 'emulator-contract-save', {
    id: 'contract-hardware',
    name: 'Hardware support contract',
    contractNumber: 'CTR-001',
    supplierId: 'supplier-hardware',
    startDate: '2026-01-01',
    endDate: '2027-01-01',
    assetIds: ['asset-warranty-1'],
    status: 'active',
  }));
  await execute(command(ITSM_ASSETS_COMMANDS.saveWarranty, 'emulator-warranty-save', {
    id: 'warranty-laptop',
    name: 'Laptop warranty',
    warrantyNumber: 'WAR-001',
    supplierId: 'supplier-hardware',
    contractId: 'contract-hardware',
    coverage: 'Parts and labour',
    startDate: '2026-01-01',
    expirationDate: '2027-01-01',
    assetIds: ['asset-warranty-1'],
    status: 'active',
  }));
  await execute(command(ITSM_ASSETS_COMMANDS.recordWarrantyClaim, 'emulator-claim-record', {
    warrantyId: 'warranty-laptop',
    claimId: 'claim-screen',
    assetId: 'asset-warranty-1',
    title: 'Screen failure',
    description: 'The display no longer powers on.',
    relatedRequestId: 'request-warranty-1',
    supportingDocument: documentMetadata('diagnostic-report'),
  }));
  await execute(command(ITSM_ASSETS_COMMANDS.transitionWarrantyClaim, 'emulator-claim-transition', {
    warrantyId: 'warranty-laptop',
    claimId: 'claim-screen',
    expectedRevision: 0,
    toStatus: 'acknowledged',
    reason: 'Supplier acknowledged the claim',
    evidence: [documentMetadata('supplier-acknowledgement')],
  }));

  const supplier = await read('suppliers/supplier-hardware');
  const contract = await read('supplierContracts/contract-hardware');
  const warranty = await read('warranties/warranty-laptop');
  const claim = await read('warranties/warranty-laptop/claims/claim-screen');
  assert.equal(supplier.revision, 0);
  assert.equal(contract.supplierId, supplier.id);
  assert.deepEqual(contract.assetIds, ['asset-warranty-1']);
  assert.equal(warranty.contractId, 'contract-hardware');
  assert.deepEqual(warranty.assetIds, ['asset-warranty-1']);
  assert.equal(claim.assetId, 'asset-warranty-1');
  assert.equal(claim.status, 'acknowledged');
  assert.equal(claim.revision, 1);
  assert.equal(claim.supportingDocument.attachmentId, 'diagnostic-report');

  const claimHistory = await documents(
    'warranties/warranty-laptop/claims/claim-screen/history',
  );
  assert.equal(claimHistory.length, 2);
  assert.deepEqual(claimHistory.map((entry) => entry.toStatus).sort(), [
    'acknowledged',
    'submitted',
  ]);
  assert.ok(claimHistory.every((entry) => entry.actor.userId === manager.uid));
  await assertTrustedArtifacts({ receipts: 6, audits: 6 });
});

test('CMDB relationships enforce direction, preserve links, retire once, and audit every command', async () => {
  await execute(command(ITSM_ASSETS_COMMANDS.registerAsset, 'emulator-cmdb-asset', {
    assetId: 'asset-server-1',
    assetTag: 'ARPTC-SRV-001',
    categoryId: 'servers',
    categoryName: 'Servers',
    type: 'server',
    brand: 'Dell',
    model: 'PowerEdge',
    serialNumber: 'SRV-001',
    locationId: 'data-centre',
    locationName: 'Data centre',
    stateId: 'new',
    stateName: 'New',
    acquisitionDate: '2026-08-01',
  }));
  await execute(command(ITSM_ASSETS_COMMANDS.saveConfigurationItem, 'emulator-ci-server', {
    ciId: 'ci-server-1',
    name: 'Application Server',
    ciType: 'server',
    operationalStatus: 'active',
    linkedAssetId: 'asset-server-1',
    criticality: 'high',
    dataQualityStatus: 'verified',
  }));
  await execute(command(ITSM_ASSETS_COMMANDS.saveConfigurationItem, 'emulator-ci-application', {
    ciId: 'ci-application-1',
    name: 'Payroll Application',
    ciType: 'application',
    operationalStatus: 'active',
    configurationBaseline: { version: '2026.07', region: 'kinshasa' },
    relatedIncidentIds: ['incident-1'],
    relatedRequestIds: ['request-1'],
    relatedChangeIds: ['change-1'],
    relatedFindingIds: ['finding-1'],
  }));

  const relationshipCommand = command(
    ITSM_ASSETS_COMMANDS.createCiRelationship,
    'emulator-cmdb-relationship',
    {
      relationshipId: 'relationship-runs-on',
      relationshipType: 'runs_on',
      sourceEntityType: 'configuration_item',
      sourceEntityId: 'ci-application-1',
      targetEntityType: 'configuration_item',
      targetEntityId: 'ci-server-1',
      description: 'Payroll is hosted on the application server.',
    },
  );
  const relationshipResult = await execute(relationshipCommand);
  assert.deepEqual(await execute(relationshipCommand), relationshipResult);

  await assert.rejects(
    () => execute(command(
      ITSM_ASSETS_COMMANDS.createCiRelationship,
      'emulator-cmdb-equivalent',
      {
        relationshipId: 'relationship-equivalent-different-id',
        relationshipType: 'runs_on',
        sourceEntityType: 'configuration_item',
        sourceEntityId: 'ci-application-1',
        targetEntityType: 'configuration_item',
        targetEntityId: 'ci-server-1',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(
    await exists('ciRelationships/relationship-equivalent-different-id'),
    false,
  );

  await assert.rejects(
    () => execute(command(ITSM_ASSETS_COMMANDS.createCiRelationship, 'emulator-cmdb-reversed', {
      relationshipId: 'relationship-invalid-reversed',
      relationshipType: 'runs_on',
      sourceEntityType: 'configuration_item',
      sourceEntityId: 'ci-server-1',
      targetEntityType: 'configuration_item',
      targetEntityId: 'ci-application-1',
    })),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(await exists('ciRelationships/relationship-invalid-reversed'), false);

  const retireCommand = command(
    ITSM_ASSETS_COMMANDS.retireCiRelationship,
    'emulator-cmdb-retire',
    {
      relationshipId: 'relationship-runs-on',
      reason: 'Application migrated to a managed platform',
    },
  );
  const retired = await execute(retireCommand);
  assert.deepEqual(await execute(retireCommand), retired);

  const application = await read('configurationItems/ci-application-1');
  assert.deepEqual(application.relatedIncidentIds, ['incident-1']);
  assert.deepEqual(application.relatedRequestIds, ['request-1']);
  assert.deepEqual(application.relatedChangeIds, ['change-1']);
  assert.deepEqual(application.relatedFindingIds, ['finding-1']);
  const relationship = await read('ciRelationships/relationship-runs-on');
  assert.equal(relationship.sourceEntityId, 'ci-application-1');
  assert.equal(relationship.targetEntityId, 'ci-server-1');
  assert.equal(relationship.sourceName, 'Payroll Application');
  assert.equal(relationship.targetName, 'Application Server');
  assert.equal(relationship.isActive, false);
  assert.equal(relationship.retiredBy, manager.uid);
  assert.equal(relationship.retirementReason, 'Application migrated to a managed platform');
  assertTimestamp(relationship.retiredAt);
  assert.equal((await documents('configurationItems/ci-server-1/history')).length, 1);
  assert.equal((await documents('configurationItems/ci-application-1/history')).length, 1);
  await assertTrustedArtifacts({ receipts: 5, audits: 5 });
});

async function execute(value) {
  return executeAssetsCommand({
    db,
    fieldValue: FieldValue,
    actor: manager,
    command: value,
  });
}

function command(type, idempotencyKey, payload) {
  return validateAssetsCommand({ command: type, idempotencyKey, payload });
}

function stockCommand(type, idempotencyKey, payload) {
  return command(type, idempotencyKey, {
    stockItemId: 'network-cable',
    reason: 'Deterministic operational stock movement',
    relatedRequestId: 'request-stock-1',
    correlationId: `correlation-${idempotencyKey}`,
    ...payload,
  });
}

function documentMetadata(attachmentId) {
  return {
    attachmentId,
    storagePath: `itsm/assets/evidence/${attachmentId}.pdf`,
    fileName: `${attachmentId}.pdf`,
    contentType: 'application/pdf',
    sizeBytes: 512,
    checksum: `sha256-${attachmentId}`,
  };
}

async function read(path) {
  const snapshot = await db.doc(path).get();
  assert.equal(snapshot.exists, true, `Expected ${path} to exist.`);
  return snapshot.data();
}

async function exists(path) {
  return (await db.doc(path).get()).exists;
}

async function documents(path) {
  const snapshot = await db.collection(path).get();
  return snapshot.docs.map((document) => document.data());
}

async function keyedDocuments(path) {
  const snapshot = await db.collection(path).get();
  return new Map(
    snapshot.docs
      .map((document) => [document.id, document.data()])
      .sort(([left], [right]) => left.localeCompare(right)),
  );
}

async function assertTrustedArtifacts({ receipts, audits }) {
  const receiptDocuments = await documents('itsmCommandReceipts');
  const auditDocuments = await documents('itsmAuditEvents');
  assert.equal(receiptDocuments.length, receipts);
  assert.equal(auditDocuments.length, audits);
  assert.ok(receiptDocuments.every((entry) => entry.actorUid === manager.uid));
  assert.ok(receiptDocuments.every((entry) => entry.command && entry.idempotencyKey));
  assert.ok(receiptDocuments.every((entry) => entry.result));
  assert.ok(receiptDocuments.every((entry) => isTimestamp(entry.createdAt)));
  assert.ok(auditDocuments.every((entry) => entry.actorUserId === manager.uid));
  assert.ok(auditDocuments.every((entry) => entry.actorRole === 'MANAGER'));
  assert.ok(auditDocuments.every((entry) => entry.sourceCommand));
  assert.ok(auditDocuments.every((entry) => entry.sourceIdempotencyKey));
  assert.ok(auditDocuments.every((entry) => entry.sourcePath));
  assert.ok(auditDocuments.every((entry) => isTimestamp(entry.createdAt)));
}

function assertTimestamp(value) {
  assert.equal(isTimestamp(value), true, 'Expected a committed Firestore Timestamp.');
}

function isTimestamp(value) {
  return Boolean(value && typeof value.toMillis === 'function' && value.toMillis() > 0);
}
