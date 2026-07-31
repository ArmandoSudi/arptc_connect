'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildKnowledgeAttachmentMetadata,
  buildServiceRequestAttachmentMetadata,
  buildSupportWorkItemIndex,
  canonicalSupportRoute,
  notificationEventsForSupportChange,
  registerKnowledgeAttachment,
  registerServiceRequestAttachment,
  synchronizeServiceRequestApproval,
  synchronizeServiceRequestTask,
} = require('../src/itsm_support_triggers');

const fieldValue = {
  serverTimestamp: () => 'server-time',
  arrayUnion: (...values) => ({ __arrayUnion: values }),
};

test('support index matches the complete shared mapper and target ownership contract', () => {
  const summary = buildSupportWorkItemIndex({
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    data: {
      requestNumber: 'REQ-2026-0001',
      title: 'Request a laptop',
      description: 'Replacement device',
      requesterId: 'manager-1',
      requestedForUserId: 'user-1',
      affectedUserId: 'user-1',
      departmentId: 'finance',
      serviceId: 'payroll',
      assignedGroupId: 'service-desk',
      assignedUserId: 'technician-1',
      priority: 'P2',
      impact: 'high',
      urgency: 'medium',
      status: 'assigned',
      lifecycleState: 'active',
      workflowDefinitionId: 'request-flow',
      workflowVersion: 3,
      createdAt: 'created',
      createdBy: 'manager-1',
      updatedAt: 'updated',
      updatedBy: 'technician-1',
      slaSummary: { status: 'at_risk', fulfilmentDueAt: 'due' },
      confidentiality: 'internal',
      linkedAssetIds: ['asset-1'],
      linkedCiIds: ['ci-1'],
      selfServiceVisible: true,
    },
  });
  assert.equal(summary.requesterId, 'user-1');
  assert.equal(summary.submittedByUserId, 'manager-1');
  assert.equal(summary.confidentiality, 'internal');
  assert.equal(summary.title, 'Request a laptop');
  assert.equal(summary.workflowVersion, 3);
  assert.equal(summary.dueAt, 'due');
  assert.deepEqual(summary.linkedAssetIds, ['asset-1']);
});

test('draft creation is silent and submission emits one deduplicated manager event', () => {
  const draft = snapshot({ requestNumber: 'REQ-1', status: 'draft' });
  assert.deepEqual(notificationEventsForSupportChange({
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    before: missingSnapshot(),
    after: draft,
    sourceEventId: 'event-draft',
    fieldValue,
  }), []);

  const submitted = snapshot({
    requestNumber: 'REQ-1',
    requesterId: 'user-1',
    requestedForUserId: 'user-1',
    status: 'submitted',
  });
  const first = notificationEventsForSupportChange({
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    before: draft,
    after: submitted,
    sourceEventId: 'event-submit',
    fieldValue,
  });
  const replay = notificationEventsForSupportChange({
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    before: draft,
    after: submitted,
    sourceEventId: 'event-submit',
    fieldValue,
  });
  assert.equal(first.length, 1);
  assert.equal(first[0].id, replay[0].id);
  assert.deepEqual(first[0].data.target.roles, ['MANAGER']);
  assert.equal(
    first[0].data.route,
    '/services/itsm/support/service-requests/request-1',
  );
});

test('assignment and status updates use audience-specific canonical routes', () => {
  const events = notificationEventsForSupportChange({
    collectionName: 'serviceRequests',
    workItemId: 'request-1',
    before: snapshot({
      requesterId: 'manager-1',
      requestedForUserId: 'user-1',
      status: 'submitted',
      assignedUserId: '',
    }),
    after: snapshot({
      requesterId: 'manager-1',
      requestedForUserId: 'user-1',
      status: 'assigned',
      assignedUserId: 'technician-1',
    }),
    sourceEventId: 'event-2',
    fieldValue,
  });
  assert.equal(events.length, 3);
  assert.deepEqual(events[0].data.target.userIds, ['technician-1']);
  assert.deepEqual(
    events[1].data.target.userIds.sort(),
    ['manager-1', 'user-1'],
  );
  assert.equal(
    events[1].data.route,
    '/services/itsm/support/my-requests/request-1',
  );
  assert.deepEqual(events[2].data.target.userIds, ['technician-1']);
  assert.equal(
    events[2].data.route,
    '/services/itsm/support/service-requests/request-1',
  );
  assert.equal(
    canonicalSupportRoute('incident', 'INC 1'),
    '/services/itsm/support/incidents/INC%201',
  );
});

