'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { executeSupportCommand } = require('../src/itsm_support_service');
const {
  ITSM_SUPPORT_COMMANDS,
  validateSupportCommand,
} = require('../src/itsm_support_validation');

const fieldValue = {
  serverTimestamp: () => 'server-time',
  increment: (value) => ({ __increment: value }),
};
const timestamp = {
  now: () => new Date('2026-07-31T10:00:00.000Z'),
  fromMillis: (value) => new Date(value),
};

test('draft initialization pins nested configuration and submission is replay-safe', async () => {
  const db = fakeDatabase(baseDocuments());
  const initialize = command(
    ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
    'initialize-request-1234',
    {
      catalogueItemId: 'computer',
      title: 'Laptop for field work',
      responses: { justification: 'Field inspections' },
    },
  );
  const common = {
    db,
    fieldValue,
    timestamp,
    actor: actor('user-1', 'USER'),
    agent: userAgent(),
  };
  const initialized = await executeSupportCommand({ ...common, command: initialize });
  assert.deepEqual(
    await executeSupportCommand({ ...common, command: initialize }),
    initialized,
  );

  const draft = db.document(`serviceRequests/${initialized.requestId}`);
  assert.equal(draft.catalogueItemId, 'computer');
  assert.equal(draft.catalogueItemVersion, 4);
  assert.equal(draft.workflowDefinitionId, 'service-request');
  assert.equal(draft.workflowVersion, 3);
  assert.equal(draft.slaPolicyId, 'standard-fulfilment');
  assert.equal(draft.slaPolicyVersion, 2);
  assert.equal(draft.requesterId, 'user-1');
  assert.equal(draft.requestedForUserId, 'user-1');
  assert.equal(draft.status, 'draft');

  const submit = command(
    ITSM_SUPPORT_COMMANDS.submitServiceRequest,
    'submit-request-1234',
    {
      requestId: initialized.requestId,
      responses: {},
      attachmentIds: [],
    },
  );
  const submitted = await executeSupportCommand({ ...common, command: submit });
  assert.deepEqual(
    await executeSupportCommand({ ...common, command: submit }),
    submitted,
  );
  const request = db.document(`serviceRequests/${initialized.requestId}`);
  const index = db.document(
    `itsmWorkItemIndex/service_request:${initialized.requestId}`,
  );
  assert.equal(request.status, 'awaiting_approval');
  assert.equal(request.pendingApprovalCount, 1);
  assert.equal(request.taskCount, 1);
  assert.equal(request.mandatoryTaskCount, 1);
  assert.deepEqual(request.approvalStepIds, ['manager-approval']);
  assert.equal(
    db.document(
      `serviceRequests/${initialized.requestId}/approvals/manager-approval`,
    ).status,
    'pending',
  );
  assert.equal(index.requesterId, 'user-1');
  assert.equal(index.confidentiality, 'internal');
  assert.equal(index.title, 'Laptop for field work');
  assert.equal(index.workflowVersion, 3);
});

test('new drafts pin immutable catalogue versions across parent publication changes', async () => {
  const documents = baseDocuments();
  const publishedVersion = clone(documents['serviceCatalogItems/computer']);
  documents['serviceCatalogItems/computer'] = {
    ...documents['serviceCatalogItems/computer'],
    currentPublishedVersion: 4,
    currentPublishedVersionId: '000004',
  };
  documents['serviceCatalogItems/computer/versions/000004'] = publishedVersion;
  const db = fakeDatabase(documents);
  const common = {
    db,
    fieldValue,
    timestamp,
    actor: actor('user-1', 'USER'),
    agent: userAgent(),
  };
  const initialized = await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
      'initialize-pinned-catalogue-1234',
      {
        catalogueItemId: 'computer',
        responses: { justification: 'Field inspections' },
      },
    ),
  });
  const draft = db.document(`serviceRequests/${initialized.requestId}`);
  assert.equal(draft.catalogueItemVersion, 4);
  assert.equal(draft.catalogueItemVersionDocumentId, '000004');

  db.put('serviceCatalogItems/computer', {
    ...documents['serviceCatalogItems/computer'],
    version: 5,
    currentPublishedVersion: 5,
    currentPublishedVersionId: '000005',
    formFields: [{ key: 'new_required_field', required: true }],
  });
  db.put('serviceCatalogItems/computer/versions/000005', {
    ...publishedVersion,
    version: 5,
    formFields: [{ key: 'new_required_field', required: true }],
  });

  await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.submitServiceRequest,
      'submit-pinned-catalogue-1234',
      { requestId: initialized.requestId, attachmentIds: [] },
    ),
  });
  assert.equal(
    db.document(`serviceRequests/${initialized.requestId}`).status,
    'awaiting_approval',
  );
});

