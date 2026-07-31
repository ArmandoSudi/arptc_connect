'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { executeAssetsCommand } = require('../src/itsm_assets_service');
const {
  ITSM_ASSETS_COMMANDS,
  validateAssetsCommand,
} = require('../src/itsm_assets_validation');

const fieldValue = { serverTimestamp: () => 'server-time' };
const manager = {
  uid: 'manager-1',
  role: 'MANAGER',
  displayName: 'Asset Manager',
  email: 'manager@arptc.cd',
};

test('service rejects USER and ADMIN even when called without the callable handler', async () => {
  for (const role of ['USER', 'ADMIN']) {
    await assert.rejects(
      () => executeAssetsCommand({
        db: fakeDatabase(),
        fieldValue,
        actor: { ...manager, role },
        command: command(ITSM_ASSETS_COMMANDS.registerAsset, `denied-${role}-1234`, {
          assetId: `asset-${role}`,
          assetTag: `TAG-${role}`,
          categoryId: 'computer',
          type: 'laptop',
          status: 'planned',
        }),
      }),
      (error) => error.code === 'permission-denied',
    );
  }
});

test('asset lifecycle commands are replay-safe, revision checked, and audited', async () => {
  const db = fakeDatabase();
  const register = command(ITSM_ASSETS_COMMANDS.registerAsset, 'asset-register-1234', {
    assetId: 'asset-1',
    assetTag: 'ARPTC-001',
    categoryId: 'computer',
    categoryName: 'Computer',
    type: 'laptop',
    status: 'planned',
  });
  const created = await execute(db, register);
  assert.deepEqual(await execute(db, register), created);
  assert.equal(db.document('assets/asset-1').status, 'planned');
  assert.deepEqual(
    db.document('assets/asset-1').searchTokens,
    ['arptc', '001', 'computer', 'laptop'],
  );
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 1);

  const transition = command(
    ITSM_ASSETS_COMMANDS.transitionAsset,
    'asset-transition-1234',
    {
      assetId: 'asset-1',
      expectedRevision: 0,
      toStatus: 'ordered',
      reason: 'Purchase order approved',
      relatedRequestId: 'request-1',
    },
  );
  const transitioned = await execute(db, transition);
  assert.equal(transitioned.revision, 1);
  assert.equal(db.document('assets/asset-1').status, 'ordered');
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 2);
  assert.equal(db.pathsMatching(/^itsmAuditEvents\//).length, 2);

  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.transitionAsset,
      'asset-invalid-transition-1234',
      {
        assetId: 'asset-1',
        expectedRevision: 1,
        toStatus: 'assigned',
        reason: 'Skip receiving',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.document('assets/asset-1').status, 'ordered');
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 2);

  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.updateAsset,
      'asset-stale-update-1234',
      { assetId: 'asset-1', expectedRevision: 0, model: 'Updated model' },
    )),
    (error) => error.code === 'aborted',
  );
});

