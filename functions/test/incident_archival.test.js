const assert = require('node:assert/strict');
const test = require('node:test');

const {
  archiveEligibleIncidents,
  buildArchivePatch,
} = require('../src/incident_archival');

test('buildArchivePatch uses server timestamps for every lifecycle date', () => {
  let callCount = 0;
  const fieldValue = {
    serverTimestamp() {
      callCount += 1;
      return `server-time-${callCount}`;
    },
  };

  assert.deepEqual(buildArchivePatch(fieldValue), {
    status: 'archived',
    lifecycleState: 'archived',
    archivedAt: 'server-time-1',
    updatedAt: 'server-time-1',
    lastStatusChangedAt: 'server-time-1',
  });
  assert.equal(callCount, 1);
});

test('archiveEligibleIncidents processes bounded batches until exhausted', async () => {
  const committed = [];
  const snapshots = [
    snapshot(['incident-1', 'incident-2']),
    snapshot(['incident-3']),
  ];
  const db = fakeFirestore(snapshots, committed);

  const count = await archiveEligibleIncidents({
    db,
    fieldValue: { serverTimestamp: () => 'server-time' },
    timestamp: { fromDate: (value) => value.toISOString() },
    now: new Date('2026-08-01T00:00:00.000Z'),
    batchSize: 2,
  });

  assert.equal(count, 3);
  assert.deepEqual(
    committed.map((entry) => entry.id),
    ['incident-1', 'incident-2', 'incident-3'],
  );
  assert.ok(
    committed.every(
      (entry) =>
        entry.patch.status === 'archived' &&
        entry.patch.lifecycleState === 'archived',
    ),
  );
});

test('archiveEligibleIncidents is a no-op when no documents are eligible', async () => {
  const committed = [];
  const count = await archiveEligibleIncidents({
    db: fakeFirestore([snapshot([])], committed),
    fieldValue: { serverTimestamp: () => 'server-time' },
    timestamp: { fromDate: (value) => value.toISOString() },
  });

  assert.equal(count, 0);
  assert.deepEqual(committed, []);
});

function snapshot(ids) {
  return {
    empty: ids.length === 0,
    size: ids.length,
    docs: ids.map((id) => ({ id, ref: { id } })),
  };
}

function fakeFirestore(snapshots, committed) {
  let index = 0;
  const query = {
    where: () => query,
    orderBy: () => query,
    limit: () => query,
    get: async () => snapshots[index++] ?? snapshot([]),
  };
  return {
    collection: () => query,
    batch() {
      const pending = [];
      return {
        update(ref, patch) {
          pending.push({ id: ref.id, patch });
        },
        async commit() {
          committed.push(...pending);
        },
      };
    },
  };
}
