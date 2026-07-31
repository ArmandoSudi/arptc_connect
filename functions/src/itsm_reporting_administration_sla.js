'use strict';

const crypto = require('node:crypto');

const {
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');
const {
  SOURCE_COLLECTIONS,
  validateSlaPolicyDefinition,
} = require('./itsm_reporting_administration_validation');

const DEFAULT_SLA_BATCH_SIZE = 50;
const MAX_SLA_BATCH_SIZE = 100;
const MAX_CALENDAR_MINUTES = 2102400;
const DATE_TIME_FORMATTERS = new Map();
const TERMINAL_STATUSES = new Set([
  'closed', 'completed', 'cancelled', 'rejected', 'archived',
]);

function addBusinessMinutes(startValue, minutes, rawPolicy) {
  const policy = validateSlaPolicyDefinition(rawPolicy);
  const start = toDate(startValue);
  if (!start) throw invalid('A valid SLA start date is required.');
  if (!Number.isInteger(minutes) || minutes < 0) {
    throw invalid('Business minutes must be a non-negative integer.');
  }
  if (minutes === 0) return start;
  let cursor = new Date(start.getTime());
  let remaining = minutes;
  let guard = 0;
  while (remaining > 0 && guard < MAX_CALENDAR_MINUTES) {
    if (isBusinessMinute(cursor, policy)) remaining -= 1;
    cursor = new Date(cursor.getTime() + 60000);
    guard += 1;
  }
  if (remaining > 0) throw invalid('SLA target exceeds the supported calendar range.');
  return cursor;
}

function businessMinutesBetween(startValue, endValue, rawPolicy) {
  const policy = validateSlaPolicyDefinition(rawPolicy);
  const start = toDate(startValue);
  const end = toDate(endValue);
  if (!start || !end || end <= start) return 0;
  let cursor = new Date(start.getTime());
  let total = 0;
  let guard = 0;
  while (cursor < end && guard < MAX_CALENDAR_MINUTES) {
    if (isBusinessMinute(cursor, policy)) total += 1;
    cursor = new Date(cursor.getTime() + 60000);
    guard += 1;
  }
  if (cursor < end) throw invalid('SLA interval exceeds the supported calendar range.');
  return total;
}

function initializeSlaState({ policy: rawPolicy, startedAt: startValue }) {
  const policy = validateSlaPolicyDefinition(rawPolicy);
  const startedAt = toDate(startValue);
  if (!startedAt) throw invalid('A valid SLA start date is required.');
  const responseDueAt = addBusinessMinutes(
    startedAt,
    policy.responseTargetMinutes,
    policy,
  );
  const resolutionTarget = policy.fulfilmentTargetMinutes ||
    policy.resolutionTargetMinutes;
  const resolutionDueAt = addBusinessMinutes(startedAt, resolutionTarget, policy);
  return Object.freeze({
    startedAt,
    responseDueAt,
    responseWarningAt: addBusinessMinutes(
      startedAt,
      Math.max(1, Math.floor(policy.responseTargetMinutes * policy.warningThreshold)),
      policy,
    ),
    resolutionDueAt,
    resolutionWarningAt: addBusinessMinutes(
      startedAt,
      Math.max(1, Math.floor(resolutionTarget * policy.warningThreshold)),
      policy,
    ),
    pausedAt: null,
    accumulatedPausedBusinessMinutes: 0,
    status: 'on_track',
    nextCheckAt: addBusinessMinutes(
      startedAt,
      Math.max(1, Math.floor(policy.responseTargetMinutes * policy.warningThreshold)),
      policy,
    ),
  });
}

function evaluateSlaState({ workItem, policy: rawPolicy, now: nowValue }) {
  const policy = validateSlaPolicyDefinition(rawPolicy);
  const now = toDate(nowValue);
  if (!now) throw invalid('A valid SLA evaluation time is required.');
  const current = workItem.slaState && typeof workItem.slaState === 'object'
    ? workItem.slaState
    : initializeSlaState({
      policy,
      startedAt: workItem.slaStartedAt || workItem.createdAt || now,
    });
  const status = normalizeString(workItem.status).toLowerCase();
  const isPaused = policy.pauseStates.includes(status);
  let state = normalizeSlaState(current);
  const events = [];

  if (isPaused && !state.pausedAt) {
    state = { ...state, pausedAt: now, status: 'paused', nextCheckAt: null };
    events.push('sla.paused');
    return Object.freeze({ state: Object.freeze(state), events: Object.freeze(events) });
  }
  if (!isPaused && state.pausedAt) {
    const pausedMinutes = businessMinutesBetween(state.pausedAt, now, policy);
    state = {
      ...state,
      responseDueAt: state.respondedAt
        ? state.responseDueAt
        : addBusinessMinutes(state.responseDueAt, pausedMinutes, policy),
      responseWarningAt: state.respondedAt
        ? state.responseWarningAt
        : addBusinessMinutes(state.responseWarningAt, pausedMinutes, policy),
      resolutionDueAt: addBusinessMinutes(
        state.resolutionDueAt,
        pausedMinutes,
        policy,
      ),
      resolutionWarningAt: addBusinessMinutes(
        state.resolutionWarningAt,
        pausedMinutes,
        policy,
      ),
      pausedAt: null,
      accumulatedPausedBusinessMinutes:
        state.accumulatedPausedBusinessMinutes + pausedMinutes,
    };
    events.push('sla.resumed');
  }

  const respondedAt = toDate(
    workItem.respondedAt || workItem.firstResponseAt || state.respondedAt,
  );
  const resolvedAt = toDate(
    workItem.resolvedAt || workItem.closedAt || workItem.completedAt ||
      state.resolvedAt,
  );
  state = { ...state, respondedAt, resolvedAt };
  const response = milestoneStatus({
    now,
    completedAt: respondedAt,
    warningAt: state.responseWarningAt,
    dueAt: state.responseDueAt,
  });
  const resolution = milestoneStatus({
    now,
    completedAt: resolvedAt,
    warningAt: state.resolutionWarningAt,
    dueAt: state.resolutionDueAt,
  });
  const activeMilestone = respondedAt ? resolution : response;
  const previousStatus = normalizedCode(current.status, 'on_track');
  if (activeMilestone.status !== previousStatus) {
    events.push(`sla.${activeMilestone.status}`);
  }
  for (const target of policy.escalationTargets) {
    const elapsed = businessMinutesBetween(state.startedAt, now, policy);
    const resolutionTarget = policy.fulfilmentTargetMinutes ||
      policy.resolutionTargetMinutes;
    const progress = resolutionTarget === 0 ? 0 : elapsed / resolutionTarget * 100;
    const already = Array.isArray(current.emittedEscalationEvents)
      ? current.emittedEscalationEvents
      : [];
    if (progress >= target.atPercent && !already.includes(target.eventName)) {
      events.push(target.eventName);
    }
  }
  const emittedEscalationEvents = [...new Set([
    ...(current.emittedEscalationEvents || []),
    ...events.filter((event) => policy.escalationTargets.some(
      (target) => target.eventName === event,
    )),
  ])];
  return Object.freeze({
    state: Object.freeze({
      ...state,
      status: activeMilestone.status,
      responseStatus: response.status,
      resolutionStatus: resolution.status,
      nextCheckAt: activeMilestone.nextCheckAt,
      emittedEscalationEvents,
      lastEvaluatedAt: now,
    }),
    events: Object.freeze(events),
  });
}

async function processSlaTimers({
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
  const now = timestamp.now();
  const results = [];
  for (const collectionName of SOURCE_COLLECTIONS) {
    const snapshot = await db.collection(collectionName)
      .where('lifecycleState', '==', 'active')
      .where('slaNextCheckAt', '<=', now)
      .orderBy('slaNextCheckAt')
      .limit(safeBatchSize)
      .get();
    let changedCount = 0;
    for (const document of snapshot.docs) {
      const changed = await processSlaWorkItem({
        db,
        fieldValue,
        timestamp,
        collectionName,
        workItemId: document.id,
      });
      if (changed) changedCount += 1;
    }
    results.push({ collectionName, scannedCount: snapshot.size, changedCount });
  }
  logger?.info('ITSM generalized SLA processing completed', { results });
  return results;
}

async function processSlaWorkItemChange({
  db,
  fieldValue,
  timestamp,
  collectionName,
  workItemId,
  before,
  after,
}) {
  const afterData = snapshotData(after);
  if (!afterData || !normalizeString(afterData.slaPolicyId)) return false;
  const beforeData = snapshotData(before) || {};
  const now = toDate(timestamp.now()) || new Date();
  const nextCheckAt = toDate(afterData.slaNextCheckAt);
  const statusChanged = normalizedCode(beforeData.status) !==
    normalizedCode(afterData.status);
  const policyChanged = normalizeString(beforeData.slaPolicyId) !==
    normalizeString(afterData.slaPolicyId) ||
    normalizeString(beforeData.slaPolicyVersionDocumentId) !==
    normalizeString(afterData.slaPolicyVersionDocumentId);
  if (!statusChanged && !policyChanged && (!nextCheckAt || nextCheckAt > now)) {
    return false;
  }
  return processSlaWorkItem({
    db,
    fieldValue,
    timestamp,
    collectionName,
    workItemId,
  });
}

async function processSlaWorkItem({
  db,
  fieldValue,
  timestamp,
  collectionName,
  workItemId,
  policyId,
  actor = systemActor(),
}) {
  if (!SOURCE_COLLECTIONS.includes(collectionName)) {
    throw invalid(`Unsupported SLA source ${collectionName}.`);
  }
  const workItemRef = db.collection(collectionName).doc(workItemId);
  return db.runTransaction(async (transaction) => {
    const itemSnapshot = await transaction.get(workItemRef);
    if (!itemSnapshot.exists) throw notFound('The SLA work item does not exist.');
    const item = itemSnapshot.data() || {};
    if (TERMINAL_STATUSES.has(normalizedCode(item.status)) ||
        normalizedCode(item.lifecycleState) !== 'active') return false;
    const resolvedPolicyId = normalizeString(policyId || item.slaPolicyId);
    if (!resolvedPolicyId) throw precondition('The work item has no SLA policy.');
    const policyRef = db.collection('slaPolicies').doc(resolvedPolicyId);
    const policyParent = await transaction.get(policyRef);
    if (!policyParent.exists) throw precondition('The SLA policy does not exist.');
    const parent = policyParent.data() || {};
    const versionDocumentId = normalizeString(
      item.slaPolicyVersionDocumentId || parent.currentPublishedVersionDocumentId,
    );
    if (!versionDocumentId) throw precondition('The SLA policy has no published version.');
    const versionRef = policyRef.collection('versions').doc(versionDocumentId);
    const versionSnapshot = await transaction.get(versionRef);
    if (!versionSnapshot.exists) throw precondition('The pinned SLA version is missing.');
    const version = versionSnapshot.data() || {};
    if (version.status !== 'published') {
      throw precondition('The pinned SLA version is not published.');
    }
    const now = toDate(timestamp.now()) || new Date();
    const initial = item.slaState || initializeSlaState({
      policy: version.definition,
      startedAt: item.slaStartedAt || item.createdAt || now,
    });
    const evaluation = evaluateSlaState({
      workItem: { ...item, slaState: initial },
      policy: version.definition,
      now,
    });
    const patch = {
      slaPolicyId: resolvedPolicyId,
      slaPolicyVersion: version.version,
      slaPolicyVersionDocumentId: versionDocumentId,
      slaState: timestampsInState(evaluation.state, timestamp),
      slaStatus: evaluation.state.status,
      slaNextCheckAt: evaluation.state.nextCheckAt
        ? fromDate(timestamp, evaluation.state.nextCheckAt)
        : null,
      slaLastEvaluatedAt: fieldValue.serverTimestamp(),
      updatedAt: fieldValue.serverTimestamp(),
    };
    transaction.update(workItemRef, patch);
    transaction.set(db.collection('itsmWorkItemIndex').doc(
      `${workItemTypeFor(collectionName)}:${workItemId}`,
    ), {
      slaPolicyId: resolvedPolicyId,
      slaPolicyVersion: version.version,
      slaStatus: evaluation.state.status,
      slaNextCheckAt: patch.slaNextCheckAt,
      updatedAt: patch.updatedAt,
    }, { merge: true });
    writeSlaAudit({
      db,
      fieldValue,
      transaction,
      workItemRef,
      collectionName,
      workItemId,
      actor,
      before: { slaStatus: item.slaStatus || null },
      after: {
        slaStatus: patch.slaStatus,
        events: evaluation.events,
        pausedAt: evaluation.state.pausedAt &&
          evaluation.state.pausedAt.toISOString(),
        accumulatedPausedBusinessMinutes:
          evaluation.state.accumulatedPausedBusinessMinutes,
        nextCheckAt: evaluation.state.nextCheckAt &&
          evaluation.state.nextCheckAt.toISOString(),
      },
    });
    writeSlaNotifications({
      db,
      fieldValue,
      transaction,
      collectionName,
      workItemId,
      item,
      policy: version.definition,
      events: evaluation.events,
      cycleKey: `${versionDocumentId}:${evaluation.state.startedAt.toISOString()}`,
    });
    return evaluation.events.length > 0 || item.slaStatus !== patch.slaStatus;
  });
}

function writeSlaNotifications({
  db,
  fieldValue,
  transaction,
  collectionName,
  workItemId,
  item,
  policy,
  events,
  cycleKey,
}) {
  for (const eventName of events.filter((event) =>
    ['sla.at_risk', 'sla.breached', 'sla.met'].includes(event) ||
      policy.escalationTargets.some((target) => target.eventName === event))) {
    const target = policy.escalationTargets.find(
      (entry) => entry.eventName === eventName,
    );
    const id = deterministicId(
      'sla',
      collectionName,
      workItemId,
      cycleKey,
      eventName,
    );
    const route = routeFor(collectionName, workItemId);
    transaction.set(db.collection('notificationEvents').doc(id), {
      eventType: eventName,
      moduleKey: 'ticketing',
      title: `SLA ${eventName.split('.').at(-1).replaceAll('_', ' ')}`,
      body: `${referenceFor(item, workItemId)} requires attention.`,
      entityType: workItemTypeFor(collectionName),
      entityId: workItemId,
      route,
      deepLink: route,
      deduplicationId: id,
      target: target && target.userId
        ? { type: 'USERS', userIds: [target.userId], userEmails: [] }
        : {
          type: 'MODULE_ROLE',
          moduleKey: 'ticketing',
          roles: ['MANAGER'],
          ...(target && target.assignmentGroupId
            ? { assignmentGroupId: target.assignmentGroupId }
            : {}),
        },
      createdByUserId: 'system',
      createdByName: 'ITSM SLA processor',
      createdByEmail: '',
      createdAt: fieldValue.serverTimestamp(),
      status: 'PENDING',
    }, { merge: false });
  }
}

function writeSlaAudit({
  db,
  fieldValue,
  transaction,
  workItemRef,
  collectionName,
  workItemId,
  actor,
  before,
  after,
}) {
  const eventId = deterministicId(
    'sla-audit',
    collectionName,
    workItemId,
    JSON.stringify(after),
  );
  const createdAt = fieldValue.serverTimestamp();
  const event = canonicalAuditEvent({
    eventId,
    action: 'sla_evaluated',
    entityType: workItemTypeFor(collectionName),
    entityId: workItemId,
    sourcePath: workItemRef.path,
    actor,
    before,
    after,
    createdAt,
    sourceCommand: 'scheduled.sla.process',
  });
  transaction.create(workItemRef.collection('auditLogs').doc(eventId), event);
  transaction.create(db.collection('itsmAuditEvents').doc(eventId), event);
}

function canonicalAuditEvent({
  eventId,
  action,
  entityType,
  entityId,
  sourcePath,
  actor,
  before,
  after,
  createdAt,
  sourceCommand,
}) {
  return {
    schemaVersion: 1,
    eventType: `itsm.${entityType}.${action}`,
    action,
    module: 'ticketing',
    entityType,
    entityId,
    entityReference: entityId,
    sourcePath,
    actor: {
      userId: actor.uid,
      displayName: actor.displayName,
      email: actor.email,
      role: actor.role,
      departmentId: actor.departmentId || null,
    },
    actorUserId: actor.uid,
    before,
    after,
    correlationId: eventId,
    sourceCommand,
    sourceIdempotencyKey: eventId,
    confidentiality: 'internal',
    isRestricted: false,
    authorizedManagerIds: [],
    createdAt,
    occurredAt: createdAt,
  };
}

function isBusinessMinute(date, policy) {
  const local = localParts(date, policy.timeZone);
  if (policy.holidays.includes(local.dateKey)) return false;
  const windows = policy.weeklyWindows[String(local.weekday)] || [];
  return windows.some((window) => {
    const minute = local.hour * 60 + local.minute;
    return minute >= minutesOfDay(window.start) && minute < minutesOfDay(window.end);
  });
}

function localParts(date, timeZone) {
  let formatter = DATE_TIME_FORMATTERS.get(timeZone);
  if (!formatter) {
    formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      weekday: 'short',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    });
    DATE_TIME_FORMATTERS.set(timeZone, formatter);
  }
  const parts = formatter.formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  const weekdays = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };
  return {
    dateKey: `${values.year}-${values.month}-${values.day}`,
    weekday: weekdays[values.weekday],
    hour: Number(values.hour),
    minute: Number(values.minute),
  };
}

