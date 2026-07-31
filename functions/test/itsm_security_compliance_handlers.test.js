'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createItsmSecurityComplianceCallableHandler,
  safeUnexpectedError,
} = require('../src/itsm_security_compliance_handlers');
const {
  SECURITY_COMPLIANCE_COMMANDS: C,
} = require('../src/itsm_security_compliance_validation');

class HttpsError extends Error {
  constructor(code, message, details) {
    super(message); this.code = code; this.details = details;
  }
}

test('handler rejects unauthenticated callers before profile lookup', async () => {
  let profileRead = false;
  const handler = factory(C.createFinding, async () => {
    profileRead = true;
    return managerAgent();
  });
  await assert.rejects(
    handler({ auth: null, data: {} }),
    (error) => error.code === 'unauthenticated',
  );
  assert.equal(profileRead, false);
});

test('handler derives role from trusted agent instead of request data', async () => {
  const handler = factory(C.createFinding, async () => userAgent());
  await assert.rejects(
    handler({
      auth: { uid: 'user-1', token: { email: 'user@arptc.cd' } },
      data: {
        command: C.createFinding,
        idempotencyKey: 'handler-test-1234',
        payload: {
          title: 'Finding', description: 'Description', source: 'scan',
          severity: 'high', risk: 'high',
        },
      },
    }),
    (error) => error.code === 'permission-denied',
  );
});

test('handler rejects a client-forged role field as unsupported input', async () => {
  const handler = factory(C.createFinding, async () => managerAgent());
  const value = validFindingCommand();
  value.payload.actorRole = 'MANAGER';
  await assert.rejects(
    handler({ auth: { uid: 'manager-1', token: {} }, data: value }),
    (error) => error.code === 'invalid-argument',
  );
});

test('handler maps disabled and missing profiles to permission denied', async () => {
  for (const profile of [null, { ...managerAgent(), isActive: false }]) {
    const handler = factory(C.createFinding, async () => profile);
    await assert.rejects(
      handler({
        auth: { uid: 'manager-1', token: {} },
        data: validFindingCommand(),
      }),
      (error) => error.code === 'permission-denied',
    );
  }
});

test('unknown handler registration is rejected synchronously', () => {
  assert.throws(
    () => factory('security.unknown', async () => managerAgent()),
    /unknown security command/,
  );
});

test('unexpected errors are logged without exposing arbitrary objects', async () => {
  const logs = [];
  const handler = createItsmSecurityComplianceCallableHandler({
    expectedCommand: C.createFinding,
    db: {}, fieldValue: {}, timestamp: {},
    findAgent: async () => { throw new Error('database unavailable'); },
    HttpsError,
    logger: { error: (...args) => logs.push(args) },
  });
  await assert.rejects(
    handler({ auth: { uid: 'manager-1', token: {} }, data: validFindingCommand() }),
    (error) => error.code === 'internal' && !/database unavailable/.test(error.message),
  );
  assert.equal(logs.length, 1);
  assert.equal(logs[0][1].errorMessage, 'database unavailable');
});

test('safe unexpected errors are bounded', () => {
  const safe = safeUnexpectedError('command', {
    name: 'Failure', code: 'x', message: 'm'.repeat(3000),
    stack: 'line\n'.repeat(1000),
  });
  assert.equal(safe.errorMessage.length, 2000);
  assert(safe.errorStack.length <= 8000);
});

function factory(expectedCommand, findAgent) {
  return createItsmSecurityComplianceCallableHandler({
    expectedCommand,
    db: {}, fieldValue: {}, timestamp: {}, findAgent, HttpsError,
    logger: { error: () => {} },
  });
}

function validFindingCommand() {
  return {
    command: C.createFinding,
    idempotencyKey: 'handler-test-1234',
    payload: {
      title: 'Finding', description: 'Description', source: 'scan',
      severity: 'high', risk: 'high',
    },
  };
}

function managerAgent() {
  return {
    firstName: 'Manager', isActive: true,
    modulePermissions: { ticketing: 'MANAGER' },
  };
}

function userAgent() {
  return {
    firstName: 'User', isActive: true,
    modulePermissions: { ticketing: 'USER' },
  };
}
