'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const ITSM_CHANGES_COMMANDS = Object.freeze({
  initializeDraft: 'change.initialize_draft',
  saveDraft: 'change.save_draft',
  submit: 'change.submit',
  cancel: 'change.cancel',
  assess: 'change.assess',
  requestApproval: 'change.approval.request',
  decideApproval: 'change.approval.decide',
  saveCabMeeting: 'change.cab_meeting.save',
  schedule: 'change.schedule',
  startImplementation: 'change.implementation.start',
  recordImplementationResult: 'change.implementation.record_result',
  recordPostImplementationReview: 'change.pir.record',
  close: 'change.close',
});

const SELF_SERVICE_ROLES = Object.freeze([
  ITSM_ROLES.user,
  ITSM_ROLES.manager,
  ITSM_ROLES.admin,
]);
const MANAGER_ONLY = Object.freeze([ITSM_ROLES.manager]);

const CHANGES_COMMAND_ALLOWED_ROLES = Object.freeze({
  [ITSM_CHANGES_COMMANDS.initializeDraft]: SELF_SERVICE_ROLES,
  [ITSM_CHANGES_COMMANDS.saveDraft]: SELF_SERVICE_ROLES,
  [ITSM_CHANGES_COMMANDS.submit]: SELF_SERVICE_ROLES,
  [ITSM_CHANGES_COMMANDS.cancel]: SELF_SERVICE_ROLES,
  [ITSM_CHANGES_COMMANDS.assess]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.requestApproval]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.decideApproval]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.saveCabMeeting]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.schedule]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.startImplementation]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.recordImplementationResult]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.recordPostImplementationReview]: MANAGER_ONLY,
  [ITSM_CHANGES_COMMANDS.close]: MANAGER_ONLY,
});

const CHANGE_TYPES = Object.freeze(['standard', 'normal', 'emergency']);
const CHANGE_STATUSES = Object.freeze([
  'draft',
  'submitted',
  'assessment',
  'awaiting_approval',
  'approved',
  'scheduled',
  'implementation',
  'review',
  'closed',
  'rejected',
  'cancelled',
  'failed',
  'rolled_back',
]);
const IMPACT_LEVELS = Object.freeze(['low', 'medium', 'high', 'critical']);
const URGENCY_LEVELS = Object.freeze(['low', 'medium', 'high', 'critical']);
const COMPLEXITY_LEVELS = Object.freeze(['low', 'medium', 'high']);
const APPROVAL_DECISIONS = Object.freeze([
  'approved',
  'rejected',
  'clarification_requested',
]);
const IMPLEMENTATION_OUTCOMES = Object.freeze([
  'succeeded',
  'failed',
  'rolled_back',
]);
const PIR_OUTCOMES = Object.freeze(['successful', 'partial', 'unsuccessful']);

const ENVELOPE_FIELDS = new Set(['command', 'idempotencyKey', 'payload']);
const PAYLOAD_FIELDS = Object.freeze({
  [ITSM_CHANGES_COMMANDS.initializeDraft]: new Set([
    'changeId',
    'workflowDefinitionId',
    'changeType',
    'title',
    'description',
    'justification',
  ]),
  [ITSM_CHANGES_COMMANDS.saveDraft]: new Set([
    'changeId',
    'expectedRevision',
    'title',
    'description',
    'justification',
  ]),
  [ITSM_CHANGES_COMMANDS.submit]: new Set([
    'changeId',
    'expectedRevision',
  ]),
  [ITSM_CHANGES_COMMANDS.cancel]: new Set([
    'changeId',
    'expectedRevision',
    'reason',
  ]),
  [ITSM_CHANGES_COMMANDS.assess]: new Set([
    'changeId',
    'expectedRevision',
    'ownerUserId',
    'affectedServiceIds',
    'affectedCiIds',
    'affectedAssetIds',
    'relatedIncidentIds',
    'relatedRequestIds',
    'impact',
    'urgency',
    'complexity',
    'expectedDowntimeMinutes',
    'implementationPlan',
    'testPlan',
    'testEvidenceAttachmentIds',
    'communicationPlan',
    'rollbackPlan',
    'approvalGroupId',
  ]),
  [ITSM_CHANGES_COMMANDS.requestApproval]: new Set([
    'changeId',
    'expectedRevision',
  ]),
  [ITSM_CHANGES_COMMANDS.decideApproval]: new Set([
    'changeId',
    'approvalId',
    'expectedRevision',
    'decision',
    'comment',
    'conditions',
  ]),
  [ITSM_CHANGES_COMMANDS.saveCabMeeting]: new Set([
    'changeId',
    'meetingId',
    'expectedRevision',
    'approvalGroupId',
    'title',
    'agenda',
    'participantUserIds',
    'scheduledStartAt',
    'scheduledEndAt',
    'notes',
  ]),
  [ITSM_CHANGES_COMMANDS.schedule]: new Set([
    'changeId',
    'expectedRevision',
    'plannedStartAt',
    'plannedEndAt',
    'expectedDowntimeMinutes',
    'maintenanceWindowId',
    'publishMaintenance',
  ]),
  [ITSM_CHANGES_COMMANDS.startImplementation]: new Set([
    'changeId',
    'expectedRevision',
    'comment',
  ]),
  [ITSM_CHANGES_COMMANDS.recordImplementationResult]: new Set([
    'changeId',
    'expectedRevision',
    'outcome',
    'summary',
    'evidenceAttachmentIds',
  ]),
  [ITSM_CHANGES_COMMANDS.recordPostImplementationReview]: new Set([
    'changeId',
    'expectedRevision',
    'outcome',
    'summary',
    'lessonsLearned',
    'followUpActions',
    'evidenceAttachmentIds',
  ]),
  [ITSM_CHANGES_COMMANDS.close]: new Set([
    'changeId',
    'expectedRevision',
    'comment',
  ]),
});

