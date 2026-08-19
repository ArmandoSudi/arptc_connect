'use strict';

const { createHash } = require('node:crypto');
const { FieldPath } = require('firebase-admin/firestore');

const DEFAULT_PAGE_SIZE = 100;
const MAX_PAGE_SIZE = 100;
const DEFAULT_MAX_PAGES = 4;
const MAX_PAGES_PER_RUN = 25;
const DEFAULT_TRANSACTION_BATCH_SIZE = 20;
const MAX_TRANSACTION_BATCH_SIZE = 25;
const SYSTEM_ACTOR_UID = 'system:organization-acting-head-expiration';

class OrganizationMaintenanceError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'OrganizationMaintenanceError';
    this.code = code;
  }
}

function isExpiredActiveActingHead(assignmentValue, nowValue) {
  const assignment = objectOrEmpty(assignmentValue);
  const nowMilliseconds = timestampMilliseconds(nowValue);
  const endsAtMilliseconds = timestampMilliseconds(assignment.endsAt);
  return normalizeString(assignment.assignmentType).toUpperCase() === 'HEAD' &&
    assignment.isActing === true &&
    normalizeString(assignment.status).toUpperCase() === 'ACTIVE' &&
    Number.isFinite(nowMilliseconds) &&
    Number.isFinite(endsAtMilliseconds) &&
    endsAtMilliseconds <= nowMilliseconds;
}

function actingHeadExpirationAuditId(assignmentIdValue) {
  const assignmentId = requiredIdentifier(assignmentIdValue, 'assignment ID');
  const digest = createHash('sha256').update(assignmentId).digest('hex');
  return `acting_head_expired_${digest.substring(0, 48)}`;
}

function buildActingHeadExpirationMutation({
  assignmentId,
  assignment: assignmentValue,
  writeTimestamp,
  projectionCleared,
}) {
  const normalizedAssignmentId = requiredIdentifier(assignmentId, 'assignment ID');
  const assignment = objectOrEmpty(assignmentValue);
  const actorUid = SYSTEM_ACTOR_UID;
  return {
    assignmentUpdate: {
      status: 'ENDED',
      endedAt: writeTimestamp,
      endedBy: actorUid,
      updatedAt: writeTimestamp,
      updatedBy: actorUid,
    },
    unitProjectionUpdate: {
      actingHeadUserId: null,
      actingHeadAssignmentId: null,
      actingHeadEndsAt: null,
      updatedAt: writeTimestamp,
      updatedBy: actorUid,
    },
    auditEvent: {
      eventType: 'ORGANIZATION_UNIT_ACTING_HEAD_EXPIRED',
      actorUid,
      actorType: 'SYSTEM',
      organizationId: normalizeString(assignment.organizationId),
      unitId: normalizeString(assignment.unitId),
      agentId: normalizeString(assignment.agentId),
      assignmentId: normalizedAssignmentId,
      reason: 'Acting leadership period expired.',
      before: {
        status: normalizeString(assignment.status).toUpperCase(),
        isActing: assignment.isActing === true,
        endsAt: assignment.endsAt || null,
      },
      after: {
        status: 'ENDED',
        projectionCleared: projectionCleared === true,
      },
      maintenanceKey: `acting-head-expiration:${normalizedAssignmentId}`,
      createdAt: writeTimestamp,
      schemaVersion: 2,
    },
  };
}

async function fetchExpiredActingHeadAssignmentsPage({
  db,
  now,
  pageSize = DEFAULT_PAGE_SIZE,
  cursor = null,
  documentIdField = FieldPath.documentId(),
}) {
  const limit = normalizeBoundedInteger(
    pageSize,
    'page size',
    MAX_PAGE_SIZE,
  );
  const normalizedCursor = normalizeCursor(cursor);
  if (!Number.isFinite(timestampMilliseconds(now))) {
    throw invalid('A valid maintenance timestamp is required.');
  }

  let query = db.collection('organizationAssignments')
    .where('assignmentType', '==', 'HEAD')
    .where('isActing', '==', true)
    .where('status', '==', 'ACTIVE')
    .where('endsAt', '<=', now)
    .orderBy('endsAt', 'asc')
    .orderBy(documentIdField, 'asc');
  if (normalizedCursor) {
    query = query.startAfter(
      normalizedCursor.endsAt,
      normalizedCursor.assignmentId,
    );
  }
  const snapshot = await query.limit(limit).get();
  const documents = snapshot.docs || [];
  const nextCursor = documents.length > 0
    ? cursorFromDocument(documents.at(-1))
    : null;
  return {
    documents,
    nextCursor,
    // An exact final page may report one harmless continuation. The next bounded
    // query will be empty, without ever requiring an unbounded look-ahead read.
    hasMore: documents.length === limit,
  };
}

