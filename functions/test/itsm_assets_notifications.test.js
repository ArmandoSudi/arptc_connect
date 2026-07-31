'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  LICENCE_EXPIRY_SCAN,
  LICENCE_RENEWAL_SCAN,
  WARRANTY_SCAN,
  buildAssetAssignmentNotificationEvent,
  buildExpiryNotificationEvent,
  buildLowStockNotificationEvent,
  deterministicExpiryEventId,
  processSoftwareLicenceExpiryNotifications,
  processSoftwareLicenceRenewalNotifications,
  processWarrantyExpiryNotifications,
} = require('../src/itsm_assets_notifications');

const fieldValue = { serverTimestamp: () => 'server-time' };
const timestamp = {
  now: () => new Date('2026-08-01T10:00:00.000Z'),
};

test('warranty scan emits only active records inside the warning window', async () => {
  const db = fakeExpiryDatabase({
    'warranties/due': warranty('2026-08-12T00:00:00.000Z'),
    'warranties/later': warranty('2026-10-12T00:00:00.000Z'),
    'warranties/inactive': {
      ...warranty('2026-08-10T00:00:00.000Z'),
      isActive: false,
    },
  });

  const result = await processWarrantyExpiryNotifications({
    db,
    fieldValue,
    timestamp,
    warningWindowDays: 30,
  });

  assert.equal(result.scannedCount, 1);
  assert.equal(result.eligibleCount, 1);
  assert.equal(result.createdCount, 1);
  assert.equal(db.notificationEvents().length, 1);
  assert.equal(db.notificationEvents()[0].entityId, 'due');
  assert.deepEqual(db.notificationEvents()[0].target, {
    type: 'MODULE_ROLE',
    moduleKey: 'ticketing',
    roles: ['MANAGER'],
  });
});

test('licence renewal and expiry scans use separate event templates', async () => {
  const db = fakeExpiryDatabase({
    'softwareLicences/office': {
      softwareProduct: 'Office Suite',
      renewalDate: '2026-08-09T00:00:00.000Z',
      expiryDate: '2026-08-20T00:00:00.000Z',
      isActive: true,
    },
  });

  await processSoftwareLicenceRenewalNotifications({
    db,
    fieldValue,
    timestamp,
  });
  await processSoftwareLicenceExpiryNotifications({
    db,
    fieldValue,
    timestamp,
  });

  const events = db.notificationEvents();
  assert.equal(events.length, 2);
  assert.ok(events.some((event) =>
    event.title === 'Software licence renewal due' &&
    event.body === 'Office Suite is due for renewal on 2026-08-09.'));
  assert.ok(events.some((event) =>
    event.title === 'Software licence expiring' &&
    event.body === 'Office Suite expires on 2026-08-20.'));
  assert.ok(events.every((event) =>
    event.deepLink ===
      '/services/itsm/assets-configuration/licences?licenceId=office'));
});

test('deterministic IDs make repeated scheduled delivery idempotent', async () => {
  const db = fakeExpiryDatabase({
    'warranties/retry-safe': warranty('2026-08-12T00:00:00.000Z'),
  });

  const first = await processWarrantyExpiryNotifications({
    db,
    fieldValue,
    timestamp,
  });
  const replay = await processWarrantyExpiryNotifications({
    db,
    fieldValue,
    timestamp,
  });

  assert.equal(first.createdCount, 1);
  assert.equal(replay.createdCount, 0);
  assert.equal(replay.duplicateCount, 1);
  assert.equal(db.notificationEvents().length, 1);
  const event = db.notificationEvents()[0];
  assert.equal(event.deduplicationId, deterministicExpiryEventId({
    recordId: 'retry-safe',
    notificationKind: 'warranty_expiring',
    dateBucket: '2026-08-12',
  }));
});

test('bounded pagination returns and consumes a stable date and ID cursor', async () => {
  const db = fakeExpiryDatabase({
    'warranties/a': warranty('2026-08-05T00:00:00.000Z'),
    'warranties/b': warranty('2026-08-05T00:00:00.000Z'),
    'warranties/c': warranty('2026-08-06T00:00:00.000Z'),
  });

  const first = await processWarrantyExpiryNotifications({
    db,
    fieldValue,
    timestamp,
    batchSize: 2,
  });
  assert.equal(db.lastQueryLimit, 2);
  assert.deepEqual(first.nextCursor, {
    notificationKind: 'warranty_expiring',
    dateValue: '2026-08-05T00:00:00.000Z',
    documentId: 'b',
  });

  const second = await processWarrantyExpiryNotifications({
    db,
    fieldValue,
    timestamp,
    batchSize: 2,
    cursor: first.nextCursor,
  });
  assert.equal(second.scannedCount, 1);
  assert.equal(second.createdCount, 1);
  assert.equal(second.nextCursor, null);
  assert.deepEqual(
    db.notificationEvents().map((event) => event.entityId).sort(),
    ['a', 'b', 'c'],
  );
});

