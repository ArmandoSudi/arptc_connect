'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  migrateLegacyAgentAccount,
} = require('../src/agent_account_migration');

const fieldValue = { serverTimestamp: () => 'server-time' };

test('moves a legacy email-keyed agent to its Firebase Auth UID', async () => {
  const db = fakeDatabase({
    'agents/legacy@example.com': {
      firstName: 'Legacy',
      name: 'Agent',
      email: 'legacy@example.com',
      isActive: true,
      position: 'BUREAU_ATTACHE',
      direction: 'dep-it',
      service: 'svc-support',
      bureau: 'bureau-helpdesk',
      modulePermissions: { ticketing: 'MANAGER' },
      createdAt: 'original-created-at',
    },
  });
  const auth = fakeAuth({ 'legacy@example.com': { uid: 'auth-uid-1' } });

  const result = await migrateLegacyAgentAccount({
    db,
    auth,
    fieldValue,
    legacyAgentId: 'legacy@example.com',
    actorUid: 'manager-1',
  });

  assert.deepEqual(result, {
    uid: 'auth-uid-1',
    authAccountCreated: false,
    alreadyCanonical: false,
    requiresOrganizationAssignment: true,
  });
  const canonical = db.document('agents/auth-uid-1');
  assert.equal(canonical.email, 'legacy@example.com');
  assert.equal(canonical.departmentId, undefined);
  assert.equal(canonical.serviceId, undefined);
  assert.equal(canonical.bureauId, undefined);
  assert.equal(canonical.primaryAssignmentId, undefined);
  assert.equal(canonical.direction, undefined);
  assert.equal(canonical.id, undefined);
  assert.equal(canonical.modulePermissions.ticketing, 'MANAGER');
  assert.equal(canonical.migration.sourceAgentId, 'legacy@example.com');
  assert.equal(db.document('agents/legacy@example.com'), undefined);
});

test('creates Auth once and uses a migration receipt for safe retries', async () => {
  const db = fakeDatabase({
    'agents/generated-agent-id': {
      firstName: 'Console',
      name: 'Agent',
      email: 'console@example.com',
      position: 'DEPARTMENT_HEAD',
      departmentId: 'dep-it',
    },
  });
  const auth = fakeAuth();

  const first = await migrateLegacyAgentAccount({
    db,
    auth,
    fieldValue,
    legacyAgentId: 'generated-agent-id',
    actorUid: 'manager-1',
    defaultPassword: 'Arptc@1234',
  });
  const second = await migrateLegacyAgentAccount({
    db,
    auth,
    fieldValue,
    legacyAgentId: 'generated-agent-id',
    actorUid: 'manager-1',
    defaultPassword: 'Arptc@1234',
  });

  assert.equal(first.authAccountCreated, true);
  assert.equal(auth.createdUsers[0].password, 'Arptc@1234');
  assert.equal(db.document(`agents/${first.uid}`).isActive, true);
  assert.equal(db.document(`agents/${first.uid}`).department, undefined);
  assert.equal(first.requiresOrganizationAssignment, true);
  assert.deepEqual(db.document(`agents/${first.uid}`).modulePermissions, {});
  assert.equal(db.document('agents/generated-agent-id'), undefined);
  assert.deepEqual(second, {
    uid: first.uid,
    authAccountCreated: false,
    alreadyCanonical: true,
    requiresOrganizationAssignment: true,
  });
  assert.equal(auth.createdUsers.length, 1);
});

test('collapses a same-email duplicate into the existing UID document', async () => {
  const db = fakeDatabase({
    'agents/legacy-id': {
      firstName: 'Legacy',
      name: 'Agent',
      email: 'agent@example.com',
      position: 'SERVICE_HEAD',
      departmentId: 'dep-it',
      serviceId: 'svc-support',
    },
    'agents/auth-uid-1': {
      firstName: 'Canonical',
      name: 'Agent',
      email: 'agent@example.com',
      position: 'SERVICE_HEAD',
      departmentId: 'dep-it',
      serviceId: 'svc-support',
    },
  });
  const auth = fakeAuth({ 'agent@example.com': { uid: 'auth-uid-1' } });

  const result = await migrateLegacyAgentAccount({
    db,
    auth,
    fieldValue,
    legacyAgentId: 'legacy-id',
    actorUid: 'manager-1',
  });

  assert.equal(result.alreadyCanonical, true);
  assert.equal(result.requiresOrganizationAssignment, true);
  assert.equal(db.document('agents/legacy-id'), undefined);
  assert.equal(db.document('agents/auth-uid-1').firstName, 'Canonical');
  assert.equal(db.document('agents/auth-uid-1').service, undefined);
});

