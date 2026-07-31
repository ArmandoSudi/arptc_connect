'use strict';

const crypto = require('node:crypto');

const { normalizeString } = require('./itsm_permissions');

const REPORT_SOURCE_COLLECTIONS = Object.freeze([
  'incidentTickets',
  'serviceRequests',
  'assets',
  'stockItems',
  'softwareLicences',
  'warranties',
  'changeRequests',
  'securityFindings',
  'securityExceptions',
  'assetComplianceAssessments',
  'accessReviewCampaigns',
  'accessReviewItems',
]);
const REPORT_SHARD_COUNT = 32;
const DEFAULT_COMPACTION_BATCH_SIZE = 20;
const MAX_COMPACTION_BATCH_SIZE = 100;
const MAX_SHARDS_PER_SNAPSHOT = 64;

function normalizeReportContribution({ collectionName, documentId, data }) {
  if (!REPORT_SOURCE_COLLECTIONS.includes(collectionName) || !data) return null;
  const status = normalizedCode(data.status || data.lifecycleState, 'unknown');
  const lifecycleState = normalizedCode(data.lifecycleState, status);
  const createdAt = toDate(
    data.createdAt || data.detectedAt || data.assessedAt || data.startedAt,
  );
  const updatedAt = toDate(data.updatedAt || data.lastStatusChangedAt) || createdAt;
  const referenceAt = updatedAt || createdAt || new Date(0);
  const sourceType = sourceTypeFor(collectionName);
  const priority = normalizedPriority(data.priority);
  const severity = normalizedCode(data.severity || data.risk, 'unclassified');
  const category = safeDimension(data.categoryName || data.categoryId);
  const service = safeDimension(
    data.affectedServiceName || data.serviceName || data.serviceId,
  );
  const department = safeDimension(
    data.createdByDepartmentName || data.departmentName || data.departmentId,
  );
  const assignedTo = safeDimension(
    data.assignedToName || data.ownerName || data.assignedToUserId ||
      data.ownerUserId,
  );
  const assignedToId = safeDimension(
    data.assignedToUserId || data.ownerUserId || data.assigneeUserId,
  );
  const slaStatus = normalizedCode(
    data.slaStatus || data.slaSummary && data.slaSummary.status,
    'not_applicable',
  );
  const isActive = lifecycleState === 'active' || isOperationalStatus(status);
  const isClosed = ['closed', 'resolved', 'completed'].includes(lifecycleState) ||
    ['closed', 'resolved', 'completed'].includes(status);
  const closedAt = toDate(data.closedAt || data.resolvedAt || data.completedAt);
  const resolutionTimeMinutes = createdAt && closedAt && closedAt >= createdAt
    ? Math.round((closedAt.getTime() - createdAt.getTime()) / 60000)
    : null;
  return Object.freeze({
    sourceCollection: collectionName,
    sourceType,
    sourceId: documentId,
    createdAt: createdAt && createdAt.toISOString(),
    updatedAt: updatedAt && updatedAt.toISOString(),
    status,
    lifecycleState,
    priority,
    severity,
    category,
    service,
    department,
    assignedTo,
    assignedToId,
    slaStatus,
    isActive,
    isClosed,
    isArchived: lifecycleState === 'archived' || status === 'archived',
    isUnassigned: isActive && !normalizeString(
      data.assignedToUserId || data.ownerUserId || data.assigneeUserId,
    ),
    isLowStock: collectionName === 'stockItems' &&
      numeric(data.reorderLevel, data.minimumQuantity) > 0 &&
      numeric(data.availableQuantity, data.quantityOnHand) <=
      numeric(data.reorderLevel, data.minimumQuantity),
    isExpiryRisk: isWithinDays(
      data.expiresAt || data.expiryDate || data.warrantyEndAt || data.renewalAt,
      90,
      referenceAt,
    ),
    isOverdue: Boolean(data.isOverdue) ||
      isPast(data.dueAt || data.remediationDueAt, referenceAt),
    changeSucceeded: collectionName === 'changeRequests' &&
      ['successful', 'completed', 'closed'].includes(
        normalizedCode(data.implementationResult || status),
      ),
    changeFailed: collectionName === 'changeRequests' &&
      ['failed', 'rolled_back'].includes(
        normalizedCode(data.implementationResult || status),
      ),
    resolutionTimeMinutes,
    closedAt: closedAt && closedAt.toISOString(),
    highlight: collectionName === 'incidentTickets' &&
      isActive && ['P1', 'P2'].includes(priority)
      ? Object.freeze({
        entityType: 'incident',
        entityId: documentId,
        reference: normalizeString(data.ticketNumber || data.reference).slice(0, 80),
        title: normalizeString(data.title).slice(0, 180),
        priority,
        status,
        createdAt: createdAt && createdAt.toISOString(),
      })
      : null,
  });
}

