'use strict';

const {
  deterministicId,
} = require('./itsm_security_compliance_projections');
const { normalizeString } = require('./itsm_permissions');

const MANAGER_TARGET = Object.freeze({
  type: 'MODULE_ROLE',
  moduleKey: 'ticketing',
  roles: Object.freeze(['MANAGER']),
});

function buildSecurityNotification({
  eventType,
  entityType,
  entityId,
  sourceId,
  actor,
  title,
  body,
  route,
  recipientUserIds = [],
  createdAt,
}) {
  const recipients = [...new Set(recipientUserIds
    .map(normalizeString)
    .filter((uid) => uid && uid !== normalizeString(actor && actor.uid)))];
  const target = recipients.length > 0
    ? { type: 'USERS', userIds: recipients, emails: [] }
    : MANAGER_TARGET;
  const recipientKey = recipients.length > 0
    ? recipients.sort().join(',')
    : 'ticketing:MANAGER';
  return {
    id: deterministicId('security_notification', eventType, entityId, sourceId, recipientKey),
    data: {
      eventType,
      moduleKey: 'ticketing',
      title,
      body,
      entityType,
      entityId,
      route,
      deepLink: route,
      target,
      actorUserId: normalizeString(actor && actor.uid),
      sourceId,
      deduplicationId: deterministicId('security_event', eventType, entityId, sourceId),
      status: 'pending',
      deliveryAttempts: 0,
      createdAt,
    },
  };
}

function notificationForAction({ action, entityType, entityId, document, actor, sourceId, createdAt }) {
  const route = canonicalRoute(entityType, entityId);
  const requesterId = normalizeString(document.requesterId);
  const ownerId = normalizeString(document.ownerUserId);
  const subjectId = normalizeString(document.subjectUserId);
  const recipients = [requesterId, ownerId, subjectId].filter(Boolean);
  const labels = {
    submitted: ['Security review required', `${reference(document, entityId)} requires review.`],
    assigned: ['Security work assigned', `${reference(document, entityId)} was assigned to you.`],
    approved: ['Security request approved', `${reference(document, entityId)} was approved.`],
    rejected: ['Security request rejected', `${reference(document, entityId)} was rejected.`],
    validation_requested: ['Validation required', `${reference(document, entityId)} requires validation.`],
    validation_failed: ['Validation failed', `${reference(document, entityId)} requires further remediation.`],
    closed: ['Security work closed', `${reference(document, entityId)} was closed.`],
    correction_requested: ['Access correction requested', `${reference(document, entityId)} requires review.`],
    revocation_assigned: ['Access revocation assigned', `${reference(document, entityId)} requires action.`],
  };
  const [title, body] = labels[action] || ['Security update', `${reference(document, entityId)} was updated.`];
  const managerBroadcast = ['submitted', 'validation_requested', 'correction_requested'].includes(action);
  return buildSecurityNotification({
    eventType: `security.${entityType}.${action}`,
    entityType,
    entityId,
    sourceId,
    actor,
    title,
    body,
    route,
    recipientUserIds: managerBroadcast ? [] : recipients,
    createdAt,
  });
}

function canonicalRoute(type, id) {
  const segment = {
    security_finding: 'findings',
    security_exception: 'exceptions',
    access_review_item: 'access-reviews/items',
    compliance_assessment: 'compliance',
  }[type] || 'security-compliance';
  return `/services/itsm/security-compliance/${segment}/${encodeURIComponent(id)}`;
}

function reference(document, fallback) {
  return normalizeString(document.reference) || fallback;
}

module.exports = {
  buildSecurityNotification,
  canonicalRoute,
  notificationForAction,
};