test('approval synchronization advances one sequential step at a time', async () => {
  const db = fakeTriggerDatabase({
    'serviceRequests/request-1': {
      requestNumber: 'REQ-1',
      status: 'awaiting_approval',
      lifecycleState: 'active',
      workflowRevision: 1,
      workflowDefinitionId: 'request-flow',
      workflowVersion: 1,
      workflowVersionDocumentId: '000001',
      workflowInstanceId: 'current',
      approvalStepIds: ['manager', 'director'],
      currentApprovalStep: 1,
      pendingApprovalCount: 2,
      taskCount: 1,
      requesterId: 'user-1',
    },
    'serviceRequests/request-1/approvals/director': {
      step: 2,
      status: 'queued',
    },
  });
  await synchronizeServiceRequestApproval({
    db,
    fieldValue,
    requestId: 'request-1',
    approvalId: 'manager',
    before: snapshot({ step: 1, status: 'pending' }),
    after: snapshot({
      step: 1,
      status: 'approved',
      decision: 'approved',
      decidedByUserId: 'manager-1',
    }),
    sourceEventId: 'approval-event-1',
  });
  assert.equal(db.document('serviceRequests/request-1').status, 'awaiting_approval');
  assert.equal(db.document('serviceRequests/request-1').pendingApprovalCount, 1);
  assert.equal(
    db.document('serviceRequests/request-1/approvals/director').status,
    'pending',
  );
  assert.equal(
    db.document('serviceRequests/request-1/workflowInstances/current').state,
    'awaiting_approval',
  );
  assert.equal(
    db.document('itsmWorkItemIndex/service_request:request-1').status,
    'awaiting_approval',
  );
});

test('rejection closes the request and mandatory completion fulfils it', async () => {
  const rejectionDb = fakeTriggerDatabase({
    'serviceRequests/rejected': {
      status: 'awaiting_approval',
      lifecycleState: 'active',
      workflowRevision: 2,
      approvalStepIds: ['approval-1'],
      pendingApprovalCount: 1,
      requesterId: 'user-1',
    },
  });
  await synchronizeServiceRequestApproval({
    db: rejectionDb,
    fieldValue,
    requestId: 'rejected',
    approvalId: 'approval-1',
    before: snapshot({ status: 'pending' }),
    after: snapshot({
      status: 'rejected',
      decision: 'rejected',
      decisionComment: 'Budget unavailable',
      decidedByUserId: 'manager-1',
    }),
    sourceEventId: 'approval-rejected',
  });
  const rejected = rejectionDb.document('serviceRequests/rejected');
  assert.equal(rejected.status, 'rejected');
  assert.equal(rejected.lifecycleState, 'closed');
  assert.equal(rejected.rejectionReason, 'Budget unavailable');
  assert.equal(rejected.closedAt, 'server-time');

  const taskDb = fakeTriggerDatabase({
    'serviceRequests/fulfilled': {
      status: 'in_fulfilment',
      lifecycleState: 'active',
      workflowRevision: 3,
      mandatoryTaskCount: 2,
      completedMandatoryTaskCount: 2,
      requesterId: 'user-1',
    },
  });
  await synchronizeServiceRequestTask({
    db: taskDb,
    fieldValue,
    requestId: 'fulfilled',
    taskId: 'task-2',
    before: snapshot({ status: 'in_progress', isMandatory: true }),
    after: snapshot({
      status: 'completed',
      isMandatory: true,
      updatedByUserId: 'manager-1',
    }),
    sourceEventId: 'task-completed',
  });
  assert.equal(taskDb.document('serviceRequests/fulfilled').status, 'fulfilled');
  assert.equal(
    taskDb.document('itsmWorkItemIndex/service_request:fulfilled').status,
    'fulfilled',
  );
});

