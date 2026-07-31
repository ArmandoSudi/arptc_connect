'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { executeItsmCommand } = require('../src/itsm_command_service');

const fieldValue = { serverTimestamp: () => 'server-time' };

test('ADMIN transitions only their own service request through self-service', async () => {
  const workflow = {
    transitions: [{
      id: 'cancel',
      fromState: 'submitted',
      toState: 'cancelled',
      allowedRoles: ['ADMIN'],
      selfServiceAllowed: true,
      isAuditable: true,
    }],
  };
  const db = fakeDatabase({
    'serviceRequests/own': request('admin-1'),
    'serviceRequests/other': request('user-2'),
    'incidentTickets/incident-own': {
      ...request('admin-1'),
      ticketNumber: 'INC-1',
    },
    'workflowDefinitions/request-flow/versions/000001': workflow,
  });
  const actor = {
    uid: 'admin-1',
    email: 'admin@arptc.cd',
    displayName: 'Admin',
    role: 'ADMIN',
  };
  const result = await executeItsmCommand({
    db,
    fieldValue,
    actor,
    envelope: transitionEnvelope('own', 'service_request', 'admin-own-1234'),
  });
  assert.equal(result.status, 'cancelled');
  const own = db.document('serviceRequests/own');
  assert.equal(own.lifecycleState, 'closed');
  assert.equal(own.cancellationReason, 'No longer required');
  assert.equal(own.closedAt, 'server-time');
  assert.equal(
    db.document('serviceRequests/own/workflowInstances/current').state,
    'cancelled',
  );
  assert.equal(
    db.document('itsmWorkItemIndex/service_request:own').status,
    'cancelled',
  );

  await assert.rejects(
    () => executeItsmCommand({
      db,
      fieldValue,
      actor,
      envelope: transitionEnvelope('other', 'service_request', 'admin-other-1234'),
    }),
    (error) => error.code === 'permission-denied',
  );
  await assert.rejects(
    () => executeItsmCommand({
      db,
      fieldValue,
      actor,
      envelope: transitionEnvelope(
        'incident-own',
        'incident',
        'admin-incident-1234',
      ),
    }),
    (error) => error.code === 'permission-denied',
  );
});

test('approval decisions enforce singular assignment, groups, and self-approval', async () => {
  const seed = {
    'serviceRequests/request-1': request('user-1'),
    'serviceRequests/request-1/approvals/named': {
      status: 'pending',
      approverUserId: 'manager-2',
    },
    'serviceRequests/request-1/approvals/group': {
      status: 'pending',
      approverGroupId: 'service-desk',
    },
    'serviceRequests/self': request('manager-1'),
    'serviceRequests/self/approvals/group': {
      status: 'pending',
      approverGroupId: 'service-desk',
    },
    'agents/manager-1': {
      assignmentGroupIds: ['service-desk'],
    },
  };
  const db = fakeDatabase(seed);
  const actor = {
    uid: 'manager-1',
    email: 'manager-1@arptc.cd',
    displayName: 'Manager One',
    role: 'MANAGER',
  };
  await assert.rejects(
    () => executeItsmCommand({
      db,
      fieldValue,
      actor,
      envelope: approvalEnvelope('request-1', 'named', 'named-denied-1234'),
    }),
    (error) => error.code === 'permission-denied',
  );
  const approved = await executeItsmCommand({
    db,
    fieldValue,
    actor,
    envelope: approvalEnvelope('request-1', 'group', 'group-approved-1234'),
  });
  assert.equal(approved.decision, 'approved');
  assert.equal(
    db.document('serviceRequests/request-1/approvals/group').decidedByUserId,
    'manager-1',
  );
  await assert.rejects(
    () => executeItsmCommand({
      db,
      fieldValue,
      actor,
      envelope: approvalEnvelope('self', 'group', 'self-denied-1234'),
    }),
    (error) => error.code === 'permission-denied',
  );
});

function request(requesterId) {
  return {
    requestNumber: 'REQ-1',
    title: 'Request',
    requesterId,
    status: 'submitted',
    workflowState: 'submitted',
    lifecycleState: 'active',
    workflowDefinitionId: 'request-flow',
    workflowVersion: 1,
    workflowVersionDocumentId: '000001',
    workflowInstanceId: 'current',
    workflowRevision: 0,
  };
}

function transitionEnvelope(entityId, entityType, idempotencyKey) {
  return {
    command: 'workflow.transition',
    entityType,
    entityId,
    idempotencyKey,
    payload: {
      transitionId: 'cancel',
      toState: 'cancelled',
      expectedRevision: 0,
      reason: 'No longer required',
    },
  };
}

function approvalEnvelope(entityId, approvalId, idempotencyKey) {
  return {
    command: 'approval.decide',
    entityType: 'service_request',
    entityId,
    idempotencyKey,
    payload: { approvalId, decision: 'approved', comment: '' },
  };
}

function fakeDatabase(seed) {
  const documents = new Map(Object.entries(seed).map(([path, value]) => [
    path,
    structuredClone(value),
  ]));
  class Ref {
    constructor(path) { this.path = path; this.id = path.split('/').at(-1); }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) { return new Ref(`${this.path}/${id}`); }
  }
  return {
    collection(name) { return new Collection(name); },
    document(path) { return documents.get(path); },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (ref) => {
          const value = documents.get(ref.path);
          return {
            exists: value !== undefined,
            data: () => structuredClone(value),
            get: (field) => value && value[field],
          };
        },
        create: (ref, value) => writes.push(['create', ref, value]),
        set: (ref, value, options) => writes.push(['set', ref, value, options]),
        update: (ref, value) => writes.push(['update', ref, value]),
      };
      const result = await callback(transaction);
      for (const [kind, ref, value, options] of writes) {
        if (kind === 'create' && documents.has(ref.path)) {
          throw new Error(`Document already exists: ${ref.path}`);
        }
        const current = documents.get(ref.path) || {};
        documents.set(
          ref.path,
          structuredClone(
            kind === 'update' || options && options.merge
              ? { ...current, ...value }
              : value,
          ),
        );
      }
      return result;
    },
  };
}