test('submission queues later approval steps and preserves mandatory task policy', async () => {
  const documents = baseDocuments();
  documents['workflowDefinitions/service-request/versions/000003'] = {
    status: 'published',
    approvalSteps: [
      { id: 'manager', approverGroupId: 'service-desk' },
      { id: 'director', approverUserId: 'director-1' },
    ],
    fulfilmentTasks: [
      { id: 'required', mandatory: true },
      { id: 'optional', mandatory: false },
    ],
  };
  const db = fakeDatabase(documents);
  const common = {
    db,
    fieldValue,
    timestamp,
    actor: actor('user-1', 'USER'),
    agent: userAgent(),
  };
  const draft = await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
      'initialize-sequential-1234',
      {
        catalogueItemId: 'computer',
        responses: { justification: 'Replacement' },
      },
    ),
  });
  await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.submitServiceRequest,
      'submit-sequential-1234',
      { requestId: draft.requestId, attachmentIds: [] },
    ),
  });
  const request = db.document(`serviceRequests/${draft.requestId}`);
  assert.equal(request.pendingApprovalCount, 2);
  assert.equal(request.mandatoryTaskCount, 1);
  assert.equal(
    db.document(`serviceRequests/${draft.requestId}/approvals/manager`).status,
    'pending',
  );
  assert.equal(
    db.document(`serviceRequests/${draft.requestId}/approvals/director`).status,
    'queued',
  );
  assert.equal(
    db.document(`serviceRequests/${draft.requestId}/tasks/optional`).isMandatory,
    false,
  );
});

test('MANAGER on-behalf requests preserve actor and project target ownership', async () => {
  const documents = baseDocuments();
  documents['agents/user-2'] = {
    firstName: 'Second',
    name: 'Agent',
    email: 'second@arptc.cd',
    departmentId: 'finance',
    serviceId: 'payroll',
    isActive: true,
  };
  const initialize = command(
    ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
    'initialize-behalf-1234',
    {
      catalogueItemId: 'computer',
      requestedForUserId: 'user-2',
      responses: { justification: 'Replacement' },
    },
  );

  await assert.rejects(
    () => executeSupportCommand({
      db: fakeDatabase(documents),
      fieldValue,
      timestamp,
      actor: actor('user-1', 'USER'),
      agent: userAgent(),
      command: initialize,
    }),
    (error) => error.code === 'permission-denied',
  );

  const db = fakeDatabase(documents);
  const result = await executeSupportCommand({
    db,
    fieldValue,
    timestamp,
    actor: actor('manager-1', 'MANAGER'),
    agent: managerAgent(),
    command: initialize,
  });
  const request = db.document(`serviceRequests/${result.requestId}`);
  const index = db.document(`itsmWorkItemIndex/service_request:${result.requestId}`);
  assert.equal(request.requesterId, 'manager-1');
  assert.equal(request.createdBy, 'manager-1');
  assert.equal(request.requestedForUserId, 'user-2');
  assert.equal(request.affectedUserId, 'user-2');
  assert.equal(index.requesterId, 'user-2');
  assert.equal(index.submittedByUserId, 'manager-1');
});

test('submission requires trusted attachment metadata for required documents', async () => {
  const documents = baseDocuments();
  documents['serviceCatalogItems/computer'].requiredDocuments = [{
    key: 'approval_letter',
    required: true,
    maximumFiles: 1,
    allowedContentTypes: ['application/pdf'],
  }];
  const db = fakeDatabase(documents);
  const common = {
    db,
    fieldValue,
    timestamp,
    actor: actor('user-1', 'USER'),
    agent: userAgent(),
  };
  const initialized = await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
      'initialize-docs-1234',
      {
        catalogueItemId: 'computer',
        responses: { justification: 'Replacement' },
      },
    ),
  });
  const missing = command(
    ITSM_SUPPORT_COMMANDS.submitServiceRequest,
    'submit-docs-missing-1234',
    { requestId: initialized.requestId, attachmentIds: [] },
  );
  await assert.rejects(
    () => executeSupportCommand({ ...common, command: missing }),
    (error) => error.code === 'failed-precondition' &&
      error.details.missingDocuments.includes('approval_letter'),
  );

  db.put(`serviceRequests/${initialized.requestId}/attachments/file-1`, {
    requestId: initialized.requestId,
    workItemId: initialized.requestId,
    storagePath: `itsm/serviceRequests/${initialized.requestId}/attachments/file-1/approval.pdf`,
    documentRequirementKey: 'approval_letter',
    uploadedByUserId: 'user-1',
    contentType: 'application/pdf',
    sizeBytes: 200,
  });
  await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.submitServiceRequest,
      'submit-docs-present-1234',
      { requestId: initialized.requestId, attachmentIds: ['file-1'] },
    ),
  });
  assert.equal(
    db.document(`serviceRequests/${initialized.requestId}`).attachmentCount,
    1,
  );
});

