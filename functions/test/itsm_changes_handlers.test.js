'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createItsmChangesCallableHandler,
} = require('../src/itsm_changes_handlers');
const { ITSM_CHANGES_COMMANDS } = require('../src/itsm_changes_validation');

class FakeHttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

test('callable rejects unauthenticated requests before validation or profile lookup', async () => {
  let lookups = 0;
  const handler = createHandler({
    expectedCommand: ITSM_CHANGES_COMMANDS.initializeDraft,
    role: 'USER',
    onLookup: () => { lookups += 1; },
  });
  await assert.rejects(
    () => handler({ auth: null, data: draftCommand() }),
    (error) => error.code === 'unauthenticated',
  );
  assert.equal(lookups, 0);
});

test('callable validates the endpoint command before profile lookup', async () => {
  let lookups = 0;
  const handler = createHandler({
    expectedCommand: ITSM_CHANGES_COMMANDS.cancel,
    role: 'USER',
    onLookup: () => { lookups += 1; },
  });
  await assert.rejects(
    () => handler({ auth: { uid: 'user-1', token: {} }, data: draftCommand() }),
    (error) => error.code === 'invalid-argument',
  );
  assert.equal(lookups, 0);
});

test('USER and ADMIN cannot invoke MANAGER operational commands', async () => {
  for (const role of ['USER', 'ADMIN']) {
    const handler = createHandler({
      expectedCommand: ITSM_CHANGES_COMMANDS.assess,
      role,
    });
    await assert.rejects(
      () => handler({
        auth: { uid: role.toLowerCase(), token: {} },
        data: assessmentCommand(),
      }),
      (error) => error.code === 'permission-denied',
    );
  }
});

test('disabled profiles cannot invoke self-service commands', async () => {
  const handler = createHandler({
    expectedCommand: ITSM_CHANGES_COMMANDS.initializeDraft,
    role: 'USER',
    isActive: false,
  });
  await assert.rejects(
    () => handler({ auth: { uid: 'user-1', token: {} }, data: draftCommand() }),
    (error) => error.code === 'permission-denied',
  );
});

test('unexpected failures log bounded diagnostics without request payloads', async () => {
  const logs = [];
  const handler = createHandler({
    expectedCommand: ITSM_CHANGES_COMMANDS.initializeDraft,
    role: 'USER',
    logger: { error: (message, details) => logs.push({ message, details }) },
    db: {
      collection: () => ({ doc: () => ({}) }),
      runTransaction: async () => {
        const error = new Error('Firestore dependency failed');
        error.code = 'firestore/internal';
        throw error;
      },
    },
  });
  const data = draftCommand();
  data.payload.description = 'SENSITIVE-CHANGE-PAYLOAD';
  await assert.rejects(
    () => handler({ auth: { uid: 'user-1', token: {} }, data }),
    (error) => error.code === 'internal',
  );
  assert.equal(logs.length, 1);
  assert.equal(logs[0].details.errorCode, 'firestore/internal');
  assert.match(logs[0].details.errorMessage, /dependency failed/);
  assert.doesNotMatch(JSON.stringify(logs[0]), /SENSITIVE-CHANGE-PAYLOAD/);
});

test('unknown commands cannot be registered as callable endpoints', () => {
  assert.throws(
    () => createItsmChangesCallableHandler({ expectedCommand: 'change.unknown' }),
    /unknown change command/,
  );
});

function createHandler({
  expectedCommand,
  role,
  isActive = true,
  onLookup,
  logger,
  db,
}) {
  return createItsmChangesCallableHandler({
    expectedCommand,
    db: db || {
      collection: () => { throw new Error('Database must not be reached.'); },
    },
    fieldValue: { serverTimestamp: () => 'server-time' },
    timestamp: {
      now: () => new Date('2026-08-01T10:00:00.000Z'),
      fromDate: (date) => date.toISOString(),
    },
    findAgent: async () => {
      onLookup?.();
      return {
        firstName: 'Authoritative',
        name: 'Agent',
        email: 'agent@arptc.cd',
        isActive,
        modulePermissions: { ticketing: role },
      };
    },
    HttpsError: FakeHttpsError,
    logger,
  });
}

function draftCommand() {
  return {
    command: ITSM_CHANGES_COMMANDS.initializeDraft,
    idempotencyKey: 'handler-draft-1234',
    payload: {
      workflowDefinitionId: 'change-workflow',
      changeType: 'normal',
      title: 'Network change',
      description: 'Upgrade the network.',
      justification: 'Improve reliability.',
    },
  };
}

function assessmentCommand() {
  return {
    command: ITSM_CHANGES_COMMANDS.assess,
    idempotencyKey: 'handler-assess-1234',
    payload: {
      changeId: 'change-1',
      expectedRevision: 1,
      ownerUserId: 'manager-1',
      affectedServiceIds: ['network'],
      impact: 'medium',
      urgency: 'medium',
      complexity: 'medium',
      expectedDowntimeMinutes: 30,
      implementationPlan: 'Deploy.',
      testPlan: 'Test.',
      communicationPlan: 'Notify.',
      rollbackPlan: 'Rollback.',
    },
  };
}
