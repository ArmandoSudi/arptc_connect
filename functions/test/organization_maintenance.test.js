'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  actingHeadExpirationAuditId,
  expireActingHeadAssignment,
  fetchExpiredActingHeadAssignmentsPage,
  isExpiredActiveActingHead,
  runActingHeadExpirationMaintenance,
} = require('../src/organization_maintenance');

const now = new Date('2026-08-11T12:00:00.000Z');
const serverTimestamp = new Date('2026-08-11T12:00:01.000Z');
const fieldValue = { serverTimestamp: () => serverTimestamp };

test('identifies only active acting HEAD assignments at or before the boundary', () => {
  const eligible = actingAssignment({ endsAt: now });
  assert.equal(isExpiredActiveActingHead(eligible, now), true);
  assert.equal(isExpiredActiveActingHead({
    ...eligible,
    endsAt: new Date('2026-08-11T12:00:00.001Z'),
  }, now), false);
  assert.equal(isExpiredActiveActingHead({ ...eligible, status: 'ENDED' }, now), false);
  assert.equal(isExpiredActiveActingHead({ ...eligible, isActing: false }, now), false);
  assert.equal(isExpiredActiveActingHead({
    ...eligible,
    assignmentType: 'MEMBER',
  }, now), false);
  assert.equal(isExpiredActiveActingHead({ ...eligible, endsAt: null }, now), false);
});

test('uses a bounded stable endsAt and document-ID query with a composite cursor', async () => {
  const query = new QueryRecorder([
    queryDocument('assignment-b', new Date('2026-08-10T09:00:00.000Z')),
  ]);
  const db = { collection: (name) => {
    assert.equal(name, 'organizationAssignments');
    return query;
  } };
  const cursor = {
    endsAt: new Date('2026-08-09T09:00:00.000Z'),
    assignmentId: 'assignment-a',
  };

  const page = await fetchExpiredActingHeadAssignmentsPage({
    db,
    now,
    pageSize: 1,
    cursor,
    documentIdField: '__name__',
  });

  assert.deepEqual(query.filters, [
    ['assignmentType', '==', 'HEAD'],
    ['isActing', '==', true],
    ['status', '==', 'ACTIVE'],
    ['endsAt', '<=', now],
  ]);
  assert.deepEqual(query.orders, [
    ['endsAt', 'asc'],
    ['__name__', 'asc'],
  ]);
  assert.deepEqual(query.after, [cursor.endsAt, cursor.assignmentId]);
  assert.equal(query.pageLimit, 1);
  assert.equal(page.hasMore, true);
  assert.equal(page.nextCursor.assignmentId, 'assignment-b');
});

