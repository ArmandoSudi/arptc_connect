'use strict';

const crypto = require('node:crypto');

const DEFAULT_EXPIRY_BATCH_SIZE = 100;
const MAX_EXPIRY_BATCH_SIZE = 200;
const DEFAULT_WARNING_WINDOW_DAYS = 30;
const MANAGER_TARGET = Object.freeze({
  type: 'MODULE_ROLE',
  moduleKey: 'ticketing',
  roles: Object.freeze(['MANAGER']),
});

const WARRANTY_SCAN = Object.freeze({
  collectionName: 'warranties',
  dateField: 'expirationDate',
  notificationKind: 'warranty_expiring',
  eventType: 'asset.warranty_expiring',
  entityType: 'warranty',
  activeQuery: Object.freeze({ field: 'isActive', value: true }),
});

const LICENCE_RENEWAL_SCAN = Object.freeze({
  collectionName: 'softwareLicences',
  dateField: 'renewalDate',
  notificationKind: 'licence_renewal_due',
  eventType: 'licence.expiring',
  entityType: 'software_licence',
});

const LICENCE_EXPIRY_SCAN = Object.freeze({
  collectionName: 'softwareLicences',
  dateField: 'expiryDate',
  notificationKind: 'licence_expiring',
  eventType: 'licence.expiring',
  entityType: 'software_licence',
});

async function processWarrantyExpiryNotifications(options) {
  return processExpiryNotificationBatch({
    ...options,
    scan: WARRANTY_SCAN,
  });
}

async function processSoftwareLicenceRenewalNotifications(options) {
  return processExpiryNotificationBatch({
    ...options,
    scan: LICENCE_RENEWAL_SCAN,
  });
}

async function processSoftwareLicenceExpiryNotifications(options) {
  return processExpiryNotificationBatch({
    ...options,
    scan: LICENCE_EXPIRY_SCAN,
  });
}

async function processExpiryNotificationBatch({
  db,
  fieldValue,
  timestamp,
  scan,
  warningWindowDays = DEFAULT_WARNING_WINDOW_DAYS,
  batchSize = DEFAULT_EXPIRY_BATCH_SIZE,
  cursor = null,
  logger,
}) {
  requireDependency(db, 'db');
  requireDependency(fieldValue, 'fieldValue');
  requireDependency(timestamp, 'timestamp');
  const safeBatchSize = boundedBatchSize(batchSize);
  const safeWarningDays = boundedWarningWindow(warningWindowDays);
  const now = toDate(timestamp.now());
  if (!now) throw new TypeError('timestamp.now() must return a valid date.');
  const rangeStart = startOfUtcDay(now);
  const rangeEnd = endOfUtcDay(addUtcDays(rangeStart, safeWarningDays));
  const normalizedCursor = normalizeCursor(cursor, scan);
  const rangeStartValue = queryDateValue(rangeStart, timestamp);
  const rangeEndValue = queryDateValue(rangeEnd, timestamp);

  let query = db.collection(scan.collectionName);
  if (scan.activeQuery) {
    query = query.where(
      scan.activeQuery.field,
      '==',
      scan.activeQuery.value,
    );
  }
  query = query
    .where(scan.dateField, '>=', rangeStartValue)
    .where(scan.dateField, '<=', rangeEndValue)
    .orderBy(scan.dateField)
    .orderBy('__name__');
  if (normalizedCursor) {
    query = query.startAfter(
      queryDateValue(toDate(normalizedCursor.dateValue), timestamp),
      normalizedCursor.documentId,
    );
  }
  const snapshot = await query.limit(safeBatchSize).get();
  const documents = snapshot.docs || [];
  let eligibleCount = 0;
  let createdCount = 0;
  let duplicateCount = 0;

  for (const document of documents) {
    const record = document.data() || {};
    if (!isActiveRecord(record)) continue;
    const dueAt = toDate(record[scan.dateField]);
    if (!isInsideInclusiveWindow(dueAt, rangeStart, rangeEnd)) continue;
    eligibleCount += 1;
    const event = buildExpiryNotificationEvent({
      scan,
      recordId: document.id,
      record,
      dueAt,
      createdAt: fieldValue.serverTimestamp(),
    });
    const created = await createNotificationEventIfAbsent({ db, event });
    if (created) {
      createdCount += 1;
    } else {
      duplicateCount += 1;
    }
  }

  const nextCursor = documents.length === safeBatchSize
    ? cursorFromDocument(documents[documents.length - 1], scan)
    : null;
  const result = {
    notificationKind: scan.notificationKind,
    scannedCount: documents.length,
    eligibleCount,
    createdCount,
    duplicateCount,
    nextCursor,
  };
  logger?.info('ITSM asset expiry notification batch completed', result);
  return result;
}

