'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildCabMeetingNotificationEvent,
  buildChangeApprovalDecisionNotificationEvent,
  buildChangeApprovalRequestedNotificationEvent,
  buildChangeOwnerAssignedNotificationEvent,
  buildChangeStatusNotificationEvent,
  buildChangeSubmittedNotificationEvent,
  canonicalApprovalsRoute,
  canonicalCalendarRoute,
  canonicalChangeRoute,
} = require('../src/itsm_changes_notifications');

const actor = {
  uid: 'manager-1',
  displayName: 'Authoritative Manager',
  email: 'manager@arptc.cd',
};
const change = {
  changeNumber: 'CHG-20260801-ABC123',
  title: 'Network upgrade',
  changeType: 'normal',
  requesterId: 'user-1',
  requesterEmail: 'user@arptc.cd',
  ownerUserId: 'manager-2',
  ownerEmail: 'manager2@arptc.cd',
};

test('submitted changes notify the ticketing MANAGER role on a canonical route', () => {
  const event = buildChangeSubmittedNotificationEvent({
    change,
    changeId: 'change-1',
    actor,
    sourceId: 'receipt-1234',
    createdAt: 'server-time',
  });
  assert.equal(event.data.eventType, 'change.submitted');
  assert.equal(event.data.deepLink, '/services/itsm/changes/requests/change-1');
  assert.deepEqual(event.data.target, {
    type: 'MODULE_ROLE',
    moduleKey: 'ticketing',
    roles: ['MANAGER'],
  });
  assert.equal(event.data.createdByName, 'Authoritative Manager');
});

test('approval requests exclude the requester and target configured users only', () => {
  const event = buildChangeApprovalRequestedNotificationEvent({
    change,
    changeId: 'change-1',
    approvalId: 'approval-1',
    approverUserIds: ['user-1', 'manager-2', 'manager-2', 'manager-3'],
    actor,
    sourceId: 'receipt-1234',
    createdAt: 'server-time',
  });
  assert.deepEqual(event.data.target.userIds, ['manager-2', 'manager-3']);
  assert.equal(
    event.data.route,
    '/services/itsm/changes/approvals?changeId=change-1&approvalId=approval-1',
  );
});

test('decision events target requester and owner but not the acting manager', () => {
  const event = buildChangeApprovalDecisionNotificationEvent({
    change,
    changeId: 'change-1',
    approvalId: 'approval-1',
    decision: 'rejected',
    comment: 'Rollback evidence is incomplete.',
    actor: { ...actor, uid: 'manager-2' },
    sourceId: 'decision-1234',
    createdAt: 'server-time',
  });
  assert.deepEqual(event.data.target.userIds, ['user-1']);
  assert.deepEqual(event.data.target.userEmails, ['user@arptc.cd']);
  assert.match(event.data.body, /Rollback evidence is incomplete/);
  assert.equal(event.data.status, 'PENDING');
});

test('owner and CAB notifications use authoritative user targets', () => {
  const owner = buildChangeOwnerAssignedNotificationEvent({
    change,
    changeId: 'change-1',
    actor,
    sourceId: 'owner-1234',
    createdAt: 'server-time',
  });
  assert.deepEqual(owner.data.target.userIds, ['manager-2']);

  const cab = buildCabMeetingNotificationEvent({
    change,
    changeId: 'change-1',
    meetingId: 'meeting-1',
    participantUserIds: ['manager-1', 'manager-2', 'manager-3'],
    actor,
    sourceId: 'meeting-1234',
    createdAt: 'server-time',
  });
  assert.deepEqual(cab.data.target.userIds, ['manager-2', 'manager-3']);
});

test('status notifications deduplicate recipients and return null for actor-only changes', () => {
  const event = buildChangeStatusNotificationEvent({
    change: { ...change, ownerUserId: 'user-1' },
    changeId: 'change-1',
    status: 'scheduled',
    actor,
    sourceId: 'schedule-1234',
    createdAt: 'server-time',
  });
  assert.deepEqual(event.data.target.userIds, ['user-1']);
  assert.match(event.data.body, /scheduled/);

  assert.equal(buildChangeStatusNotificationEvent({
    change: { ...change, requesterId: 'manager-1', ownerUserId: 'manager-1' },
    changeId: 'change-1',
    status: 'closed',
    actor,
    sourceId: 'close-1234',
    createdAt: 'server-time',
  }), null);
});

test('notification IDs are deterministic and source-specific', () => {
  const options = {
    change,
    changeId: 'change-1',
    actor,
    sourceId: 'receipt-1234',
    createdAt: 'server-time',
  };
  const first = buildChangeSubmittedNotificationEvent(options);
  const replay = buildChangeSubmittedNotificationEvent({
    ...options,
    createdAt: 'later-server-time',
  });
  const next = buildChangeSubmittedNotificationEvent({
    ...options,
    sourceId: 'receipt-5678',
  });
  assert.equal(first.id, replay.id);
  assert.notEqual(first.id, next.id);
  assert.equal(first.id, first.data.deduplicationId);
});

test('canonical route helpers safely encode IDs', () => {
  assert.equal(
    canonicalChangeRoute('change:1'),
    '/services/itsm/changes/requests/change%3A1',
  );
  assert.equal(
    canonicalApprovalsRoute('change:1'),
    '/services/itsm/changes/approvals?changeId=change%3A1',
  );
  assert.equal(
    canonicalCalendarRoute('change:1'),
    '/services/itsm/changes/calendar?changeId=change%3A1',
  );
});