test('assignment and return create immutable custodianship and lifecycle events', async () => {
  const db = fakeDatabase({
    'assets/asset-1': {
      assetTag: 'ARPTC-001',
      type: 'laptop',
      condition: 'good',
      status: 'configured',
      revision: 2,
    },
  });
  const assigned = await execute(db, command(
    ITSM_ASSETS_COMMANDS.assignAsset,
    'asset-assign-1234',
    {
      assetId: 'asset-1',
      expectedRevision: 2,
      assignedUserId: 'user-1',
      assignedUserName: 'Spoofed Name',
      assignedUserEmail: 'spoofed@example.test',
      departmentId: 'finance',
      relatedRequestId: 'request-asset-1',
    },
  ));
  assert.equal(assigned.status, 'assigned');
  assert.equal(db.document('assets/asset-1').assignedUserId, 'user-1');
  assert.equal(db.document('assets/asset-1').assignedUserName, 'First Agent ARPTC');
  assert.equal(db.document('assets/asset-1').assignedUserEmail, 'authoritative@arptc.cd');
  assert.equal(db.pathsMatching(/^assetAssignments\//).length, 1);
  const projection = db.document('assetSelfServiceProjections/user-1_asset-1');
  assert.equal(projection.assignedUserName, 'First Agent ARPTC');
  assert.equal(projection.isCurrent, true);
  assert.equal(projection.acquisitionCost, undefined);
  assert.equal(projection.supplierId, undefined);
  assert.equal(projection.securityBaselineId, undefined);
  assert.equal(projection.attachmentIds, undefined);
  assert.equal(db.pathsMatching(/^notificationEvents\//).length, 1);

  await execute(db, command(ITSM_ASSETS_COMMANDS.updateAsset, 'asset-update-assigned-1234', {
    assetId: 'asset-1',
    expectedRevision: 3,
    model: 'Authoritative refreshed model',
    acquisitionCost: 9999,
    supplierId: 'internal-supplier',
    securityBaselineId: 'internal-baseline',
    attachmentIds: ['internal-attachment'],
  }));
  const refreshedProjection = db.document(
    'assetSelfServiceProjections/user-1_asset-1',
  );
  assert.equal(refreshedProjection.model, 'Authoritative refreshed model');
  assert.equal(refreshedProjection.acquisitionCost, undefined);
  assert.equal(refreshedProjection.supplierId, undefined);
  assert.equal(refreshedProjection.securityBaselineId, undefined);
  assert.equal(refreshedProjection.attachmentIds, undefined);

  const returned = await execute(db, command(
    ITSM_ASSETS_COMMANDS.returnAsset,
    'asset-return-1234',
    {
      assetId: 'asset-1',
      expectedRevision: 4,
      condition: 'good',
      stockLocationId: 'main',
      reason: 'Custodian returned device',
    },
  ));
  assert.equal(returned.status, 'returned');
  assert.equal(db.document('assets/asset-1').assignedUserId, null);
  assert.equal(db.pathsMatching(/^assetAssignments\//).length, 1);
  const assignment = db.document(assigned.assignmentId
    ? `assetAssignments/${assigned.assignmentId}`
    : 'assetAssignments/missing');
  assert.equal(assignment.status, 'returned');
  assert.equal(assignment.isCurrent, false);
  assert.equal(assignment.assignedAt, 'server-time');
  assert.equal(assignment.returnedAt, 'server-time');
  assert.equal(
    db.document('assetSelfServiceProjections/user-1_asset-1').isCurrent,
    false,
  );
  assert.equal(db.document('assetAssignmentLocks/asset-1').isActive, false);
});

test('assignment rejects missing, disabled, and duplicate active custodians atomically', async () => {
  const baseAsset = {
    assetTag: 'ARPTC-002',
    type: 'laptop',
    status: 'configured',
    revision: 0,
  };
  const missingDb = fakeDatabase({ 'assets/asset-2': baseAsset });
  await assert.rejects(
    () => execute(missingDb, command(ITSM_ASSETS_COMMANDS.assignAsset, 'missing-user-1234', {
      assetId: 'asset-2',
      expectedRevision: 0,
      assignedUserId: 'missing-user',
      assignedUserName: 'Ignored',
    })),
    (error) => error.code === 'not-found',
  );
  assert.equal(missingDb.pathsMatching(/^assetAssignments\//).length, 0);

  const disabledDb = fakeDatabase({
    'assets/asset-2': baseAsset,
    'agents/disabled-user': { name: 'Disabled', isActive: false },
  });
  await assert.rejects(
    () => execute(disabledDb, command(ITSM_ASSETS_COMMANDS.assignAsset, 'disabled-user-1234', {
      assetId: 'asset-2',
      expectedRevision: 0,
      assignedUserId: 'disabled-user',
      assignedUserName: 'Ignored',
    })),
    (error) => error.code === 'failed-precondition',
  );

  const duplicateDb = fakeDatabase({
    'assets/asset-2': baseAsset,
    'assetAssignmentLocks/asset-2': {
      assignmentId: 'existing-assignment',
      isActive: true,
    },
  });
  await assert.rejects(
    () => execute(duplicateDb, command(ITSM_ASSETS_COMMANDS.assignAsset, 'duplicate-user-1234', {
      assetId: 'asset-2',
      expectedRevision: 0,
      assignedUserId: 'user-1',
      assignedUserName: 'Ignored',
    })),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(duplicateDb.pathsMatching(/^assetAssignments\//).length, 0);
});

test('stock receipt, reservation, issue, return, transfer, adjustment, and reconciliation stay consistent', async () => {
  const db = fakeDatabase({
    'stockItems/cable': { balances: {}, totalOnHand: 0, totalReserved: 0 },
    'stockSupportingDocuments/adjustment-sheet': {
      ...documentMetadata('adjustment-sheet'),
      stockItemId: 'cable',
      storagePath:
        'itsm/stock/cable/supportingDocuments/adjustment-sheet/adjustment-sheet.pdf',
    },
    'stockSupportingDocuments/count-sheet': {
      ...documentMetadata('count-sheet'),
      stockItemId: 'cable',
      storagePath:
        'itsm/stock/cable/supportingDocuments/count-sheet/count-sheet.pdf',
    },
  });
  await execute(db, stockCommand(
    ITSM_ASSETS_COMMANDS.receiveStock,
    'stock-receive-1234',
    { quantity: 20, destinationLocationId: 'main' },
  ));
  await execute(db, stockCommand(
    ITSM_ASSETS_COMMANDS.reserveStock,
    'stock-reserve-1234',
    {
      quantity: 5,
      sourceLocationId: 'main',
      recipientUserId: 'user-1',
      recipientName: 'First Agent',
    },
  ));
  await execute(db, stockCommand(
    ITSM_ASSETS_COMMANDS.issueStock,
    'stock-issue-1234',
    {
      quantity: 7,
      reservedQuantity: 5,
      sourceLocationId: 'main',
      recipientUserId: 'user-1',
      recipientName: 'First Agent',
    },
  ));
  await execute(db, stockCommand(
    ITSM_ASSETS_COMMANDS.returnStock,
    'stock-return-1234',
    {
      quantity: 2,
      destinationLocationId: 'main',
      recipientUserId: 'user-1',
      recipientName: 'First Agent',
    },
  ));
  await execute(db, stockCommand(
    ITSM_ASSETS_COMMANDS.transferStock,
    'stock-transfer-1234',
    { quantity: 4, sourceLocationId: 'main', destinationLocationId: 'annex' },
  ));
  await execute(db, stockCommand(
    ITSM_ASSETS_COMMANDS.adjustStock,
    'stock-adjust-1234',
    {
      sourceLocationId: 'annex',
      adjustmentDelta: -1,
      supportingDocument: documentMetadata('adjustment-sheet'),
    },
  ));
  const reconciled = await execute(db, command(
    ITSM_ASSETS_COMMANDS.reconcileStock,
    'stock-reconcile-1234',
    {
      stockItemId: 'cable',
      sourceLocationId: 'annex',
      targetOnHand: 5,
      targetReserved: 1,
      reason: 'Cycle count',
      supportingDocument: documentMetadata('count-sheet'),
      correlationId: 'cycle-count-2026',
    },
  ));

  const stock = db.document('stockItems/cable');
  assert.deepEqual(stock.balances, {
    main: { onHand: 11, reserved: 0 },
    annex: { onHand: 5, reserved: 1 },
  });
  assert.equal(reconciled.totalOnHand, 16);
  assert.equal(reconciled.totalReserved, 1);
  assert.equal(reconciled.availableQuantity, 15);
  assert.equal(db.pathsMatching(/^stockMovements\//).length, 7);
  const movements = db.documentsMatching(/^stockMovements\//);
  assert.ok(movements.every((movement) => movement.actorUserId === 'manager-1'));
  assert.ok(movements.every((movement) => movement.occurredAt === 'server-time'));
  assert.equal(
    movements.find((movement) => movement.movementType === 'issue').recipient.userId,
    'user-1',
  );
  assert.equal(
    movements.find((movement) => movement.movementType === 'reconciliation')
      .supportingDocument.attachmentId,
    'count-sheet',
  );
  assert.equal(
    movements.find((movement) => movement.movementType === 'reconciliation')
      .supportingDocument.storagePath,
    'itsm/stock/cable/supportingDocuments/count-sheet/count-sheet.pdf',
  );
});

test('failed stock movement rolls back quantity, movement, audit, and receipt writes', async () => {
  const db = fakeDatabase({
    'stockItems/laptop': {
      balances: { main: { onHand: 2, reserved: 1 } },
      totalOnHand: 2,
      totalReserved: 1,
      availableQuantity: 1,
    },
  });
  await assert.rejects(
    () => execute(db, stockCommand(
      ITSM_ASSETS_COMMANDS.issueStock,
      'stock-overissue-1234',
      {
        stockItemId: 'laptop',
        quantity: 2,
        sourceLocationId: 'main',
        recipientUserId: 'user-1',
        recipientName: 'First Agent',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.deepEqual(db.document('stockItems/laptop').balances.main, {
    onHand: 2,
    reserved: 1,
  });
  assert.equal(db.pathsMatching(/^stockMovements\//).length, 0);
  assert.equal(db.pathsMatching(/^itsmAuditEvents\//).length, 0);
  assert.equal(db.pathsMatching(/^itsmCommandReceipts\//).length, 0);
});

test('stock evidence is resolved from trusted metadata and bound to its item', async () => {
  for (const [seed, code] of [
    [{}, 'not-found'],
    [{
      'stockSupportingDocuments/evidence-1': {
        ...documentMetadata('evidence-1'),
        stockItemId: 'other-item',
      },
    }, 'failed-precondition'],
  ]) {
    const db = fakeDatabase({
      'stockItems/cable': {
        balances: { main: { onHand: 2, reserved: 0 } },
      },
      ...seed,
    });
    await assert.rejects(
      () => execute(db, stockCommand(
        ITSM_ASSETS_COMMANDS.adjustStock,
        `stock-evidence-${code}-1234`,
        {
          sourceLocationId: 'main',
          adjustmentDelta: 1,
          supportingDocument: documentMetadata('evidence-1'),
        },
      )),
      (error) => error.code === code,
    );
    assert.equal(db.pathsMatching(/^stockMovements\//).length, 0);
  }
});

test('stock replay creates exactly one immutable movement and one audit event', async () => {
  const db = fakeDatabase({ 'stockItems/mouse': { balances: {} } });
  const receipt = stockCommand(
    ITSM_ASSETS_COMMANDS.receiveStock,
    'stock-idempotent-1234',
    { stockItemId: 'mouse', quantity: 10, destinationLocationId: 'main' },
  );
  const first = await execute(db, receipt);
  assert.deepEqual(await execute(db, receipt), first);
  assert.equal(db.document('stockItems/mouse').totalOnHand, 10);
  assert.equal(db.pathsMatching(/^stockMovements\//).length, 1);
  assert.equal(db.pathsMatching(/^itsmAuditEvents\//).length, 1);
});

test('stock configuration is revisioned and low-stock alerts are episode-deduplicated', async () => {
  const db = fakeDatabase();
  const location = await execute(db, command(
    ITSM_ASSETS_COMMANDS.saveStockLocation,
    'stock-location-save-1234',
    {
      id: 'main',
      name: 'Main store',
      siteId: 'kinshasa-hq',
      siteName: 'Kinshasa HQ',
    },
  ));
  assert.deepEqual(location, { id: 'main', revision: 0, created: true });
  await execute(db, command(ITSM_ASSETS_COMMANDS.saveStockItem, 'stock-item-save-1234', {
    id: 'cable-low',
    sku: 'CAB-001',
    name: 'Network cable',
    kind: 'consumable',
    unitOfMeasure: 'piece',
    minimumQuantity: 3,
  }));
  assert.equal(db.document('stockItems/cable-low').revision, 0);

  const move = (type, key, payload) => execute(db, command(type, key, {
    stockItemId: 'cable-low',
    reason: 'Stock threshold test',
    ...payload,
  }));
  await move(ITSM_ASSETS_COMMANDS.receiveStock, 'low-receive-1234', {
    quantity: 10,
    destinationLocationId: 'main',
  });
  await move(ITSM_ASSETS_COMMANDS.issueStock, 'low-issue-1-1234', {
    quantity: 7,
    sourceLocationId: 'main',
    recipientUserId: 'user-1',
    recipientName: 'Spoofed Recipient',
  });
  await move(ITSM_ASSETS_COMMANDS.issueStock, 'low-issue-2-1234', {
    quantity: 1,
    sourceLocationId: 'main',
    recipientUserId: 'user-1',
    recipientName: 'Spoofed Recipient',
  });
  assert.equal(db.pathsMatching(/^notificationEvents\//).length, 1);
  await move(ITSM_ASSETS_COMMANDS.receiveStock, 'low-recover-1234', {
    quantity: 10,
    destinationLocationId: 'main',
  });
  await move(ITSM_ASSETS_COMMANDS.issueStock, 'low-issue-3-1234', {
    quantity: 9,
    sourceLocationId: 'main',
    recipientUserId: 'user-1',
    recipientName: 'Spoofed Recipient',
  });
  assert.equal(db.pathsMatching(/^notificationEvents\//).length, 2);
  assert.equal(db.document('stockItems/cable-low').lowStockEpisode, 2);
  assert.ok(db.documentsMatching(/^stockMovements\//)
    .filter((movement) => movement.recipient)
    .every((movement) => movement.recipient.name === 'First Agent ARPTC'));

  const beforeConfigUpdate = db.document('stockItems/cable-low').balances;
  const updated = await execute(db, command(
    ITSM_ASSETS_COMMANDS.saveStockItem,
    'stock-item-update-1234',
    {
      id: 'cable-low',
      expectedRevision: 0,
      sku: 'CAB-001',
      name: 'Network cable',
      kind: 'consumable',
      unitOfMeasure: 'piece',
      minimumQuantity: 5,
    },
  ));
  assert.equal(updated.revision, 1);
  assert.deepEqual(db.document('stockItems/cable-low').balances, beforeConfigUpdate);

  await assert.rejects(
    () => execute(db, command(ITSM_ASSETS_COMMANDS.saveStockItem, 'stock-item-stale-1234', {
      id: 'cable-low',
      expectedRevision: 0,
      sku: 'CAB-001',
      name: 'Network cable',
      kind: 'consumable',
      unitOfMeasure: 'piece',
      minimumQuantity: 3,
    })),
    (error) => error.code === 'aborted',
  );
});

test('stock movements reject missing or disabled recipients before any write', async () => {
  for (const [userId, agent, code] of [
    ['missing-user', null, 'not-found'],
    ['disabled-user', { name: 'Disabled', isActive: false }, 'failed-precondition'],
  ]) {
    const seed = {
      'stockItems/cable': {
        balances: { main: { onHand: 5, reserved: 0 } },
        isActive: true,
      },
    };
    if (agent) seed[`agents/${userId}`] = agent;
    const db = fakeDatabase(seed);
    await assert.rejects(
      () => execute(db, stockCommand(ITSM_ASSETS_COMMANDS.issueStock, `stock-${userId}-1234`, {
        quantity: 1,
        sourceLocationId: 'main',
        recipientUserId: userId,
        recipientName: 'Ignored',
      })),
      (error) => error.code === code,
    );
    assert.equal(db.pathsMatching(/^stockMovements\//).length, 0);
    assert.equal(db.pathsMatching(/^itsmCommandReceipts\//).length, 0);
  }
});

test('licence allocation enforces purchased capacity and release is replay-safe', async () => {
  const db = fakeDatabase();
  await execute(db, command(
    ITSM_ASSETS_COMMANDS.registerLicence,
    'licence-register-1234',
    {
      licenceId: 'office',
      softwareProduct: 'Office Suite',
      vendor: 'Vendor',
      licenceType: 'subscription',
      purchasedQuantity: 2,
      purchaseDate: '2026-01-01',
      effectiveDate: '2026-01-01',
      expiryDate: '2027-01-01',
      renewalDate: '2026-12-01',
      complianceStatus: 'compliant',
    },
  ));
  assert.ok(db.document('softwareLicences/office').expiryDate instanceof Date);
  assert.ok(db.document('softwareLicences/office').renewalDate instanceof Date);
  const allocation = await execute(db, command(
    ITSM_ASSETS_COMMANDS.allocateLicence,
    'licence-allocate-1234',
    {
      licenceId: 'office',
      assignmentType: 'user',
      assigneeId: 'user-1',
      assigneeName: 'First Agent',
      quantity: 2,
    },
  ));
  assert.equal(
    db.document(`softwareLicences/office/allocations/${allocation.allocationId}`)
      .assigneeName,
    'First Agent ARPTC',
  );
  assert.equal(
    db.document(`softwareLicences/office/allocations/${allocation.allocationId}`)
      .assigneeEmail,
    'authoritative@arptc.cd',
  );
  assert.equal(db.document('softwareLicences/office').availableQuantity, 0);
  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.allocateLicence,
      'licence-overallocate-1234',
      {
        licenceId: 'office',
        assignmentType: 'device',
        assigneeId: 'asset-1',
        assigneeName: 'Laptop',
        quantity: 1,
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.document('softwareLicences/office').allocatedQuantity, 2);

  const release = command(ITSM_ASSETS_COMMANDS.releaseLicence, 'licence-release-1234', {
    licenceId: 'office',
    allocationId: allocation.allocationId,
    reason: 'User left the department',
  });
  const released = await execute(db, release);
  assert.deepEqual(await execute(db, release), released);
  assert.equal(db.document('softwareLicences/office').allocatedQuantity, 0);
  assert.equal(db.document('softwareLicences/office').availableQuantity, 2);
  assert.equal(db.pathsMatching(/^softwareLicences\/office\/history\//).length, 3);
});

test('licence allocation resolves user and device targets and rejects unavailable targets', async () => {
  const db = fakeDatabase({
    'softwareLicences/tool': {
      purchasedQuantity: 4,
      allocatedQuantity: 0,
      revision: 0,
    },
    'assets/device-1': {
      assetTag: 'ARPTC-DEVICE-1',
      status: 'assigned',
    },
    'assets/retired-device': {
      assetTag: 'ARPTC-OLD-1',
      status: 'retired',
    },
    'agents/disabled-user': { name: 'Disabled', isActive: false },
  });
  const device = await execute(db, command(
    ITSM_ASSETS_COMMANDS.allocateLicence,
    'licence-device-1234',
    {
      licenceId: 'tool',
      assignmentType: 'device',
      assigneeId: 'device-1',
      assigneeName: 'Spoofed device',
      quantity: 1,
    },
  ));
  assert.equal(
    db.document(`softwareLicences/tool/allocations/${device.allocationId}`).assigneeName,
    'ARPTC-DEVICE-1',
  );
  for (const [id, assignmentType, code] of [
    ['missing-user', 'user', 'not-found'],
    ['disabled-user', 'user', 'failed-precondition'],
    ['missing-device', 'device', 'not-found'],
    ['retired-device', 'device', 'failed-precondition'],
  ]) {
    await assert.rejects(
      () => execute(db, command(
        ITSM_ASSETS_COMMANDS.allocateLicence,
        `licence-${id}-1234`,
        {
          licenceId: 'tool',
          assignmentType,
          assigneeId: id,
          assigneeName: 'Ignored',
          quantity: 1,
        },
      )),
      (error) => error.code === code,
    );
  }
});

test('supplier, contract, warranty, and claim commands validate references and preserve history', async () => {
  const db = fakeDatabase({
    'assets/asset-1': { assetTag: 'ARPTC-001' },
  });
  await execute(db, command(ITSM_ASSETS_COMMANDS.saveSupplier, 'supplier-save-1234', {
    id: 'supplier-1',
    name: 'Hardware Supplier',
    contactEmail: 'support@supplier.test',
  }));
  await execute(db, command(ITSM_ASSETS_COMMANDS.saveContract, 'contract-save-1234', {
    id: 'contract-1',
    name: 'Hardware support',
    contractNumber: 'CTR-001',
    supplierId: 'supplier-1',
    startDate: '2026-01-01',
    endDate: '2027-01-01',
  }));
  await execute(db, command(ITSM_ASSETS_COMMANDS.saveWarranty, 'warranty-save-1234', {
    id: 'warranty-1',
    name: 'Laptop warranty',
    warrantyNumber: 'WAR-001',
    supplierId: 'supplier-1',
    contractId: 'contract-1',
    coverage: 'Parts and labour',
    startDate: '2026-01-01',
    expirationDate: '2027-01-01',
    assetIds: ['asset-1'],
  }));
  assert.ok(db.document('supplierContracts/contract-1').startDate instanceof Date);
  assert.ok(db.document('supplierContracts/contract-1').endDate instanceof Date);
  assert.ok(db.document('warranties/warranty-1').startDate instanceof Date);
  assert.ok(db.document('warranties/warranty-1').expirationDate instanceof Date);
  await execute(db, command(
    ITSM_ASSETS_COMMANDS.recordWarrantyClaim,
    'claim-record-1234',
    {
      warrantyId: 'warranty-1',
      claimId: 'claim-1',
      assetId: 'asset-1',
      title: 'Screen failure',
      description: 'The display no longer powers on.',
      supportingDocument: documentMetadata('diagnostic'),
    },
  ));
  const transitioned = await execute(db, command(
    ITSM_ASSETS_COMMANDS.transitionWarrantyClaim,
    'claim-transition-1234',
    {
      warrantyId: 'warranty-1',
      claimId: 'claim-1',
      expectedRevision: 0,
      toStatus: 'acknowledged',
      reason: 'Supplier acknowledged the claim',
    },
  ));
  assert.equal(transitioned.status, 'acknowledged');
  assert.equal(
    db.document('warranties/warranty-1/claims/claim-1').status,
    'acknowledged',
  );
  assert.equal(
    db.pathsMatching(/^warranties\/warranty-1\/claims\/claim-1\/history\//).length,
    2,
  );
});

test('CMDB relationships enforce entity direction and runs_on CI type direction', async () => {
  const db = fakeDatabase({
    'configurationItems/application-1': {
      name: 'Payroll application',
      ciType: 'application',
    },
    'configurationItems/server-1': {
      name: 'Application server',
      ciType: 'server',
    },
    'assets/asset-1': { assetTag: 'ARPTC-001' },
  });
  const created = await execute(db, relationshipCommand(
    'relationship-runs-on-1234',
    'rel-1',
    'runs_on',
    'configuration_item',
    'application-1',
    'configuration_item',
    'server-1',
  ));
  assert.equal(created.isActive, true);

  await assert.rejects(
    () => execute(db, relationshipCommand(
      'relationship-equivalent-1234',
      'rel-equivalent-different-id',
      'runs_on',
      'configuration_item',
      'application-1',
      'configuration_item',
      'server-1',
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.document('ciRelationships/rel-equivalent-different-id'), undefined);

  await assert.rejects(
    () => execute(db, relationshipCommand(
      'relationship-reversed-1234',
      'rel-2',
      'runs_on',
      'configuration_item',
      'server-1',
      'configuration_item',
      'application-1',
    )),
    (error) => error.code === 'failed-precondition',
  );
  await assert.rejects(
    () => execute(db, relationshipCommand(
      'relationship-invalid-direction-1234',
      'rel-3',
      'represented_by',
      'configuration_item',
      'application-1',
      'asset',
      'asset-1',
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.document('ciRelationships/rel-2'), undefined);
  assert.equal(db.document('ciRelationships/rel-3'), undefined);
});

test('CMDB CI save validates linked assets, revisions, and relationship retirement', async () => {
  const db = fakeDatabase({
    'assets/asset-1': { assetTag: 'ARPTC-001' },
    'configurationItems/server-1': {
      name: 'Application server',
      ciType: 'server',
      operationalStatus: 'active',
      revision: 0,
    },
    'agents/ci-owner': {
      firstName: 'Authoritative',
      name: 'Owner',
      email: 'ci.owner@arptc.cd',
      isActive: true,
    },
  });
  const saved = await execute(db, command(
    ITSM_ASSETS_COMMANDS.saveConfigurationItem,
    'ci-save-application-1234',
    {
      ciId: 'application-1',
      name: 'Payroll application',
      ciType: 'application',
      operationalStatus: 'active',
      linkedAssetId: 'asset-1',
      ownerUserId: 'ci-owner',
      ownerName: 'Spoofed Owner',
      configurationBaseline: { version: '2026.07', region: 'kinshasa' },
      relatedIncidentIds: ['incident-1'],
      relatedRequestIds: ['request-1'],
    },
  ));
  assert.equal(saved.created, true);
  assert.equal(db.document('configurationItems/application-1').linkedAssetId, 'asset-1');
  assert.equal(
    db.document('configurationItems/application-1').ownerName,
    'Authoritative Owner',
  );
  assert.equal(
    db.document('configurationItems/application-1').ownerEmail,
    'ci.owner@arptc.cd',
  );
  assert.equal(
    db.pathsMatching(/^configurationItems\/application-1\/history\//).length,
    1,
  );
  await execute(db, command(ITSM_ASSETS_COMMANDS.saveConfigurationItem, 'ci-update-application-1234', {
    ciId: 'application-1',
    expectedRevision: 0,
    name: 'Payroll application v2',
    ciType: 'application',
    operationalStatus: 'active',
    linkedAssetId: 'asset-1',
    ownerUserId: 'ci-owner',
    ownerName: 'Another spoof',
    configurationBaseline: { version: '2026.08', region: 'kinshasa' },
  }));
  assert.equal(
    db.pathsMatching(/^configurationItems\/application-1\/history\//).length,
    2,
  );
  assert.deepEqual(
    db.documentsMatching(/^configurationItems\/application-1\/history\//)
      .map((entry) => entry.revision)
      .sort(),
    [0, 1],
  );

  await execute(db, relationshipCommand(
    'relationship-retire-create-1234',
    'rel-retire',
    'runs_on',
    'configuration_item',
    'application-1',
    'configuration_item',
    'server-1',
  ));
  const retired = await execute(db, command(
    ITSM_ASSETS_COMMANDS.retireCiRelationship,
    'relationship-retire-1234',
    { relationshipId: 'rel-retire', reason: 'Application migrated' },
  ));
  assert.equal(retired.isActive, false);
  assert.equal(db.document('ciRelationships/rel-retire').isActive, false);

  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.saveConfigurationItem,
      'ci-missing-asset-1234',
      {
        ciId: 'device-2',
        name: 'Missing device',
        ciType: 'device',
        linkedAssetId: 'missing-asset',
      },
    )),
    (error) => error.code === 'not-found',
  );
  assert.equal(db.document('configurationItems/device-2'), undefined);
});

function execute(db, value) {
  return executeAssetsCommand({ db, fieldValue, actor: manager, command: value });
}

function command(type, idempotencyKey, payload) {
  return validateAssetsCommand({ command: type, idempotencyKey, payload });
}

function stockCommand(type, idempotencyKey, payload) {
  return command(type, idempotencyKey, {
    stockItemId: 'cable',
    reason: 'Operational stock movement',
    relatedRequestId: 'request-1',
    ...payload,
  });
}

function relationshipCommand(
  idempotencyKey,
  relationshipId,
  relationshipType,
  sourceEntityType,
  sourceEntityId,
  targetEntityType,
  targetEntityId,
) {
  return command(ITSM_ASSETS_COMMANDS.createCiRelationship, idempotencyKey, {
    relationshipId,
    relationshipType,
    sourceEntityType,
    sourceEntityId,
    targetEntityType,
    targetEntityId,
  });
}

function documentMetadata(attachmentId) {
  return {
    attachmentId,
    storagePath: `itsm/assets/evidence/${attachmentId}.pdf`,
    fileName: `${attachmentId}.pdf`,
    contentType: 'application/pdf',
    sizeBytes: 512,
  };
}

function fakeDatabase(seed = {}) {
  const documents = new Map(
    Object.entries({
      'agents/user-1': {
        firstName: 'First',
        name: 'Agent',
        postName: 'ARPTC',
        email: 'authoritative@arptc.cd',
        isActive: true,
      },
      ...seed,
    }).map(([path, value]) => [path, clone(value)]),
  );

  class Reference {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) { return new Reference(`${this.path}/${id}`); }
  }
  const snapshot = (reference) => {
    const value = documents.get(reference.path);
    return {
      id: reference.id,
      ref: reference,
      exists: value !== undefined,
      data: () => clone(value),
      get: (field) => value && value[field],
    };
  };
  return {
    collection(name) { return new Collection(name); },
    document(path) { return clone(documents.get(path)); },
    pathsMatching(pattern) { return [...documents.keys()].filter((path) => pattern.test(path)); },
    documentsMatching(pattern) {
      return [...documents.entries()]
        .filter(([path]) => pattern.test(path))
        .map(([, value]) => clone(value));
    },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (reference) => snapshot(reference),
        create: (reference, value) => writes.push({ kind: 'create', reference, value }),
        set: (reference, value, options) => writes.push({
          kind: 'set',
          reference,
          value,
          options,
        }),
        update: (reference, value) => writes.push({ kind: 'update', reference, value }),
      };
      const result = await callback(transaction);
      const next = new Map([...documents.entries()].map(([path, value]) => [
        path,
        clone(value),
      ]));
      for (const write of writes) {
        const path = write.reference.path;
        if (write.kind === 'create') {
          if (next.has(path)) throw new Error(`Document already exists: ${path}`);
          next.set(path, clone(write.value));
        } else if (write.kind === 'update') {
          if (!next.has(path)) throw new Error(`Document does not exist: ${path}`);
          next.set(path, { ...next.get(path), ...clone(write.value) });
        } else if (write.kind === 'set') {
          next.set(path, write.options && write.options.merge
            ? { ...(next.get(path) || {}), ...clone(write.value) }
            : clone(write.value));
        }
      }
      documents.clear();
      for (const [path, value] of next) documents.set(path, value);
      return result;
    },
  };
}

function clone(value) {
  return value === undefined ? undefined : structuredClone(value);
}