function validateChangesCommand(input, expectedCommand) {
  if (!isPlainObject(input)) {
    throw invalid('The change command must be an object.');
  }
  rejectUnknownFields(input, ENVELOPE_FIELDS, 'change command');
  const command = normalizeString(input.command);
  if (!Object.values(ITSM_CHANGES_COMMANDS).includes(command)) {
    throw invalid(`Unknown change command: ${command || '(empty)'}.`);
  }
  if (expectedCommand && command !== expectedCommand) {
    throw invalid(`The ${expectedCommand} endpoint cannot execute ${command}.`);
  }
  const idempotencyKey = normalizeString(input.idempotencyKey);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/.test(idempotencyKey)) {
    throw invalid('idempotencyKey must contain 8-128 safe characters.');
  }
  const payload = input.payload === undefined ? {} : input.payload;
  if (!isPlainObject(payload)) throw invalid('payload must be an object.');
  rejectUnknownFields(payload, PAYLOAD_FIELDS[command], `${command} payload`);
  return deepFreeze({
    command,
    idempotencyKey,
    payload: validatePayload(command, payload),
  });
}

function validatePayload(command, payload) {
  switch (command) {
    case ITSM_CHANGES_COMMANDS.initializeDraft:
      return {
        changeId: optionalIdentifier(payload.changeId, 'changeId'),
        workflowDefinitionId: requireIdentifier(
          payload.workflowDefinitionId,
          'workflowDefinitionId',
        ),
        changeType: enumValue(payload.changeType, CHANGE_TYPES, 'changeType'),
        title: requireText(payload.title, 'title', 240),
        description: requireText(payload.description, 'description', 12000),
        justification: requireText(payload.justification, 'justification', 8000),
      };
    case ITSM_CHANGES_COMMANDS.saveDraft:
      return {
        ...changeRevision(payload),
        title: requireText(payload.title, 'title', 240),
        description: requireText(payload.description, 'description', 12000),
        justification: requireText(payload.justification, 'justification', 8000),
      };
    case ITSM_CHANGES_COMMANDS.submit:
      return changeRevision(payload);
    case ITSM_CHANGES_COMMANDS.cancel:
      return {
        ...changeRevision(payload),
        reason: requireText(payload.reason, 'reason', 4000),
      };
    case ITSM_CHANGES_COMMANDS.assess:
      return {
        ...changeRevision(payload),
        ownerUserId: requireIdentifier(payload.ownerUserId, 'ownerUserId'),
        affectedServiceIds: identifierList(
          payload.affectedServiceIds,
          'affectedServiceIds',
          50,
          true,
        ),
        affectedCiIds: identifierList(payload.affectedCiIds, 'affectedCiIds', 100),
        affectedAssetIds: identifierList(
          payload.affectedAssetIds,
          'affectedAssetIds',
          100,
        ),
        relatedIncidentIds: identifierList(
          payload.relatedIncidentIds,
          'relatedIncidentIds',
          100,
        ),
        relatedRequestIds: identifierList(
          payload.relatedRequestIds,
          'relatedRequestIds',
          100,
        ),
        impact: enumValue(payload.impact, IMPACT_LEVELS, 'impact'),
        urgency: enumValue(payload.urgency, URGENCY_LEVELS, 'urgency'),
        complexity: enumValue(payload.complexity, COMPLEXITY_LEVELS, 'complexity'),
        expectedDowntimeMinutes: nonNegativeInteger(
          payload.expectedDowntimeMinutes,
          'expectedDowntimeMinutes',
          43200,
        ),
        implementationPlan: requireText(
          payload.implementationPlan,
          'implementationPlan',
          30000,
        ),
        testPlan: requireText(payload.testPlan, 'testPlan', 30000),
        testEvidenceAttachmentIds: identifierList(
          payload.testEvidenceAttachmentIds,
          'testEvidenceAttachmentIds',
          50,
        ),
        communicationPlan: requireText(
          payload.communicationPlan,
          'communicationPlan',
          30000,
        ),
        rollbackPlan: requireText(payload.rollbackPlan, 'rollbackPlan', 30000),
        approvalGroupId: optionalIdentifier(
          payload.approvalGroupId,
          'approvalGroupId',
        ),
      };
    case ITSM_CHANGES_COMMANDS.requestApproval:
      return changeRevision(payload);
    case ITSM_CHANGES_COMMANDS.decideApproval:
      return {
        ...changeRevision(payload),
        approvalId: requireIdentifier(payload.approvalId, 'approvalId'),
        decision: enumValue(payload.decision, APPROVAL_DECISIONS, 'decision'),
        comment: requireText(payload.comment, 'comment', 8000),
        conditions: textList(payload.conditions, 'conditions', 20, 2000),
      };
    case ITSM_CHANGES_COMMANDS.saveCabMeeting:
      return validateCabMeeting(payload);
    case ITSM_CHANGES_COMMANDS.schedule:
      return validateSchedule(payload);
    case ITSM_CHANGES_COMMANDS.startImplementation:
      return {
        ...changeRevision(payload),
        comment: optionalText(payload.comment, 4000),
      };
    case ITSM_CHANGES_COMMANDS.recordImplementationResult:
      return {
        ...changeRevision(payload),
        outcome: enumValue(
          payload.outcome,
          IMPLEMENTATION_OUTCOMES,
          'outcome',
        ),
        summary: requireText(payload.summary, 'summary', 30000),
        evidenceAttachmentIds: identifierList(
          payload.evidenceAttachmentIds,
          'evidenceAttachmentIds',
          50,
        ),
      };
    case ITSM_CHANGES_COMMANDS.recordPostImplementationReview:
      return {
        ...changeRevision(payload),
        outcome: enumValue(payload.outcome, PIR_OUTCOMES, 'outcome'),
        summary: requireText(payload.summary, 'summary', 30000),
        lessonsLearned: optionalText(payload.lessonsLearned, 30000),
        followUpActions: textList(
          payload.followUpActions,
          'followUpActions',
          50,
          4000,
        ),
        evidenceAttachmentIds: identifierList(
          payload.evidenceAttachmentIds,
          'evidenceAttachmentIds',
          50,
        ),
      };
    case ITSM_CHANGES_COMMANDS.close:
      return {
        ...changeRevision(payload),
        comment: optionalText(payload.comment, 4000),
      };
    default:
      throw invalid(`Unknown change command: ${command}.`);
  }
}