function milestoneStatus({ now, completedAt, warningAt, dueAt }) {
  if (completedAt) {
    return { status: completedAt <= dueAt ? 'met' : 'breached', nextCheckAt: null };
  }
  if (now >= dueAt) return { status: 'breached', nextCheckAt: null };
  if (now >= warningAt) return { status: 'at_risk', nextCheckAt: dueAt };
  return { status: 'on_track', nextCheckAt: warningAt };
}

function normalizeSlaState(value) {
  return {
    startedAt: requiredDate(value.startedAt, 'slaState.startedAt'),
    responseDueAt: requiredDate(value.responseDueAt, 'slaState.responseDueAt'),
    responseWarningAt: requiredDate(
      value.responseWarningAt,
      'slaState.responseWarningAt',
    ),
    resolutionDueAt: requiredDate(
      value.resolutionDueAt,
      'slaState.resolutionDueAt',
    ),
    resolutionWarningAt: requiredDate(
      value.resolutionWarningAt,
      'slaState.resolutionWarningAt',
    ),
    pausedAt: toDate(value.pausedAt),
    accumulatedPausedBusinessMinutes: Number(
      value.accumulatedPausedBusinessMinutes || 0,
    ),
    respondedAt: toDate(value.respondedAt),
    resolvedAt: toDate(value.resolvedAt),
    status: normalizedCode(value.status, 'on_track'),
    emittedEscalationEvents: Array.isArray(value.emittedEscalationEvents)
      ? value.emittedEscalationEvents.map(normalizeString).filter(Boolean)
      : [],
  };
}