function contributionEntries(contribution, nowValue = new Date()) {
  if (!contribution) return [];
  const now = toDate(nowValue) || new Date();
  const occurredAt = toDate(contribution.createdAt) || now;
  const periods = [
    period('current', 'current', null, null),
    periodForDate('week', occurredAt),
    periodForDate('month', occurredAt),
  ];
  const entries = [];
  for (const audience of ['MANAGER', 'ADMIN']) {
    for (const value of periods) {
      entries.push(buildEntry(contribution, audience, value));
      if (contribution.sourceCollection === 'incidentTickets') {
        entries.push(buildEntry(contribution, audience, value, 'incident'));
      }
    }
    if (audience === 'MANAGER' && contribution.closedAt) {
      const closedAt = toDate(contribution.closedAt);
      entries.push(buildClosureEntry(contribution, periodForDate('week', closedAt)));
      entries.push(buildClosureEntry(contribution, periodForDate('month', closedAt)));
    }
  }
  return entries;
}

function buildEntry(contribution, audience, periodValue, forcedSnapshotType) {
  const snapshotType = forcedSnapshotType ||
    (audience === 'MANAGER' ? 'operational' : 'executive');
  const metrics = {
    totalCount: 1,
    activeCount: contribution.isActive ? 1 : 0,
    closedCount: contribution.isClosed ? 1 : 0,
    archivedCount: contribution.isArchived ? 1 : 0,
    unassignedCount: contribution.isUnassigned ? 1 : 0,
    slaAtRiskCount: contribution.slaStatus === 'at_risk' ? 1 : 0,
    slaBreachedCount: contribution.slaStatus === 'breached' ? 1 : 0,
    assignedCount: contribution.isActive && !contribution.isUnassigned ? 1 : 0,
    criticalCount: contribution.isActive &&
      ['P1', 'P2'].includes(contribution.priority) ? 1 : 0,
    awaitingApprovalCount: contribution.status === 'awaiting_approval' ? 1 : 0,
    awaitingFulfilmentCount: ['approved', 'fulfilment'].includes(
      contribution.status,
    ) ? 1 : 0,
    resolutionTimeMinutesTotal: contribution.resolutionTimeMinutes || 0,
    resolvedDurationCount: contribution.resolutionTimeMinutes === null ? 0 : 1,
  };
  if (contribution.sourceCollection === 'stockItems') {
    metrics.lowStockCount = contribution.isLowStock ? 1 : 0;
  }
  if (['softwareLicences', 'warranties'].includes(contribution.sourceCollection)) {
    metrics.expiryRiskCount = contribution.isExpiryRisk ? 1 : 0;
  }
  if (contribution.sourceCollection === 'changeRequests') {
    metrics.successfulChangeCount = contribution.changeSucceeded ? 1 : 0;
    metrics.failedChangeCount = contribution.changeFailed ? 1 : 0;
  }
  if (['securityFindings', 'accessReviewItems'].includes(
    contribution.sourceCollection,
  )) {
    metrics.overdueCount = contribution.isOverdue ? 1 : 0;
  }
  const breakdowns = {
    bySourceType: { [contribution.sourceType]: 1 },
    byStatus: { [contribution.status]: 1 },
    bySlaStatus: { [contribution.slaStatus]: 1 },
  };
  if (contribution.priority) breakdowns.byPriority = { [contribution.priority]: 1 };
  if (contribution.service) breakdowns.byService = { [contribution.service]: 1 };
  if (contribution.department) {
    breakdowns.byDepartment = { [contribution.department]: 1 };
  }
  if (contribution.category) breakdowns.byCategory = { [contribution.category]: 1 };
  if (audience === 'MANAGER' && contribution.assignedTo) {
    breakdowns.byAssignee = { [contribution.assignedTo]: 1 };
  }
  if (audience === 'MANAGER' && contribution.assignedToId) {
    breakdowns.byAssigneeId = { [contribution.assignedToId]: 1 };
  }
  if (['securityFindings', 'securityExceptions'].includes(
    contribution.sourceCollection,
  )) {
    breakdowns.bySeverity = { [contribution.severity]: 1 };
  }
  const snapshotId = snapshotDocumentId({
    audience,
    snapshotType,
    scopeType: 'global',
    scopeId: 'global',
    periodGranularity: periodValue.granularity,
    periodKey: periodValue.key,
  });
  return Object.freeze({
    snapshotId,
    audience,
    snapshotType,
    scopeType: 'global',
    scopeId: 'global',
    ...periodValue,
    metrics: Object.freeze(metrics),
    breakdowns: deepFreeze(breakdowns),
    sourceCounts: Object.freeze({ [contribution.sourceType]: 1 }),
    highlights: contribution.highlight && audience === 'ADMIN'
      ? Object.freeze({
        [`${contribution.sourceType}:${contribution.sourceId}`]: contribution.highlight,
      })
      : Object.freeze({}),
  });
}