test('batch size is capped at the processor maximum', async () => {
  const db = fakeExpiryDatabase({
    'warranties/due': warranty('2026-08-05T00:00:00.000Z'),
  });
  await processWarrantyExpiryNotifications({
    db,
    fieldValue,
    timestamp,
    batchSize: 9999,
  });
  assert.equal(db.lastQueryLimit, 200);
});

test('warranty and licence events use canonical entity-specific deep links', () => {
  const warrantyEvent = buildExpiryNotificationEvent({
    scan: WARRANTY_SCAN,
    recordId: 'warranty/unsafe',
    record: { name: 'Laptop coverage' },
    dueAt: '2026-08-12T00:00:00.000Z',
    createdAt: 'server-time',
  });
  const renewalEvent = buildExpiryNotificationEvent({
    scan: LICENCE_RENEWAL_SCAN,
    recordId: 'licence-1',
    record: { softwareProduct: 'ERP' },
    dueAt: '2026-08-15T00:00:00.000Z',
    createdAt: 'server-time',
  });
  const expiryEvent = buildExpiryNotificationEvent({
    scan: LICENCE_EXPIRY_SCAN,
    recordId: 'licence-1',
    record: { softwareProduct: 'ERP' },
    dueAt: '2026-08-20T00:00:00.000Z',
    createdAt: 'server-time',
  });

  assert.equal(warrantyEvent.data.eventType, 'asset.warranty_expiring');
  assert.equal(
    warrantyEvent.data.deepLink,
    '/services/itsm/assets-configuration/' +
      'suppliers-warranties?warrantyId=warranty%2Funsafe',
  );
  assert.equal(renewalEvent.data.eventType, 'licence.expiring');
  assert.equal(expiryEvent.data.eventType, 'licence.expiring');
  assert.notEqual(renewalEvent.id, expiryEvent.id);
});

test('assignment events target only the authoritative assignee with a canonical route', () => {
  const event = buildAssetAssignmentNotificationEvent({
    assetId: 'asset-1',
    assetTag: 'ARPTC-001',
    assignedUserId: 'user-1',
    assignedUserEmail: 'USER@ARPTC.CD',
    assignmentId: 'assignment-1',
    actor: { uid: 'manager-1', displayName: 'Manager', email: 'manager@arptc.cd' },
    createdAt: 'server-time',
  });
  assert.equal(event.data.eventType, 'asset.assigned');
  assert.deepEqual(event.data.target, {
    type: 'USERS',
    userIds: ['user-1'],
    userEmails: ['user@arptc.cd'],
  });
  assert.equal(
    event.data.deepLink,
    '/services/itsm/assets-configuration/assets/my/asset-1',
  );
  assert.equal(
    buildAssetAssignmentNotificationEvent({
      assetId: 'asset-1',
      assetTag: 'Different display only',
      assignedUserId: 'user-1',
      assignedUserEmail: 'user@arptc.cd',
      assignmentId: 'assignment-1',
      actor: {},
      createdAt: 'later',
    }).id,
    event.id,
  );
});

test('low-stock events target ticketing managers and deduplicate by episode', () => {
  const first = buildLowStockNotificationEvent({
    stockItemId: 'cable-1',
    stockItemName: 'Network cable',
    sku: 'CAB-1',
    availableQuantity: 2,
    minimumQuantity: 3,
    episode: 1,
    actor: { uid: 'manager-1' },
    createdAt: 'server-time',
  });
  const replay = buildLowStockNotificationEvent({
    stockItemId: 'cable-1',
    stockItemName: 'Network cable',
    availableQuantity: 1,
    minimumQuantity: 3,
    episode: 1,
    actor: { uid: 'manager-2' },
    createdAt: 'later',
  });
  const nextEpisode = buildLowStockNotificationEvent({
    stockItemId: 'cable-1',
    stockItemName: 'Network cable',
    availableQuantity: 3,
    minimumQuantity: 3,
    episode: 2,
    actor: {},
    createdAt: 'later',
  });
  assert.equal(first.id, replay.id);
  assert.notEqual(first.id, nextEpisode.id);
  assert.deepEqual(first.data.target, {
    type: 'MODULE_ROLE',
    moduleKey: 'ticketing',
    roles: ['MANAGER'],
  });
  assert.equal(
    first.data.deepLink,
    '/services/itsm/assets-configuration/stock?stockItemId=cable-1',
  );
});

