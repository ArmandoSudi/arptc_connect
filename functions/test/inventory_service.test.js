'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  INVENTORY_COMMANDS,
  InventoryCommandError,
  authorizeCommand,
  balanceDocumentId,
  createInventoryCallableHandler,
  inventoryRole,
  payloadDigest,
} = require('../src/inventory_service');

test('resolves only the dedicated Inventory permission', () => {
  assert.equal(inventoryRole({ modulePermissions: { inventory: 'manager' } }), 'MANAGER');
  assert.equal(inventoryRole({ modulePermissions: { inventaire: 'USER' } }), 'USER');
  assert.equal(inventoryRole({ modulePermissions: { ticketing: 'MANAGER' } }), 'NONE');
});

test('normalizes Inventory roles and gives the canonical key precedence', () => {
  assert.equal(
    inventoryRole({ modulePermissions: { inventory: ' admin ' } }),
    'ADMIN',
  );
  assert.equal(
    inventoryRole({
      modulePermissions: { inventory: 'USER', inventaire: 'MANAGER' },
    }),
    'USER',
  );
  assert.equal(inventoryRole({}), 'NONE');
  assert.equal(inventoryRole({ modulePermissions: null }), 'NONE');
  assert.equal(inventoryRole({ modulePermissions: [] }), 'NONE');
});

test('keeps ADMIN commands read-only', () => {
  for (const command of Object.values(INVENTORY_COMMANDS)) {
    assert.throws(
      () => authorizeCommand(command, 'ADMIN'),
      (error) => error instanceof InventoryCommandError &&
        error.code === 'permission-denied' &&
        /read-only/.test(error.message),
      `ADMIN unexpectedly received mutation access to ${command}`,
    );
  }
  assert.doesNotThrow(
    () => authorizeCommand(INVENTORY_COMMANDS.saveItem, 'MANAGER'),
  );
  assert.doesNotThrow(
    () => authorizeCommand(INVENTORY_COMMANDS.submitRequest, 'USER'),
  );
});

test('callable authorization rejects ADMIN before executing a mutation', async () => {
  class TestHttpsError extends Error {
    constructor(code, message, details) {
      super(message);
      this.code = code;
      this.details = details;
    }
  }
  const handler = createInventoryCallableHandler({
    expectedCommand: INVENTORY_COMMANDS.receiveStock,
    db: {
      collection: () => ({
        doc: () => ({
          get: async () => ({
            exists: true,
            data: () => ({
              isActive: true,
              modulePermissions: { inventory: 'ADMIN' },
            }),
          }),
        }),
      }),
    },
    fieldValue: {},
    timestamp: {},
    HttpsError: TestHttpsError,
  });

  await assert.rejects(
    handler({
      auth: {
        uid: 'admin-1',
        token: { email_verified: true },
      },
      data: { commandId: 'admin-mutation-attempt' },
    }),
    (error) => error instanceof TestHttpsError &&
      error.code === 'permission-denied' &&
      /read-only/.test(error.message),
  );
});

test('enforces the complete Inventory command role matrix', () => {
  const userCommands = new Set([
    INVENTORY_COMMANDS.submitRequest,
    INVENTORY_COMMANDS.cancelRequest,
    INVENTORY_COMMANDS.confirmReceipt,
  ]);
  const managerCommands = new Set([
    ...Object.values(INVENTORY_COMMANDS),
  ]);
  managerCommands.delete(INVENTORY_COMMANDS.cancelRequest);
  managerCommands.delete(INVENTORY_COMMANDS.confirmReceipt);

  for (const command of Object.values(INVENTORY_COMMANDS)) {
    if (userCommands.has(command)) {
      assert.doesNotThrow(
        () => authorizeCommand(command, 'USER'),
        `USER should be allowed to execute ${command}`,
      );
    } else {
      assert.throws(
        () => authorizeCommand(command, 'USER'),
        InventoryCommandError,
        `USER unexpectedly received access to ${command}`,
      );
    }

    if (managerCommands.has(command)) {
      assert.doesNotThrow(
        () => authorizeCommand(command, 'MANAGER'),
        `MANAGER should be allowed to execute ${command}`,
      );
    } else {
      assert.throws(
        () => authorizeCommand(command, 'MANAGER'),
        InventoryCommandError,
        `MANAGER unexpectedly received access to ${command}`,
      );
    }

    assert.throws(
      () => authorizeCommand(command, 'NONE'),
      (error) => error instanceof InventoryCommandError &&
        error.code === 'permission-denied',
      `NONE unexpectedly received access to ${command}`,
    );
  }
});

test('restricts cancellation and receipt confirmation to USER', () => {
  assert.doesNotThrow(
    () => authorizeCommand(INVENTORY_COMMANDS.confirmReceipt, 'USER'),
  );
  assert.throws(
    () => authorizeCommand(INVENTORY_COMMANDS.cancelRequest, 'MANAGER'),
    /requested-for USER/,
  );
});

test('command payload digests are stable regardless of map key order', () => {
  assert.equal(
    payloadDigest({ commandId: 'one', payload: { b: 2, a: 1 } }),
    payloadDigest({ payload: { a: 1, b: 2 }, commandId: 'one' }),
  );
  assert.notEqual(
    payloadDigest({ commandId: 'one', quantityMilli: 1000 }),
    payloadDigest({ commandId: 'one', quantityMilli: 2000 }),
  );
});

test('balance IDs are deterministic per item and location', () => {
  assert.equal(
    balanceDocumentId('paper', 'central-a'),
    balanceDocumentId('paper', 'central-a'),
  );
  assert.notEqual(
    balanceDocumentId('paper', 'central-a'),
    balanceDocumentId('paper', 'central-b'),
  );
});