async function expireActingHeadAssignment({
  db,
  fieldValue,
  now,
  assignmentRef,
}) {
  if (!assignmentRef || !normalizeString(assignmentRef.id)) {
    throw invalid('An assignment document reference is required.');
  }
  if (!fieldValue || typeof fieldValue.serverTimestamp !== 'function') {
    throw invalid('A server timestamp provider is required.');
  }

  return db.runTransaction(async (transaction) => {
    const assignmentSnapshot = await transaction.get(assignmentRef);
    if (!assignmentSnapshot.exists) {
      return skippedResult(assignmentRef.id, 'MISSING');
    }
    const assignment = assignmentSnapshot.data() || {};
    if (!isExpiredActiveActingHead(assignment, now)) {
      return skippedResult(assignmentSnapshot.id, 'NO_LONGER_ELIGIBLE');
    }

    const assignmentId = assignmentSnapshot.id;
    const unitId = normalizeString(assignment.unitId);
    const unitRef = unitId
      ? db.collection('organizationUnits').doc(unitId)
      : null;
    const auditRef = db.collection('organizationAuditEvents')
      .doc(actingHeadExpirationAuditId(assignmentId));
    const [unitSnapshot, auditSnapshot] = await Promise.all([
      unitRef ? transaction.get(unitRef) : Promise.resolve(null),
      transaction.get(auditRef),
    ]);
    const projectionCleared = Boolean(
      unitSnapshot &&
      unitSnapshot.exists &&
      normalizeString(unitSnapshot.get('actingHeadAssignmentId')) === assignmentId,
    );
    const writeTimestamp = fieldValue.serverTimestamp();
    const mutation = buildActingHeadExpirationMutation({
      assignmentId,
      assignment,
      writeTimestamp,
      projectionCleared,
    });

    transaction.update(assignmentRef, mutation.assignmentUpdate);
    if (projectionCleared) {
      transaction.update(unitRef, mutation.unitProjectionUpdate);
    }
    if (!auditSnapshot.exists) {
      transaction.create(auditRef, mutation.auditEvent);
    }

    return {
      assignmentId,
      ended: true,
      projectionCleared,
      auditCreated: !auditSnapshot.exists,
      skippedReason: null,
    };
  });
}

async function runActingHeadExpirationMaintenance({
  db,
  fieldValue,
  now,
  pageSize = DEFAULT_PAGE_SIZE,
  maxPages = DEFAULT_MAX_PAGES,
  transactionBatchSize = DEFAULT_TRANSACTION_BATCH_SIZE,
  cursor = null,
  fetchPage = fetchExpiredActingHeadAssignmentsPage,
  expireAssignment = expireActingHeadAssignment,
  documentIdField = FieldPath.documentId(),
}) {
  const normalizedPageSize = normalizeBoundedInteger(
    pageSize,
    'page size',
    MAX_PAGE_SIZE,
  );
  const normalizedMaxPages = normalizeBoundedInteger(
    maxPages,
    'maximum page count',
    MAX_PAGES_PER_RUN,
  );
  const normalizedBatchSize = normalizeBoundedInteger(
    transactionBatchSize,
    'transaction batch size',
    MAX_TRANSACTION_BATCH_SIZE,
  );
  let currentCursor = normalizeCursor(cursor);
  const result = {
    pagesProcessed: 0,
    scannedCount: 0,
    endedCount: 0,
    skippedCount: 0,
    projectionClearedCount: 0,
    auditCreatedCount: 0,
    hasMore: false,
    nextCursor: null,
  };

  for (let pageIndex = 0; pageIndex < normalizedMaxPages; pageIndex += 1) {
    const page = await fetchPage({
      db,
      now,
      pageSize: normalizedPageSize,
      cursor: currentCursor,
      documentIdField,
    });
    const documents = Array.isArray(page && page.documents)
      ? page.documents
      : [];
    if (documents.length > normalizedPageSize) {
      throw invalid('The maintenance page exceeded its requested bound.');
    }
    result.pagesProcessed += 1;
    result.scannedCount += documents.length;

    for (const batch of chunk(documents, normalizedBatchSize)) {
      const outcomes = await Promise.all(batch.map((document) => expireAssignment({
        db,
        fieldValue,
        now,
        assignmentRef: document.ref,
      })));
      for (const outcome of outcomes) {
        if (outcome && outcome.ended === true) {
          result.endedCount += 1;
          if (outcome.projectionCleared === true) {
            result.projectionClearedCount += 1;
          }
          if (outcome.auditCreated === true) result.auditCreatedCount += 1;
        } else {
          result.skippedCount += 1;
        }
      }
    }

    if (!page || page.hasMore !== true) {
      result.nextCursor = null;
      return result;
    }
    const nextCursor = normalizeCursor(page.nextCursor);
    if (!nextCursor || sameCursor(currentCursor, nextCursor)) {
      throw new OrganizationMaintenanceError(
        'failed-precondition',
        'The acting-head maintenance cursor did not advance.',
      );
    }
    currentCursor = nextCursor;
    result.nextCursor = nextCursor;
  }

  result.hasMore = true;
  return result;
}