test('knowledge lifecycle is state-based, authorized, versioned, and replay-safe', async () => {
  const db = fakeDatabase({
    'knowledgeCategories/general': { isActive: true },
  });
  const common = {
    db,
    fieldValue,
    timestamp,
    actor: actor('manager-1', 'MANAGER'),
    agent: managerAgent(),
  };
  const save = command(
    ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft,
    'knowledge-save-1234',
    {
      categoryId: 'general',
      title: 'Reset a password',
      summary: 'Password reset steps',
      content: 'Open the identity portal and select Reset password.',
      languageCode: 'en',
      visibility: 'employee',
      relatedServiceIds: ['identity'],
    },
  );
  const created = await executeSupportCommand({ ...common, command: save });
  assert.deepEqual(await executeSupportCommand({ ...common, command: save }), created);

  const transition = async (type, key, extra = {}) => executeSupportCommand({
    ...common,
    command: command(type, key, {
      articleId: created.articleId,
      expectedVersionNumber: 1,
      ...extra,
    }),
  });
  await transition(
    ITSM_SUPPORT_COMMANDS.submitKnowledgeReview,
    'knowledge-review-1234',
  );
  await transition(
    ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview,
    'knowledge-reject-1234',
    { reason: 'Add a security warning.' },
  );
  await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft,
      'knowledge-resave-1234',
      {
        articleId: created.articleId,
        expectedVersionNumber: 1,
        categoryId: 'general',
        title: 'Reset a password safely',
        summary: 'Password reset steps',
        content: 'Use only the official identity portal.',
        languageCode: 'en',
        visibility: 'employee',
      },
    ),
  });
  await transition(
    ITSM_SUPPORT_COMMANDS.submitKnowledgeReview,
    'knowledge-rereview-1234',
  );
  await transition(
    ITSM_SUPPORT_COMMANDS.publishKnowledgeArticle,
    'knowledge-publish-1234',
  );

  const reader = {
    ...common,
    actor: actor('user-1', 'USER'),
    agent: userAgent(),
  };
  await executeSupportCommand({
    ...reader,
    command: command(
      ITSM_SUPPORT_COMMANDS.recordKnowledgeView,
      'knowledge-view-1234',
      { articleId: created.articleId },
    ),
  });
  const feedback = command(
    ITSM_SUPPORT_COMMANDS.recordKnowledgeFeedback,
    'knowledge-feedback-1234',
    { articleId: created.articleId, helpful: true, comment: 'Useful' },
  );
  await executeSupportCommand({ ...reader, command: feedback });
  await executeSupportCommand({ ...reader, command: feedback });
  await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.retireKnowledgeArticle,
      'knowledge-retire-1234',
      { articleId: created.articleId },
    ),
  });
  await executeSupportCommand({
    ...common,
    command: command(
      ITSM_SUPPORT_COMMANDS.archiveKnowledgeArticle,
      'knowledge-archive-1234',
      { articleId: created.articleId },
    ),
  });

  const article = db.document(`knowledgeArticles/${created.articleId}`);
  assert.equal(article.state, 'archived');
  assert.equal(article.currentVersionNumber, 1);
  assert.equal(article.publishedVersionNumber, 1);
  assert.equal(article.viewCount, 1);
  assert.equal(article.usageCount, 1);
  assert.equal(article.helpfulCount, 1);
  assert.equal(article.notHelpfulCount, 0);
  assert.equal(
    db.document(`knowledgeArticles/${created.articleId}/versions/000001`).state,
    'archived',
  );
});