function validateCabMeeting(payload) {
  const scheduledStartAt = requireIsoDate(
    payload.scheduledStartAt,
    'scheduledStartAt',
  );
  const scheduledEndAt = requireIsoDate(payload.scheduledEndAt, 'scheduledEndAt');
  requireOrderedWindow(scheduledStartAt, scheduledEndAt, 24 * 60, 'CAB meeting');
  return {
    ...changeRevision(payload),
    meetingId: optionalIdentifier(payload.meetingId, 'meetingId'),
    approvalGroupId: requireIdentifier(
      payload.approvalGroupId,
      'approvalGroupId',
    ),
    title: requireText(payload.title, 'title', 240),
    agenda: requireText(payload.agenda, 'agenda', 30000),
    participantUserIds: identifierList(
      payload.participantUserIds,
      'participantUserIds',
      50,
      true,
    ),
    scheduledStartAt,
    scheduledEndAt,
    notes: optionalText(payload.notes, 30000),
  };
}

function validateSchedule(payload) {
  const plannedStartAt = requireIsoDate(payload.plannedStartAt, 'plannedStartAt');
  const plannedEndAt = requireIsoDate(payload.plannedEndAt, 'plannedEndAt');
  requireOrderedWindow(plannedStartAt, plannedEndAt, 90 * 24 * 60, 'change');
  if (payload.publishMaintenance !== undefined &&
      typeof payload.publishMaintenance !== 'boolean') {
    throw invalid('publishMaintenance must be a boolean.');
  }
  return {
    ...changeRevision(payload),
    plannedStartAt,
    plannedEndAt,
    expectedDowntimeMinutes: nonNegativeInteger(
      payload.expectedDowntimeMinutes,
      'expectedDowntimeMinutes',
      43200,
    ),
    maintenanceWindowId: optionalIdentifier(
      payload.maintenanceWindowId,
      'maintenanceWindowId',
    ),
    publishMaintenance: payload.publishMaintenance === true,
  };
}