function buildClosureEntry(contribution, periodValue) {
  const snapshotType = 'operational';
  return Object.freeze({
    snapshotId: snapshotDocumentId({
      audience: 'MANAGER',
      snapshotType,
      scopeType: 'global',
      scopeId: 'global',
      periodGranularity: periodValue.granularity,
      periodKey: periodValue.key,
    }),
    audience: 'MANAGER',
    snapshotType,
    scopeType: 'global',
    scopeId: 'global',
    ...periodValue,
    metrics: Object.freeze({ closedThisPeriodCount: 1 }),
    breakdowns: Object.freeze({}),
    sourceCounts: Object.freeze({}),
    highlights: Object.freeze({}),
    closureSourceType: contribution.sourceType,
  });
}

async function maintainReportContribution({
  db,
  fieldValue,
  collectionName,
  documentId,
  after,
  sourceEventId,
  now,
}) {
  if (!REPORT_SOURCE_COLLECTIONS.includes(collectionName)) return { ignored: true };
  const data = snapshotData(after);
  const contribution = normalizeReportContribution({
    collectionName,
    documentId,
    data,
  });
  const entries = contributionEntries(contribution, now);
  const sourcePath = `${collectionName}/${documentId}`;
  const checkpointId = sha256(sourcePath);
  const fingerprint = sha256(stableStringify({ contribution, entries }));
  const checkpointRef = db.collection('itsmReportContributions').doc(checkpointId);
  return db.runTransaction(async (transaction) => {
    const checkpointSnapshot = await transaction.get(checkpointRef);
    const previous = checkpointSnapshot.exists
      ? checkpointSnapshot.data() || {}
      : {};
    if (previous.fingerprint === fingerprint) {
      return { duplicate: true, checkpointId };
    }
    const previousEntries = Array.isArray(previous.entries) ? previous.entries : [];
    const keys = new Map();
    for (const entry of [...previousEntries, ...entries]) {
      const shardId = reportShardId(sourcePath);
      keys.set(`${entry.snapshotId}/${shardId}`, { entry, shardId });
    }
    const states = new Map();
    for (const [key, value] of keys) {
      const ref = db.collection('itsmReportSnapshots')
        .doc(value.entry.snapshotId)
        .collection('shards')
        .doc(value.shardId);
      const snapshot = await transaction.get(ref);
      states.set(key, {
        ref,
        data: snapshot.exists ? snapshot.data() || {} : {},
      });
    }
    for (const entry of previousEntries) applyEntry(states, sourcePath, entry, -1);
    for (const entry of entries) applyEntry(states, sourcePath, entry, 1);
    const serverTime = fieldValue.serverTimestamp();
    for (const state of states.values()) {
      transaction.set(state.ref, {
        ...state.data,
        updatedAt: serverTime,
      }, { merge: false });
    }
    for (const entry of uniqueEntries([...previousEntries, ...entries])) {
      transaction.set(db.collection('itsmReportSnapshots').doc(entry.snapshotId), {
        schemaVersion: 1,
        snapshotType: entry.snapshotType,
        audience: entry.audience,
        scopeType: entry.scopeType,
        scopeId: entry.scopeId,
        periodGranularity: entry.granularity,
        periodKey: entry.key,
        periodStart: entry.start || null,
        periodEnd: entry.end || null,
        confidentiality: 'internal',
        needsCompaction: true,
        sourceWatermark: serverTime,
        updatedAt: serverTime,
      }, { merge: true });
    }
    transaction.set(checkpointRef, {
      schemaVersion: 1,
      sourcePath,
      sourceCollection: collectionName,
      sourceDocumentId: documentId,
      sourceEventId: normalizeString(sourceEventId),
      fingerprint,
      contribution,
      entries,
      updatedAt: serverTime,
    }, { merge: false });
    return {
      duplicate: false,
      deleted: !contribution,
      checkpointId,
      snapshotCount: uniqueEntries(entries).length,
    };
  });
}

