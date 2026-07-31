'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const COMMANDS = Object.freeze({
  createFinding: 'security.finding.create',
  triageFinding: 'security.finding.triage',
  assignFinding: 'security.finding.assign',
  planRemediation: 'security.finding.remediation.plan',
  submitFindingValidation: 'security.finding.validation.submit',
  validateFinding: 'security.finding.validation.decide',
  acceptFindingRisk: 'security.finding.risk.accept',
  closeFinding: 'security.finding.close',
  cancelFinding: 'security.finding.cancel',
  createException: 'security.exception.create',
  submitException: 'security.exception.submit',
  requestExceptionApproval: 'security.exception.approval.request',
  decideExceptionApproval: 'security.exception.approval.decide',
  activateException: 'security.exception.activate',
  renewException: 'security.exception.renew',
  closeException: 'security.exception.close',
  assessCompliance: 'security.compliance.assess',
  createReviewCampaign: 'security.access_review.campaign.create',
  activateReviewCampaign: 'security.access_review.campaign.activate',
  completeReviewCampaign: 'security.access_review.campaign.complete',
  createReviewItem: 'security.access_review.item.create',
  decideReviewItem: 'security.access_review.item.decide',
  requestAccessCorrection: 'security.access_review.correction.request',
  completeRevocationTask: 'security.access_review.revocation.complete',
});

const SELF_SERVICE = Object.freeze([
  ITSM_ROLES.user,
  ITSM_ROLES.manager,
  ITSM_ROLES.admin,
]);
const MANAGER = Object.freeze([ITSM_ROLES.manager]);
const mutableAllowedRoles = Object.fromEntries(
  Object.values(COMMANDS).map((command) => [command, MANAGER]),
);
for (const command of [
  COMMANDS.createException,
  COMMANDS.submitException,
  COMMANDS.renewException,
  COMMANDS.closeException,
]) {
  mutableAllowedRoles[command] = SELF_SERVICE;
}
mutableAllowedRoles[COMMANDS.requestAccessCorrection] = Object.freeze([
  ITSM_ROLES.user,
  ITSM_ROLES.admin,
]);
const ALLOWED_ROLES = Object.freeze(mutableAllowedRoles);

const ENVELOPE_FIELDS = new Set(['command', 'idempotencyKey', 'payload']);
const COMMON_REVISION = ['expectedRevision'];
const PAYLOAD_FIELDS = Object.freeze({
  [COMMANDS.createFinding]: fields(
    'findingId', 'title', 'description', 'source', 'severity', 'risk',
    'confidentiality', 'affectedAssetIds', 'affectedCiIds',
    'affectedServiceIds', 'dueAt', 'relatedIncidentId', 'relatedChangeId',
  ),
  [COMMANDS.triageFinding]: fields('findingId', ...COMMON_REVISION, 'severity', 'risk', 'dueAt'),
  [COMMANDS.assignFinding]: fields('findingId', ...COMMON_REVISION, 'ownerUserId'),
  [COMMANDS.planRemediation]: fields(
    'findingId', ...COMMON_REVISION, 'remediationPlan', 'remediationLinks',
  ),
  [COMMANDS.submitFindingValidation]: fields('findingId', ...COMMON_REVISION, 'comment'),
  [COMMANDS.validateFinding]: fields(
    'findingId', ...COMMON_REVISION, 'result', 'comment',
  ),
  [COMMANDS.acceptFindingRisk]: fields(
    'findingId', ...COMMON_REVISION, 'reason', 'expiresAt',
  ),
  [COMMANDS.closeFinding]: fields('findingId', ...COMMON_REVISION, 'comment'),
  [COMMANDS.cancelFinding]: fields('findingId', ...COMMON_REVISION, 'reason'),
  [COMMANDS.createException]: fields(
    'exceptionId', 'title', 'requirementOrControl', 'businessJustification',
    'scope', 'affectedAssetId', 'affectedServiceId', 'affectedUserId',
    'riskDescription', 'compensatingControls', 'requestedStartAt',
    'requestedEndAt', 'reviewAt', 'confidentiality',
  ),
  [COMMANDS.submitException]: fields('exceptionId', ...COMMON_REVISION),
  [COMMANDS.requestExceptionApproval]: fields(
    'exceptionId', ...COMMON_REVISION, 'approvalId', 'approverUserIds',
    'approverGroupId',
  ),
  [COMMANDS.decideExceptionApproval]: fields(
    'exceptionId', ...COMMON_REVISION, 'approvalId', 'decision', 'comment',
  ),
  [COMMANDS.activateException]: fields('exceptionId', ...COMMON_REVISION),
  [COMMANDS.renewException]: fields(
    'exceptionId', ...COMMON_REVISION, 'newExceptionId', 'businessJustification',
    'requestedStartAt', 'requestedEndAt', 'reviewAt',
  ),
  [COMMANDS.closeException]: fields('exceptionId', ...COMMON_REVISION, 'reason'),
  [COMMANDS.assessCompliance]: fields(
    'assessmentId', 'assetId', 'assetTag', 'assetName', 'assignedUserId',
    'assignedUserName', 'checks', 'nextAssessmentAt', 'remediationRequestId',
    'remediationChangeId', 'remediationSummary', 'evidenceIds',
  ),
  [COMMANDS.createReviewCampaign]: fields(
    'campaignId', 'title', 'scope', 'systemId', 'systemName', 'ownerUserId',
    'startsAt', 'dueAt', 'allowSelfServiceCorrection', 'reviewerUserIds',
    'departmentIds',
  ),
  [COMMANDS.activateReviewCampaign]: fields('campaignId', ...COMMON_REVISION),
  [COMMANDS.completeReviewCampaign]: fields('campaignId', ...COMMON_REVISION),
  [COMMANDS.createReviewItem]: fields(
    'itemId', 'campaignId', 'subjectUserId', 'currentAccess', 'currentRole',
    'departmentId', 'departmentName', 'reviewerUserId', 'dueAt',
  ),
  [COMMANDS.decideReviewItem]: fields(
    'itemId', ...COMMON_REVISION, 'decision', 'justification',
    'assignedToUserId', 'targetAccess', 'taskDueAt',
  ),
  [COMMANDS.requestAccessCorrection]: fields('itemId', 'type', 'reason'),
  [COMMANDS.completeRevocationTask]: fields(
    'taskId', ...COMMON_REVISION, 'completionEvidenceId', 'comment',
  ),
});

