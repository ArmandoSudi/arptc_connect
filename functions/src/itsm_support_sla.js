'use strict';

const { normalizeString } = require('./itsm_permissions');
const {
  buildSupportWorkItemIndex,
  deterministicId,
} = require('./itsm_support_triggers');

const DEFAULT_SLA_BATCH_SIZE = 100;
const MAX_SLA_BATCH_SIZE = 200;
const TERMINAL_STATES = new Set([
  'closed',
  'rejected',
  'cancelled',
  'archived',
]);

function evaluateServiceRequestSla(data, nowValue) {
  const now = toDate(nowValue);
  const status = normalizeString(data.status).toLowerCase();
  const lifecycle = normalizeString(data.lifecycleState).toLowerCase();
  if (!now || lifecycle !== 'active' || TERMINAL_STATES.has(status)) return null;
  const summary = data.slaSummary && typeof data.slaSummary === 'object'
    ? data.slaSummary
    : {};
  const dueAt = toDate(summary.fulfilmentDueAt || data.fulfilmentDueAt);
  if (!dueAt) return null;
  const warningAt = toDate(summary.warningAt || data.slaWarningAt) || dueAt;
  const nextStatus = now >= dueAt
    ? 'breached'
    : now >= warningAt
      ? 'at_risk'
      : 'on_track';
  return {
    status: nextStatus,
    dueAt,
    warningAt,
    nextCheckAt: nextStatus === 'on_track'
      ? warningAt
      : nextStatus === 'at_risk'
        ? dueAt
        : null,
  };
}

async function processServiceRequestSlaBatch({
  db,
  fieldValue,
  timestamp,
  logger,
  batchSize = DEFAULT_SLA_BATCH_SIZE,
}) {
  const safeBatchSize = Math.min(
    MAX_SLA_BATCH_SIZE,
    Math.max(1, Number(batchSize) || DEFAULT_SLA_BATCH_SIZE),
  );
  const nowTimestamp = timestamp.now();
  const snapshot = await db
    .collection('serviceRequests')
    .where('lifecycleState', '==', 'active')
    .where('slaNextCheckAt', '<=', nowTimestamp)
    .orderBy('slaNextCheckAt')
    .limit(safeBatchSize)
    .get();
  let changedCount = 0;
  for (const document of snapshot.docs) {
    const changed = await processServiceRequestSlaDocument({
      db,
      fieldValue,
      nowTimestamp,
      requestRef: document.ref,
    });
    if (changed) changedCount += 1;
  }
  logger?.info('ITSM service-request SLA batch completed', {
    scannedCount: snapshot.size,
    changedCount,
    batchSize: safeBatchSize,
  });
  return { scannedCount: snapshot.size, changedCount };
}

async function processServiceRequestSlaDocument({
  db,
  fieldValue,
  nowTimestamp,
  requestRef,
}) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(requestRef);
    if (!snapshot.exists) return false;
    const request = snapshot.data() || {};
    const evaluation = evaluateServiceRequestSla(request, nowTimestamp);
    if (!evaluation) return false;
    const currentStatus = normalizeString(
      request.slaStatus ||
        (request.slaSummary && request.slaSummary.status),
    ).toLowerCase();
    const timestampValue = fieldValue.serverTimestamp();
    const nextSummary = {
      ...(request.slaSummary || {}),
      status: evaluation.status,
      warningAt: request.slaSummary && request.slaSummary.warningAt ||
        evaluation.warningAt,
      fulfilmentDueAt: request.slaSummary &&
        request.slaSummary.fulfilmentDueAt || evaluation.dueAt,
      lastEvaluatedAt: timestampValue,
    };
    const patch = {
      slaStatus: evaluation.status,
      slaSummary: nextSummary,
      slaNextCheckAt: evaluation.nextCheckAt,
      slaLastEvaluatedAt: timestampValue,
      updatedAt: timestampValue,
    };
    transaction.update(requestRef, patch);
    transaction.set(
      db.collection('itsmWorkItemIndex').doc(
        `service_request:${requestRef.id}`,
      ),
      buildSupportWorkItemIndex({
        collectionName: 'serviceRequests',
        workItemId: requestRef.id,
        data: { ...request, ...patch },
      }),
      { merge: false },
    );
    if (evaluation.status !== currentStatus &&
        ['at_risk', 'breached'].includes(evaluation.status)) {
      writeSlaNotificationEvents({
        db,
        transaction,
        requestRef,
        request,
        evaluation,
        createdAt: timestampValue,
      });
    }
    return evaluation.status !== currentStatus;
  });
}