function applyEntry(states, sourcePath, entry, direction) {
  const key = `${entry.snapshotId}/${reportShardId(sourcePath)}`;
  const state = states.get(key);
  state.data = {
    schemaVersion: 1,
    metrics: addNumericMaps(state.data.metrics, entry.metrics, direction),
    breakdowns: addNestedNumericMaps(
      state.data.breakdowns,
      entry.breakdowns,
      direction,
    ),
    sourceCounts: addNumericMaps(
      state.data.sourceCounts,
      entry.sourceCounts,
      direction,
    ),
    highlights: applyHighlightMap(
      state.data.highlights,
      entry.highlights,
      direction,
    ),
  };
}

async function compactReportSnapshots({
  db,
  fieldValue,
  logger,
  batchSize = DEFAULT_COMPACTION_BATCH_SIZE,
}) {
  const safeBatchSize = Math.min(
    MAX_COMPACTION_BATCH_SIZE,
    Math.max(1, Number(batchSize) || DEFAULT_COMPACTION_BATCH_SIZE),
  );
  const snapshot = await db.collection('itsmReportSnapshots')
    .where('needsCompaction', '==', true)
    .orderBy('updatedAt')
    .limit(safeBatchSize)
    .get();
  let compactedCount = 0;
  for (const parent of snapshot.docs) {
    const result = await compactReportSnapshot({
      db,
      fieldValue,
      snapshotRef: parent.ref,
    });
    if (result.compacted) compactedCount += 1;
  }
  logger?.info('ITSM report snapshot compaction completed', {
    scannedCount: snapshot.size,
    compactedCount,
    batchSize: safeBatchSize,
  });
  return { scannedCount: snapshot.size, compactedCount };
}