function validateSecurityComplianceCommand(input, expectedCommand) {
  if (!isObject(input)) throw invalid('The command must be an object.');
  rejectUnknown(input, ENVELOPE_FIELDS, 'command');
  const command = normalizeString(input.command);
  if (!Object.values(COMMANDS).includes(command)) {
    throw invalid(`Unknown security command: ${command || '(empty)'}.`);
  }
  if (expectedCommand && command !== expectedCommand) {
    throw invalid(`The ${expectedCommand} endpoint cannot execute ${command}.`);
  }
  const idempotencyKey = normalizeString(input.idempotencyKey);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/.test(idempotencyKey)) {
    throw invalid('idempotencyKey must contain 8-128 safe characters.');
  }
  const payload = input.payload === undefined ? {} : input.payload;
  if (!isObject(payload)) throw invalid('payload must be an object.');
  rejectUnknown(payload, PAYLOAD_FIELDS[command], `${command} payload`);
  return deepFreeze({
    command,
    idempotencyKey,
    payload: validatePayload(command, payload),
  });
}

function validatePayload(command, value) {
  const revision = () => ({
    expectedRevision: integer(value.expectedRevision, 'expectedRevision', 0),
  });
  const entity = (key) => ({ [key]: identifier(value[key], key) });
  switch (command) {
    case COMMANDS.createFinding:
      return {
        findingId: optionalIdentifier(value.findingId, 'findingId'),
        title: text(value.title, 'title', 240),
        description: text(value.description, 'description', 12000),
        source: text(value.source, 'source', 240),
        severity: enumeration(value.severity, ['low', 'medium', 'high', 'critical'], 'severity'),
        risk: enumeration(value.risk, ['low', 'medium', 'high', 'critical'], 'risk'),
        confidentiality: enumeration(value.confidentiality || 'restricted', ['internal', 'confidential', 'restricted'], 'confidentiality'),
        affectedAssetIds: identifiers(value.affectedAssetIds, 'affectedAssetIds', 100),
        affectedCiIds: identifiers(value.affectedCiIds, 'affectedCiIds', 100),
        affectedServiceIds: identifiers(value.affectedServiceIds, 'affectedServiceIds', 50),
        dueAt: optionalDate(value.dueAt, 'dueAt'),
        relatedIncidentId: optionalIdentifier(value.relatedIncidentId, 'relatedIncidentId'),
        relatedChangeId: optionalIdentifier(value.relatedChangeId, 'relatedChangeId'),
      };
    case COMMANDS.triageFinding:
      return { ...entity('findingId'), ...revision(), severity: enumeration(value.severity, ['low', 'medium', 'high', 'critical'], 'severity'), risk: enumeration(value.risk, ['low', 'medium', 'high', 'critical'], 'risk'), dueAt: optionalDate(value.dueAt, 'dueAt') };
    case COMMANDS.assignFinding:
      return { ...entity('findingId'), ...revision(), ownerUserId: identifier(value.ownerUserId, 'ownerUserId') };
    case COMMANDS.planRemediation:
      return { ...entity('findingId'), ...revision(), remediationPlan: text(value.remediationPlan, 'remediationPlan', 12000), remediationLinks: remediationLinks(value.remediationLinks) };
    case COMMANDS.submitFindingValidation:
      return { ...entity('findingId'), ...revision(), comment: optionalText(value.comment, 'comment', 4000) };
    case COMMANDS.validateFinding:
      return { ...entity('findingId'), ...revision(), result: enumeration(value.result, ['passed', 'failed', 'partially_validated'], 'result'), comment: text(value.comment, 'comment', 4000) };
    case COMMANDS.acceptFindingRisk:
      return { ...entity('findingId'), ...revision(), reason: text(value.reason, 'reason', 8000), expiresAt: optionalDate(value.expiresAt, 'expiresAt') };
    case COMMANDS.closeFinding:
      return { ...entity('findingId'), ...revision(), comment: text(value.comment, 'comment', 4000) };
    case COMMANDS.cancelFinding:
      return { ...entity('findingId'), ...revision(), reason: text(value.reason, 'reason', 4000) };
    case COMMANDS.createException:
      return {
        exceptionId: optionalIdentifier(value.exceptionId, 'exceptionId'),
        title: text(value.title, 'title', 240),
        requirementOrControl: text(value.requirementOrControl, 'requirementOrControl', 1000),
        businessJustification: text(value.businessJustification, 'businessJustification', 8000),
        scope: text(value.scope, 'scope', 4000),
        affectedAssetId: optionalIdentifier(value.affectedAssetId, 'affectedAssetId'),
        affectedServiceId: optionalIdentifier(value.affectedServiceId, 'affectedServiceId'),
        affectedUserId: optionalIdentifier(value.affectedUserId, 'affectedUserId'),
        riskDescription: text(value.riskDescription, 'riskDescription', 8000),
        compensatingControls: controls(value.compensatingControls),
        requestedStartAt: date(value.requestedStartAt, 'requestedStartAt'),
        requestedEndAt: date(value.requestedEndAt, 'requestedEndAt'),
        reviewAt: date(value.reviewAt, 'reviewAt'),
        confidentiality: enumeration(value.confidentiality || 'confidential', ['internal', 'confidential', 'restricted'], 'confidentiality'),
      };
    case COMMANDS.submitException:
    case COMMANDS.activateException:
      return { ...entity('exceptionId'), ...revision() };
    case COMMANDS.requestExceptionApproval: {
      const approverUserIds = identifiers(
        value.approverUserIds,
        'approverUserIds',
        50,
      );
      const approverGroupId = optionalIdentifier(
        value.approverGroupId,
        'approverGroupId',
      );
      if (approverUserIds.length === 0 && !approverGroupId) {
        throw invalid(
          'An approverUserId or approverGroupId is required.',
        );
      }
      return {
        ...entity('exceptionId'),
        ...revision(),
        approvalId: optionalIdentifier(value.approvalId, 'approvalId'),
        approverUserIds,
        approverGroupId,
      };
    }
    case COMMANDS.decideExceptionApproval:
      return { ...entity('exceptionId'), ...revision(), approvalId: identifier(value.approvalId, 'approvalId'), decision: enumeration(value.decision, ['approved', 'rejected'], 'decision'), comment: text(value.comment, 'comment', 4000) };
    case COMMANDS.renewException:
      return { ...entity('exceptionId'), ...revision(), newExceptionId: optionalIdentifier(value.newExceptionId, 'newExceptionId'), businessJustification: text(value.businessJustification, 'businessJustification', 8000), requestedStartAt: date(value.requestedStartAt, 'requestedStartAt'), requestedEndAt: date(value.requestedEndAt, 'requestedEndAt'), reviewAt: date(value.reviewAt, 'reviewAt') };
    case COMMANDS.closeException:
      return { ...entity('exceptionId'), ...revision(), reason: text(value.reason, 'reason', 4000) };
    case COMMANDS.assessCompliance:
      return {
        assessmentId: optionalIdentifier(value.assessmentId, 'assessmentId'),
        assetId: identifier(value.assetId, 'assetId'),
        assetTag: text(value.assetTag, 'assetTag', 160),
        assetName: text(value.assetName, 'assetName', 240),
        assignedUserId: optionalIdentifier(value.assignedUserId, 'assignedUserId'),
        assignedUserName: optionalText(value.assignedUserName, 'assignedUserName', 240),
        checks: complianceChecks(value.checks),
        nextAssessmentAt: optionalDate(value.nextAssessmentAt, 'nextAssessmentAt'),
        remediationRequestId: optionalIdentifier(value.remediationRequestId, 'remediationRequestId'),
        remediationChangeId: optionalIdentifier(value.remediationChangeId, 'remediationChangeId'),
        remediationSummary: optionalText(value.remediationSummary, 'remediationSummary', 8000),
        evidenceIds: identifiers(value.evidenceIds, 'evidenceIds', 100),
      };
    case COMMANDS.createReviewCampaign:
      return { campaignId: optionalIdentifier(value.campaignId, 'campaignId'), title: text(value.title, 'title', 240), scope: text(value.scope, 'scope', 4000), systemId: identifier(value.systemId, 'systemId'), systemName: text(value.systemName, 'systemName', 240), ownerUserId: identifier(value.ownerUserId, 'ownerUserId'), startsAt: date(value.startsAt, 'startsAt'), dueAt: date(value.dueAt, 'dueAt'), allowSelfServiceCorrection: boolean(value.allowSelfServiceCorrection, 'allowSelfServiceCorrection', true), reviewerUserIds: identifiers(value.reviewerUserIds, 'reviewerUserIds', 100, true), departmentIds: identifiers(value.departmentIds, 'departmentIds', 100) };
    case COMMANDS.activateReviewCampaign:
    case COMMANDS.completeReviewCampaign:
      return { ...entity('campaignId'), ...revision() };
    case COMMANDS.createReviewItem:
      return { itemId: optionalIdentifier(value.itemId, 'itemId'), campaignId: identifier(value.campaignId, 'campaignId'), subjectUserId: identifier(value.subjectUserId, 'subjectUserId'), currentAccess: text(value.currentAccess, 'currentAccess', 4000), currentRole: text(value.currentRole, 'currentRole', 240), departmentId: identifier(value.departmentId, 'departmentId'), departmentName: text(value.departmentName, 'departmentName', 240), reviewerUserId: identifier(value.reviewerUserId, 'reviewerUserId'), dueAt: date(value.dueAt, 'dueAt') };
    case COMMANDS.decideReviewItem:
      return { ...entity('itemId'), ...revision(), decision: enumeration(value.decision, ['retain', 'revoke', 'modify'], 'decision'), justification: text(value.justification, 'justification', 4000), assignedToUserId: optionalIdentifier(value.assignedToUserId, 'assignedToUserId'), targetAccess: optionalText(value.targetAccess, 'targetAccess', 4000), taskDueAt: optionalDate(value.taskDueAt, 'taskDueAt') };
    case COMMANDS.requestAccessCorrection:
      return { ...entity('itemId'), type: enumeration(value.type, ['correction', 'revocation'], 'type'), reason: text(value.reason, 'reason', 4000) };
    case COMMANDS.completeRevocationTask:
      return { ...entity('taskId'), ...revision(), completionEvidenceId: identifier(value.completionEvidenceId, 'completionEvidenceId'), comment: text(value.comment, 'comment', 4000) };
    default:
      throw invalid('Unsupported security command.');
  }
}

