const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const ITSM_COMMANDS = Object.freeze({
  transitionWorkItem: 'workflow.transition',
  decideApproval: 'approval.decide',
  indexAuditEvent: 'audit.index',
  maintainWorkItemIndex: 'work_item.index',
  processSla: 'sla.process',
  createNotificationEvent: 'notification.create',
});

const ENTITY_TYPE_ALIASES = Object.freeze({
  incident: 'incident',
  incident_ticket: 'incident',
  service_request: 'service_request',
  request: 'service_request',
  change: 'change_request',
  change_request: 'change_request',
  security_finding: 'security_finding',
  security_exception: 'security_exception',
  asset: 'asset',
  configuration_item: 'configuration_item',
  ci: 'configuration_item',
});

const COMMAND_ALLOWED_ROLES = Object.freeze({
  [ITSM_COMMANDS.transitionWorkItem]: [
    ITSM_ROLES.user,
    ITSM_ROLES.manager,
    ITSM_ROLES.admin,
  ],
  [ITSM_COMMANDS.decideApproval]: [ITSM_ROLES.manager],
  [ITSM_COMMANDS.indexAuditEvent]: [ITSM_ROLES.manager],
  [ITSM_COMMANDS.maintainWorkItemIndex]: [ITSM_ROLES.manager],
  [ITSM_COMMANDS.processSla]: [ITSM_ROLES.manager],
  [ITSM_COMMANDS.createNotificationEvent]: [ITSM_ROLES.manager],
});

const NOTIFICATION_EVENT_TYPES = new Set([
  'incident.created',
  'incident.assigned',
  'service_request.submitted',
  'approval.requested',
  'approval.decided',
  'asset.assigned',
  'asset.warranty_expiring',
  'licence.expiring',
  'change.scheduled',
  'change.failed',
  'sla.at_risk',
  'sla.breached',
  'security_finding.assigned',
  'security_exception.expiring',
  'access_review.due',
]);

const ENVELOPE_FIELDS = new Set([
  'command',
  'idempotencyKey',
  'entityType',
  'entityId',
  'payload',
]);

const PAYLOAD_FIELDS = Object.freeze({
  [ITSM_COMMANDS.transitionWorkItem]: new Set([
    'transitionId',
    'toState',
    'expectedRevision',
    'reason',
  ]),
  [ITSM_COMMANDS.decideApproval]: new Set([
    'approvalId',
    'decision',
    'comment',
  ]),
  [ITSM_COMMANDS.indexAuditEvent]: new Set(['auditEventId']),
  [ITSM_COMMANDS.maintainWorkItemIndex]: new Set([]),
  [ITSM_COMMANDS.processSla]: new Set(['action', 'reason']),
  [ITSM_COMMANDS.createNotificationEvent]: new Set([
    'eventType',
    'title',
    'body',
    'route',
    'target',
  ]),
});

function validateCommandEnvelope(input, expectedCommand) {
  if (!isPlainObject(input)) {
    throw invalid('The command request must be an object.');
  }
  rejectUnknownFields(input, ENVELOPE_FIELDS, 'command request');

  const command = normalizeString(input.command);
  if (!Object.values(ITSM_COMMANDS).includes(command)) {
    throw invalid(`Unknown ITSM command: ${command || '(empty)'}.`);
  }
  if (expectedCommand && command !== expectedCommand) {
    throw invalid(
      `The ${expectedCommand} endpoint cannot execute ${command}.`,
    );
  }

  const idempotencyKey = normalizeString(input.idempotencyKey);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/.test(idempotencyKey)) {
    throw invalid(
      'idempotencyKey must contain 8-128 safe characters.',
    );
  }

  const entityType = normalizeEntityType(input.entityType);
  const entityId = requireIdentifier(input.entityId, 'entityId');
  const payload = input.payload === undefined ? {} : input.payload;
  if (!isPlainObject(payload)) {
    throw invalid('payload must be an object.');
  }
  rejectUnknownFields(payload, PAYLOAD_FIELDS[command], `${command} payload`);

  const normalizedPayload = validatePayload(command, payload);
  return deepFreeze({
    command,
    idempotencyKey,
    entityType,
    entityId,
    payload: normalizedPayload,
  });
}

function validatePayload(command, payload) {
  switch (command) {
    case ITSM_COMMANDS.transitionWorkItem:
      return {
        transitionId: requireIdentifier(
          payload.transitionId,
          'transitionId',
        ),
        toState: requireIdentifier(payload.toState, 'toState'),
        expectedRevision: requireNonNegativeInteger(
          payload.expectedRevision,
          'expectedRevision',
        ),
        reason: optionalText(payload.reason, 2000),
      };
    case ITSM_COMMANDS.decideApproval: {
      const decision = normalizeString(payload.decision).toLowerCase();
      if (!['approved', 'rejected', 'clarification_requested'].includes(
        decision,
      )) {
        throw invalid(
          'decision must be approved, rejected, or clarification_requested.',
        );
      }
      const comment = optionalText(payload.comment, 4000);
      if (decision === 'rejected' && !comment) {
        throw invalid('A rejection comment is required.');
      }
      return {
        approvalId: requireIdentifier(payload.approvalId, 'approvalId'),
        decision,
        comment,
      };
    }
    case ITSM_COMMANDS.indexAuditEvent:
      return {
        auditEventId: requireIdentifier(
          payload.auditEventId,
          'auditEventId',
        ),
      };
    case ITSM_COMMANDS.maintainWorkItemIndex:
      return {};
    case ITSM_COMMANDS.processSla: {
      const action = normalizeString(payload.action).toLowerCase();
      if (!['recalculate', 'pause', 'resume', 'check'].includes(action)) {
        throw invalid(
          'SLA action must be recalculate, pause, resume, or check.',
        );
      }
      return { action, reason: optionalText(payload.reason, 2000) };
    }
    case ITSM_COMMANDS.createNotificationEvent:
      return validateNotificationPayload(payload);
    default:
      throw invalid(`Unknown ITSM command: ${command}.`);
  }
}

