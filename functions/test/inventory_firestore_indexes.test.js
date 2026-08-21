'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const assert = require('node:assert/strict');

const configuration = JSON.parse(fs.readFileSync(
  path.resolve(__dirname, '../../firestore.indexes.json'),
  'utf8',
));

const requiredSignatures = new Set([
  'inventoryCatalogProjections|isActive:ASCENDING,isRequestable:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryCatalogProjections|isActive:ASCENDING,isRequestable:ASCENDING,categoryId:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryItems|isActive:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryItems|categoryId:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryItems|isActive:ASCENDING,categoryId:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryWarehouses|isActive:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryLocations|warehouseId:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryParameters|type:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'inventoryBalances|itemId:ASCENDING,itemNameLower:ASCENDING,__name__:ASCENDING',
  'inventoryBalances|warehouseId:ASCENDING,isLowStock:ASCENDING,itemNameLower:ASCENDING,__name__:ASCENDING',
  'inventoryStockMovements|itemId:ASCENDING,createdAt:DESCENDING,__name__:DESCENDING',
  'inventoryStockMovements|relatedRequestId:ASCENDING,createdAt:DESCENDING,__name__:DESCENDING',
  'inventoryStockMovements|itemId:ASCENDING,relatedRequestId:ASCENDING,createdAt:DESCENDING,__name__:DESCENDING',
  'materialRequests|requestedFor.userId:ASCENDING,updatedAt:DESCENDING,__name__:DESCENDING',
  'materialRequests|requestedFor.userId:ASCENDING,status:ASCENDING,updatedAt:DESCENDING,__name__:DESCENDING',
  'materialRequests|assignedManager.userId:ASCENDING,updatedAt:DESCENDING,__name__:DESCENDING',
  'materialRequests|assignedManager.userId:ASCENDING,status:ASCENDING,updatedAt:DESCENDING,__name__:DESCENDING',
  'materialRequests|status:ASCENDING,updatedAt:DESCENDING,__name__:DESCENDING',
  'inventoryAlerts|isActive:ASCENDING,triggeredAt:DESCENDING,__name__:DESCENDING',
]);

test('inventory composite indexes exactly match repository query contracts', () => {
  const inventoryIndexes = configuration.indexes.filter((index) =>
    index.collectionGroup.startsWith('inventory') ||
      index.collectionGroup === 'materialRequests');
  const signatures = inventoryIndexes.map(indexSignature);
  assert.equal(
    new Set(signatures).size,
    signatures.length,
    'Inventory indexes must not contain duplicate definitions.',
  );
  assert.deepEqual(
    new Set(signatures),
    requiredSignatures,
    'Inventory indexes must not be missing or include obsolete contracts.',
  );
  assert.ok(
    inventoryIndexes.every((index) => index.queryScope === 'COLLECTION'),
    'Inventory indexes must match top-level collection queries.',
  );
  assert.ok(
    inventoryIndexes.every((index) => index.fields.length >= 3),
    'Do not configure unnecessary single-field Inventory indexes.',
  );
});

function indexSignature(index) {
  const fields = index.fields.map((field) =>
    `${field.fieldPath}:${field.order || field.arrayConfig}`);
  return `${index.collectionGroup}|${fields.join(',')}`;
}
