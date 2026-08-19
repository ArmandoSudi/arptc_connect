'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createItsmAssetsCallableHandler,
} = require('../src/itsm_assets_handlers');
const { ITSM_ASSETS_COMMANDS } = require('../src/itsm_assets_validation');

class FakeHttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

test('assets callable rejects unauthenticated requests before profile lookup', async () => {
  let lookups = 0;
  const handler = createHandler('MANAGER', () => { lookups += 1; });
  await assert.rejects(
    () => handler({ auth: null, data: registerCommand() }),
    (error) => error.code === 'unauthenticated',
  );
  assert.equal(lookups, 0);
});

test('USER and ADMIN cannot invoke operational asset commands', async () => {
  for (const role of ['USER', 'ADMIN']) {
    const handler = createHandler(role);
    await assert.rejects(
      () => handler({
        auth: { uid: `${role.toLowerCase()}-1`, token: {} },
        data: registerCommand(),
      }),
      (error) => error.code === 'permission-denied',
    );
  }
});

test('disabled MANAGER profiles cannot invoke asset commands', async () => {
  const handler = createHandler('MANAGER', null, false);
  await assert.rejects(
    () => handler({
      auth: { uid: 'manager-1', token: {} },
      data: registerCommand(),
    }),
    (error) => error.code === 'permission-denied',
  );
});

test('assets callable validates its dedicated endpoint command', async () => {
  const handler = createHandler('MANAGER');
  await assert.rejects(
    () => handler({
      auth: { uid: 'manager-1', token: {} },
      data: {
        command: ITSM_ASSETS_COMMANDS.registerLicence,
        idempotencyKey: 'wrong-endpoint-1234',
        payload: {},
      },
    }),
    (error) => error.code === 'invalid-argument',
  );
});

test('unexpected callable failures log bounded diagnostics without request data', async () => {
  const logs = [];
  const handler = createItsmAssetsCallableHandler({
    expectedCommand: ITSM_ASSETS_COMMANDS.registerAsset,
    db: {
      runTransaction: async () => {
        const error = new Error('Admin SDK transaction failed');
        error.code = 'firestore/internal';
        throw error;
      },
      collection: () => ({ doc: () => ({}) }),
    },
    fieldValue: { serverTimestamp: () => 'server-time' },
    findAgent: async () => ({
      firstName: 'Test',
      name: 'Agent',
      isActive: true,
      modulePermissions: { ticketing: 'MANAGER' },
    }),
    HttpsError: FakeHttpsError,
    logger: { error: (message, details) => logs.push({ message, details }) },
  });
  const data = registerCommand();
  data.payload.description = 'SENSITIVE-PAYLOAD-MARKER';
  await assert.rejects(
    () => handler({ auth: { uid: 'manager-1', token: {} }, data }),
    (error) => error.code === 'internal',
  );
  assert.equal(logs.length, 1);
  assert.equal(logs[0].details.errorCode, 'firestore/internal');
  assert.equal(logs[0].details.errorMessage, 'Admin SDK transaction failed');
  assert.match(logs[0].details.errorStack, /Admin SDK transaction failed/);
  assert.doesNotMatch(JSON.stringify(logs[0]), /SENSITIVE-PAYLOAD-MARKER/);
});

function createHandler(role, onLookup, isActive = true) {
  return createItsmAssetsCallableHandler({
    expectedCommand: ITSM_ASSETS_COMMANDS.registerAsset,
    db: { collection: () => { throw new Error('Database must not be reached.'); } },
    fieldValue: {},
    findAgent: async () => {
      onLookup?.();
      return {
        firstName: 'Test',
        name: 'Agent',
        email: 'test@arptc.cd',
        isActive,
        modulePermissions: { ticketing: role },
      };
    },
    HttpsError: FakeHttpsError,
  });
}

function registerCommand() {
  return {
    command: ITSM_ASSETS_COMMANDS.registerAsset,
    idempotencyKey: 'register-asset-1234',
    payload: {
      assetId: 'asset-1',
      assetTag: 'ARPTC-001',
      categoryId: 'computer',
      categoryName: 'Computer',
      type: 'laptop',
      brand: 'Dell',
      model: 'Latitude',
      serialNumber: 'SN-001',
      locationId: 'kinshasa-hq',
      locationName: 'Kinshasa HQ',
      stateId: 'new',
      stateName: 'New',
      acquisitionDate: '2026-08-01',
      status: 'in_stock',
    },
  };
}
