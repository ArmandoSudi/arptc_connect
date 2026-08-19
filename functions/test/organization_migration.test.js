'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  isUnplacedAgent,
  listUnplacedAgentsPage,
  normalizePageSize,
  unplacedAgentSummary,
} = require('../src/organization_migration');

test('identifies only active profiles without a complete v2 placement', () => {
  assert.equal(isUnplacedAgent({ isActive: false }), false);
  assert.equal(isUnplacedAgent({
    isActive: true,
    organizationSchemaVersion: 2,
    organizationId: 'org-1',
    primaryOrganizationUnitId: 'unit-1',
    primaryAssignmentId: 'assignment-1',
  }), false);
  assert.equal(isUnplacedAgent({
    isActive: true,
    organizationId: 'legacy-org',
  }), true);
  assert.equal(isUnplacedAgent({
    isActive: true,
    organizationSchemaVersion: 2,
    organizationId: 'org-1',
    primaryOrganizationUnitId: 'unit-1',
  }), true);
});

test('builds a minimal unplaced-agent summary without private fields', () => {
  assert.deepEqual(unplacedAgentSummary(' uid-1 ', {
    firstName: ' Aline ',
    name: ' Mbuyi ',
    postName: ' Kanku ',
    email: 'ALINE@ARPTC.CD',
    matricule: 'PRIVATE',
    modulePermissions: { usermanagement: 'MANAGER' },
    isActive: true,
  }), {
    id: 'uid-1',
    displayName: 'Aline Mbuyi Kanku',
    email: 'aline@arptc.cd',
    isActive: true,
  });
});

test('rejects unbounded page sizes', () => {
  for (const value of [0, 101, 1.5, 'invalid']) {
    assert.throws(
      () => normalizePageSize(value),
      (error) => error.code === 'invalid-argument',
    );
  }
  assert.equal(normalizePageSize(100), 100);
});

test('returns a stable bounded page and cursor after filtering', async () => {
  const db = fakeDatabase([
    ['agent-a', { isActive: true, email: 'a@example.com' }],
    ['agent-b', {
      isActive: true,
      organizationSchemaVersion: 2,
      organizationId: 'org-1',
      primaryOrganizationUnitId: 'unit-1',
      primaryAssignmentId: 'assignment-1',
    }],
    ['agent-c', { isActive: false, email: 'c@example.com' }],
    ['agent-d', { isActive: true, email: 'd@example.com' }],
  ]);
  const fieldPath = { documentId: () => '__name__' };

  const first = await listUnplacedAgentsPage({
    db,
    fieldPath,
    limit: 2,
  });
  assert.deepEqual(first.items.map((item) => item.id), ['agent-a']);
  assert.equal(first.nextCursor, 'agent-b');
  assert.equal(first.scannedCount, 2);

  const second = await listUnplacedAgentsPage({
    db,
    fieldPath,
    limit: 2,
    afterId: first.nextCursor,
  });
  assert.deepEqual(second.items.map((item) => item.id), ['agent-d']);
  assert.equal(second.nextCursor, 'agent-d');
});

function fakeDatabase(seed) {
  return {
    collection(name) {
      assert.equal(name, 'agents');
      return fakeQuery(seed);
    },
  };
}

function fakeQuery(seed, options = {}) {
  const state = {
    limit: options.limit ?? seed.length,
    afterId: options.afterId ?? '',
  };
  return {
    orderBy(field) {
      assert.equal(field, '__name__');
      return fakeQuery(seed, state);
    },
    limit(value) {
      return fakeQuery(seed, { ...state, limit: value });
    },
    startAfter(value) {
      return fakeQuery(seed, { ...state, afterId: value });
    },
    async get() {
      const start = state.afterId
        ? seed.findIndex(([id]) => id === state.afterId) + 1
        : 0;
      const selected = seed.slice(start, start + state.limit);
      const docs = selected.map(([id, data]) => ({
        id,
        data: () => data,
      }));
      return { docs, size: docs.length };
    },
  };
}