function validateNotificationPayload(payload) {
  const target = payload.target;
  if (!isPlainObject(target)) {
    throw invalid('Notification target must be an object.');
  }
  rejectUnknownFields(
    target,
    new Set(['type', 'userIds', 'userEmails', 'moduleKey', 'roles']),
    'notification target',
  );
  const type = normalizeString(target.type).toUpperCase();
  if (!['USERS', 'MODULE_ROLE'].includes(type)) {
    throw invalid('Notification target type is not supported.');
  }

  const normalizedTarget = { type };
  if (type === 'USERS') {
    normalizedTarget.userIds = stringArray(target.userIds, 'userIds');
    normalizedTarget.userEmails = stringArray(
      target.userEmails,
      'userEmails',
    ).map((value) => value.toLowerCase());
    if (
      normalizedTarget.userIds.length === 0 &&
      normalizedTarget.userEmails.length === 0
    ) {
      throw invalid('A USERS target requires at least one recipient.');
    }
  } else if (type === 'MODULE_ROLE') {
    normalizedTarget.moduleKey = 'ticketing';
    normalizedTarget.roles = stringArray(target.roles, 'roles').map(
      (value) => value.toUpperCase(),
    );
    if (normalizedTarget.roles.length === 0) {
      throw invalid('A MODULE_ROLE target requires at least one role.');
    }
    if (normalizedTarget.roles.some((role) => role !== ITSM_ROLES.manager)) {
      throw invalid('ITSM role notifications may target MANAGER only.');
    }
  }

  const eventType = requireIdentifier(payload.eventType, 'eventType');
  if (!NOTIFICATION_EVENT_TYPES.has(eventType)) {
    throw invalid('Notification eventType is not an approved ITSM event.');
  }

  return {
    eventType,
    title: requiredText(payload.title, 'title', 180),
    body: requiredText(payload.body, 'body', 1000),
    route: optionalText(payload.route, 500),
    target: normalizedTarget,
  };
}

function normalizeEntityType(value) {
  const key = normalizeString(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
  const entityType = ENTITY_TYPE_ALIASES[key];
  if (!entityType) {
    throw invalid(`Unsupported ITSM entity type: ${key || '(empty)'}.`);
  }
  return entityType;
}

function requireIdentifier(value, field) {
  const identifier = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(identifier)) {
    throw invalid(`${field} is not a valid identifier.`);
  }
  return identifier;
}

function requireNonNegativeInteger(value, field) {
  if (!Number.isInteger(value) || value < 0) {
    throw invalid(`${field} must be a non-negative integer.`);
  }
  return value;
}

function requiredText(value, field, maxLength) {
  const text = normalizeString(value);
  if (!text || text.length > maxLength) {
    throw invalid(`${field} is required and must be at most ${maxLength} characters.`);
  }
  return text;
}

function optionalText(value, maxLength) {
  const text = normalizeString(value);
  if (text.length > maxLength) {
    throw invalid(`Text must be at most ${maxLength} characters.`);
  }
  return text;
}

function safeMap(value, field) {
  if (value === undefined || value === null) {
    return {};
  }
  if (!isPlainObject(value)) {
    throw invalid(`${field} must be an object.`);
  }
  return cloneJsonValue(value);
}

function stringArray(value, field) {
  if (value === undefined || value === null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw invalid(`${field} must be an array.`);
  }
  const values = [...new Set(value.map(normalizeString).filter(Boolean))];
  if (values.length > 100) {
    throw invalid(`${field} cannot contain more than 100 values.`);
  }
  return values;
}

function rejectUnknownFields(object, allowed, label) {
  for (const field of Object.keys(object)) {
    if (!allowed.has(field)) {
      throw invalid(`Unknown field ${field} in ${label}.`);
    }
  }
}

function cloneJsonValue(value) {
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (_) {
    throw invalid('Payload values must be JSON serializable.');
  }
}

function deepFreeze(value) {
  if (!value || typeof value !== 'object' || Object.isFrozen(value)) {
    return value;
  }
  Object.values(value).forEach(deepFreeze);
  return Object.freeze(value);
}

function isPlainObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return false;
  }
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

module.exports = {
  COMMAND_ALLOWED_ROLES,
  ENTITY_TYPE_ALIASES,
  ITSM_COMMANDS,
  NOTIFICATION_EVENT_TYPES,
  deepFreeze,
  normalizeEntityType,
  validateCommandEnvelope,
};
