'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  evaluateServiceRequestSla,
  processServiceRequestSlaBatch,
} = require('../src/itsm_support_sla');

const fieldValue = { serverTimestamp: () => 'server-time' };
const timestamp = {
  now: () => new Date('2026-08-01T10:00:00.000Z'),
};

test('SLA evaluation handles warning, breach, and terminal records', () => {
  const request = {
    status: 'in_fulfilment',
    lifecycleState: 'active',
    slaSummary: {
      warningAt: new Date('2026-08-01T09:00:00.000Z'),
      fulfilmentDueAt: new Date('2026-08-01T11:00:00.000Z'),
    },
  };
  assert.equal(
    evaluateServiceRequestSla(request, timestamp.now()).status,
    'at_risk',
  );
  assert.equal(
    evaluateServiceRequestSla(
      request,
      new Date('2026-08-01T12:00:00.000Z'),
    ).status,
    'breached',
  );
  assert.equal(
    evaluateServiceRequestSla({ ...request, status: 'closed' }, timestamp.now()),
    null,
  );
});

test('scheduled SLA processing is bounded and writes deduplicated audience routes', async () => {
  const db = fakeSlaDatabase({
    'serviceRequests/request-1': {
      requestNumber: 'REQ-1',
      title: 'Laptop request',
      requesterId: 'user-1',
      requestedForUserId: 'user-1',
      requesterEmail: 'user-1@arptc.cd',
      status: 'in_fulfilment',
      lifecycleState: 'active',
      slaStatus: 'on_track',
      slaNextCheckAt: new Date('2026-08-01T09:00:00.000Z'),
      slaSummary: {
        status: 'on_track',
        warningAt: new Date('2026-08-01T09:00:00.000Z'),
        fulfilmentDueAt: new Date('2026-08-01T11:00:00.000Z'),
      },
    },
  });
  const result = await processServiceRequestSlaBatch({
    db,
    fieldValue,
    timestamp,
    batchSize: 500,
  });
  assert.deepEqual(result, { scannedCount: 1, changedCount: 1 });
  assert.equal(db.queryLimit, 200);
  assert.equal(db.document('serviceRequests/request-1').slaStatus, 'at_risk');
  const notifications = db.paths()
    .filter((path) => path.startsWith('notificationEvents/'))
    .map((path) => db.document(path));
  assert.equal(notifications.length, 2);
  assert.ok(notifications.some(
    (event) => event.route ===
      '/services/itsm/support/my-requests/request-1',
  ));
  assert.ok(notifications.some(
    (event) => event.route ===
      '/services/itsm/support/service-requests/request-1',
  ));
});

function fakeSlaDatabase(seed) {
  const documents = new Map(Object.entries(seed).map(([path, value]) => [
    path,
    structuredClone(value),
  ]));
  class Ref {
    constructor(path) { this.path = path; this.id = path.split('/').at(-1); }
  }
  class Query {
    where() { return this; }
    orderBy() { return this; }
    limit(value) { api.queryLimit = value; return this; }
    async get() {
      const docs = [...documents.entries()]
        .filter(([path]) => path.split('/').length === 2 &&
          path.startsWith('serviceRequests/'))
        .slice(0, api.queryLimit)
        .map(([path, value]) => ({
          ref: new Ref(path),
          data: () => structuredClone(value),
        }));
      return { docs, size: docs.length };
    }
    doc(id) { return new Ref(`${this.path}/${id}`); }
    constructor(path) { this.path = path; }
  }
  const api = {
    queryLimit: null,
    collection(name) { return new Query(name); },
    document(path) { return documents.get(path); },
    paths() { return [...documents.keys()]; },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (ref) => {
          const value = documents.get(ref.path);
          return {
            exists: value !== undefined,
            data: () => structuredClone(value),
          };
        },
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
  return api;
}
