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
          categoryName: 'Computer',
          type: 'laptop',
          brand: 'Dell',
          model: 'Latitude',
          serialNumber: `SERIAL-${role}`,
          locationId: 'head-office',
          locationName: 'Head office',
          stateId: 'good',
          stateName: 'Good',
          acquisitionDate: '2026-08-01',
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
    brand: 'Dell',
    model: 'Latitude',
    serialNumber: 'SERIAL-001',
    locationId: 'head-office',
    locationName: 'Head office',
    stateId: 'good',
    stateName: 'Good',
    acquisitionDate: '2026-08-01',
  });
  const created = await execute(db, register);
  assert.deepEqual(await execute(db, register), created);
  assert.equal(db.document('assets/asset-1').status, 'in_stock');
  assert.equal(db.document('assets/asset-1').isInStock, true);
  assert.deepEqual(
    db.document('assets/asset-1').searchTokens,
    ['arptc', '001', 'computer', 'laptop', 'dell', 'latitude', 'serial'],
  );
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 1);

  const transition = command(
    ITSM_ASSETS_COMMANDS.transitionAsset,
    'asset-transition-1234',
    {
      assetId: 'asset-1',
      expectedRevision: 0,
      toStatus: 'configured',
      reason: 'Security baseline applied',
      relatedRequestId: 'request-1',
    },
  );
  const transitioned = await execute(db, transition);
  assert.equal(transitioned.revision, 1);
  assert.equal(db.document('assets/asset-1').status, 'configured');
  assert.equal(db.document('assets/asset-1').isInStock, true);
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 2);
  assert.equal(db.pathsMatching(/^itsmAuditEvents\//).length, 2);

  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.transitionAsset,
      'asset-invalid-transition-1234',
      {
        assetId: 'asset-1',
        expectedRevision: 1,
        toStatus: 'ordered',
        reason: 'Invalid backwards transition',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.document('assets/asset-1').status, 'configured');
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

test('generic lifecycle transitions cannot bypass assignment or return workflows', async () => {
  const unassigned = {
    assetTag: 'ASSET-SAFE-1',
    serialNumber: 'ASSET-SAFE-1',
    status: 'in_stock',
    isInStock: true,
    revision: 0,
  };
  const assigned = {
    ...unassigned,
    status: 'assigned',
    isInStock: false,
    assignedUserId: 'user-1',
    assignedUserName: 'First Agent ARPTC',
    currentAssignmentId: 'assignment-1',
  };
  for (const finalCase of [
    {
      db: fakeDatabase({'assets/unassigned': unassigned}),
      assetId: 'unassigned',
      toStatus: 'assigned',
    },
    {
      db: fakeDatabase({'assets/assigned': assigned}),
      assetId: 'assigned',
      toStatus: 'returned',
    },
  ]) {
    await assert.rejects(
      () => execute(finalCase.db, command(
        ITSM_ASSETS_COMMANDS.transitionAsset,
        `safe-transition-${finalCase.assetId}-${finalCase.toStatus}`,
        {
          assetId: finalCase.assetId,
          expectedRevision: 0,
          toStatus: finalCase.toStatus,
          reason: 'Workflow ownership test',
        },
      )),
      (error) => error.code === 'failed-precondition',
    );
  }
});

test('lost and stolen states preserve custody until recovery is returned', async () => {
  for (const exceptionalStatus of ['lost', 'stolen']) {
    const db = fakeDatabase({
      'assets/asset-1': {
        assetTag: 'ASSET-EXCEPTION-1',
        type: 'laptop',
        status: 'assigned',
        condition: 'good',
        isInStock: false,
        assignedUserId: 'user-1',
        assignedUserName: 'First Agent ARPTC',
        currentAssignmentId: 'assignment-1',
        revision: 0,
      },
      'assetAssignments/assignment-1': {
        assetId: 'asset-1',
        assignedUserId: 'user-1',
        assignedUserName: 'First Agent ARPTC',
        status: 'current',
        isCurrent: true,
      },
    });

    const reported = await execute(db, command(
      ITSM_ASSETS_COMMANDS.transitionAsset,
      `asset-report-${exceptionalStatus}-1234`,
      {
        assetId: 'asset-1',
        expectedRevision: 0,
        toStatus: exceptionalStatus,
        reason: `Asset reported ${exceptionalStatus}`,
      },
    ));

    assert.equal(reported.status, exceptionalStatus);
    assert.equal(db.document('assets/asset-1').assignedUserId, 'user-1');
    assert.equal(db.document('assets/asset-1').currentAssignmentId, 'assignment-1');
    assert.equal(db.document('assetAssignments/assignment-1').status, 'current');
    assert.equal(
      db.document('assetAssignments/assignment-1').assetStatus,
      exceptionalStatus,
    );
    assert.equal(
      db.document('assetSelfServiceProjections/user-1_asset-1').isCurrent,
      true,
    );

    const recovered = await execute(db, command(
      ITSM_ASSETS_COMMANDS.returnAsset,
      `asset-recover-${exceptionalStatus}-1234`,
      {
        assetId: 'asset-1',
        expectedRevision: 1,
        condition: 'good',
        reason: `Recovered after being ${exceptionalStatus}`,
      },
    ));

    assert.equal(recovered.status, 'returned');
    assert.equal(db.document('assets/asset-1').assignedUserId, null);
    assert.equal(db.document('assetAssignments/assignment-1').status, 'returned');
    assert.equal(
      db.document('assetSelfServiceProjections/user-1_asset-1').isCurrent,
      false,
    );
  }
});

test('asset registration accepts an omitted location and starts in stock', async () => {
  const db = fakeDatabase();
  const result = await execute(db, command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    'asset-initial-assignment-1234',
    {
      assetId: 'asset-registered',
      assetTag: 'SN-REGISTERED',
      categoryId: 'laptop',
      categoryName: 'Laptop',
      type: 'Laptop',
      brand: 'Dell',
      model: 'Latitude 7450',
      serialNumber: 'SN-REGISTERED',
      productNumber: 'PN-7450',
      stateId: 'good',
      stateName: 'Good',
      acquisitionDate: '2026-08-01',
      observation: 'New workstation',
    },
  ));

  const asset = db.document('assets/asset-registered');
  assert.equal(result.status, 'in_stock');
  assert.equal(asset.status, 'in_stock');
  assert.equal(asset.isInStock, true);
  assert.equal(asset.productNumber, 'PN-7450');
  assert.equal(asset.locationId, undefined);
  assert.equal(asset.locationName, undefined);
  assert.equal(asset.stateName, 'Good');
  assert.equal(asset.assignedUserId, null);
  assert.equal(db.pathsMatching(/^assetAssignments\//).length, 0);
  const stateEvents = db.documentsMatching(/^assetStateEvents\//);
  assert.equal(stateEvents.length, 1);
  assert.equal(stateEvents[0].fromStateId, null);
  assert.equal(stateEvents[0].toStateId, 'good');
  assert.equal(stateEvents[0].observation, 'New workstation');
});

test('asset registration can create an authoritative initial assignment atomically', async () => {
  const db = fakeDatabase({
    'agents/agent-1': {
      firstName: 'Armando',
      name: 'Sudi',
      email: 'armando@arptc.cd',
      departmentId: 'it',
      departmentName: 'Information Technology',
      isActive: true,
    },
  });
  const result = await execute(db, command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    'asset-register-assigned-1234',
    {
      assetId: 'asset-assigned',
      assetTag: 'SN-ASSIGNED',
      categoryId: 'laptop',
      categoryName: 'Laptop',
      type: 'Laptop',
      brand: 'Dell',
      model: 'Latitude 7450',
      serialNumber: 'SN-ASSIGNED',
      stateId: 'good',
      stateName: 'Good',
      condition: 'good',
      acquisitionDate: '2026-08-01',
      assignedUserId: 'agent-1',
      assignedAt: '2026-08-14',
    },
  ));

  const asset = db.document('assets/asset-assigned');
  assert.equal(result.status, 'assigned');
  assert.equal(result.revision, 0);
  assert.ok(result.assignmentId);
  assert.equal(asset.status, 'assigned');
  assert.equal(asset.isInStock, false);
  assert.equal(asset.assignedUserId, 'agent-1');
  assert.equal(asset.assignedUserName, 'Armando Sudi');
  assert.equal(asset.assignedUserEmail, 'armando@arptc.cd');
  assert.equal(asset.departmentId, 'it');
  assert.equal(asset.currentAssignmentId, result.assignmentId);
  const assignment = db.document(`assetAssignments/${result.assignmentId}`);
  assert.equal(assignment.status, 'current');
  assert.equal(assignment.isCurrent, true);
  assert.equal(assignment.assignedUserId, 'agent-1');
  assert.equal(assignment.assignedAt.toISOString(), '2026-08-14T00:00:00.000Z');
  assert.equal(db.document('assetAssignmentLocks/asset-assigned').isActive, true);
  const projection = db.document(
    'assetSelfServiceProjections/agent-1_asset-assigned',
  );
  assert.equal(projection.status, 'assigned');
  assert.equal(projection.isCurrent, true);
  assert.equal(projection.assignmentId, result.assignmentId);
  assert.equal(db.pathsMatching(/^notificationEvents\//).length, 1);
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 1);
  assert.equal(db.pathsMatching(/^assetStateEvents\//).length, 1);
  assert.equal(db.pathsMatching(/^itsmAuditEvents\//).length, 1);
});

test('invalid initial assignee rolls back asset registration', async () => {
  const db = fakeDatabase({
    'agents/disabled-agent': {
      name: 'Disabled Agent',
      email: 'disabled@arptc.cd',
      isActive: false,
    },
  });
  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.registerAsset,
      'asset-register-disabled-1234',
      {
        assetId: 'asset-disabled',
        assetTag: 'SN-DISABLED',
        categoryId: 'laptop',
        categoryName: 'Laptop',
        type: 'Laptop',
        brand: 'Dell',
        model: 'Latitude 7450',
        serialNumber: 'SN-DISABLED',
        stateId: 'good',
        stateName: 'Good',
        acquisitionDate: '2026-08-01',
        assignedUserId: 'disabled-agent',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );

  assert.equal(db.document('assets/asset-disabled'), undefined);
  assert.equal(db.pathsMatching(/^assetAssignments\//).length, 0);
  assert.equal(db.pathsMatching(/^assetIdentifierLocks\//).length, 0);
  assert.equal(db.pathsMatching(/^itsmCommandReceipts\//).length, 0);
});

test('serial numbers are unique while product numbers can be shared', async () => {
  const db = fakeDatabase();
  const registration = (assetId, serialNumber, productNumber) => command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    `asset-register-${assetId}-1234`,
    {
      assetId,
      assetTag: serialNumber,
      categoryId: 'laptop',
      categoryName: 'Laptop',
      type: 'Laptop',
      brand: 'Dell',
      model: 'Latitude',
      serialNumber,
      productNumber,
      stateId: 'good',
      stateName: 'Good',
      acquisitionDate: '2026-08-01',
    },
  );

  await execute(db, registration('asset-a', ' SN-UNIQUE-1 ', 'PN-UNIQUE-1'));
  await execute(db, registration('asset-b', 'SN-UNIQUE-2', 'PN-UNIQUE-2'));

  await assert.rejects(
    () => execute(db, registration('asset-c', 'sn-unique-1', 'PN-UNIQUE-3')),
    (error) => error.code === 'already-exists' && /serial number/.test(error.message),
  );
  await execute(db, registration('asset-d', 'SN-UNIQUE-4', 'pn-unique-1'));
  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.updateAsset,
      'asset-update-duplicate-serial-1234',
      {
        assetId: 'asset-b',
        expectedRevision: 0,
        serialNumber: 'SN-UNIQUE-1',
      },
    )),
    (error) => error.code === 'already-exists',
  );

  assert.equal(db.document('assets/asset-b').serialNumber, 'SN-UNIQUE-2');
  assert.equal(db.document('assets/asset-d').productNumber, 'pn-unique-1');
  assert.equal(db.pathsMatching(/^assetIdentifierLocks\//).length, 3);
});

test('legacy assets prevent duplicate serials but allow shared product numbers', async () => {
  const db = fakeDatabase({
    'assets/legacy-asset': {
      assetTag: 'LEGACY-SN-1',
      serialNumber: 'LEGACY-SN-1',
      productNumber: 'LEGACY-PN-1',
      status: 'in_stock',
      revision: 0,
    },
  });
  const registration = (assetId, serialNumber, productNumber) => command(
    ITSM_ASSETS_COMMANDS.registerAsset,
    `legacy-register-${assetId}-1234`,
    {
      assetId,
      assetTag: serialNumber,
      categoryId: 'laptop',
      categoryName: 'Laptop',
      type: 'Laptop',
      brand: 'Dell',
      model: 'Latitude',
      serialNumber,
      productNumber,
      stateId: 'good',
      stateName: 'Good',
      acquisitionDate: '2026-08-01',
    },
  );

  await assert.rejects(
    () => execute(db, registration('duplicate-serial', 'legacy-sn-1', 'NEW-PN')),
    (error) => error.code === 'already-exists' && /serial number/.test(error.message),
  );
  await execute(db, registration('duplicate-product', 'NEW-SN', 'legacy-pn-1'));
  assert.equal(db.document('assets/duplicate-product').productNumber, 'legacy-pn-1');
  assert.equal(db.pathsMatching(/^assetIdentifierLocks\//).length, 1);
  assert.equal(db.pathsMatching(/^assets\/[^/]+$/).length, 2);
});

test('asset state changes require a new state and preserve immutable observations', async () => {
  const db = fakeDatabase({
    'assets/asset-state-1': {
      assetTag: 'ARPTC-STATE-1',
      type: 'laptop',
      status: 'in_stock',
      isInStock: true,
      stateId: 'good',
      stateName: 'Good',
      revision: 3,
    },
  });
  const result = await execute(db, command(
    ITSM_ASSETS_COMMANDS.changeAssetState,
    'asset-state-change-1234',
    {
      assetId: 'asset-state-1',
      expectedRevision: 3,
      stateId: 'damaged',
      stateName: 'Damaged',
      observation: 'Screen cracked during inspection.',
    },
  ));
  assert.equal(result.revision, 4);
  assert.equal(db.document('assets/asset-state-1').stateId, 'damaged');
  assert.equal(db.document('assets/asset-state-1').isInStock, true);
  const events = db.documentsMatching(/^assetStateEvents\//);
  assert.equal(events.length, 1);
  assert.deepEqual(
    {
      fromStateId: events[0].fromStateId,
      toStateId: events[0].toStateId,
      observation: events[0].observation,
      revision: events[0].revision,
    },
    {
      fromStateId: 'good',
      toStateId: 'damaged',
      observation: 'Screen cracked during inspection.',
      revision: 4,
    },
  );
  await assert.rejects(
    () => execute(db, command(
      ITSM_ASSETS_COMMANDS.changeAssetState,
      'asset-state-same-1234',
      {
        assetId: 'asset-state-1',
        expectedRevision: 4,
        stateId: 'damaged',
        stateName: 'Damaged',
        observation: 'No actual state change.',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(db.pathsMatching(/^assetStateEvents\//).length, 1);
});

test('asset parameter commands use Firestore-generated IDs for new values', async () => {
  const db = fakeDatabase();
  const result = await execute(db, command(
    ITSM_ASSETS_COMMANDS.saveAssetParameter,
    'asset-parameter-create-1234',
    {
      type: 'category',
      name: 'Laptop',
      isActive: true,
      sortOrder: 1,
    },
  ));

  const parameter = db.document(`assetParameters/${result.id}`);
  assert.match(result.id, /^generated-/);
  assert.equal(parameter.type, 'category');
  assert.equal(parameter.name, 'Laptop');
  assert.equal(parameter.revision, 0);
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
  assert.equal(db.document('assets/asset-1').isInStock, false);
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
  assert.equal(db.document('assets/asset-1').isInStock, false);
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

test('decommissioning rejects active custody and retires an unassigned asset', async () => {
  const activeDb = fakeDatabase({
    'assets/asset-active': {
      assetTag: 'ACTIVE-1',
      type: 'laptop',
      status: 'assigned',
      isInStock: false,
      assignedUserId: 'user-1',
      currentAssignmentId: 'assignment-active',
      revision: 2,
    },
    'assetAssignmentLocks/asset-active': {
      assetId: 'asset-active',
      assignmentId: 'assignment-active',
      assignedUserId: 'user-1',
      isActive: true,
    },
  });
  await assert.rejects(
    () => execute(activeDb, command(
      ITSM_ASSETS_COMMANDS.decommissionAsset,
      'asset-decommission-active-1234',
      {
        assetId: 'asset-active',
        expectedRevision: 2,
        observation: 'Device reached end of useful life.',
      },
    )),
    (error) => error.code === 'failed-precondition',
  );
  assert.equal(activeDb.document('assets/asset-active').status, 'assigned');

  const db = fakeDatabase({
    'assets/asset-stock': {
      assetTag: 'STOCK-1',
      type: 'laptop',
      status: 'in_stock',
      isInStock: true,
      assignedUserId: null,
      currentAssignmentId: null,
      revision: 5,
    },
  });
  const result = await execute(db, command(
    ITSM_ASSETS_COMMANDS.decommissionAsset,
    'asset-decommission-stock-1234',
    {
      assetId: 'asset-stock',
      expectedRevision: 5,
      observation: 'Mainboard failure is beyond economical repair.',
    },
  ));
  const asset = db.document('assets/asset-stock');
  assert.equal(result.status, 'retired');
  assert.equal(asset.status, 'retired');
  assert.equal(asset.isInStock, false);
  assert.equal(asset.decommissionedBy, manager.uid);
  assert.equal(
    asset.decommissionReason,
    'Mainboard failure is beyond economical repair.',
  );
  assert.equal(db.pathsMatching(/^assetLifecycleEvents\//).length, 1);
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

  let generatedId = 0;
  class Reference {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) {
      const resolvedId = id || `generated-${++generatedId}`;
      return new Reference(`${this.path}/${resolvedId}`);
    }
    where(field, operator, value) {
      return new Query(this.path, [{ field, operator, value }]);
    }
  }
  class Query {
    constructor(path, filters = [], maximum = null) {
      this.path = path;
      this.filters = filters;
      this.maximum = maximum;
    }
    where(field, operator, value) {
      return new Query(
        this.path,
        [...this.filters, { field, operator, value }],
        this.maximum,
      );
    }
    limit(maximum) {
      return new Query(this.path, this.filters, maximum);
    }
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
        get: async (target) => {
          if (target instanceof Reference) return snapshot(target);
          const prefix = `${target.path}/`;
          const values = [...documents.entries()]
            .filter(([path]) =>
              path.startsWith(prefix) && !path.substring(prefix.length).includes('/'),
            )
            .filter(([, value]) => target.filters.every((filter) => {
              if (filter.operator === '==') {
                return value[filter.field] === filter.value;
              }
              if (filter.operator === 'in') {
                return filter.value.includes(value[filter.field]);
              }
              throw new Error(`Unsupported query operator: ${filter.operator}`);
            }))
            .slice(0, target.maximum || undefined)
            .map(([path]) => snapshot(new Reference(path)));
          return { docs: values, empty: values.length === 0, size: values.length };
        },
        create: (reference, value) => writes.push({ kind: 'create', reference, value }),
        set: (reference, value, options) => writes.push({
          kind: 'set',
          reference,
          value,
          options,
        }),
        update: (reference, value) => writes.push({ kind: 'update', reference, value }),
        delete: (reference) => writes.push({ kind: 'delete', reference }),
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
        } else if (write.kind === 'delete') {
          next.delete(path);
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