async function processServiceRequestSlaChange({
  db,
  fieldValue,
  timestamp,
  after,
}) {
  if (!after || after.exists === false) return false;
  const data = after.data() || {};
  const nextCheckAt = toDate(data.slaNextCheckAt);
  const nowTimestamp = timestamp.now();
  const now = toDate(nowTimestamp);
  if (!nextCheckAt || !now || nextCheckAt > now) return false;
  return processServiceRequestSlaDocument({
    db,
    fieldValue,
    nowTimestamp,
    requestRef: after.ref,
  });
}

function writeSlaNotificationEvents({
  db,
  transaction,
  requestRef,
  request,
  evaluation,
  createdAt,
}) {
  const eventType = evaluation.status === 'breached'
    ? 'sla.breached'
    : 'sla.at_risk';
  const reference = normalizeString(request.requestNumber || request.reference) ||
    requestRef.id;
  const operationalRoute =
    `/services/itsm/support/service-requests/${encodeURIComponent(requestRef.id)}`;
  const requesterRoute =
    `/services/itsm/support/my-requests/${encodeURIComponent(requestRef.id)}`;
  const common = {
    eventType,
    moduleKey: 'ticketing',
    title: evaluation.status === 'breached'
      ? 'Service request SLA breached'
      : 'Service request SLA at risk',
    body: `${reference} is ${evaluation.status.replace('_', ' ')}.`,
    entityType: 'service_request',
    entityId: requestRef.id,
    createdByUserId: 'system',
    createdByName: 'ITSM SLA processor',
    createdByEmail: '',
    createdAt,
    status: 'PENDING',
  };
  const managerId = deterministicId(
    'sla',
    requestRef.id,
    evaluation.status,
    'manager',
  );
  transaction.set(db.collection('notificationEvents').doc(managerId), {
    ...common,
    route: operationalRoute,
    deepLink: operationalRoute,
    deduplicationId: managerId,
    target: {
      type: 'MODULE_ROLE',
      moduleKey: 'ticketing',
      roles: ['MANAGER'],
    },
  }, { merge: false });

  const requesterIds = [...new Set([
    request.requestedForUserId,
    request.affectedUserId,
    request.requesterId,
  ].map(normalizeString).filter(Boolean))];
  const requesterEmails = [...new Set([
    request.requestedForEmail,
    request.affectedUserEmail,
    request.requesterEmail,
  ].map((value) => normalizeString(value).toLowerCase()).filter(Boolean))];
  if (requesterIds.length === 0 && requesterEmails.length === 0) return;
  const requesterId = deterministicId(
    'sla',
    requestRef.id,
    evaluation.status,
    'requester',
  );
  transaction.set(db.collection('notificationEvents').doc(requesterId), {
    ...common,
    route: requesterRoute,
    deepLink: requesterRoute,
    deduplicationId: requesterId,
    target: {
      type: 'USERS',
      userIds: requesterIds,
      userEmails: requesterEmails,
    },
  }, { merge: false });
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

module.exports = {
  DEFAULT_SLA_BATCH_SIZE,
  MAX_SLA_BATCH_SIZE,
  evaluateServiceRequestSla,
  processServiceRequestSlaBatch,
  processServiceRequestSlaChange,
  processServiceRequestSlaDocument,
};
