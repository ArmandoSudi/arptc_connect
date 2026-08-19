'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  assertAuthorizedOrganizationNotification,
  buildAuthorizationQueryPlans,
  createOrganizationNotificationEvent,
  deduplicateRecipients,
  deterministicOrganizationNotificationId,
  isAuthorizationProjectionRecipient,
  resolveOrganizationRecipientsPage,
  splitIntoSafeBatches,
  validateOrganizationNotificationPayload,
  validateOrganizationNotificationTarget,
  validateRecipientPageSize,
  validateSameOrganization,
  writeOrganizationInboxDocuments,
} = require('../src/organization_notifications');

const organizationId = 'org-arptc';

test('validates and normalizes an organization scope target', () => {
  assert.deepEqual(validateOrganizationNotificationTarget({
    type: 'org_scope',
    organizationId,
    scopeKey: 'unit:department-it',
    moduleKey: 'Support',
    roles: ['manager', 'USER', 'manager'],
  }), {
    type: 'ORG_SCOPE',
    organizationId,
    scopeKey: 'unit:department-it',
    moduleKey: 'ticketing',
    roles: ['MANAGER', 'USER'],
  });

  assert.throws(
    () => validateOrganizationNotificationTarget({
      type: 'ALL',
      organizationId,
      scopeKey: `org:${organizationId}`,
    }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('ORG_SCOPE'),
  );
  assert.throws(
    () => validateOrganizationNotificationTarget({
      type: 'ORG_SCOPE',
      organizationId,
      scopeKey: 'org:another-organization',
    }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('must match'),
  );
  assert.throws(
    () => validateOrganizationNotificationTarget({
      type: 'ORG_SCOPE',
      organizationId,
      scopeKey: `org:${organizationId}`,
      moduleKey: 'news',
    }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('provided together'),
  );
});

test('validates title, body, source, target, and internal routes', () => {
  const payload = notificationPayload();
  assert.deepEqual(validateOrganizationNotificationPayload(payload), payload);

  assert.throws(
    () => validateOrganizationNotificationPayload({
      ...payload,
      source: { ...payload.source, route: 'https://example.com/phishing' },
    }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('internal application route'),
  );
  assert.throws(
    () => validateOrganizationNotificationPayload({ ...payload, body: '' }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('body is required'),
  );
});

test('authorizes only verified UserManagement announcement sources', async () => {
  const db = new FakeSourceDb({
    [`organizations/${organizationId}`]: {
      status: 'ACTIVE',
    },
  });
  const payload = notificationPayload();
  await assert.doesNotReject(() => assertAuthorizedOrganizationNotification({
    db,
    actor: managerActor(),
    payload,
  }));

  await assert.rejects(
    () => assertAuthorizedOrganizationNotification({
      db,
      actor: managerActor(),
      payload: {
        ...payload,
        source: {
          ...payload.source,
          eventType: 'incident.created',
          moduleKey: 'ticketing',
        },
      },
    }),
    (error) => error.code === 'permission-denied' &&
      error.message.includes('not authorized'),
  );
  await assert.rejects(
    () => assertAuthorizedOrganizationNotification({
      db,
      actor: {
        ...managerActor(),
        modulePermissions: { usermanagement: 'ADMIN' },
      },
      payload,
    }),
    (error) => error.code === 'permission-denied' &&
      error.message.includes('manager'),
  );
  await assert.rejects(
    () => assertAuthorizedOrganizationNotification({
      db,
      actor: managerActor(),
      payload: {
        ...payload,
        source: {
          ...payload.source,
          route: '/service/usermanagement/organizations/org-other',
        },
      },
    }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('canonical'),
  );
});

test('trusted event creation derives actor identity and is transactionally replay-safe', async () => {
  const db = new FakeNotificationCommandDb({
    [`organizations/${organizationId}`]: { status: 'ACTIVE' },
  });
  const payload = notificationPayload();
  const actor = {
    ...managerActor(),
    firstName: 'Aline',
    name: 'Kabongo',
    email: 'ALINE@EXAMPLE.COM',
  };
  const input = {
    db,
    fieldValue: { serverTimestamp: () => 'server-time' },
    payload,
    actor,
  };

  const first = await createOrganizationNotificationEvent(input);
  const replay = await createOrganizationNotificationEvent(input);
  assert.equal(first.created, true);
  assert.equal(replay.created, false);
  assert.equal(replay.replayed, true);
  assert.equal(
    db.pathsMatching(/^notificationEvents\//).length,
    1,
  );
  assert.equal(
    db.pathsMatching(/^organizationCommandReceipts\//).length,
    1,
  );
  assert.equal(
    db.pathsMatching(/^organizationAuditEvents\//).length,
    1,
  );
  const event = db.document(`notificationEvents/${first.eventId}`);
  assert.equal(event.createdByUserId, 'uid-manager');
  assert.equal(event.createdByName, 'Aline Kabongo');
  assert.equal(event.createdByEmail, 'aline@example.com');
  assert.equal(event.status, 'PENDING');
  const audit = db.document(`organizationAuditEvents/${first.eventId}`);
  assert.equal(audit.eventType, 'ORGANIZATION_NOTIFICATION_CREATED');
  assert.equal(audit.actorUid, 'uid-manager');
  assert.equal(audit.after.notificationEventId, first.eventId);

  await assert.rejects(
    () => createOrganizationNotificationEvent({
      ...input,
      payload: { ...payload, body: 'Changed after command completion.' },
    }),
    (error) => error.code === 'already-exists',
  );
  assert.equal(db.document(`notificationEvents/${first.eventId}`).body,
    'A policy has changed.');
  assert.equal(
    db.pathsMatching(/^organizationAuditEvents\//).length,
    1,
  );
});

test('rejects cross-organization targets before scope resolution', () => {
  assert.deepEqual(
    validateSameOrganization(organizationId, baseTarget()),
    baseTarget(),
  );
  assert.throws(
    () => validateSameOrganization('org-other', baseTarget()),
    (error) => error.code === 'permission-denied' &&
      error.message.includes("caller's organization"),
  );
});

test('matches inherited ancestor scopes from agentAuthorizationIndex', () => {
  const projection = {
    organizationId,
    isActive: true,
    scopeKeys: [
      `org:${organizationId}`,
      'unit:department-it',
      'unit:service-operations',
      'unit:bureau-helpdesk',
    ],
    scopeRoleKeys: [],
  };

  assert.equal(isAuthorizationProjectionRecipient(projection, {
    ...baseTarget(),
    scopeKey: 'unit:department-it',
  }), true);
  assert.equal(isAuthorizationProjectionRecipient(projection, {
    ...baseTarget(),
    scopeKey: 'unit:department-finance',
  }), false);
  assert.equal(isAuthorizationProjectionRecipient({
    ...projection,
    organizationId: 'org-other',
  }, baseTarget()), false);
  assert.equal(isAuthorizationProjectionRecipient({
    ...projection,
    isActive: false,
  }, baseTarget()), false);
});

test('builds scopeRoleKeys and matches any requested role', () => {
  const target = {
    ...baseTarget(),
    scopeKey: 'unit:department-it',
    moduleKey: 'ticketing',
    roles: ['USER', 'MANAGER'],
  };
  assert.deepEqual(buildAuthorizationQueryPlans(target), [
    {
      field: 'scopeRoleKeys',
      key: 'unit:department-it|ticketing:MANAGER',
    },
    {
      field: 'scopeRoleKeys',
      key: 'unit:department-it|ticketing:USER',
    },
  ]);
  assert.equal(isAuthorizationProjectionRecipient({
    organizationId,
    isActive: true,
    scopeRoleKeys: [
      'unit:department-it|ticketing:MANAGER',
      'unit:service-operations|ticketing:MANAGER',
    ],
  }, target), true);
  assert.equal(isAuthorizationProjectionRecipient({
    organizationId,
    isActive: true,
    scopeRoleKeys: ['unit:department-it|news:MANAGER'],
  }, target), false);
});

test('deduplicates recipients returned by overlapping scope-role queries', () => {
  const manager = { id: 'uid-manager' };
  const recipients = deduplicateRecipients([
    manager,
    { id: 'uid-user' },
    { id: 'uid-manager' },
    'uid-user',
    '',
  ]);
  assert.deepEqual(recipients, [manager, { id: 'uid-user' }]);
});

test('splits writes into safe batches and rejects unsafe batch sizes', () => {
  const recipients = Array.from({ length: 805 }, (_, index) => `uid-${index}`);
  const batches = splitIntoSafeBatches(recipients);
  assert.deepEqual(batches.map((batch) => batch.length), [400, 400, 5]);
  assert.deepEqual(batches.flat(), recipients);
  assert.throws(
    () => splitIntoSafeBatches(recipients, 401),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('between 1 and 400'),
  );
  assert.equal(validateRecipientPageSize(400), 400);
  assert.throws(
    () => validateRecipientPageSize(401),
    (error) => error.code === 'invalid-argument',
  );
});

test('creates stable event IDs independent of duplicate role ordering', () => {
  const first = notificationPayload({ roles: ['USER', 'MANAGER'] });
  const second = notificationPayload({ roles: ['manager', 'USER', 'MANAGER'] });
  assert.equal(
    deterministicOrganizationNotificationId(first),
    deterministicOrganizationNotificationId(second),
  );
  assert.match(
    deterministicOrganizationNotificationId(first),
    /^org_scope_[a-f0-9]{48}$/,
  );
});

test('pages recipients with a bounded document cursor', async () => {
  const db = new FakeAuthorizationDb([
    authorizationDocument('uid-a'),
    authorizationDocument('uid-b'),
    authorizationDocument('uid-c'),
  ]);
  const first = await resolveOrganizationRecipientsPage({
    db,
    target: baseTarget(),
    pageSize: 2,
  });
  assert.deepEqual(first, {
    recipientIds: ['uid-a', 'uid-b'],
    nextCursor: 'uid-b',
    hasMore: true,
  });

  const second = await resolveOrganizationRecipientsPage({
    db,
    target: baseTarget(),
    cursor: first.nextCursor,
    pageSize: 2,
  });
  assert.deepEqual(second, {
    recipientIds: ['uid-c'],
    nextCursor: null,
    hasMore: false,
  });
  assert.deepEqual(db.queries.map((query) => ({
    cursor: query.cursor,
    limit: query.pageSize,
  })), [
    { cursor: '', limit: 2 },
    { cursor: 'uid-b', limit: 2 },
  ]);
});

test('repeated inbox delivery uses deterministic paths and merge writes', async () => {
  const db = new FakeWriteDb();
  const input = {
    db,
    recipientIds: ['uid-a', 'uid-b', 'uid-a'],
    eventId: 'org_scope_123',
    notification: { title: 'Notice' },
    batchSize: 1,
  };
  assert.equal(await writeOrganizationInboxDocuments(input), 2);
  assert.equal(await writeOrganizationInboxDocuments(input), 2);
  assert.equal(db.commits.length, 4);
  assert.deepEqual(
    db.commits.flat().map((write) => write.path),
    [
      'agents/uid-a/notifications/org_scope_123',
      'agents/uid-b/notifications/org_scope_123',
      'agents/uid-a/notifications/org_scope_123',
      'agents/uid-b/notifications/org_scope_123',
    ],
  );
  assert.ok(db.commits.flat().every((write) => write.options.merge === true));
});

function baseTarget() {
  return {
    type: 'ORG_SCOPE',
    organizationId,
    scopeKey: `org:${organizationId}`,
  };
}

function notificationPayload({ roles } = {}) {
  return {
    commandId: 'announce-2026-08',
    title: 'Organization update',
    body: 'A policy has changed.',
    source: {
      id: 'policy-update-2026-08',
      eventType: 'organization.announcement.published',
      moduleKey: 'usermanagement',
      entityType: 'organization',
      entityId: organizationId,
      route: `/service/usermanagement/organizations/${organizationId}`,
    },
    target: roles ? {
      ...baseTarget(),
      moduleKey: 'ticketing',
      roles,
    } : baseTarget(),
  };
}

function managerActor() {
  return {
    uid: 'uid-manager',
    organizationId,
    modulePermissions: { usermanagement: 'MANAGER' },
  };
}

function authorizationDocument(id) {
  return {
    id,
    data: () => ({
      organizationId,
      isActive: true,
      scopeKeys: [`org:${organizationId}`],
    }),
  };
}

class FakeAuthorizationDb {
  constructor(documents) {
    this.documents = documents;
    this.queries = [];
  }

  collection(name) {
    assert.equal(name, 'agentAuthorizationIndex');
    const query = new FakeAuthorizationQuery(this.documents);
    this.queries.push(query);
    return query;
  }
}

class FakeAuthorizationQuery {
  constructor(documents) {
    this.documents = documents;
    this.cursor = '';
    this.pageSize = 0;
  }

  where() {
    return this;
  }

  orderBy() {
    return this;
  }

  startAfter(cursor) {
    this.cursor = cursor;
    return this;
  }

  limit(pageSize) {
    this.pageSize = pageSize;
    return this;
  }

  async get() {
    const docs = this.documents
      .filter((document) => !this.cursor || document.id > this.cursor)
      .slice(0, this.pageSize);
    return { docs, size: docs.length };
  }
}

class FakeWriteDb {
  constructor() {
    this.commits = [];
  }

  collection(name) {
    return new FakeDocumentReference(name);
  }

  batch() {
    const writes = [];
    return {
      set: (reference, data, options) => {
        writes.push({ path: reference.path, data, options });
      },
      commit: async () => {
        this.commits.push(writes);
      },
    };
  }
}

class FakeSourceDb {
  constructor(documents) {
    this.documents = documents;
  }

  collection(name) {
    return {
      doc: (id) => ({
        get: async () => {
          const data = this.documents[`${name}/${id}`];
          return {
            id,
            exists: Boolean(data),
            data: () => data,
          };
        },
      }),
    };
  }
}

class FakeNotificationCommandDb {
  constructor(documents) {
    this.documents = new Map(Object.entries(documents));
  }

  collection(name) {
    return new FakeNotificationCommandReference(this, name);
  }

  document(path) {
    return this.documents.get(path);
  }

  pathsMatching(pattern) {
    return [...this.documents.keys()].filter((path) => pattern.test(path));
  }

  async runTransaction(callback) {
    const writes = [];
    const transaction = {
      get: async (reference) => reference.snapshot(),
      create: (reference, data) => writes.push({ reference, data }),
    };
    const result = await callback(transaction);
    for (const { reference, data } of writes) {
      if (this.documents.has(reference.path)) {
        throw new Error(`Document already exists: ${reference.path}`);
      }
      this.documents.set(reference.path, structuredClone(data));
    }
    return result;
  }
}

class FakeNotificationCommandReference {
  constructor(db, path) {
    this.db = db;
    this.path = path;
    this.id = path.split('/').at(-1);
  }

  doc(id) {
    return new FakeNotificationCommandReference(this.db, `${this.path}/${id}`);
  }

  async get() {
    return this.snapshot();
  }

  snapshot() {
    const data = this.db.documents.get(this.path);
    return {
      id: this.id,
      exists: data !== undefined,
      data: () => data,
      get: (field) => field.split('.').reduce(
        (value, key) => value && value[key],
        data,
      ),
    };
  }
}

class FakeDocumentReference {
  constructor(path) {
    this.path = path;
  }

  doc(id) {
    return new FakeDocumentReference(`${this.path}/${id}`);
  }

  collection(name) {
    return new FakeDocumentReference(`${this.path}/${name}`);
  }
}
