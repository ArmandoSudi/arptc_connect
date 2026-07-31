'use strict';

const crypto = require('node:crypto');
const { normalizeString } = require('./itsm_permissions');

function complianceResult(checks) {
  if (!Array.isArray(checks) || checks.length === 0 ||
      checks.some((check) => check.result === 'unknown')) {
    return 'assessment_pending';
  }
  if (checks.some((check) => check.result === 'non_compliant')) {
    return 'non_compliant';
  }
  return checks.every((check) => check.result === 'not_applicable')
    ? 'assessment_pending'
    : 'compliant';
}

function safeComplianceStatus(result) {
  return result === 'compliant'
    ? 'compliant'
    : result === 'non_compliant'
      ? 'action_required'
      : 'assessment_pending';
}

function buildOwnDeviceComplianceProjection(assessment, updatedAt) {
  const assignedUserId = normalizeString(assessment.assignedUserId);
  if (!assignedUserId) return null;
  return {
    id: deterministicId('own_compliance', assessment.assetId, assignedUserId),
    data: {
      assetId: normalizeString(assessment.assetId),
      assetTag: normalizeString(assessment.assetTag),
      assetName: normalizeString(assessment.assetName),
      assignedUserId,
      status: safeComplianceStatus(assessment.result),
      assessedAt: assessment.assessedAt,
      updatedAt,
    },
  };
}

function buildSecurityWorkItemIndex({ type, id, document, route }) {
  return {
    id: `${type}:${id}`,
    data: {
      id,
      type,
      reference: normalizeString(document.reference),
      title: normalizeString(document.title),
      requesterId: normalizeString(
        document.requesterId || document.createdByUserId,
      ),
      assignedUserId: normalizeString(
        document.ownerUserId || document.assignedUserId,
      ),
      status: normalizeString(document.status),
      lifecycleState: lifecycleState(document.status),
      priority: normalizeString(document.risk || document.severity),
      confidentiality: normalizeString(document.confidentiality || 'restricted'),
      selfServiceVisible: type === 'security_exception',
      createdAt: document.createdAt || null,
      updatedAt: document.updatedAt || document.createdAt || null,
      dueAt: document.dueAt || document.reviewAt || null,
      closedAt: document.closedAt || null,
      route,
    },
  };
}

function lifecycleState(status) {
  if (status === 'closed') return 'closed';
  if (['cancelled', 'rejected', 'expired'].includes(status)) return 'cancelled';
  return 'active';
}

function deterministicId(prefix, ...values) {
  return `${prefix}_${crypto.createHash('sha256')
    .update(values.map((value) => normalizeString(value)).join('\u0000'))
    .digest('hex').slice(0, 40)}`;
}

module.exports = {
  buildOwnDeviceComplianceProjection,
  buildSecurityWorkItemIndex,
  complianceResult,
  deterministicId,
  safeComplianceStatus,
};
