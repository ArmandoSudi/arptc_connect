'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  ITSM_ASSETS_COMMANDS,
  validateAssetsCommand,
} = require('../src/itsm_assets_validation');

test('stock validation rejects zero, fractional, and negative movement quantities', () => {
  for (const quantity of [0, -1, 1.5]) {
    assert.throws(
      () => validate(ITSM_ASSETS_COMMANDS.receiveStock, {
        stockItemId: 'laptop',
        quantity,
        destinationLocationId: 'main',
        reason: 'Delivery',
      }),
      (error) => error.code === 'invalid-argument',
    );
  }
});

test('stock validation requires directional locations and receiving parties', () => {
  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.transferStock, {
      stockItemId: 'laptop',
      quantity: 1,
      sourceLocationId: 'main',
      destinationLocationId: 'main',
      reason: 'Move',
    }),
    /source and destination must be different/,
  );
  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.issueStock, {
      stockItemId: 'laptop',
      quantity: 1,
      sourceLocationId: 'main',
      reason: 'Issue',
    }),
    /recipientUserId is required/,
  );
});

test('adjustment and reconciliation require supporting evidence metadata', () => {
  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.adjustStock, {
      stockItemId: 'cable',
      sourceLocationId: 'main',
      adjustmentDelta: -2,
      reason: 'Damaged items',
    }),
    /supportingDocument is required/,
  );
  const command = validate(ITSM_ASSETS_COMMANDS.reconcileStock, {
    stockItemId: 'cable',
    sourceLocationId: 'main',
    targetOnHand: 8,
    targetReserved: 1,
    reason: 'Cycle count',
    supportingDocument: documentMetadata(),
  });
  assert.equal(command.payload.supportingDocument.attachmentId, 'count-sheet');
});

test('licence secrets and unrestricted secret-like CI fields are rejected', () => {
  assert.throws(
    () => validateAssetsCommand({
      command: ITSM_ASSETS_COMMANDS.registerLicence,
      idempotencyKey: 'licence-secret-1234',
      payload: {
        licenceId: 'office',
        softwareProduct: 'Office',
        vendor: 'Vendor',
        licenceType: 'subscription',
        purchasedQuantity: 10,
        licenceKey: 'DO-NOT-STORE',
      },
    }),
    /unsupported fields: licenceKey/,
  );
  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.saveConfigurationItem, {
      ciId: 'app-1',
      name: 'Payroll',
      ciType: 'application',
      configurationBaseline: { adminPassword: 'secret' },
    }),
    /cannot contain secret fields/,
  );
});

test('relationship validation accepts only known directional vocabulary', () => {
  const command = validate(ITSM_ASSETS_COMMANDS.createCiRelationship, {
    relationshipId: 'rel-1',
    relationshipType: 'runs_on',
    sourceEntityType: 'configuration_item',
    sourceEntityId: 'application-1',
    targetEntityType: 'configuration_item',
    targetEntityId: 'server-1',
  });
  assert.equal(command.payload.relationshipType, 'runs_on');
  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.createCiRelationship, {
      relationshipId: 'rel-2',
      relationshipType: 'contains_secret',
      sourceEntityType: 'configuration_item',
      sourceEntityId: 'application-1',
      targetEntityType: 'configuration_item',
      targetEntityId: 'server-1',
    }),
    /relationshipType must be one of/,
  );
});

test('stock location and item save commands validate strict revisioned records', () => {
  const location = validate(ITSM_ASSETS_COMMANDS.saveStockLocation, {
    id: 'main-store',
    name: 'Main store',
    siteId: 'kinshasa-hq',
    siteName: 'Kinshasa HQ',
    isActive: true,
  });
  assert.equal(location.payload.expectedRevision, null);
  assert.equal(location.payload.isActive, true);

  const item = validate(ITSM_ASSETS_COMMANDS.saveStockItem, {
    id: 'usb-cable',
    sku: 'USB-C-001',
    name: 'USB-C cable',
    kind: 'consumable',
    unitOfMeasure: 'piece',
    minimumQuantity: 5,
  });
  assert.equal(item.payload.minimumQuantity, 5);
  assert.equal(item.payload.kind, 'consumable');

  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.saveStockItem, {
      id: 'bad-item',
      sku: 'BAD',
      name: 'Bad item',
      kind: 'unknown',
      minimumQuantity: 0,
    }),
    /kind must be one of/,
  );
  assert.throws(
    () => validate(ITSM_ASSETS_COMMANDS.saveStockLocation, {
      id: 'bad-location',
      name: 'Bad location',
      siteId: 'site-1',
      siteName: 'Site',
      isActive: 'yes',
    }),
    /isActive must be a boolean/,
  );
});

function validate(command, payload) {
  return validateAssetsCommand({
    command,
    idempotencyKey: `${command.replaceAll('.', '-')}-1234`,
    payload,
  });
}

function documentMetadata() {
  return {
    attachmentId: 'count-sheet',
    storagePath: 'itsm/stock/count-sheet.pdf',
    fileName: 'count-sheet.pdf',
    contentType: 'application/pdf',
    sizeBytes: 1024,
    checksum: 'sha256:abc',
  };
}