function buildExpiryNotificationEvent({
  scan,
  recordId,
  record,
  dueAt,
  createdAt,
}) {
  const safeRecordId = normalizeString(recordId);
  const dateBucket = expiryDateBucket(dueAt);
  if (!safeRecordId || !dateBucket) {
    throw new TypeError('A record ID and valid due date are required.');
  }
  const id = deterministicExpiryEventId({
    recordId: safeRecordId,
    notificationKind: scan.notificationKind,
    dateBucket,
  });
  const presentation = expiryPresentation({
    scan,
    recordId: safeRecordId,
    record,
    dateBucket,
  });
  return {
    id,
    data: {
      eventType: scan.eventType,
      moduleKey: 'ticketing',
      title: presentation.title,
      body: presentation.body,
      entityType: scan.entityType,
      entityId: safeRecordId,
      route: presentation.route,
      deepLink: presentation.route,
      deduplicationId: id,
      target: {
        ...MANAGER_TARGET,
        roles: [...MANAGER_TARGET.roles],
      },
      sourceEventId: `scheduled:${scan.notificationKind}:${dateBucket}`,
      createdByUserId: 'system',
      createdByName: 'ITSM asset notification processor',
      createdByEmail: '',
      createdAt,
      status: 'PENDING',
    },
  };
}

function buildAssetAssignmentNotificationEvent({
  assetId,
  assetTag,
  assignedUserId,
  assignedUserEmail,
  assignmentId,
  actor,
  createdAt,
}) {
  const safeAssetId = requireNotificationIdentifier(assetId, 'assetId');
  const safeUserId = requireNotificationIdentifier(
    assignedUserId,
    'assignedUserId',
  );
  const safeAssignmentId = requireNotificationIdentifier(
    assignmentId,
    'assignmentId',
  );
  const id = deterministicOperationalEventId(
    'asset_assignment',
    safeAssetId,
    safeAssignmentId,
    safeUserId,
  );
  const route = '/services/itsm/assets-configuration/' +
    `assets/my/${encodeURIComponent(safeAssetId)}`;
  const label = safeDisplayName(assetTag, safeAssetId);
  return {
    id,
    data: {
      eventType: 'asset.assigned',
      moduleKey: 'ticketing',
      title: 'Asset assigned to you',
      body: `${label} was assigned to you.`,
      entityType: 'asset',
      entityId: safeAssetId,
      route,
      deepLink: route,
      deduplicationId: id,
      target: {
        type: 'USERS',
        userIds: [safeUserId],
        userEmails: normalizeEmailList([assignedUserEmail]),
      },
      sourceEventId: `asset.assignment:${safeAssignmentId}`,
      createdByUserId: normalizeString(actor && actor.uid) || 'system',
      createdByName: normalizeString(actor && actor.displayName),
      createdByEmail: normalizeString(actor && actor.email).toLowerCase(),
      createdAt,
      status: 'PENDING',
    },
  };
}

function buildLowStockNotificationEvent({
  stockItemId,
  stockItemName,
  sku,
  availableQuantity,
  minimumQuantity,
  episode,
  actor,
  createdAt,
}) {
  const safeStockItemId = requireNotificationIdentifier(
    stockItemId,
    'stockItemId',
  );
  const safeEpisode = Number(episode);
  if (!Number.isSafeInteger(safeEpisode) || safeEpisode < 1) {
    throw new TypeError('episode must be a positive integer.');
  }
  const id = deterministicOperationalEventId(
    'stock_low',
    safeStockItemId,
    String(safeEpisode),
  );
  const route = '/services/itsm/assets-configuration/' +
    `stock?stockItemId=${encodeURIComponent(safeStockItemId)}`;
  const label = safeDisplayName(stockItemName || sku, safeStockItemId);
  return {
    id,
    data: {
      eventType: 'stock.low',
      moduleKey: 'ticketing',
      title: 'Low stock alert',
      body: `${label} has ${Number(availableQuantity)} available ` +
        `(minimum ${Number(minimumQuantity)}).`,
      entityType: 'stock_item',
      entityId: safeStockItemId,
      route,
      deepLink: route,
      deduplicationId: id,
      target: {
        ...MANAGER_TARGET,
        roles: [...MANAGER_TARGET.roles],
      },
      sourceEventId: `stock.low:${safeStockItemId}:${safeEpisode}`,
      createdByUserId: normalizeString(actor && actor.uid) || 'system',
      createdByName: normalizeString(actor && actor.displayName),
      createdByEmail: normalizeString(actor && actor.email).toLowerCase(),
      createdAt,
      status: 'PENDING',
    },
  };
}

function deterministicOperationalEventId(...parts) {
  const source = parts.map(normalizeString).join('|');
  return `asset_event_${crypto.createHash('sha256').update(source).digest('hex')}`;
}

function requireNotificationIdentifier(value, field) {
  const normalized = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(normalized)) {
    throw new TypeError(`${field} must be a safe identifier.`);
  }
  return normalized;
}

function normalizeEmailList(values) {
  return [...new Set(values
    .map((value) => normalizeString(value).toLowerCase())
    .filter((value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)))];
}