function command(type, idempotencyKey, payload) {
  return validateSupportCommand({ command: type, idempotencyKey, payload });
}

function baseDocuments() {
  return {
    'serviceCatalogItems/computer': {
      code: 'COMPUTER',
      version: 4,
      name: { en: 'Request a computer', fr: 'Demander un ordinateur' },
      description: { en: 'Request approved equipment', fr: 'Demander un equipement' },
      status: 'published',
      visibleRoles: ['USER', 'MANAGER', 'ADMIN'],
      eligibility: { allEmployees: true, excludedUserIds: [] },
      formFields: [{ key: 'justification', type: 'long_text', required: true }],
      workflow: { id: 'service-request', version: 3 },
      slaPolicy: { id: 'standard-fulfilment', version: 2 },
      fulfilmentGroupId: 'service-desk',
      workflowAllowsCancellation: true,
      allowManagerRequestOnBehalf: true,
      requiredDocuments: [],
    },
    'workflowDefinitions/service-request': { status: 'published' },
    'workflowDefinitions/service-request/versions/000003': {
      status: 'published',
      approvalSteps: [{ id: 'manager-approval', groupId: 'service-desk' }],
      fulfilmentTasks: [{ id: 'prepare-device', title: { en: 'Prepare device' } }],
    },
    'slaPolicies/standard-fulfilment': { status: 'published' },
    'slaPolicies/standard-fulfilment/versions/000002': {
      status: 'published',
      responseTargetMinutes: 60,
      fulfilmentTargetMinutes: 480,
    },
  };
}

function actor(uid, role) {
  return {
    uid,
    role,
    displayName: role === 'MANAGER' ? 'IT Manager' : 'First Agent',
    email: `${uid}@arptc.cd`,
  };
}

function userAgent() {
  return {
    firstName: 'First',
    name: 'Agent',
    email: 'user-1@arptc.cd',
    departmentId: 'dsi',
    serviceId: 'support',
  };
}

function managerAgent() {
  return {
    firstName: 'IT',
    name: 'Manager',
    email: 'manager-1@arptc.cd',
    departmentId: 'dsi',
    serviceId: 'support',
  };
}

function fakeDatabase(seed = {}) {
  const documents = new Map(
    Object.entries(seed).map(([path, value]) => [path, clone(value)]),
  );

  class Reference {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) { return new Reference(`${this.path}/${id}`); }
  }
  const snapshot = (reference) => {
    const value = documents.get(reference.path);
    return {
      id: reference.id,
      ref: reference,
      exists: value !== undefined,
      data: () => value === undefined ? undefined : clone(value),
      get: (name) => value && value[name],
    };
  };
  const applyPatch = (current, patch) => {
    const next = { ...(current || {}) };
    for (const [key, value] of Object.entries(patch)) {
      if (value && typeof value === 'object' && Number.isFinite(value.__increment)) {
        next[key] = Number(next[key] || 0) + value.__increment;
      } else {
        next[key] = clone(value);
      }
    }
    return next;
  };
  return {
    collection(name) { return new Collection(name); },
    document(path) {
      const value = documents.get(path);
      return value === undefined ? undefined : clone(value);
    },
    put(path, value) { documents.set(path, clone(value)); },
    paths() { return [...documents.keys()]; },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (reference) => snapshot(reference),
        create: (reference, value) => writes.push({ kind: 'create', reference, value }),
        set: (reference, value, options) => writes.push({ kind: 'set', reference, value, options }),
        update: (reference, value) => writes.push({ kind: 'update', reference, value }),
        delete: (reference) => writes.push({ kind: 'delete', reference }),
      };
      const result = await callback(transaction);
      for (const write of writes) {
        const path = write.reference.path;
        if (write.kind === 'create') {
          if (documents.has(path)) throw new Error(`Document already exists: ${path}`);
          documents.set(path, clone(write.value));
        } else if (write.kind === 'set') {
          documents.set(path, write.options && write.options.merge
            ? applyPatch(documents.get(path), write.value)
            : clone(write.value));
        } else if (write.kind === 'update') {
          if (!documents.has(path)) throw new Error(`Document does not exist: ${path}`);
          documents.set(path, applyPatch(documents.get(path), write.value));
        } else if (write.kind === 'delete') {
          documents.delete(path);
        }
      }
      return result;
    },
  };
}

function clone(value) {
  return value === undefined ? undefined : structuredClone(value);
}