function complianceChecks(value) {
  if (!Array.isArray(value) || value.length === 0 || value.length > 20) {
    throw invalid('checks must contain 1-20 entries.');
  }
  const allowedControls = ['operating_system_support', 'patch_status', 'antivirus_edr', 'encryption', 'backup', 'approved_software', 'security_baseline'];
  const seen = new Set();
  return value.map((entry, index) => {
    if (!isObject(entry)) throw invalid(`checks[${index}] must be an object.`);
    rejectUnknown(entry, fields('control', 'result', 'summary', 'evidenceIds'), `checks[${index}]`);
    const control = enumeration(entry.control, allowedControls, `checks[${index}].control`);
    if (seen.has(control)) throw invalid(`checks contains duplicate ${control}.`);
    seen.add(control);
    return { control, result: enumeration(entry.result, ['compliant', 'non_compliant', 'not_applicable', 'unknown'], `checks[${index}].result`), summary: optionalText(entry.summary, `checks[${index}].summary`, 2000), evidenceIds: identifiers(entry.evidenceIds, `checks[${index}].evidenceIds`, 20) };
  });
}

function controls(value) {
  if (!Array.isArray(value) || value.length === 0 || value.length > 50) {
    throw invalid('compensatingControls must contain 1-50 entries.');
  }
  return value.map((entry, index) => {
    if (!isObject(entry)) throw invalid(`compensatingControls[${index}] must be an object.`);
    rejectUnknown(entry, fields('id', 'description', 'ownerUserId', 'effective', 'validationNotes'), `compensatingControls[${index}]`);
    return { id: identifier(entry.id, `compensatingControls[${index}].id`), description: text(entry.description, `compensatingControls[${index}].description`, 2000), ownerUserId: optionalIdentifier(entry.ownerUserId, `compensatingControls[${index}].ownerUserId`), effective: boolean(entry.effective, `compensatingControls[${index}].effective`, false), validationNotes: optionalText(entry.validationNotes, `compensatingControls[${index}].validationNotes`, 2000) };
  });
}