function changeRevision(payload) {
  return {
    changeId: requireIdentifier(payload.changeId, 'changeId'),
    expectedRevision: nonNegativeInteger(
      payload.expectedRevision,
      'expectedRevision',
      Number.MAX_SAFE_INTEGER,
    ),
  };
}

function requireOrderedWindow(startIso, endIso, maximumMinutes, label) {
  const start = new Date(startIso);
  const end = new Date(endIso);
  if (end <= start) throw invalid(`The ${label} end must be after its start.`);
  if ((end.getTime() - start.getTime()) / 60000 > maximumMinutes) {
    throw invalid(`The ${label} window cannot exceed ${maximumMinutes} minutes.`);
  }
}

function enumValue(value, allowed, field) {
  const normalized = normalizeString(value).toLowerCase();
  if (!allowed.includes(normalized)) {
    throw invalid(`${field} must be one of: ${allowed.join(', ')}.`);
  }
  return normalized;
}

function requireIdentifier(value, field) {
  const identifier = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(identifier)) {
    throw invalid(`${field} must be a safe identifier.`);
  }
  return identifier;
}

function optionalIdentifier(value, field) {
  const normalized = normalizeString(value);
  return normalized ? requireIdentifier(normalized, field) : '';
}

function identifierList(value, field, maximum, required = false) {
  if (value === undefined || value === null) {
    if (required) throw invalid(`${field} must contain at least one entry.`);
    return [];
  }
  if (!Array.isArray(value) || value.length > maximum) {
    throw invalid(`${field} must be an array with at most ${maximum} entries.`);
  }
  const result = [...new Set(value.map((entry) => requireIdentifier(entry, field)))];
  if (required && result.length === 0) {
    throw invalid(`${field} must contain at least one entry.`);
  }
  return result;
}

function requireText(value, field, maximum) {
  const text = normalizeString(value);
  if (!text) throw invalid(`${field} is required.`);
  if (text.length > maximum) throw invalid(`${field} is too long.`);
  return text;
}

function optionalText(value, maximum) {
  const text = normalizeString(value);
  if (text.length > maximum) throw invalid('A text value is too long.');
  return text;
}

function textList(value, field, maximumEntries, maximumLength) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > maximumEntries) {
    throw invalid(`${field} must contain at most ${maximumEntries} entries.`);
  }
  return value.map((entry) => requireText(entry, field, maximumLength));
}

function nonNegativeInteger(value, field, maximum) {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < 0 || number > maximum) {
    throw invalid(`${field} must be a non-negative integer.`);
  }
  return number;
}

function requireIsoDate(value, field) {
  const text = normalizeString(value);
  const date = new Date(text);
  if (!text || Number.isNaN(date.getTime()) || !/^\d{4}-\d{2}-\d{2}T/.test(text)) {
    throw invalid(`${field} must be an ISO-8601 date and time.`);
  }
  return date.toISOString();
}

function rejectUnknownFields(value, allowed, label) {
  const unknown = Object.keys(value).filter((key) => !allowed.has(key));
  if (unknown.length > 0) {
    throw invalid(`${label} contains unsupported fields: ${unknown.join(', ')}.`);
  }
}

function isPlainObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function deepFreeze(value) {
  if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
  Object.freeze(value);
  Object.values(value).forEach(deepFreeze);
  return value;
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

module.exports = {
  APPROVAL_DECISIONS,
  CHANGES_COMMAND_ALLOWED_ROLES,
  CHANGE_STATUSES,
  CHANGE_TYPES,
  COMPLEXITY_LEVELS,
  IMPACT_LEVELS,
  IMPLEMENTATION_OUTCOMES,
  ITSM_CHANGES_COMMANDS,
  PIR_OUTCOMES,
  URGENCY_LEVELS,
  validateChangesCommand,
};
