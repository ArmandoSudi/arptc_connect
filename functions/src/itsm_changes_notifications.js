'use strict';

const crypto = require('node:crypto');

const MANAGER_TARGET = Object.freeze({
  type: 'MODULE_ROLE',
  moduleKey: 'ticketing',
  roles: Object.freeze(['MANAGER']),
});

function buildChangeSubmittedNotificationEvent({
  change,
  changeId,
  actor,
  sourceId,
  createdAt,
}) {
  return buildEvent({
    eventKind: 'submitted',
    eventType: 'change.submitted',
    change,
    changeId,
    actor,
    sourceId,
    createdAt,
    title: 'New change request',
    body: `${changeLabel(change, changeId)} requires assessment.`,
    route: canonicalChangeRoute(changeId),
    target: managerTarget(),
  });
}

function buildChangeOwnerAssignedNotificationEvent({
  change,
  changeId,
  actor,
  sourceId,
  createdAt,
}) {
  const ownerUserId = requireIdentifier(change.ownerUserId, 'ownerUserId');
  if (ownerUserId === normalizeString(actor && actor.uid)) return null;
  return buildEvent({
    eventKind: `owner_assigned:${ownerUserId}`,
    eventType: 'change.owner_assigned',
    change,
    changeId,
    actor,
    sourceId,
    createdAt,
    title: 'Change assigned to you',
    body: `${changeLabel(change, changeId)} was assigned to you.`,
    route: canonicalChangeRoute(changeId),
    target: userTarget([ownerUserId], [change.ownerEmail]),
  });
}

function buildChangeApprovalRequestedNotificationEvent({
  change,
  changeId,
  approvalId,
  approverUserIds,
  actor,
  sourceId,
  createdAt,
}) {
  const safeApprovalId = requireIdentifier(approvalId, 'approvalId');
  const recipients = normalizeIdentifierList(approverUserIds)
    .filter((userId) => userId !== normalizeString(change.requesterId));
  if (recipients.length === 0) {
    throw new TypeError('At least one independent approver is required.');
  }
  return buildEvent({
    eventKind: `approval_requested:${safeApprovalId}`,
    eventType: 'change.approval_requested',
    change,
    changeId,
    actor,
    sourceId,
    createdAt,
    title: change.changeType === 'emergency'
      ? 'Emergency change approval required'
      : 'Change approval required',
    body: `${changeLabel(change, changeId)} is awaiting your decision.`,
    route: canonicalApprovalsRoute(changeId, safeApprovalId),
    target: userTarget(recipients, []),
  });
}

function buildChangeApprovalDecisionNotificationEvent({
  change,
  changeId,
  approvalId,
  decision,
  comment,
  actor,
  sourceId,
  createdAt,
}) {
  const normalizedDecision = normalizeString(decision).toLowerCase();
  if (!['approved', 'rejected', 'clarification_requested'].includes(
    normalizedDecision,
  )) {
    throw new TypeError('The approval decision is invalid.');
  }
  const recipients = recipientPairs(change, actor);
  if (recipients.length === 0) return null;
  const safeComment = normalizeString(comment).slice(0, 240);
  const suffix = safeComment ? `: ${safeComment}` : '.';
  return buildEvent({
    eventKind: `approval_decision:${approvalId}:${normalizedDecision}`,
    eventType: 'change.approval_decided',
    change,
    changeId,
    actor,
    sourceId,
    createdAt,
    title: 'Change approval updated',
    body: `${changeLabel(change, changeId)} was ${displayDecision(normalizedDecision)}` +
      suffix,
    route: canonicalChangeRoute(changeId),
    target: userTarget(
      recipients.map((recipient) => recipient.userId),
      recipients.map((recipient) => recipient.email),
    ),
  });
}

function buildChangeStatusNotificationEvent({
  change,
  changeId,
  status,
  actor,
  sourceId,
  createdAt,
  route,
}) {
  const normalizedStatus = requireIdentifier(status, 'status').toLowerCase();
  const recipients = recipientPairs(change, actor);
  if (recipients.length === 0) return null;
  return buildEvent({
    eventKind: `status:${normalizedStatus}`,
    eventType: 'change.status_changed',
    change,
    changeId,
    actor,
    sourceId,
    createdAt,
    title: 'Change request updated',
    body: `${changeLabel(change, changeId)} is now ${humanize(normalizedStatus)}.`,
    route: route || canonicalChangeRoute(changeId),
    target: userTarget(
      recipients.map((recipient) => recipient.userId),
      recipients.map((recipient) => recipient.email),
    ),
  });
}

function buildCabMeetingNotificationEvent({
  change,
  changeId,
  meetingId,
  participantUserIds,
  actor,
  sourceId,
  createdAt,
}) {
  const safeMeetingId = requireIdentifier(meetingId, 'meetingId');
  const recipients = normalizeIdentifierList(participantUserIds)
    .filter((userId) => userId !== normalizeString(actor && actor.uid));
  if (recipients.length === 0) return null;
  return buildEvent({
    eventKind: `cab_meeting:${safeMeetingId}`,
    eventType: 'change.cab_meeting_scheduled',
    change,
    changeId,
    actor,
    sourceId,
    createdAt,
    title: 'CAB meeting scheduled',
    body: `${changeLabel(change, changeId)} was added to a CAB agenda.`,
    route: canonicalApprovalsRoute(changeId),
    target: userTarget(recipients, []),
  });
}

