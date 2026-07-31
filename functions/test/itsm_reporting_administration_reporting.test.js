'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  contributionEntries,
  maintainReportContribution,
  normalizeReportContribution,
  periodForDate,
  reportShardId,
  snapshotDocumentId,
} = require('../src/itsm_reporting_administration_reporting');

test('report normalization excludes descriptions, identities and restricted evidence', () => {
  const contribution = normalizeReportContribution({
    collectionName: 'securityFindings',
    documentId: 'finding-1',
    data: {
      title: 'Secret vulnerability',
      description: 'Sensitive exploit details',
      evidence: { token: 'secret' },
      requesterEmail: 'person@arptc.cd',
      status: 'assigned',
      lifecycleState: 'active',
      severity: 'critical',
      ownerName: 'Security Team',
      createdAt: '2026-08-10T10:00:00Z',
    },
  });
  const encoded = JSON.stringify(contribution);
  assert.equal(encoded.includes('Sensitive exploit'), false);
  assert.equal(encoded.includes('person@arptc.cd'), false);
  assert.equal(encoded.includes('secret'), false);
  assert.equal(contribution.severity, 'critical');
});

test('MANAGER snapshots include workload while ADMIN snapshots stay sanitized', () => {
  const contribution = normalizeReportContribution({
    collectionName: 'incidentTickets',
    documentId: 'INC-1',
    data: {
      status: 'open',
      lifecycleState: 'active',
      priority: 'P1',
      assignedToName: 'Agent One',
      affectedServiceName: 'Internet',
      createdAt: '2026-08-10T10:00:00Z',
      slaStatus: 'at_risk',
    },
  });
  const entries = contributionEntries(contribution, new Date('2026-08-11T00:00:00Z'));
  const manager = entries.find((entry) =>
    entry.audience === 'MANAGER' && entry.granularity === 'current');
  const admin = entries.find((entry) =>
    entry.audience === 'ADMIN' && entry.granularity === 'current');
  const incident = entries.find((entry) =>
    entry.audience === 'ADMIN' && entry.snapshotType === 'incident' &&
    entry.granularity === 'current');
  assert.equal(manager.metrics.activeCount, 1);
  assert.equal(manager.metrics.slaAtRiskCount, 1);
  assert.deepEqual(manager.breakdowns.byAssignee, { 'Agent One': 1 });
  assert.equal(Object.hasOwn(admin.breakdowns, 'byAssignee'), false);
  assert.equal(incident.metrics.criticalCount, 1);
  assert.equal(Object.values(incident.highlights).length, 1);
});

test('period keys and snapshot IDs are deterministic', () => {
  assert.equal(
    periodForDate('week', new Date('2026-08-12T10:00:00Z')).key,
    '2026-08-10',
  );
  assert.equal(
    periodForDate('month', new Date('2026-08-12T10:00:00Z')).key,
    '2026-08',
  );
  const parts = {
    audience: 'ADMIN', snapshotType: 'executive', scopeType: 'global',
    scopeId: 'global', periodGranularity: 'month', periodKey: '2026-08',
  };
  assert.equal(snapshotDocumentId(parts), snapshotDocumentId(parts));
  assert.equal(reportShardId('incidentTickets/INC-1'), reportShardId('incidentTickets/INC-1'));
});

test('manager closure periods count closure date instead of creation date', () => {
  const contribution = normalizeReportContribution({
    collectionName: 'incidentTickets',
    documentId: 'INC-old',
    data: {
      status: 'closed', lifecycleState: 'closed',
      createdAt: '2026-06-01T10:00:00Z',
      closedAt: '2026-08-12T10:00:00Z',
    },
  });
  const entries = contributionEntries(contribution);
  const closure = entries.find((entry) =>
    entry.audience === 'MANAGER' && entry.snapshotType === 'operational' &&
    entry.granularity === 'week' && entry.key === '2026-08-10' &&
    entry.metrics.closedThisPeriodCount === 1);
  assert(closure);
});

test('report trigger checkpoints make duplicate delivery a no-op and reverse updates', async () => {
  const db = fakeDatabase();
  const common = {
    db,
    fieldValue: { serverTimestamp: () => 'server-time' },
    collectionName: 'incidentTickets',
    documentId: 'INC-1',
    sourceEventId: 'event-1',
    now: new Date('2026-08-10T10:00:00Z'),
  };
  const open = snapshot({
    status: 'open', lifecycleState: 'active', priority: 'P1',
    createdAt: '2026-08-10T10:00:00Z',
  });
  const first = await maintainReportContribution({ ...common, after: open });
  const replay = await maintainReportContribution({ ...common, after: open });
  assert.equal(first.duplicate, false);
  assert.equal(replay.duplicate, true);

  await maintainReportContribution({
    ...common,
    sourceEventId: 'event-2',
    after: snapshot({
      status: 'closed', lifecycleState: 'closed', priority: 'P1',
      createdAt: '2026-08-10T10:00:00Z',
    }),
  });
  const snapshotId = 'MANAGER__operational__global__global__current__current';
  const shardPath = `itsmReportSnapshots/${snapshotId}/shards/${reportShardId('incidentTickets/INC-1')}`;
  const shard = db.documents.get(shardPath);
  assert.equal(shard.metrics.totalCount, 1);
  assert.equal(shard.metrics.activeCount, 0);
  assert.equal(shard.metrics.closedCount, 1);

  await maintainReportContribution({ ...common, sourceEventId: 'event-3', after: null });
  assert.equal(db.documents.get(shardPath).metrics.totalCount, 0);
});

function snapshot(data) {
  return { exists: true, data: () => data };
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
        set: (ref, value, options) => writes.push({ type: 'set', ref, value, options }),
        create: (ref, value) => writes.push({ type: 'create', ref, value }),
        update: (ref, value) => writes.push({ type: 'update', ref, value }),
      };
      const result = await callback(transaction);
      for (const write of writes) {
        const current = documents.get(write.ref.path) || {};
        if (write.type === 'create' && documents.has(write.ref.path)) {
          throw new Error('already exists');
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