test('transactionally ends an expired assignment, clears its matching projection, and audits once', async () => {
  const db = fakeDatabase({
    'organizationAssignments/assignment-1': actingAssignment(),
    'organizationUnits/unit-1': {
      actingHeadUserId: 'agent-1',
      actingHeadAssignmentId: 'assignment-1',
      actingHeadEndsAt: new Date('2026-08-11T10:00:00.000Z'),
    },
  });
  const assignmentRef = db.collection('organizationAssignments').doc('assignment-1');

  const first = await expireActingHeadAssignment({
    db,
    fieldValue,
    now,
    assignmentRef,
  });
  const second = await expireActingHeadAssignment({
    db,
    fieldValue,
    now,
    assignmentRef,
  });

  assert.deepEqual(first, {
    assignmentId: 'assignment-1',
    ended: true,
    projectionCleared: true,
    auditCreated: true,
    skippedReason: null,
  });
  assert.equal(second.ended, false);
  assert.equal(second.skippedReason, 'NO_LONGER_ELIGIBLE');
  assert.equal(db.read('organizationAssignments/assignment-1').status, 'ENDED');
  assert.equal(db.read('organizationAssignments/assignment-1').endedBy,
    'system:organization-acting-head-expiration');
  assert.equal(db.read('organizationUnits/unit-1').actingHeadAssignmentId, null);
  const auditPath = `organizationAuditEvents/${actingHeadExpirationAuditId(
    'assignment-1',
  )}`;
  const audit = db.read(auditPath);
  assert.equal(audit.eventType, 'ORGANIZATION_UNIT_ACTING_HEAD_EXPIRED');
  assert.equal(audit.assignmentId, 'assignment-1');
  assert.equal(audit.after.projectionCleared, true);
  assert.equal(db.paths(/^organizationAuditEvents\//).length, 1);
});

test('does not clear a unit projection that already references a newer assignment', async () => {
  const db = fakeDatabase({
    'organizationAssignments/assignment-old': actingAssignment(),
    'organizationUnits/unit-1': {
      actingHeadUserId: 'agent-new',
      actingHeadAssignmentId: 'assignment-new',
      actingHeadEndsAt: new Date('2026-09-01T10:00:00.000Z'),
    },
  });

  const result = await expireActingHeadAssignment({
    db,
    fieldValue,
    now,
    assignmentRef: db.collection('organizationAssignments').doc('assignment-old'),
  });

  assert.equal(result.ended, true);
  assert.equal(result.projectionCleared, false);
  assert.equal(
    db.read('organizationUnits/unit-1').actingHeadAssignmentId,
    'assignment-new',
  );
  const audit = db.read(`organizationAuditEvents/${actingHeadExpirationAuditId(
    'assignment-old',
  )}`);
  assert.equal(audit.after.projectionCleared, false);
});

test('processes pages and transactions in bounded stable batches', async () => {
  const documents = ['assignment-a', 'assignment-b', 'assignment-c']
    .map((id) => ({ id, ref: { id } }));
  const cursorsSeen = [];
  const batches = [];
  let active = 0;
  let maximumConcurrent = 0;
  const pages = [
    {
      documents: documents.slice(0, 2),
      nextCursor: { endsAt: now, assignmentId: 'assignment-b' },
      hasMore: true,
    },
    {
      documents: documents.slice(2),
      nextCursor: { endsAt: now, assignmentId: 'assignment-c' },
      hasMore: false,
    },
  ];

  const result = await runActingHeadExpirationMaintenance({
    db: {},
    fieldValue,
    now,
    pageSize: 2,
    maxPages: 3,
    transactionBatchSize: 2,
    documentIdField: '__name__',
    fetchPage: async ({ cursor }) => {
      cursorsSeen.push(cursor && cursor.assignmentId);
      return pages.shift();
    },
    expireAssignment: async ({ assignmentRef }) => {
      active += 1;
      maximumConcurrent = Math.max(maximumConcurrent, active);
      batches.push(assignmentRef.id);
      await Promise.resolve();
      active -= 1;
      return {
        ended: true,
        projectionCleared: assignmentRef.id !== 'assignment-b',
        auditCreated: true,
      };
    },
  });

  assert.deepEqual(cursorsSeen, [null, 'assignment-b']);
  assert.deepEqual(batches, ['assignment-a', 'assignment-b', 'assignment-c']);
  assert.equal(maximumConcurrent, 2);
  assert.deepEqual(result, {
    pagesProcessed: 2,
    scannedCount: 3,
    endedCount: 3,
    skippedCount: 0,
    projectionClearedCount: 2,
    auditCreatedCount: 3,
    hasMore: false,
    nextCursor: null,
  });
});

test('stops at the configured page bound and returns a resumable cursor', async () => {
  const page = {
    documents: [{ id: 'assignment-a', ref: { id: 'assignment-a' } }],
    nextCursor: { endsAt: now, assignmentId: 'assignment-a' },
    hasMore: true,
  };
  const result = await runActingHeadExpirationMaintenance({
    db: {},
    fieldValue,
    now,
    pageSize: 1,
    maxPages: 1,
    transactionBatchSize: 1,
    fetchPage: async () => page,
    expireAssignment: async () => ({
      ended: true,
      projectionCleared: false,
      auditCreated: true,
    }),
  });

  assert.equal(result.pagesProcessed, 1);
  assert.equal(result.scannedCount, 1);
  assert.equal(result.hasMore, true);
  assert.deepEqual(result.nextCursor, page.nextCursor);
});

test('rejects unsafe bounds and non-advancing cursors', async () => {
  await assert.rejects(
    () => runActingHeadExpirationMaintenance({
      db: {}, fieldValue, now, pageSize: 101,
    }),
    hasCode('invalid-argument'),
  );
  await assert.rejects(
    () => runActingHeadExpirationMaintenance({
      db: {},
      fieldValue,
      now,
      cursor: { endsAt: now, assignmentId: 'assignment-a' },
      fetchPage: async () => ({
        documents: [],
        nextCursor: { endsAt: now, assignmentId: 'assignment-a' },
        hasMore: true,
      }),
    }),
    hasCode('failed-precondition'),
  );
});

function actingAssignment(overrides = {}) {
  return {
    organizationId: 'org-1',
    agentId: 'agent-1',
    unitId: 'unit-1',
    assignmentType: 'HEAD',
    isPrimary: false,
    isActing: true,
    status: 'ACTIVE',
    startsAt: new Date('2026-08-01T10:00:00.000Z'),
    endsAt: new Date('2026-08-11T10:00:00.000Z'),
    ...overrides,
  };
}

function queryDocument(id, endsAt) {
  return {
    id,
    ref: { id },
    get: (field) => field === 'endsAt' ? endsAt : undefined,
    data: () => ({ endsAt }),
  };
}

class QueryRecorder {
  constructor(documents) {
    this.documents = documents;
    this.filters = [];
    this.orders = [];
    this.after = null;
    this.pageLimit = null;
  }

  where(...values) {
    this.filters.push(values);
    return this;
  }

  orderBy(...values) {
    this.orders.push(values);
    return this;
  }

  startAfter(...values) {
    this.after = values;
    return this;
  }

  limit(value) {
    this.pageLimit = value;
    return this;
  }

  async get() {
    return { docs: this.documents.slice(0, this.pageLimit) };
  }
}

function fakeDatabase(seed) {
  const documents = new Map(Object.entries(seed).map(([path, data]) => [
    path,
    structuredClone(data),
  ]));
  const reference = (collectionName, id) => ({
    id,
    path: `${collectionName}/${id}`,
  });
  return {
    collection(collectionName) {
      return { doc: (id) => reference(collectionName, id) };
    },
    async runTransaction(work) {
      const transaction = {
        async get(ref) {
          const data = documents.get(ref.path);
          return snapshot(ref, data);
        },
        update(ref, updates) {
          if (!documents.has(ref.path)) throw new Error(`Missing ${ref.path}`);
          documents.set(ref.path, {
            ...documents.get(ref.path),
            ...structuredClone(updates),
          });
        },
        create(ref, data) {
          if (documents.has(ref.path)) throw new Error(`Existing ${ref.path}`);
          documents.set(ref.path, structuredClone(data));
        },
      };
      return work(transaction);
    },
    read(path) {
      const data = documents.get(path);
      return data && structuredClone(data);
    },
    paths(pattern) {
      return [...documents.keys()].filter((path) => pattern.test(path));
    },
  };
}

function snapshot(ref, data) {
  return {
    id: ref.id,
    exists: data !== undefined,
    data: () => data && structuredClone(data),
    get: (field) => data && data[field],
  };
}

function hasCode(code) {
  return (error) => error && error.code === code;
}