test('does not overwrite an unrelated canonical profile', async () => {
  const db = fakeDatabase({
    'agents/legacy-id': {
      email: 'legacy@example.com',
      position: 'DEPARTMENT_HEAD',
      departmentId: 'dep-it',
    },
    'agents/auth-uid-1': { email: 'other@example.com', isActive: true },
  });
  const auth = fakeAuth({ 'legacy@example.com': { uid: 'auth-uid-1' } });

  await assert.rejects(
    () => migrateLegacyAgentAccount({
      db,
      auth,
      fieldValue,
      legacyAgentId: 'legacy-id',
      actorUid: 'manager-1',
    }),
    (error) => error.code === 'already-exists',
  );
  assert.equal(db.document('agents/auth-uid-1').email, 'other@example.com');
  assert.notEqual(db.document('agents/legacy-id'), undefined);
});

test('preserves an existing canonical schema-v2 placement and its projections', async () => {
  const placement = {
    organizationSchemaVersion: 2,
    organizationId: 'org-arptc',
    organizationName: 'ARPTC',
    primaryOrganizationUnitId: 'bureau-support',
    primaryOrganizationUnitName: 'Support',
    primaryOrganizationUnitType: 'BUREAU',
    primaryAssignmentId: 'assignment-current',
    organizationAncestorUnitIds: ['department-it', 'service-operations'],
    organizationPathUnitIds: [
      'department-it',
      'service-operations',
      'bureau-support',
    ],
    organizationPathNames: ['IT', 'Operations', 'Support'],
    scopeKeys: [
      'org:org-arptc',
      'unit:department-it',
      'unit:service-operations',
      'unit:bureau-support',
    ],
    departmentId: 'department-it',
    department: 'IT',
    serviceId: 'service-operations',
    service: 'Operations',
    bureauId: 'bureau-support',
    bureau: 'Support',
  };
  const db = fakeDatabase({
    'agents/legacy-id': {
      firstName: 'Legacy',
      name: 'Agent',
      email: 'agent@example.com',
      departmentId: 'obsolete-department',
    },
    'agents/auth-uid-1': {
      firstName: 'Canonical',
      name: 'Agent',
      email: 'agent@example.com',
      isActive: true,
      ...placement,
    },
    'agentDirectory/auth-uid-1': { marker: 'safe-directory-retained' },
    'agentAuthorizationIndex/auth-uid-1': {
      marker: 'authorization-retained',
    },
  });
  const auth = fakeAuth({ 'agent@example.com': { uid: 'auth-uid-1' } });

  const result = await migrateLegacyAgentAccount({
    db,
    auth,
    fieldValue,
    legacyAgentId: 'legacy-id',
    actorUid: 'manager-1',
  });

  assert.equal(result.alreadyCanonical, true);
  assert.equal(result.requiresOrganizationAssignment, false);
  const canonical = db.document('agents/auth-uid-1');
  for (const [key, value] of Object.entries(placement)) {
    assert.deepEqual(canonical[key], value, key);
  }
  assert.equal(
    db.document('agentDirectory/auth-uid-1').marker,
    'safe-directory-retained',
  );
  assert.equal(
    db.document('agentAuthorizationIndex/auth-uid-1').marker,
    'authorization-retained',
  );
  assert.equal(db.document('agents/legacy-id'), undefined);
});

function fakeAuth(existingUsers = {}) {
  const users = new Map(Object.entries(existingUsers));
  const createdUsers = [];
  let counter = 1;
  return {
    createdUsers,
    async getUserByEmail(email) {
      const user = users.get(email);
      if (!user) {
        const error = new Error('User not found');
        error.code = 'auth/user-not-found';
        throw error;
      }
      return { email, ...user };
    },
    async createUser(data) {
      const user = { uid: `created-uid-${counter++}`, ...data };
      users.set(data.email, user);
      createdUsers.push(user);
      return user;
    },
    async deleteUser(uid) {
      for (const [email, user] of users.entries()) {
        if (user.uid === uid) users.delete(email);
      }
    },
  };
}

function fakeDatabase(seed = {}) {
  const documents = new Map(Object.entries(seed));
  const reference = (path) => ({
    path,
    async get() {
      return snapshot(path, documents.get(path));
    },
  });
  return {
    collection(name) {
      return { doc: (id) => reference(`${name}/${id}`) };
    },
    async runTransaction(callback) {
      return callback({
        get: (ref) => ref.get(),
        set(ref, data, options = {}) {
          const existing = documents.get(ref.path) || {};
          documents.set(
            ref.path,
            options.merge ? { ...existing, ...data } : data,
          );
        },
        delete(ref) {
          documents.delete(ref.path);
        },
      });
    },
    document(path) {
      return documents.get(path);
    },
  };
}

function snapshot(id, data) {
  return {
    id: id.split('/').pop(),
    exists: data !== undefined,
    data: () => data,
  };
}