function remediationLinks(value) {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length > 100) throw invalid('remediationLinks must be a list of at most 100 entries.');
  return value.map((entry, index) => {
    if (!isObject(entry)) throw invalid(`remediationLinks[${index}] must be an object.`);
    rejectUnknown(entry, fields('type', 'recordId', 'summary'), `remediationLinks[${index}]`);
    return { type: enumeration(entry.type, ['service_request', 'change_request', 'task'], `remediationLinks[${index}].type`), recordId: identifier(entry.recordId, `remediationLinks[${index}].recordId`), summary: optionalText(entry.summary, `remediationLinks[${index}].summary`, 1000) };
  });
}

function fields(...names) { return new Set(names); }
function isObject(value) { return value !== null && typeof value === 'object' && !Array.isArray(value); }
function rejectUnknown(value, allowed, label) { for (const key of Object.keys(value)) if (!allowed.has(key)) throw invalid(`${label} contains unknown field ${key}.`); }
function identifier(value, label) { const result = normalizeString(value); if (!/^[A-Za-z0-9][A-Za-z0-9._:@-]{0,127}$/.test(result)) throw invalid(`${label} is invalid.`); return result; }
function optionalIdentifier(value, label) { return value === undefined || value === null || normalizeString(value) === '' ? null : identifier(value, label); }
function text(value, label, max) { const result = normalizeString(value); if (!result || result.length > max) throw invalid(`${label} is required and must not exceed ${max} characters.`); return result; }
function optionalText(value, label, max) { const result = normalizeString(value); if (result.length > max) throw invalid(`${label} must not exceed ${max} characters.`); return result; }
function enumeration(value, allowed, label) { const result = normalizeString(value).toLowerCase(); if (!allowed.includes(result)) throw invalid(`${label} must be one of: ${allowed.join(', ')}.`); return result; }
function integer(value, label, minimum) { if (!Number.isSafeInteger(value) || value < minimum) throw invalid(`${label} must be an integer greater than or equal to ${minimum}.`); return value; }
function boolean(value, label, fallback) { if (value === undefined) return fallback; if (typeof value !== 'boolean') throw invalid(`${label} must be a boolean.`); return value; }
function date(value, label) {
  const text = normalizeString(value);
  const isoDateTime = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})$/;
  if (!isoDateTime.test(text)) {
    throw invalid(`${label} must be an ISO-8601 date and time.`);
  }
  const result = new Date(text);
  if (Number.isNaN(result.getTime())) {
    throw invalid(`${label} must be an ISO-8601 date and time.`);
  }
  return result;
}
function optionalDate(value, label) { return value === undefined || value === null || value === '' ? null : date(value, label); }
function identifiers(value, label, max, required = false) { if (value === undefined && !required) return []; if (!Array.isArray(value) || (required && value.length === 0) || value.length > max) throw invalid(`${label} must contain ${required ? '1-' : '0-'}${max} identifiers.`); return [...new Set(value.map((entry) => identifier(entry, label)))]; }
function deepFreeze(value) { if (value && typeof value === 'object' && !Object.isFrozen(value)) { Object.freeze(value); for (const child of Object.values(value)) deepFreeze(child); } return value; }
function invalid(message) { return new ItsmCommandError('invalid-argument', message); }

module.exports = {
  SECURITY_COMPLIANCE_ALLOWED_ROLES: ALLOWED_ROLES,
  SECURITY_COMPLIANCE_COMMANDS: COMMANDS,
  validateSecurityComplianceCommand,
};