function timestampsInState(state, timestamp) {
  return Object.fromEntries(Object.entries(state).map(([key, value]) => [
    key,
    value instanceof Date ? fromDate(timestamp, value) : value,
  ]));
}

function fromDate(timestamp, date) {
  return typeof timestamp.fromDate === 'function' ? timestamp.fromDate(date) : date;
}

function requiredDate(value, name) {
  const date = toDate(value);
  if (!date) throw invalid(`${name} is invalid.`);
  return date;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function snapshotData(snapshot) {
  if (!snapshot || snapshot.exists === false) return null;
  return typeof snapshot.data === 'function' ? snapshot.data() || {} : snapshot;
}

function minutesOfDay(value) {
  const [hours, minutes] = value.split(':').map(Number);
  return hours * 60 + minutes;
}

function normalizedCode(value, fallback = '') {
  return normalizeString(value).toLowerCase().replace(/[^a-z0-9]+/g, '_') || fallback;
}

function workItemTypeFor(collectionName) {
  return ({
    incidentTickets: 'incident',
    serviceRequests: 'service_request',
    changeRequests: 'change_request',
    securityFindings: 'security_finding',
    securityExceptions: 'security_exception',
    assetComplianceAssessments: 'asset_compliance_assessment',
    accessReviewItems: 'access_review_item',
  })[collectionName];
}

function routeFor(collectionName, id) {
  const encoded = encodeURIComponent(id);
  return ({
    incidentTickets: `/services/itsm/support/incidents/${encoded}`,
    serviceRequests: `/services/itsm/support/service-requests/${encoded}`,
    changeRequests: `/services/itsm/changes/${encoded}`,
    securityFindings: `/services/itsm/security-compliance/findings/${encoded}`,
    securityExceptions: `/services/itsm/security-compliance/exceptions/${encoded}`,
    assetComplianceAssessments:
      `/services/itsm/security-compliance/asset-compliance/${encoded}`,
    accessReviewItems: `/services/itsm/security-compliance/access-reviews/${encoded}`,
  })[collectionName];
}

function referenceFor(item, fallback) {
  return normalizeString(
    item.ticketNumber || item.requestNumber || item.changeNumber ||
      item.reference || item.title,
  ) || fallback;
}

function deterministicId(...parts) {
  return crypto.createHash('sha256').update(parts.join('\u0000')).digest('hex');
}

function systemActor() {
  return {
    uid: 'system',
    displayName: 'ITSM SLA processor',
    email: '',
    role: 'SYSTEM',
  };
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

function precondition(message) {
  return new ItsmCommandError('failed-precondition', message);
}

function notFound(message) {
  return new ItsmCommandError('not-found', message);
}

module.exports = {
  DEFAULT_SLA_BATCH_SIZE,
  MAX_CALENDAR_MINUTES,
  MAX_SLA_BATCH_SIZE,
  addBusinessMinutes,
  businessMinutesBetween,
  canonicalAuditEvent,
  evaluateSlaState,
  initializeSlaState,
  isBusinessMinute,
  processSlaTimers,
  processSlaWorkItem,
  processSlaWorkItemChange,
};