async function compactReportSnapshot({ db, fieldValue, snapshotRef }) {
  return db.runTransaction(async (transaction) => {
    const parent = await transaction.get(snapshotRef);
    if (!parent.exists || parent.get('needsCompaction') !== true) {
      return { compacted: false, shardCount: 0 };
    }
    const shardQuery = snapshotRef.collection('shards')
      .orderBy('__name__')
      .limit(MAX_SHARDS_PER_SNAPSHOT);
    const shards = await transaction.get(shardQuery);
    let metrics = {};
    let breakdowns = {};
    let sourceCounts = {};
    let highlights = {};
    for (const shard of shards.docs) {
      const data = shard.data() || {};
      metrics = addNumericMaps(metrics, data.metrics, 1);
      breakdowns = addNestedNumericMaps(breakdowns, data.breakdowns, 1);
      sourceCounts = addNumericMaps(sourceCounts, data.sourceCounts, 1);
      highlights = { ...highlights, ...(data.highlights || {}) };
    }
    transaction.update(snapshotRef, {
      metrics: pruneNumericMap(metrics),
      breakdowns: pruneNestedNumericMap(breakdowns),
      trends: [],
      highlights: Object.values(highlights)
        .sort((left, right) => normalizeString(right.createdAt)
          .localeCompare(normalizeString(left.createdAt)))
        .slice(0, 5),
      sourceCounts: pruneNumericMap(sourceCounts),
      generatedAt: fieldValue.serverTimestamp(),
      isComplete: shards.size < MAX_SHARDS_PER_SNAPSHOT,
      needsCompaction: false,
    });
    return { compacted: true, shardCount: shards.size };
  });
}

async function reconcileReportingSources({
  db,
  fieldValue,
  collectionName,
  pageSize = 100,
  cursor = null,
  dryRun = true,
}) {
  if (!REPORT_SOURCE_COLLECTIONS.includes(collectionName)) {
    throw new Error(`Unsupported reporting source ${collectionName}.`);
  }
  const safePageSize = Math.min(200, Math.max(1, Number(pageSize) || 100));
  let query = db.collection(collectionName).orderBy('__name__').limit(safePageSize);
  if (cursor) query = query.startAfter(cursor);
  const page = await query.get();
  if (!dryRun) {
    for (const document of page.docs) {
      await maintainReportContribution({
        db,
        fieldValue,
        collectionName,
        documentId: document.id,
        after: document,
        sourceEventId: `reconcile:${document.id}`,
      });
    }
  }
  return {
    dryRun,
    scannedCount: page.size,
    nextCursor: page.size === safePageSize ? page.docs.at(-1).id : null,
  };
}

function addNumericMaps(current = {}, delta = {}, direction = 1) {
  const result = { ...(current || {}) };
  for (const [key, value] of Object.entries(delta || {})) {
    result[key] = Math.max(
      0,
      Number(result[key] || 0) + Number(value || 0) * direction,
    );
  }
  return result;
}

function addNestedNumericMaps(current = {}, delta = {}, direction = 1) {
  const result = {};
  for (const [key, value] of Object.entries(current || {})) {
    result[key] = { ...(value || {}) };
  }
  for (const [group, values] of Object.entries(delta || {})) {
    result[group] = addNumericMaps(result[group], values, direction);
  }
  return result;
}

function pruneNumericMap(value = {}) {
  return Object.fromEntries(
    Object.entries(value).filter(([, count]) => Number(count) !== 0),
  );
}

function pruneNestedNumericMap(value = {}) {
  return Object.fromEntries(Object.entries(value)
    .map(([key, counts]) => [key, pruneNumericMap(counts)])
    .filter(([, counts]) => Object.keys(counts).length > 0));
}

function applyHighlightMap(current = {}, delta = {}, direction = 1) {
  const result = { ...(current || {}) };
  for (const [key, value] of Object.entries(delta || {})) {
    if (direction > 0) result[key] = value;
    else delete result[key];
  }
  return result;
}

function snapshotDocumentId(parts) {
  return [
    parts.audience,
    parts.snapshotType,
    parts.scopeType,
    parts.scopeId,
    parts.periodGranularity,
    parts.periodKey,
  ].map((value) => normalizeString(value).replace(/[^A-Za-z0-9_-]/g, '_'))
    .join('__');
}

function reportShardId(sourcePath) {
  const value = Number.parseInt(sha256(sourcePath).slice(0, 8), 16);
  return `shard_${String(value % REPORT_SHARD_COUNT).padStart(2, '0')}`;
}