function buildEvent({
  eventKind,
  eventType,
  change,
  changeId,
  actor,
  sourceId,
  createdAt,
  title,
  body,
  route,
  target,
}) {
  const safeChangeId = requireIdentifier(changeId, 'changeId');
  const safeSourceId = requireIdentifier(sourceId, 'sourceId');
  const recipientKey = target.type === 'USERS'
    ? normalizeIdentifierList(target.userIds).join(',')
    : 'ticketing:MANAGER';
  const id = deterministicChangeNotificationId({
    eventKind,
    changeId: safeChangeId,
    sourceId: safeSourceId,
    recipientKey,
  });
  return {
    id,
    data: {
      eventType,
      moduleKey: 'ticketing',
      title,
      body,
      entityType: 'change_request',
      entityId: safeChangeId,
      route,
      deepLink: route,
      deduplicationId: id,
      target,
      sourceEventId: `change:${safeSourceId}:${eventKind}`,
      createdByUserId: normalizeString(actor && actor.uid) || 'system',
      createdByName: normalizeString(actor && actor.displayName),
      createdByEmail: normalizeString(actor && actor.email).toLowerCase(),
      createdAt,
      status: 'PENDING',
      changeType: normalizeString(change && change.changeType).toLowerCase(),
      changeReference: normalizeString(change && change.changeNumber),
    },
  };
}

function deterministicChangeNotificationId({
  eventKind,
  changeId,
  sourceId,
  recipientKey = '',
}) {
  const source = [eventKind, changeId, sourceId, recipientKey]
    .map(normalizeString)
    .join('|');
  return `change_event_${crypto.createHash('sha256').update(source).digest('hex')}`;
}

function canonicalChangeRoute(changeId) {
  return `/services/itsm/changes/requests/${encodeURIComponent(
    requireIdentifier(changeId, 'changeId'),
  )}`;
}

function canonicalApprovalsRoute(changeId, approvalId = '') {
  const parameters = new URLSearchParams({ changeId: requireIdentifier(changeId, 'changeId') });
  if (approvalId) parameters.set('approvalId', requireIdentifier(approvalId, 'approvalId'));
  return `/services/itsm/changes/approvals?${parameters.toString()}`;
}

function canonicalCalendarRoute(changeId) {
  return '/services/itsm/changes/calendar?' +
    new URLSearchParams({ changeId: requireIdentifier(changeId, 'changeId') });
}

function managerTarget() {
  return { ...MANAGER_TARGET, roles: [...MANAGER_TARGET.roles] };
}

function userTarget(userIds, userEmails) {
  return {
    type: 'USERS',
    userIds: normalizeIdentifierList(userIds),
    userEmails: normalizeEmailList(userEmails),
  };
}

function recipientPairs(change, actor) {
  const actorUid = normalizeString(actor && actor.uid);
  const pairs = [
    {
      userId: normalizeString(change && change.requesterId),
      email: normalizeString(change && change.requesterEmail).toLowerCase(),
    },
    {
      userId: normalizeString(change && change.ownerUserId),
      email: normalizeString(change && change.ownerEmail).toLowerCase(),
    },
  ].filter((pair) => pair.userId && pair.userId !== actorUid);
  return [...new Map(pairs.map((pair) => [pair.userId, pair])).values()];
}

function normalizeIdentifierList(values) {
  return [...new Set((Array.isArray(values) ? values : [])
    .map(normalizeString)
    .filter((value) => /^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(value)))];
}

function normalizeEmailList(values) {
  return [...new Set((Array.isArray(values) ? values : [])
    .map((value) => normalizeString(value).toLowerCase())
    .filter((value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)))];
}

function requireIdentifier(value, field) {
  const normalized = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(normalized)) {
    throw new TypeError(`${field} must be a safe identifier.`);
  }
  return normalized;
}

function changeLabel(change, fallback) {
  return normalizeString(change && (change.changeNumber || change.title)).slice(0, 240) ||
    fallback;
}

function displayDecision(value) {
  return value === 'clarification_requested'
    ? 'returned for clarification'
    : value;
}

function humanize(value) {
  return value.replaceAll('_', ' ');
}

function normalizeString(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

module.exports = {
  buildCabMeetingNotificationEvent,
  buildChangeApprovalDecisionNotificationEvent,
  buildChangeApprovalRequestedNotificationEvent,
  buildChangeOwnerAssignedNotificationEvent,
  buildChangeStatusNotificationEvent,
  buildChangeSubmittedNotificationEvent,
  canonicalApprovalsRoute,
  canonicalCalendarRoute,
  canonicalChangeRoute,
  deterministicChangeNotificationId,
};
