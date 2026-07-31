'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildOwnDeviceComplianceProjection,
  buildSecurityWorkItemIndex,
  complianceResult,
  safeComplianceStatus,
} = require('../src/itsm_security_compliance_projections');
const {
  buildSecurityNotification,
  canonicalRoute,
} = require('../src/itsm_security_compliance_notifications');

test('compliance result and safe status never expose control details', () => {
  assert.equal(complianceResult([]), 'assessment_pending');
  assert.equal(complianceResult([{ result: 'unknown' }]), 'assessment_pending');
  assert.equal(complianceResult([{ result: 'non_compliant' }]), 'non_compliant');
  assert.equal(complianceResult([{ result: 'compliant' }]), 'compliant');
  assert.equal(safeComplianceStatus('non_compliant'), 'action_required');

  const projection = buildOwnDeviceComplianceProjection({
    assetId: 'asset-1',
    assetTag: 'A-1',
    assetName: 'Laptop',
    assignedUserId: 'user-1',
    result: 'non_compliant',
    assessedAt: 'server-time',
    checks: [{ secret: 'must-not-leak' }],
    evidenceIds: ['secret-evidence'],
  }, 'server-time');
  assert.deepEqual(Object.keys(projection.data).sort(), [
    'assessedAt', 'assetId', 'assetName', 'assetTag', 'assignedUserId',
    'status', 'updatedAt',
  ]);
  assert.equal(projection.data.status, 'action_required');
});

test('unassigned assets do not create self-service projections', () => {
  assert.equal(buildOwnDeviceComplianceProjection({
    assetId: 'asset-1',
    result: 'compliant',
  }, 'now'), null);
});

test('security work-item projection restricts findings from self service', () => {
  const finding = buildSecurityWorkItemIndex({
    type: 'security_finding',
    id: 'finding-1',
    document: { status: 'detected', confidentiality: 'restricted' },
    route: '/finding/1',
  });
  assert.equal(finding.data.selfServiceVisible, false);
  assert.equal(finding.data.confidentiality, 'restricted');
});

test('notification IDs are deterministic and actor is removed from recipients', () => {
  const input = {
    eventType: 'security.exception.approved',
    entityType: 'security_exception',
    entityId: 'exception-1',
    sourceId: 'receipt-1',
    actor: { uid: 'manager-1' },
    title: 'Approved',
    body: 'Approved.',
    route: canonicalRoute('security_exception', 'exception-1'),
    recipientUserIds: ['manager-1', 'user-1', 'user-1'],
    createdAt: 'server-time',
  };
  const first = buildSecurityNotification(input);
  const second = buildSecurityNotification(input);
  assert.equal(first.id, second.id);
  assert.deepEqual(first.data.target.userIds, ['user-1']);
  assert.equal(first.data.status, 'pending');
});
