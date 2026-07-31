'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const AUDIT_EXPORT_PAGE_SIZE = 200;
const AUDIT_EXPORT_TTL_HOURS = 24;

async function processAuditExport({
  db,
  bucket,
  fieldValue,
  timestamp,
  exportId,
  exportSnapshot,
  logger,
}) {
  const exportRef = db.collection('itsmAuditExports').doc(exportId);
  const data = snapshotData(exportSnapshot);
  if (!data || data.status !== 'queued') return { ignored: true };
  const requester = data.requester || {};
  if (![ITSM_ROLES.manager, ITSM_ROLES.admin].includes(requester.role)) {
    await exportRef.update({
      status: 'failed',
      errorCode: 'permission-denied',
      updatedAt: fieldValue.serverTimestamp(),
    });
    return { failed: true };
  }
  try {
    const events = await readAuthorizedAuditEvents({
      db,
      requester,
      filters: data.filters || {},
      maxRows: Number(data.maxRows || 1000),
    });
    const fileName = `itsm-audit-${exportId}.csv`;
    const storagePath =
      `itsm/reporting-exports/${requester.userId}/${exportId}/${fileName}`;
    const file = bucket.file(storagePath);
    await file.save(auditEventsToCsv(events), {
      resumable: false,
      contentType: 'text/csv; charset=utf-8',
      metadata: {
        cacheControl: 'private, max-age=0, no-store',
        metadata: {
          exportId,
          requesterUserId: requester.userId,
          confidentiality: 'internal',
        },
      },
    });
    const completedAt = timestamp.now();
    const expiresAt = fromDate(
      timestamp,
      new Date(toDate(completedAt).getTime() + AUDIT_EXPORT_TTL_HOURS * 3600000),
    );
    await exportRef.update({
      status: 'completed',
      rowCount: events.length,
      fileName,
      storagePath,
      contentType: 'text/csv',
      completedAt,
      expiresAt,
      updatedAt: fieldValue.serverTimestamp(),
    });
    return { completed: true, rowCount: events.length, storagePath };
  } catch (error) {
    logger?.error('ITSM audit export failed', {
      exportId,
      errorName: normalizeString(error && error.name).slice(0, 120),
      errorMessage: normalizeString(error && error.message).slice(0, 1000),
    });
    await exportRef.update({
      status: 'failed',
      errorCode: 'export-failed',
      updatedAt: fieldValue.serverTimestamp(),
    });
    throw error;
  }
}

async function readAuthorizedAuditEvents({ db, requester, filters, maxRows }) {
  const safeMaximum = Math.min(5000, Math.max(1, Number(maxRows) || 1000));
  const documents = new Map();
  for (const dateField of ['occurredAt', 'createdAt']) {
    const pageDocuments = await readAuditDocumentsByDateField({
      db,
      filters,
      dateField,
      maximum: safeMaximum,
    });
    for (const document of pageDocuments) documents.set(document.id, document);
  }
  return [...documents.values()]
    .map((document) => normalizeAuditEvent(document.id, document.data() || {}))
    .filter((event) =>
      canExportAuditEvent(event, requester) && matchesFilters(event, filters))
    .sort((left, right) => isoDate(left.occurredAt).localeCompare(
      isoDate(right.occurredAt),
    ) || left.id.localeCompare(right.id))
    .slice(0, safeMaximum);
}

async function readAuditDocumentsByDateField({
  db,
  filters,
  dateField,
  maximum,
}) {
  const query = db.collection('itsmAuditEvents')
    .where(dateField, '>=', filters.startAt)
    .where(dateField, '<=', filters.endAt)
    .orderBy(dateField)
    .orderBy('__name__');
  const documents = [];
  let cursor = null;
  while (documents.length < maximum) {
    const requestedSize = Math.min(
      AUDIT_EXPORT_PAGE_SIZE,
      maximum - documents.length,
    );
    let pageQuery = query.limit(requestedSize);
    if (cursor) pageQuery = pageQuery.startAfter(cursor);
    const page = await pageQuery.get();
    if (page.empty) break;
    documents.push(...page.docs);
    if (page.size < requestedSize) break;
    cursor = page.docs.at(-1);
  }
  return documents;
}

function canExportAuditEvent(event, requester) {
  if (![ITSM_ROLES.manager, ITSM_ROLES.admin].includes(requester.role)) return false;
  if (!event.isRestricted) return true;
  return requester.role === ITSM_ROLES.manager &&
    event.authorizedManagerIds.includes(requester.userId);
}

