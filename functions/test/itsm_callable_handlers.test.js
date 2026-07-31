const assert = require('node:assert/strict');
const test = require('node:test');

const {
  ITSM_COMMANDS,
} = require('../src/itsm_command_validation');
const {
  createItsmCallableHandler,
} = require('../src/itsm_callable_handlers');

class FakeHttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

test('callable boundary rejects unauthenticated requests before profile lookup', async () => {
  let lookupCount = 0;
  const handler = handlerWith({
    expectedCommand: ITSM_COMMANDS.indexAuditEvent,
    findAgent: async () => {
      lookupCount += 1;
      return manager();
    },
  });

  await assert.rejects(
    () => handler({ auth: null, data: auditCommand() }),
    (error) => error.code === 'unauthenticated',
  );
  assert.equal(lookupCount, 0);
});

test('callable boundary denies ADMIN mutation commands', async () => {
  const handler = handlerWith({
    expectedCommand: ITSM_COMMANDS.indexAuditEvent,
    findAgent: async () => ({
      ...manager(),
      modulePermissions: { ticketing: 'ADMIN' },
    }),
  });

  await assert.rejects(
    () =>
      handler({
        auth: { uid: 'admin-1', token: { email: 'admin@arptc.cd' } },
        data: auditCommand(),
      }),
    (error) => error.code === 'permission-denied',
  );
});

test('callable boundary denies a disabled MANAGER profile', async () => {
  const handler = handlerWith({
    expectedCommand: ITSM_COMMANDS.indexAuditEvent,
    findAgent: async () => ({ ...manager(), isActive: false }),
  });

  await assert.rejects(
    () =>
      handler({
        auth: { uid: 'manager-1', token: {} },
        data: auditCommand(),
      }),
    (error) => error.code === 'permission-denied',
  );
});

function handlerWith({ expectedCommand, findAgent }) {
  return createItsmCallableHandler({
    expectedCommand,
    db: {
      collection() {
        throw new Error('Database should not be reached in this test.');
      },
    },
    fieldValue: { serverTimestamp: () => 'server-time' },
    findAgent,
    HttpsError: FakeHttpsError,
  });
}

function manager() {
  return {
    firstName: 'IT',
    name: 'Manager',
    email: 'manager@arptc.cd',
    isActive: true,
    modulePermissions: { ticketing: 'MANAGER' },
  };
}

function auditCommand() {
  return {
    command: ITSM_COMMANDS.indexAuditEvent,
    idempotencyKey: 'audit-event-1234',
    entityType: 'incident',
    entityId: 'INC-1',
    payload: {
      auditEventId: 'audit-1',
    },
  };
}
