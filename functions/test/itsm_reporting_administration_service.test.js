'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  executeReportingAdministrationCommand,
  materializedParent,
} = require('../src/itsm_reporting_administration_service');
const {
  REPORTING_ADMINISTRATION_COMMANDS: C,
} = require('../src/itsm_reporting_administration_validation');

test('MANAGER draft creation is idempotent and writes local/global audit', async () => {
  const db = fakeDatabase();
  const value = command(C.createSlaPolicyDraft, {
    definitionId: 'incident-sla',
    sourceVersionDocumentId: null,
    draft: validSla(),
  });
  const first = await execute(db, manager(), value);
  const replay = await execute(db, manager(), value);
  assert.deepEqual(replay, first);
  assert.equal(first.versionDocumentId, 'v1');
  assert.equal(typeof first.commandId, 'string');
  assert.equal(first.entityId, 'incident-sla');
  assert.equal(db.documents.get('slaPolicies/incident-sla/versions/v1').status, 'draft');
  assert([...db.documents.keys()].some((path) =>
    path.startsWith('slaPolicies/incident-sla/auditLogs/')));
  assert([...db.documents.keys()].some((path) => path.startsWith('itsmAuditEvents/')));
  assert.equal([...db.documents.keys()].filter((path) =>
    path.startsWith('slaPolicies/incident-sla/versions/')).length, 1);
});

test('publication pins an immutable version and later draft update is rejected', async () => {
  const db = fakeDatabase();
  await execute(db, manager(), command(C.createSlaPolicyDraft, {
    definitionId: 'incident-sla',
    sourceVersionDocumentId: null,
    draft: validSla(),
  }));
  const published = await execute(db, manager(), command(C.publishSlaPolicyVersion, {
    definitionId: 'incident-sla',
    versionDocumentId: 'v1',
    expectedRevision: 0,
  }, 'publish-key-12345'));
  assert.equal(published.status, 'published');
  const parent = db.documents.get('slaPolicies/incident-sla');
  assert.equal(parent.currentPublishedVersionDocumentId, 'v1');
  assert.equal(parent.slaPolicyVersionDocumentId, 'v1');
  assert.deepEqual(parent.calendarSnapshot.holidays, ['2026-08-17']);
  await assert.rejects(
    execute(db, manager(), command(C.updateSlaPolicyDraft, {
      definitionId: 'incident-sla',
      versionDocumentId: 'v1',
      expectedRevision: 1,
      draft: validSla(),
    }, 'update-key-12345')),
    (error) => error.code === 'failed-precondition' && /immutable/.test(error.message),
  );
});

test('ADMIN has no configuration mutation command but can queue bounded export', async () => {
  const db = fakeDatabase();
  await assert.rejects(
    execute(db, admin(), command(C.createSlaPolicyDraft, {
      definitionId: 'forged-admin-policy',
      sourceVersionDocumentId: null,
      draft: validSla(),
    })),
    (error) => error.code === 'permission-denied',
  );
  const result = await execute(db, admin(), command(C.requestAuditExport, {
    startAt: new Date('2026-08-01T00:00:00Z'),
    endAt: new Date('2026-08-02T00:00:00Z'),
    module: null,
    entityType: null,
    entityId: null,
    action: null,
    actorUserId: null,
    confidentiality: null,
    maxRows: 100,
  }, 'audit-export-key-12345'));
  const exportDocument = db.documents.get(`itsmAuditExports/${result.exportId}`);
  assert.equal(exportDocument.authorizationScope, 'non_restricted_only');
  assert.equal(exportDocument.requester.role, 'ADMIN');
  assert.equal(exportDocument.status, 'queued');
});

test('catalogue materialization carries pinned workflow and SLA version IDs', () => {
  const result = materializedParent(
    require('../src/itsm_reporting_administration_service')
      .CONFIGURATION_TYPES.catalogue,
    {
      code: 'ITEM',
      workflow: { versionDocumentId: 'workflow-v2' },
      slaPolicy: { versionDocumentId: 'sla-v4' },
    },
    { definitionId: 'item-1', version: 3, versionDocumentId: 'v3' },
  );
  assert.equal(result.catalogueVersionDocumentId, 'v3');
  assert.equal(result.pinnedWorkflowVersionDocumentId, 'workflow-v2');
  assert.equal(result.pinnedSlaPolicyVersionDocumentId, 'sla-v4');
});

function command(name, payload, idempotencyKey = `service-${name}-12345678`) {
  return { command: name, idempotencyKey, payload };
}

function execute(db, actor, value) {
  return executeReportingAdministrationCommand({
    db,
    fieldValue: { serverTimestamp: () => 'server-time' },
    timestamp: {
      now: () => new Date('2026-08-01T12:00:00Z'),
      fromDate: (value) => value,
    },
    actor,
    command: value,
  });
}

function manager() {
  return { uid: 'manager-1', email: 'manager@arptc.cd', displayName: 'Manager', role: 'MANAGER' };
}

function admin() {
  return { uid: 'admin-1', email: 'admin@arptc.cd', displayName: 'Admin', role: 'ADMIN' };
}

function validSla() {
  return {
    name: { en: 'Incident SLA', fr: 'SLA incident' },
    workItemType: 'incident',
    priority: 'P2',
    serviceId: 'network',
    responseTargetMinutes: 60,
    resolutionTargetMinutes: 240,
    fulfilmentTargetMinutes: null,
    timeZone: 'Africa/Kinshasa',
    weeklyWindows: {
      1: [{ start: '08:00', end: '17:00' }],
      2: [{ start: '08:00', end: '17:00' }],
      3: [{ start: '08:00', end: '17:00' }],
      4: [{ start: '08:00', end: '17:00' }],
      5: [{ start: '08:00', end: '17:00' }],
    },
    holidays: ['2026-08-17'],
    pauseStates: ['awaiting_user'],
    warningThreshold: 0.8,
    escalationTargets: [],
  };
}

function fakeDatabase() {
  const documents = new Map();
  class Ref {
    constructor(path) { this.path = path; }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) { return new Ref(`${this.path}/${id}`); }
  }
  function snap(ref) {
    const value = documents.get(ref.path);
    return {
      exists: value !== undefined,
      data: () => value,
      get: (field) => value && value[field],
    };
  }
  return {
    documents,
    collection(name) { return new Collection(name); },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (ref) => snap(ref),
        create: (ref, value) => writes.push({ type: 'create', ref, value }),
        set: (ref, value, options) => writes.push({ type: 'set', ref, value, options }),
        update: (ref, value) => writes.push({ type: 'update', ref, value }),
      };
      const result = await callback(transaction);
      for (const write of writes) {
        const current = documents.get(write.ref.path) || {};
        if (write.type === 'create' && documents.has(write.ref.path)) {
          throw new Error(`already exists: ${write.ref.path}`);
        }
        documents.set(
          write.ref.path,
          write.type === 'update' || write.options && write.options.merge
            ? { ...current, ...write.value }
            : write.value,
        );
      }
      return result;
    },
  };
}
