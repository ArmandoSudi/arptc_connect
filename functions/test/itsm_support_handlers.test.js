'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createItsmSupportCallableHandler,
} = require('../src/itsm_support_handlers');
const {
  ITSM_SUPPORT_COMMANDS,
} = require('../src/itsm_support_validation');

class FakeHttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

test('support callable rejects unauthenticated requests before profile lookup', async () => {
  let lookups = 0;
  const handler = createHandler({
    command: ITSM_SUPPORT_COMMANDS.recordKnowledgeView,
    findAgent: async () => {
      lookups += 1;
      return agent('USER');
    },
  });

  await assert.rejects(
    () => handler({
      auth: null,
      data: knowledgeViewCommand(),
    }),
    (error) => error.code === 'unauthenticated',
  );
  assert.equal(lookups, 0);
});

test('ADMIN cannot cross the MANAGER task command boundary', async () => {
  const handler = createHandler({
    command: ITSM_SUPPORT_COMMANDS.updateServiceRequestTask,
    findAgent: async () => agent('ADMIN'),
  });

  await assert.rejects(
    () => handler({
      auth: { uid: 'admin-1', token: { email: 'admin@arptc.cd' } },
      data: {
        command: ITSM_SUPPORT_COMMANDS.updateServiceRequestTask,
        idempotencyKey: 'task-command-1234',
        payload: {
          requestId: 'request-1',
          taskId: 'task-1',
          status: 'in_progress',
        },
      },
    }),
    (error) => error.code === 'permission-denied',
  );
});

test('disabled profiles cannot invoke self-service commands', async () => {
  const handler = createHandler({
    command: ITSM_SUPPORT_COMMANDS.recordKnowledgeView,
    findAgent: async () => ({ ...agent('USER'), isActive: false }),
  });

  await assert.rejects(
    () => handler({
      auth: { uid: 'user-1', token: {} },
      data: knowledgeViewCommand(),
    }),
    (error) => error.code === 'permission-denied',
  );
});

function createHandler({ command, findAgent }) {
  return createItsmSupportCallableHandler({
    expectedCommand: command,
    db: {
      collection() {
        throw new Error('Database should not be reached.');
      },
    },
    fieldValue: {},
    timestamp: {},
    findAgent,
    HttpsError: FakeHttpsError,
  });
}

function agent(role) {
  return {
    firstName: 'Test',
    name: 'Agent',
    email: 'test@arptc.cd',
    isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function knowledgeViewCommand() {
  return {
    command: ITSM_SUPPORT_COMMANDS.recordKnowledgeView,
    idempotencyKey: 'knowledge-view-1234',
    payload: { articleId: 'article-1' },
  };
}