test('Storage finalization registers immutable trusted attachment metadata', async () => {
  const object = {
    name: 'itsm/serviceRequests/request-1/attachments/file-1/approval.pdf',
    contentType: 'application/pdf',
    size: '512',
    metadata: {
      workItemCollection: 'serviceRequests',
      workItemId: 'request-1',
      attachmentId: 'file-1',
      uploadedByUserId: 'user-1',
      documentRequirementKey: 'approval_letter',
      isInternal: 'false',
    },
  };
  const metadata = buildServiceRequestAttachmentMetadata(object, fieldValue);
  assert.equal(metadata.documentRequirementKey, 'approval_letter');
  assert.equal(metadata.isInternal, false);
  assert.ok(buildServiceRequestAttachmentMetadata({
    ...object,
    contentType: 'application/vnd.ms-powerpoint',
  }, fieldValue));
  assert.equal(buildServiceRequestAttachmentMetadata({
    ...object,
    contentType: 'application/octet-stream',
  }, fieldValue), null);

  const db = fakeAttachmentDatabase({
    'serviceRequests/request-1': {
      requesterId: 'user-1',
      requestedForUserId: 'user-2',
      status: 'draft',
    },
  });
  const result = await registerServiceRequestAttachment({ db, fieldValue, object });
  assert.equal(result.registered, true);
  assert.equal(
    db.document('serviceRequests/request-1/attachments/file-1').storagePath,
    object.name,
  );
});

test('Knowledge uploads register only under the current immutable draft version', async () => {
  const object = {
    name: 'itsm/knowledgeArticles/kb-1/versions/000002/attachments/file-1/guide.pdf',
    contentType: 'application/pdf',
    size: '1024',
    metadata: {
      articleId: 'kb-1',
      versionId: '000002',
      attachmentId: 'file-1',
      uploadedByUserId: 'manager-1',
      isInternal: 'false',
    },
  };
  const metadata = buildKnowledgeAttachmentMetadata(object, fieldValue);
  assert.equal(metadata.versionId, '000002');
  const db = fakeTriggerDatabase({
    'knowledgeArticles/kb-1': {
      state: 'draft',
      currentVersionNumber: 2,
    },
    'knowledgeArticles/kb-1/versions/000002': { state: 'draft' },
    'agents/manager-1': {
      modulePermissions: { ticketing: 'MANAGER' },
    },
  });
  const result = await registerKnowledgeAttachment({ db, fieldValue, object });
  assert.equal(result.registered, true);
  assert.equal(
    db.document(
      'knowledgeArticles/kb-1/versions/000002/attachments/file-1',
    ).storagePath,
    object.name,
  );
  assert.equal(
    db.document(
      'knowledgeArticles/kb-1/versions/000002/attachments/file-1',
    ).uploadedBy.userId,
    'manager-1',
  );
  assert.deepEqual(
    db.document('knowledgeArticles/kb-1/versions/000002').attachmentIds,
    { __arrayUnion: ['file-1'] },
  );
  const published = fakeTriggerDatabase({
    'knowledgeArticles/kb-1': { state: 'published', currentVersionNumber: 2 },
    'knowledgeArticles/kb-1/versions/000002': { state: 'published' },
    'agents/manager-1': { modulePermissions: { ticketing: 'MANAGER' } },
  });
  assert.equal(
    (await registerKnowledgeAttachment({ db: published, fieldValue, object })).reason,
    'forbidden_parent',
  );
});

function snapshot(data) { return { exists: true, data: () => data }; }
function missingSnapshot() { return { exists: false, data: () => undefined }; }

function fakeAttachmentDatabase(seed) {
  const documents = new Map(Object.entries(seed));
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
        get: async (ref) => ({
          exists: documents.has(ref.path),
          data: () => documents.get(ref.path),
        }),
        set: (ref, value) => writes.push([ref.path, value]),
      };
      const result = await callback(transaction);
      writes.forEach(([path, value]) => documents.set(path, value));
      return result;
    },
  };
}

function fakeTriggerDatabase(seed) {
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
  const read = (ref) => ({
    exists: documents.has(ref.path),
    data: () => structuredClone(documents.get(ref.path)),
  });
  return {
    collection(name) { return new Collection(name); },
    document(path) { return documents.get(path); },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (ref) => read(ref),
        update: (ref, value) => writes.push(['update', ref, value]),
        set: (ref, value, options) => writes.push(['set', ref, value, options]),
      };
      const result = await callback(transaction);
      for (const [kind, ref, value, options] of writes) {
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