function cursorFromDocument(document) {
  if (!document || !normalizeString(document.id)) {
    throw invalid('A cursor document with an ID is required.');
  }
  const endsAt = typeof document.get === 'function'
    ? document.get('endsAt')
    : (document.data() || {}).endsAt;
  return normalizeCursor({ endsAt, assignmentId: document.id });
}

function normalizeCursor(value) {
  if (value === null || value === undefined) return null;
  const cursor = objectOrEmpty(value);
  const assignmentId = requiredIdentifier(cursor.assignmentId, 'cursor assignment ID');
  if (!Number.isFinite(timestampMilliseconds(cursor.endsAt))) {
    throw invalid('The maintenance cursor has an invalid end timestamp.');
  }
  return { endsAt: cursor.endsAt, assignmentId };
}

function normalizeBoundedInteger(value, label, maximum) {
  const normalized = Number(value);
  if (!Number.isInteger(normalized) || normalized < 1 || normalized > maximum) {
    throw invalid(`${label} must be between 1 and ${maximum}.`);
  }
  return normalized;
}

function timestampMilliseconds(value) {
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value && typeof value.toDate === 'function') return value.toDate().getTime();
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'number') return value;
  if (typeof value === 'string' && value.trim()) return new Date(value).getTime();
  return Number.NaN;
}

function chunk(values, size) {
  const batches = [];
  for (let index = 0; index < values.length; index += size) {
    batches.push(values.slice(index, index + size));
  }
  return batches;
}

function sameCursor(left, right) {
  if (!left || !right) return false;
  return left.assignmentId === right.assignmentId &&
    timestampMilliseconds(left.endsAt) === timestampMilliseconds(right.endsAt);
}

function skippedResult(assignmentId, skippedReason) {
  return {
    assignmentId: normalizeString(assignmentId),
    ended: false,
    projectionCleared: false,
    auditCreated: false,
    skippedReason,
  };
}

function requiredIdentifier(value, label) {
  const normalized = normalizeString(value);
  if (!normalized || normalized.includes('/')) {
    throw invalid(`A valid ${label} is required.`);
  }
  return normalized;
}

function objectOrEmpty(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function normalizeString(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

function invalid(message) {
  return new OrganizationMaintenanceError('invalid-argument', message);
}

module.exports = {
  DEFAULT_MAX_PAGES,
  DEFAULT_PAGE_SIZE,
  DEFAULT_TRANSACTION_BATCH_SIZE,
  MAX_PAGES_PER_RUN,
  MAX_PAGE_SIZE,
  MAX_TRANSACTION_BATCH_SIZE,
  OrganizationMaintenanceError,
  SYSTEM_ACTOR_UID,
  actingHeadExpirationAuditId,
  buildActingHeadExpirationMutation,
  cursorFromDocument,
  expireActingHeadAssignment,
  fetchExpiredActingHeadAssignmentsPage,
  isExpiredActiveActingHead,
  normalizeCursor,
  runActingHeadExpirationMaintenance,
};