function expiryPresentation({ scan, recordId, record, dateBucket }) {
  if (scan.notificationKind === 'warranty_expiring') {
    const name = safeDisplayName(
      record.name || record.warrantyNumber,
      'Warranty',
    );
    const route = '/services/itsm/assets-configuration/' +
      `suppliers-warranties?warrantyId=${encodeURIComponent(recordId)}`;
    return {
      title: 'Asset warranty expiring',
      body: `${name} expires on ${dateBucket}.`,
      route,
    };
  }
  const name = safeDisplayName(record.softwareProduct, 'Software licence');
  const route = '/services/itsm/assets-configuration/' +
    `licences?licenceId=${encodeURIComponent(recordId)}`;
  if (scan.notificationKind === 'licence_renewal_due') {
    return {
      title: 'Software licence renewal due',
      body: `${name} is due for renewal on ${dateBucket}.`,
      route,
    };
  }
  return {
    title: 'Software licence expiring',
    body: `${name} expires on ${dateBucket}.`,
    route,
  };
}

async function createNotificationEventIfAbsent({ db, event }) {
  const ref = db.collection('notificationEvents').doc(event.id);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (snapshot.exists) return false;
    transaction.create(ref, event.data);
    return true;
  });
}

function deterministicExpiryEventId({
  recordId,
  notificationKind,
  dateBucket,
}) {
  const source = [recordId, notificationKind, dateBucket]
    .map(normalizeString)
    .join('|');
  return `asset_expiry_${crypto.createHash('sha256')
    .update(source)
    .digest('hex')}`;
}

function cursorFromDocument(document, scan) {
  const record = document.data() || {};
  const dueAt = toDate(record[scan.dateField]);
  if (!dueAt) return null;
  return {
    notificationKind: scan.notificationKind,
    dateValue: dueAt.toISOString(),
    documentId: document.id,
  };
}

function normalizeCursor(cursor, scan) {
  if (!cursor) return null;
  if (cursor.notificationKind !== scan.notificationKind) {
    throw new TypeError('The cursor belongs to a different expiry scan.');
  }
  const date = toDate(cursor.dateValue);
  const documentId = normalizeString(cursor.documentId);
  if (!date || !documentId) throw new TypeError('The expiry cursor is invalid.');
  return {
    notificationKind: scan.notificationKind,
    dateValue: date.toISOString(),
    documentId,
  };
}

function isActiveRecord(record) {
  if (record.isActive === false) return false;
  const state = normalizeString(record.status).toLowerCase();
  return !['cancelled', 'expired', 'inactive', 'retired'].includes(state);
}

function isInsideInclusiveWindow(date, start, end) {
  return Boolean(date && date >= start && date <= end);
}

function expiryDateBucket(value) {
  const date = toDate(value);
  return date ? date.toISOString().slice(0, 10) : '';
}

function boundedBatchSize(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return DEFAULT_EXPIRY_BATCH_SIZE;
  return Math.min(MAX_EXPIRY_BATCH_SIZE, Math.max(1, Math.floor(number)));
}

function boundedWarningWindow(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return DEFAULT_WARNING_WINDOW_DAYS;
  return Math.min(365, Math.max(0, Math.floor(number)));
}

function startOfUtcDay(value) {
  return new Date(Date.UTC(
    value.getUTCFullYear(),
    value.getUTCMonth(),
    value.getUTCDate(),
  ));
}

function endOfUtcDay(value) {
  const result = addUtcDays(value, 1);
  result.setUTCMilliseconds(result.getUTCMilliseconds() - 1);
  return result;
}

function addUtcDays(value, days) {
  const result = new Date(value.getTime());
  result.setUTCDate(result.getUTCDate() + days);
  return result;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : new Date(value.getTime());
  }
  if (typeof value.toDate === 'function') return toDate(value.toDate());
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function queryDateValue(value, timestamp) {
  if (typeof timestamp.fromDate === 'function') {
    return timestamp.fromDate(value);
  }
  // Lightweight test adapters use ISO strings instead of Firestore Timestamp.
  return value.toISOString();
}

function safeDisplayName(value, fallback) {
  const text = normalizeString(value);
  return text ? text.slice(0, 240) : fallback;
}

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function requireDependency(value, name) {
  if (!value) throw new TypeError(`${name} is required.`);
}

module.exports = {
  DEFAULT_EXPIRY_BATCH_SIZE,
  DEFAULT_WARNING_WINDOW_DAYS,
  LICENCE_EXPIRY_SCAN,
  LICENCE_RENEWAL_SCAN,
  MAX_EXPIRY_BATCH_SIZE,
  WARRANTY_SCAN,
  buildAssetAssignmentNotificationEvent,
  buildExpiryNotificationEvent,
  buildLowStockNotificationEvent,
  createNotificationEventIfAbsent,
  deterministicExpiryEventId,
  expiryDateBucket,
  isActiveRecord,
  processExpiryNotificationBatch,
  processSoftwareLicenceExpiryNotifications,
  processSoftwareLicenceRenewalNotifications,
  processWarrantyExpiryNotifications,
};