function periodForDate(granularity, date) {
  const value = new Date(Date.UTC(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
  ));
  if (granularity === 'week') {
    const weekday = value.getUTCDay() || 7;
    value.setUTCDate(value.getUTCDate() - weekday + 1);
    const end = new Date(value);
    end.setUTCDate(end.getUTCDate() + 7);
    return period(
      'week',
      value.toISOString().slice(0, 10),
      value.toISOString(),
      end.toISOString(),
    );
  }
  const start = new Date(Date.UTC(value.getUTCFullYear(), value.getUTCMonth(), 1));
  const end = new Date(Date.UTC(value.getUTCFullYear(), value.getUTCMonth() + 1, 1));
  return period(
    'month',
    start.toISOString().slice(0, 7),
    start.toISOString(),
    end.toISOString(),
  );
}

function period(granularity, key, start, end) {
  return Object.freeze({ granularity, key, start, end });
}

function sourceTypeFor(collectionName) {
  return ({
    incidentTickets: 'incident',
    serviceRequests: 'service_request',
    assets: 'asset',
    stockItems: 'stock_item',
    softwareLicences: 'software_licence',
    warranties: 'warranty',
    changeRequests: 'change_request',
    securityFindings: 'security_finding',
    securityExceptions: 'security_exception',
    assetComplianceAssessments: 'asset_compliance_assessment',
    accessReviewCampaigns: 'access_review_campaign',
    accessReviewItems: 'access_review_item',
  })[collectionName];
}

function normalizedCode(value, fallback = '') {
  return normalizeString(value).toLowerCase().replace(/[^a-z0-9]+/g, '_') || fallback;
}

function normalizedPriority(value) {
  const priority = normalizeString(value).toUpperCase();
  return ['P1', 'P2', 'P3', 'P4'].includes(priority) ? priority : null;
}

function safeDimension(value) {
  const normalized = normalizeString(value).slice(0, 120);
  return normalized && normalized.toLowerCase() !== 'restricted'
    ? normalized
    : null;
}

function numeric(...values) {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) return value;
  }
  return 0;
}

function isOperationalStatus(status) {
  return ![
    'closed', 'resolved', 'completed', 'archived', 'cancelled', 'rejected',
    'retired', 'disposed',
  ].includes(status);
}

function isWithinDays(value, days, referenceAt) {
  const date = toDate(value);
  if (!date) return false;
  const difference = date.getTime() - referenceAt.getTime();
  return difference >= 0 && difference <= days * 86400000;
}

function isPast(value, referenceAt) {
  const date = toDate(value);
  return Boolean(date && date.getTime() < referenceAt.getTime());
}

function snapshotData(snapshot) {
  if (!snapshot || snapshot.exists === false) return null;
  return typeof snapshot.data === 'function' ? snapshot.data() || {} : snapshot;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function stableStringify(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;
  return `{${Object.keys(value).sort().map((key) =>
    `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(',')}}`;
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function uniqueEntries(entries) {
  return [...new Map(entries.map((entry) => [entry.snapshotId, entry])).values()];
}

function deepFreeze(value) {
  Object.values(value).forEach((entry) => {
    if (entry && typeof entry === 'object' && !Object.isFrozen(entry)) {
      deepFreeze(entry);
    }
  });
  return Object.freeze(value);
}

module.exports = {
  DEFAULT_COMPACTION_BATCH_SIZE,
  MAX_COMPACTION_BATCH_SIZE,
  MAX_SHARDS_PER_SNAPSHOT,
  REPORT_SHARD_COUNT,
  REPORT_SOURCE_COLLECTIONS,
  addNestedNumericMaps,
  addNumericMaps,
  compactReportSnapshot,
  compactReportSnapshots,
  contributionEntries,
  maintainReportContribution,
  normalizeReportContribution,
  periodForDate,
  reconcileReportingSources,
  reportShardId,
  snapshotDocumentId,
  stableStringify,
};