function normalizeAuditEvent(id, raw) {
  const actor = raw.actor && typeof raw.actor === 'object' ? raw.actor : {};
  const confidentiality = normalizedCode(raw.confidentiality, 'internal');
  return Object.freeze({
    id,
    eventType: normalizeString(raw.eventType),
    action: normalizeString(raw.action),
    module: normalizeString(raw.module || raw.moduleKey || 'ticketing'),
    entityType: normalizeString(raw.entityType || raw.targetEntityType || raw.workItemType),
    entityId: normalizeString(raw.entityId || raw.targetEntityId || raw.workItemId),
    entityReference: normalizeString(raw.entityReference || raw.reference),
    sourcePath: normalizeString(raw.sourcePath),
    actor: Object.freeze({
      userId: normalizeString(actor.userId || raw.actorUserId),
      displayName: normalizeString(actor.displayName || raw.actorName),
      email: normalizeString(actor.email || raw.actorEmail).toLowerCase(),
      role: normalizeString(actor.role || raw.actorRole).toUpperCase(),
      departmentId: normalizeString(actor.departmentId || raw.actorDepartmentId),
    }),
    before: safeObject(raw.before || raw.previousValues),
    after: safeObject(raw.after || raw.newValues),
    fromState: normalizeString(raw.fromState),
    toState: normalizeString(raw.toState),
    comment: normalizeString(raw.comment).slice(0, 2000),
    correlationId: normalizeString(raw.correlationId),
    sourceCommand: normalizeString(raw.sourceCommand),
    confidentiality,
    isRestricted: raw.isRestricted === true || confidentiality === 'restricted',
    authorizedManagerIds: Array.isArray(raw.authorizedManagerIds)
      ? raw.authorizedManagerIds.map(normalizeString).filter(Boolean)
      : [],
    occurredAt: raw.occurredAt || raw.createdAt || null,
  });
}

function matchesFilters(event, filters) {
  if (filters.module && normalizedCode(event.module) !== normalizedCode(filters.module)) {
    return false;
  }
  if (filters.entityType && normalizedCode(event.entityType) !==
      normalizedCode(filters.entityType)) return false;
  if (filters.entityId && event.entityId !== filters.entityId) return false;
  if (filters.entityReference && event.entityReference !== filters.entityReference) {
    return false;
  }
  if (filters.correlationId && event.correlationId !== filters.correlationId) {
    return false;
  }
  if (filters.action && normalizedCode(event.action) !== normalizedCode(filters.action)) {
    return false;
  }
  if (filters.actorUserId && event.actor.userId !== filters.actorUserId) return false;
  if (filters.confidentiality && event.confidentiality !== filters.confidentiality) {
    return false;
  }
  return true;
}

function auditEventsToCsv(events) {
  const columns = [
    'eventId', 'occurredAt', 'module', 'eventType', 'action', 'entityType',
    'entityId', 'entityReference', 'actorUserId', 'actorDisplayName',
    'actorEmail', 'actorRole', 'fromState', 'toState', 'comment',
    'confidentiality', 'correlationId', 'sourceCommand', 'before', 'after',
  ];
  const rows = events.map((event) => [
    event.id,
    isoDate(event.occurredAt),
    event.module,
    event.eventType,
    event.action,
    event.entityType,
    event.entityId,
    event.entityReference,
    event.actor.userId,
    event.actor.displayName,
    event.actor.email,
    event.actor.role,
    event.fromState,
    event.toState,
    event.comment,
    event.confidentiality,
    event.correlationId,
    event.sourceCommand,
    JSON.stringify(event.before),
    JSON.stringify(event.after),
  ]);
  return [columns, ...rows]
    .map((row) => row.map(csvCell).join(','))
    .join('\r\n') + '\r\n';
}

function csvCell(value) {
  let normalized = normalizeString(value);
  if (/^[=+\-@]/.test(normalized)) normalized = `'${normalized}`;
  return `"${normalized.replaceAll('"', '""')}"`;
}

function safeObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  return JSON.parse(JSON.stringify(value));
}

function snapshotData(snapshot) {
  if (!snapshot || snapshot.exists === false) return null;
  return typeof snapshot.data === 'function' ? snapshot.data() || {} : snapshot;
}

function isoDate(value) {
  const date = toDate(value);
  return date ? date.toISOString() : '';
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function fromDate(timestamp, date) {
  return typeof timestamp.fromDate === 'function' ? timestamp.fromDate(date) : date;
}

function normalizedCode(value, fallback = '') {
  return normalizeString(value).toLowerCase().replace(/[^a-z0-9]+/g, '_') || fallback;
}

function requireAuditExportRole(role) {
  if (![ITSM_ROLES.manager, ITSM_ROLES.admin].includes(role)) {
    throw new ItsmCommandError(
      'permission-denied',
      'Only ITSM MANAGER and ADMIN roles can export audit events.',
    );
  }
}

module.exports = {
  AUDIT_EXPORT_PAGE_SIZE,
  AUDIT_EXPORT_TTL_HOURS,
  auditEventsToCsv,
  canExportAuditEvent,
  matchesFilters,
  normalizeAuditEvent,
  processAuditExport,
  readAuditDocumentsByDateField,
  readAuthorizedAuditEvents,
  requireAuditExportRole,
};
