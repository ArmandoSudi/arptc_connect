'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildImmutableAuditEvent,
  buildTrustedWorkItemSummary,
  validateNotificationRecipients,
  validateTransition,
} = require('../src/itsm_command_service');
const {
  buildIdempotencyDocumentId,
  runIdempotentCommand,
} = require('../src/itsm_idempotency');

test('idempotency IDs are stable and scoped by actor and command', () => {
  const first = buildIdempotencyDocumentId(
    'agent-1',
    'workflow.transition',
    'request-1234',
  );
  assert.equal(
    first,
    buildIdempotencyDocumentId(
      'agent-1',
      'workflow.transition',
      'request-1234',
    ),
  );
  assert.notEqual(
    first,
    buildIdempotencyDocumentId(
      'agent-2',
      'workflow.transition',
      'request-1234',
    ),
  );
});

test('an idempotent command executes once and replays its receipt', async () => {
  const db = fakeDatabase();
  let executionCount = 0;
  const arguments_ = {
    db,
    fieldValue: { serverTimestamp: () => 'server-time' },
    actorUid: 'agent-1',
    command: 'workflow.transition',
    idempotencyKey: 'request-1234',
    execute: async () => {
      executionCount += 1;
      return { status: 'assigned', workflowRevision: 1 };
    },
  };

  const first = await runIdempotentCommand(arguments_);
  const replay = await runIdempotentCommand(arguments_);

  assert.equal(executionCount, 1);
  assert.deepEqual(first, replay);
  assert.deepEqual(replay, { status: 'assigned', workflowRevision: 1 });
});

test('audit events replace forged actor data with immutable server identity', () => {
  const event = buildImmutableAuditEvent({
    actor: {
      uid: 'trusted-agent',
      displayName: 'Trusted Agent',
      email: 'trusted@arptc.cd',
      role: 'MANAGER',
    },
    envelope: {
      command: 'audit.index',
      idempotencyKey: 'audit-1234',
      entityType: 'incident',
      entityId: 'INC-1',
    },
    eventType: 'incident.updated',
    action: 'categorize',
    summary: 'Incident categorized.',
    before: { actorUserId: 'forged-agent', status: 'open' },
    after: { status: 'in_progress' },
    createdAt: 'server-time',
  });

  assert.equal(event.actorUserId, 'trusted-agent');
  assert.equal(event.actorRole, 'MANAGER');
  assert.equal(event.createdAt, 'server-time');
  assert.equal(Object.isFrozen(event), true);
  assert.equal(Object.isFrozen(event.before), true);
  assert.throws(() => {
    event.before.status = 'tampered';
  });
  assert.equal(event.before.status, 'open');
});

test('trusted work-item indexes use the shared requester and assignment keys', () => {
  const summary = buildTrustedWorkItemSummary({
    actor: { uid: 'manager-1' },
    envelope: {
      entityType: 'incident',
      entityId: 'INC-1',
    },
    workItem: {
      ticketNumber: 'INC-0001',
      title: 'Network unavailable',
      description: 'No connectivity',
      status: 'open',
      lifecycleState: 'active',
      priority: 'P1',
      createdByUserId: 'user-1',
      createdByEmail: 'USER@ARPTC.CD',
      assignedToUserId: 'manager-1',
      affectedServiceId: 'internet',
      confidentiality: 'INTERNAL',
      createdAt: 'created-time',
      updatedAt: 'updated-time',
    },
    sourcePath: 'incidentTickets/INC-1',
    updatedAt: 'index-time',
  });

  assert.equal(summary.id, 'INC-1');
  assert.equal(summary.type, 'incident');
  assert.equal(summary.reference, 'INC-0001');
  assert.equal(summary.requesterId, 'user-1');
  assert.equal(summary.assignedUserId, 'manager-1');
  assert.equal(summary.serviceId, 'internet');
  assert.equal(summary.confidentiality, 'internal');
  assert.equal(summary.selfServiceVisible, true);
});

test('workflow transitions enforce Dart field aliases and mandatory fields', () => {
  const transition = {
    id: 'submit',
    fromState: 'draft',
    toState: 'submitted',
    allowedRoles: ['USER'],
    mandatoryFields: ['title', 'request.details'],
    isAuditable: true,
  };

  assert.doesNotThrow(() =>
    validateTransition({
      transition,
      currentState: 'draft',
      requestedState: 'submitted',
      actorRole: 'USER',
      workItem: {
        title: 'Request a computer',
        request: { details: 'Needed for field work' },
      },
    }),
  );
  assert.throws(
    () =>
      validateTransition({
        transition,
        currentState: 'draft',
        requestedState: 'submitted',
        actorRole: 'USER',
        workItem: { title: 'Request a computer' },
      }),
    (error) =>
      error.code === 'failed-precondition' &&
      error.details.missingFields.includes('request.details'),
  );
  assert.throws(
    () =>
      validateTransition({
        transition: { ...transition, isAuditable: false },
        currentState: 'draft',
        requestedState: 'submitted',
        actorRole: 'USER',
        workItem: {
          title: 'Request a computer',
          request: { details: 'Needed for field work' },
        },
      }),
    (error) => error.code === 'failed-precondition',
  );
});

test('specific notifications are limited to work-item participants', () => {
  const workItem = {
    requesterUserId: 'user-1',
    requesterEmail: 'user1@arptc.cd',
    assignedToUserId: 'manager-1',
    assignedToEmail: 'manager@arptc.cd',
  };
  assert.doesNotThrow(() =>
    validateNotificationRecipients(
      { type: 'USERS', userIds: ['user-1'], userEmails: [] },
      workItem,
    ),
  );
  assert.throws(
    () =>
      validateNotificationRecipients(
        { type: 'USERS', userIds: ['unrelated-user'], userEmails: [] },
        workItem,
      ),
    (error) => error.code === 'permission-denied',
  );
});

function fakeDatabase() {
  const documents = new Map();
  return {
    collection(collectionName) {
      return {
        doc(documentId) {
          const path = `${collectionName}/${documentId}`;
          return { path };
        },
      };
    },
    async runTransaction(callback) {
      const pending = [];
      const transaction = {
        async get(reference) {
          const value = documents.get(reference.path);
          return {
            exists: value !== undefined,
            get(field) {
              return value && value[field];
            },
          };
        },
        create(reference, value) {
          pending.push({ reference, value });
        },
      };
      const result = await callback(transaction);
      for (const entry of pending) {
        if (documents.has(entry.reference.path)) {
          throw new Error('already exists');
        }
        documents.set(entry.reference.path, entry.value);
      }
      return result;
    },
  };
}