test('licence secrets are omitted from payloads and logger metadata', async () => {
  const loggerCalls = [];
  const db = fakeExpiryDatabase({
    'softwareLicences/secret-bearing': {
      softwareProduct: 'Secure Tool',
      expiryDate: '2026-08-20T00:00:00.000Z',
      isActive: true,
      licenceKey: 'DO-NOT-LEAK',
      activationSecret: 'DO-NOT-LEAK-EITHER',
      credentials: { password: 'hidden' },
    },
  });

  await processSoftwareLicenceExpiryNotifications({
    db,
    fieldValue,
    timestamp,
    logger: { info: (...args) => loggerCalls.push(args) },
  });

  const serializedEvent = JSON.stringify(db.notificationEvents()[0]);
  const serializedLogs = JSON.stringify(loggerCalls);
  assert.doesNotMatch(serializedEvent, /DO-NOT-LEAK|password|licenceKey/);
  assert.doesNotMatch(serializedLogs, /DO-NOT-LEAK|password|licenceKey/);
  assert.equal(db.notificationEvents()[0].createdAt, 'server-time');
});

function warranty(expirationDate) {
  return {
    name: 'Standard warranty',
    expirationDate,
    isActive: true,
    status: 'active',
  };
}

function fakeExpiryDatabase(seed) {
  const documents = new Map(Object.entries(seed).map(([path, value]) => [
    path,
    structuredClone(value),
  ]));
  class Ref {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
  }
  class Query {
    constructor(path) {
      this.path = path;
      this.filters = [];
      this.orders = [];
      this.cursor = null;
      this.queryLimit = null;
    }
    where(field, operator, value) {
      this.filters.push({ field, operator, value });
      return this;
    }
    orderBy(field) {
      this.orders.push(field);
      return this;
    }
    startAfter(...values) {
      this.cursor = values;
      return this;
    }
    limit(value) {
      this.queryLimit = value;
      api.lastQueryLimit = value;
      return this;
    }
    doc(id) {
      return new Ref(`${this.path}/${id}`);
    }
    async get() {
      const dateField = this.orders[0];
      let records = [...documents.entries()]
        .filter(([path]) => path.split('/').length === 2 &&
          path.startsWith(`${this.path}/`))
        .map(([path, value]) => ({
          id: path.split('/').at(-1),
          ref: new Ref(path),
          value,
        }));
      for (const filter of this.filters) {
        records = records.filter(({ value }) => compare(
          value[filter.field],
          filter.operator,
          filter.value,
        ));
      }
      records.sort((left, right) => {
        const dateOrder = String(left.value[dateField])
          .localeCompare(String(right.value[dateField]));
        return dateOrder || left.id.localeCompare(right.id);
      });
      if (this.cursor) {
        const [dateValue, documentId] = this.cursor;
        records = records.filter(({ id, value }) =>
          String(value[dateField]) > String(dateValue) ||
          (String(value[dateField]) === String(dateValue) && id > documentId));
      }
      records = records.slice(0, this.queryLimit);
      const docs = records.map(({ id, ref, value }) => ({
        id,
        ref,
        data: () => structuredClone(value),
      }));
      return { docs, size: docs.length };
    }
  }
  const api = {
    lastQueryLimit: null,
    collection(name) {
      return new Query(name);
    },
    notificationEvents() {
      return [...documents.entries()]
        .filter(([path]) => path.startsWith('notificationEvents/'))
        .map(([, value]) => structuredClone(value));
    },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (ref) => ({
          exists: documents.has(ref.path),
          data: () => structuredClone(documents.get(ref.path)),
        }),
        create: (ref, value) => writes.push([ref, value]),
      };
      const result = await callback(transaction);
      for (const [ref, value] of writes) {
        if (documents.has(ref.path)) throw new Error('already-exists');
        documents.set(ref.path, structuredClone(value));
      }
      return result;
    },
  };
  return api;
}

function compare(actual, operator, expected) {
  if (operator === '==') return actual === expected;
  if (operator === '>=') return String(actual) >= String(expected);
  if (operator === '<=') return String(actual) <= String(expected);
  throw new Error(`Unsupported test query operator: ${operator}`);
}
