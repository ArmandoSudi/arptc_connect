'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const REPORTING_ADMINISTRATION_COMMANDS = Object.freeze({
  createSlaPolicyDraft: 'reporting.sla.create_draft',
  updateSlaPolicyDraft: 'reporting.sla.update_draft',
  validateSlaPolicyDraft: 'reporting.sla.validate_draft',
  publishSlaPolicyVersion: 'reporting.sla.publish_version',
  retireSlaPolicyVersion: 'reporting.sla.retire_version',
  recalculateSla: 'reporting.sla.recalculate',
  createCatalogueItemDraft: 'reporting.catalogue.create_draft',
  updateCatalogueItemDraft: 'reporting.catalogue.update_draft',
  validateCatalogueItemDraft: 'reporting.catalogue.validate_draft',
  publishCatalogueItemVersion: 'reporting.catalogue.publish_version',
  retireCatalogueItemVersion: 'reporting.catalogue.retire_version',
  createWorkflowDraft: 'reporting.workflow.create_draft',
  updateWorkflowDraft: 'reporting.workflow.update_draft',
  validateWorkflowDraft: 'reporting.workflow.validate_draft',
  publishWorkflowVersion: 'reporting.workflow.publish_version',
  retireWorkflowVersion: 'reporting.workflow.retire_version',
  saveReferenceData: 'reporting.reference.save',
  deactivateReferenceData: 'reporting.reference.deactivate',
  requestAuditExport: 'reporting.audit.request_export',
});

const MANAGER_ONLY = Object.freeze([ITSM_ROLES.manager]);
const AUDIT_EXPORT_ROLES = Object.freeze([
  ITSM_ROLES.manager,
  ITSM_ROLES.admin,
]);
const REPORTING_ADMINISTRATION_ALLOWED_ROLES = Object.freeze(
  Object.fromEntries(Object.values(REPORTING_ADMINISTRATION_COMMANDS).map(
    (command) => [
      command,
      command === REPORTING_ADMINISTRATION_COMMANDS.requestAuditExport
        ? AUDIT_EXPORT_ROLES
        : MANAGER_ONLY,
    ],
  )),
);

const WORK_ITEM_TYPES = Object.freeze([
  'incident',
  'service_request',
  'change_request',
  'security_finding',
  'security_exception',
  'asset_compliance_assessment',
  'access_review_item',
]);
const PRIORITIES = Object.freeze(['P1', 'P2', 'P3', 'P4']);
const CONFIGURATION_ROLES = Object.freeze([
  ITSM_ROLES.user,
  ITSM_ROLES.manager,
  ITSM_ROLES.admin,
]);
const REFERENCE_DATA_TYPES = Object.freeze([
  'catalogue_category',
  'assignment_group',
  'approval_policy',
]);
const SOURCE_COLLECTIONS = Object.freeze([
  'incidentTickets',
  'serviceRequests',
  'changeRequests',
  'securityFindings',
  'securityExceptions',
  'assetComplianceAssessments',
  'accessReviewItems',
]);
const AUDIT_EXPORT_MAX_DAYS = 31;
const AUDIT_EXPORT_MAX_ROWS = 5000;

function validateReportingAdministrationCommand(raw, expectedCommand) {
  const envelope = object(raw, 'command envelope');
  exactKeys(envelope, ['command', 'idempotencyKey', 'payload'], 'command envelope');
  const command = requiredString(envelope.command, 'command', 120);
  if (expectedCommand && command !== expectedCommand) {
    invalid(`Command ${command} cannot execute on ${expectedCommand}.`);
  }
  if (!REPORTING_ADMINISTRATION_ALLOWED_ROLES[command]) {
    invalid(`Unknown Reporting & Administration command: ${command}.`);
  }
  const idempotencyKey = requiredString(
    envelope.idempotencyKey,
    'idempotencyKey',
    180,
  );
  if (idempotencyKey.length < 8) invalid('idempotencyKey is too short.');
  const payload = validatePayload(command, object(envelope.payload, 'payload'));
  return Object.freeze({ command, idempotencyKey, payload });
}

function validatePayload(command, payload) {
  const C = REPORTING_ADMINISTRATION_COMMANDS;
  if (command === C.saveReferenceData) {
    exactKeys(payload, ['referenceId', 'type', 'label'], 'payload');
    return freeze({
      referenceId: requiredId(payload.referenceId, 'referenceId'),
      type: enumValue(payload.type, 'type', REFERENCE_DATA_TYPES),
      label: localizedRequired(payload.label, 'label'),
    });
  }
  if (command === C.deactivateReferenceData) {
    exactKeys(payload, ['referenceId'], 'payload');
    return freeze({
      referenceId: requiredId(payload.referenceId, 'referenceId'),
    });
  }
  if ([
    C.createSlaPolicyDraft,
    C.createCatalogueItemDraft,
    C.createWorkflowDraft,
  ].includes(command)) {
    exactKeys(payload, ['definitionId', 'draft', 'sourceVersionDocumentId'], 'payload');
    return freeze({
      definitionId: optionalId(payload.definitionId, 'definitionId'),
      sourceVersionDocumentId: optionalId(
        payload.sourceVersionDocumentId,
        'sourceVersionDocumentId',
      ),
      draft: validateDefinition(command, object(payload.draft, 'draft')),
    });
  }
  if ([
    C.updateSlaPolicyDraft,
    C.updateCatalogueItemDraft,
    C.updateWorkflowDraft,
  ].includes(command)) {
    exactKeys(payload, [
      'definitionId',
      'versionDocumentId',
      'expectedRevision',
      'draft',
    ], 'payload');
    return freeze({
      definitionId: requiredId(payload.definitionId, 'definitionId'),
      versionDocumentId: requiredId(
        payload.versionDocumentId,
        'versionDocumentId',
      ),
      expectedRevision: integer(payload.expectedRevision, 'expectedRevision', 0),
      draft: validateDefinition(command, object(payload.draft, 'draft')),
    });
  }
  if ([
    C.validateSlaPolicyDraft,
    C.publishSlaPolicyVersion,
    C.validateCatalogueItemDraft,
    C.publishCatalogueItemVersion,
    C.validateWorkflowDraft,
    C.publishWorkflowVersion,
  ].includes(command)) {
    exactKeys(payload, [
      'definitionId',
      'versionDocumentId',
      'expectedRevision',
    ], 'payload');
    return freeze({
      definitionId: requiredId(payload.definitionId, 'definitionId'),
      versionDocumentId: requiredId(
        payload.versionDocumentId,
        'versionDocumentId',
      ),
      expectedRevision: integer(payload.expectedRevision, 'expectedRevision', 0),
    });
  }
  if ([
    C.retireSlaPolicyVersion,
    C.retireCatalogueItemVersion,
    C.retireWorkflowVersion,
  ].includes(command)) {
    exactKeys(payload, ['definitionId', 'expectedRevision', 'reason'], 'payload');
    return freeze({
      definitionId: requiredId(payload.definitionId, 'definitionId'),
      expectedRevision: integer(payload.expectedRevision, 'expectedRevision', 0),
      reason: requiredString(payload.reason, 'reason', 1000),
    });
  }
  if (command === C.recalculateSla) {
    exactKeys(payload, ['collectionName', 'workItemId', 'policyId'], 'payload');
    const collectionName = enumValue(
      payload.collectionName,
      'collectionName',
      SOURCE_COLLECTIONS,
    );
    return freeze({
      collectionName,
      workItemId: requiredId(payload.workItemId, 'workItemId'),
      policyId: optionalId(payload.policyId, 'policyId'),
    });
  }
  if (command === C.requestAuditExport) {
    return validateAuditExportRequest(payload);
  }
  invalid(`Unsupported Reporting & Administration command: ${command}.`);
}

function validateDefinition(command, draft) {
  if (command.includes('.sla.')) return validateSlaPolicyDefinition(draft);
  if (command.includes('.catalogue.')) {
    return validateCatalogueDefinition(draft);
  }
  return validateWorkflowDefinition(draft);
}

function validateSlaPolicyDefinition(raw) {
  exactKeys(raw, [
    'name', 'workItemType', 'priority', 'serviceId',
    'responseTargetMinutes', 'resolutionTargetMinutes',
    'fulfilmentTargetMinutes', 'timeZone', 'weeklyWindows', 'holidays',
    'pauseStates', 'warningThreshold', 'escalationTargets',
  ], 'SLA policy');
  const responseTargetMinutes = integer(
    raw.responseTargetMinutes,
    'responseTargetMinutes',
    1,
    525600,
  );
  const resolutionTargetMinutes = integer(
    raw.resolutionTargetMinutes,
    'resolutionTargetMinutes',
    responseTargetMinutes,
    1051200,
  );
  const fulfilmentTargetMinutes = raw.fulfilmentTargetMinutes === undefined ||
      raw.fulfilmentTargetMinutes === null
    ? null
    : integer(
      raw.fulfilmentTargetMinutes,
      'fulfilmentTargetMinutes',
      1,
      1051200,
    );
  if (fulfilmentTargetMinutes !== null &&
      fulfilmentTargetMinutes < responseTargetMinutes) {
    invalid('fulfilmentTargetMinutes cannot precede responseTargetMinutes.');
  }
  const timeZone = requiredString(raw.timeZone, 'timeZone', 80);
  assertTimeZone(timeZone);
  const weeklyWindows = validateWeeklyWindows(raw.weeklyWindows);
  const holidays = uniqueStrings(raw.holidays || [], 'holidays', {
    maximum: 400,
    normalize: validateDateKey,
  });
  const pauseStates = uniqueStrings(raw.pauseStates || [], 'pauseStates', {
    maximum: 50,
    normalize: (value) => requiredString(value, 'pause state', 80).toLowerCase(),
  });
  const warningThreshold = number(
    raw.warningThreshold === undefined ? 0.8 : raw.warningThreshold,
    'warningThreshold',
    0.01,
    0.99,
  );
  const escalationTargets = array(raw.escalationTargets || [], 'escalationTargets', 20)
    .map((entry, index) => {
      const target = object(entry, `escalationTargets[${index}]`);
      exactKeys(target, [
        'eventName', 'assignmentGroupId', 'userId', 'atPercent',
      ], `escalationTargets[${index}]`);
      if (!target.assignmentGroupId && !target.userId) {
        invalid(`escalationTargets[${index}] requires a target.`);
      }
      return freeze({
        eventName: eventName(target.eventName, `escalationTargets[${index}].eventName`),
        assignmentGroupId: optionalId(
          target.assignmentGroupId,
          `escalationTargets[${index}].assignmentGroupId`,
        ),
        userId: optionalId(target.userId, `escalationTargets[${index}].userId`),
        atPercent: number(
          target.atPercent === undefined ? 100 : target.atPercent,
          `escalationTargets[${index}].atPercent`,
          1,
          100,
        ),
      });
  if (new Set(escalationTargets.map((target) => target.eventName)).size !==
      escalationTargets.length) {
    invalid('escalationTargets contains duplicate event names.');
  }
    });
  return freeze({
    name: localizedRequired(raw.name, 'name'),
    workItemType: enumValue(raw.workItemType, 'workItemType', WORK_ITEM_TYPES),
    priority: raw.priority ? enumValue(raw.priority, 'priority', PRIORITIES) : null,
    serviceId: optionalId(raw.serviceId, 'serviceId'),
    responseTargetMinutes,
    resolutionTargetMinutes,
    fulfilmentTargetMinutes,
    timeZone,
    weeklyWindows,
    holidays,
    pauseStates,
    warningThreshold,
    escalationTargets: freeze(escalationTargets),
  });
}

function validateWeeklyWindows(raw) {
  const windows = object(raw, 'weeklyWindows');
  const result = {};
  let count = 0;
  for (const [dayKey, entries] of Object.entries(windows)) {
    const day = integer(Number(dayKey), `weeklyWindows.${dayKey}`, 1, 7);
    const normalized = array(entries, `weeklyWindows.${day}`, 8)
      .map((entry, index) => {
        const window = object(entry, `weeklyWindows.${day}[${index}]`);
        exactKeys(window, ['start', 'end'], `weeklyWindows.${day}[${index}]`);
        const start = timeOfDay(window.start, 'start');
        const end = timeOfDay(window.end, 'end');
        if (minutesOfDay(start) >= minutesOfDay(end)) {
          invalid(`weeklyWindows.${day}[${index}] must end after it starts.`);
        }
        return freeze({ start, end });
      })
      .sort((left, right) => minutesOfDay(left.start) - minutesOfDay(right.start));
    for (let index = 1; index < normalized.length; index += 1) {
      if (minutesOfDay(normalized[index].start) <
          minutesOfDay(normalized[index - 1].end)) {
        invalid(`weeklyWindows.${day} contains overlapping windows.`);
      }
    }
    count += normalized.length;
    result[String(day)] = freeze(normalized);
  }
  if (count === 0) invalid('An SLA policy requires business hours.');
  return freeze(result);
}

function validateCatalogueDefinition(raw) {
  exactKeys(raw, [
    'code', 'name', 'description', 'categoryId', 'categoryName', 'iconKey',
    'eligibility', 'visibleRoles', 'formFields', 'requiredDocuments',
    'workflow', 'approvalPolicyId', 'fulfilmentGroupId', 'slaPolicy',
    'serviceOwner', 'eligibilitySummary', 'costModel', 'availabilityTarget',
    'fulfilmentSla', 'underlyingCis', 'securityCompliance',
    'fulfilmentWorkflow',
    'activeFrom', 'activeUntil', 'allowManagerRequestOnBehalf',
    'workflowAllowsCancellation', 'sortOrder',
  ], 'catalogue item');
  const activeFrom = optionalDate(raw.activeFrom, 'activeFrom');
  const activeUntil = optionalDate(raw.activeUntil, 'activeUntil');
  if (activeFrom && activeUntil && activeFrom > activeUntil) {
    invalid('activeFrom cannot be after activeUntil.');
  }
  const visibleRoles = uniqueStrings(raw.visibleRoles, 'visibleRoles', {
    minimum: 1,
    maximum: 3,
    normalize: (value) => enumValue(value, 'visible role', CONFIGURATION_ROLES),
  });
  const formFields = validateKeyedEntries(raw.formFields || [], 'formFields', 80);
  const requiredDocuments = validateKeyedEntries(
    raw.requiredDocuments || [],
    'requiredDocuments',
    40,
  );
  return freeze({
    code: requiredString(raw.code, 'code', 80).toUpperCase(),
    name: localizedRequired(raw.name, 'name'),
    description: localizedRequired(raw.description, 'description'),
    categoryId: requiredId(raw.categoryId, 'categoryId'),
    categoryName: localizedRequired(raw.categoryName, 'categoryName'),
    iconKey: requiredString(raw.iconKey, 'iconKey', 80),
    eligibility: validateCatalogueEligibility(raw.eligibility || {}),
    visibleRoles,
    formFields,
    requiredDocuments,
    workflow: configurationReference(raw.workflow, 'workflow'),
    approvalPolicyId: optionalId(raw.approvalPolicyId, 'approvalPolicyId'),
    serviceOwner: validateCatalogueServiceOwner(raw.serviceOwner),
    eligibilitySummary: localizedRequired(
      raw.eligibilitySummary,
      'eligibilitySummary',
    ),
    costModel: localizedRequired(raw.costModel, 'costModel'),
    availabilityTarget: localizedRequired(
      raw.availabilityTarget,
      'availabilityTarget',
    ),
    fulfilmentSla: localizedRequired(raw.fulfilmentSla, 'fulfilmentSla'),
    underlyingCis: validateCatalogueConfigurationItems(raw.underlyingCis),
    securityCompliance: localizedRequired(
      raw.securityCompliance,
      'securityCompliance',
    ),
    fulfilmentWorkflow: localizedRequired(
      raw.fulfilmentWorkflow,
      'fulfilmentWorkflow',
    ),
    fulfilmentGroupId: requiredId(raw.fulfilmentGroupId, 'fulfilmentGroupId'),
    slaPolicy: configurationReference(raw.slaPolicy, 'slaPolicy'),
    activeFrom,
    activeUntil,
    allowManagerRequestOnBehalf: boolean(
      raw.allowManagerRequestOnBehalf,
      'allowManagerRequestOnBehalf',
      true,
    ),
    workflowAllowsCancellation: boolean(
      raw.workflowAllowsCancellation,
      'workflowAllowsCancellation',
      true,
    ),
    sortOrder: integer(raw.sortOrder === undefined ? 0 : raw.sortOrder, 'sortOrder', -10000, 10000),
  });
}

function validateWorkflowDefinition(raw) {
  exactKeys(raw, [
    'key', 'module', 'workItemType', 'name', 'startStateId', 'states',
    'transitions',
  ], 'workflow');
  const states = array(raw.states, 'states', 100).map((entry, index) => {
    const state = object(entry, `states[${index}]`);
    exactKeys(state, [
      'id', 'label', 'isTerminal', 'isRequired',
      'requiresApprovalBeforeEntry',
    ], `states[${index}]`);
    return freeze({
      id: requiredId(state.id, `states[${index}].id`),
      label: localizedRequired(state.label, `states[${index}].label`),
      isTerminal: boolean(state.isTerminal, 'isTerminal', false),
      isRequired: boolean(state.isRequired, 'isRequired', true),
      requiresApprovalBeforeEntry: boolean(
        state.requiresApprovalBeforeEntry,
        'requiresApprovalBeforeEntry',
        false,
      ),
    });
  });
  const transitions = array(raw.transitions, 'transitions', 250)
    .map((entry, index) => {
      const transition = object(entry, `transitions[${index}]`);
      exactKeys(transition, [
        'id', 'fromStateId', 'toStateId', 'permittedRoles',
        'mandatoryFields', 'approvalPolicyId', 'assignmentGroupId',
        'pausesSla', 'resumesSla', 'notificationEvents',
        'automationActions', 'isAuditable',
      ], `transitions[${index}]`);
      const pausesSla = boolean(transition.pausesSla, 'pausesSla', false);
      const resumesSla = boolean(transition.resumesSla, 'resumesSla', false);
      if (pausesSla && resumesSla) {
        invalid(`transitions[${index}] cannot pause and resume SLA together.`);
      }
      return freeze({
        id: requiredId(transition.id, `transitions[${index}].id`),
        fromStateId: requiredId(
          transition.fromStateId,
          `transitions[${index}].fromStateId`,
        ),
        toStateId: requiredId(
          transition.toStateId,
          `transitions[${index}].toStateId`,
        ),
        permittedRoles: uniqueStrings(
          transition.permittedRoles,
          `transitions[${index}].permittedRoles`,
          {
            minimum: 0,
            maximum: 3,
            normalize: (value) => enumValue(value, 'permitted role', CONFIGURATION_ROLES),
          },
        ),
        mandatoryFields: uniqueStrings(
          transition.mandatoryFields || [],
          `transitions[${index}].mandatoryFields`,
          { maximum: 50 },
        ),
        approvalPolicyId: optionalId(
          transition.approvalPolicyId,
          `transitions[${index}].approvalPolicyId`,
        ),
        assignmentGroupId: optionalId(
          transition.assignmentGroupId,
          `transitions[${index}].assignmentGroupId`,
        ),
        pausesSla,
        resumesSla,
        notificationEvents: uniqueStrings(
          transition.notificationEvents || [],
          `transitions[${index}].notificationEvents`,
          { maximum: 20, normalize: eventName },
        ),
        automationActions: uniqueStrings(
          transition.automationActions || [],
          `transitions[${index}].automationActions`,
          { maximum: 20 },
        ),
        isAuditable: boolean(transition.isAuditable, 'isAuditable', true),
      });
    });
  const definition = freeze({
    key: requiredString(raw.key, 'key', 100).toLowerCase(),
    module: requiredString(raw.module, 'module', 80).toLowerCase(),
    workItemType: enumValue(raw.workItemType, 'workItemType', WORK_ITEM_TYPES),
    name: localizedRequired(raw.name, 'name'),
    startStateId: optionalId(raw.startStateId, 'startStateId') || '',
    states: freeze(states),
    transitions: freeze(transitions),
  });
  return definition;
}

function workflowValidationIssues(definition) {
  const issues = [];
  if (definition.states.length === 0) issue(issues, 'no_states', null);
  const stateIds = definition.states.map((state) => state.id);
  const uniqueStateIds = new Set(stateIds);
  for (const id of duplicates(stateIds)) issue(issues, 'duplicate_state', id);
  if (!definition.startStateId) {
    issue(issues, 'missing_start_state', null);
  } else if (!uniqueStateIds.has(definition.startStateId)) {
    issue(issues, 'unknown_start_state', definition.startStateId);
  }
  const transitionIds = definition.transitions.map((transition) => transition.id);
  for (const id of duplicates(transitionIds)) issue(issues, 'duplicate_transition', id);
  const validTransitions = [];
  for (const transition of definition.transitions) {
    if (!uniqueStateIds.has(transition.fromStateId) ||
        !uniqueStateIds.has(transition.toStateId)) {
      issue(issues, 'unknown_transition_state', transition.id);
    } else {
      validTransitions.push(transition);
    }
    if (transition.permittedRoles.length === 0) {
      issue(issues, 'transition_without_role', transition.id);
    }
    if (!transition.isAuditable) {
      issue(issues, 'unaudited_transition', transition.id);
    }
  }
  if (uniqueStateIds.has(definition.startStateId)) {
    const reachable = new Set([definition.startStateId]);
    const queue = [definition.startStateId];
    while (queue.length > 0) {
      const stateId = queue.shift();
      for (const transition of validTransitions) {
        if (transition.fromStateId === stateId &&
            !reachable.has(transition.toStateId)) {
          reachable.add(transition.toStateId);
          queue.push(transition.toStateId);
        }
      }
    }
    for (const state of definition.states) {
      if (state.isRequired && !reachable.has(state.id)) {
        issue(issues, 'unreachable_required_state', state.id);
      }
    }
  }
  const byId = Object.fromEntries(definition.states.map((state) => [state.id, state]));
  for (const transition of validTransitions) {
    if (byId[transition.toStateId].requiresApprovalBeforeEntry &&
        !transition.approvalPolicyId) {
      issue(issues, 'approval_bypass', transition.id);
    }
  }
  return freeze(issues);
}

function validateAuditExportRequest(raw) {
  if (Object.hasOwn(raw, 'filters')) {
    exactKeys(raw, ['filters', 'maxRows'], 'payload');
    const filters = object(raw.filters, 'filters');
    exactKeys(filters, ['from', 'to', 'dimension', 'value'], 'filters');
    const translated = {
      startAt: filters.from,
      endAt: filters.to,
      maxRows: raw.maxRows,
    };
    if (filters.dimension || filters.value) {
      const dimension = enumValue(filters.dimension, 'filters.dimension', [
        'actorUserId', 'module', 'entityType', 'entityId',
        'reference', 'correlationId',
      ]);
      translated[dimension === 'reference' ? 'entityReference' : dimension] =
        requiredString(filters.value, 'filters.value', 180);
    }
    return validateAuditExportRequest(translated);
  }
  exactKeys(raw, [
    'startAt', 'endAt', 'module', 'entityType', 'entityId', 'action',
    'entityReference', 'correlationId', 'actorUserId', 'confidentiality',
    'maxRows',
  ], 'payload');
  const startAt = requiredDate(raw.startAt, 'startAt');
  const endAt = requiredDate(raw.endAt, 'endAt');
  if (endAt <= startAt) invalid('endAt must be after startAt.');
  if ((endAt.getTime() - startAt.getTime()) / 86400000 > AUDIT_EXPORT_MAX_DAYS) {
    invalid(`Audit exports cannot span more than ${AUDIT_EXPORT_MAX_DAYS} days.`);
  }
  return freeze({
    startAt,
    endAt,
    module: optionalString(raw.module, 'module', 80)?.toLowerCase() || null,
    entityType: optionalString(raw.entityType, 'entityType', 100)?.toLowerCase() || null,
    entityId: optionalId(raw.entityId, 'entityId'),
    entityReference: optionalString(
      raw.entityReference,
      'entityReference',
      180,
    ),
    correlationId: optionalId(raw.correlationId, 'correlationId'),
    action: optionalString(raw.action, 'action', 120)?.toLowerCase() || null,
    actorUserId: optionalId(raw.actorUserId, 'actorUserId'),
    confidentiality: raw.confidentiality
      ? enumValue(raw.confidentiality, 'confidentiality', ['public', 'internal', 'restricted'])
      : null,
    maxRows: integer(
      raw.maxRows === undefined ? 1000 : raw.maxRows,
      'maxRows',
      1,
      AUDIT_EXPORT_MAX_ROWS,
    ),
  });
}

function validateKeyedEntries(raw, name, maximum) {
  const entries = array(raw, name, maximum).map((entry, index) => {
    const value = object(entry, `${name}[${index}]`);
    const key = requiredId(value.key, `${name}[${index}].key`);
    return freeze({ ...value, key });
  });
  const keys = entries.map((entry) => entry.key);
  const duplicateKeys = duplicates(keys);
  if (duplicateKeys.length > 0) {
    invalid(`${name} contains duplicate key ${duplicateKeys[0]}.`);
  }
  return freeze(entries);
}

function validateCatalogueEligibility(raw) {
  const value = object(raw, 'eligibility');
  exactKeys(value, [
    'allEmployees', 'userIds', 'departmentIds', 'serviceIds',
    'locationIds', 'positionValues', 'excludedUserIds',
  ], 'eligibility');
  const result = freeze({
    allEmployees: boolean(value.allEmployees, 'eligibility.allEmployees', true),
    userIds: uniqueStrings(value.userIds || [], 'eligibility.userIds', {
      maximum: 500,
      normalize: (entry) => requiredId(entry, 'eligibility.userId'),
    }),
    departmentIds: uniqueStrings(
      value.departmentIds || [],
      'eligibility.departmentIds',
      {
        maximum: 200,
        normalize: (entry) => requiredId(entry, 'eligibility.departmentId'),
      },
    ),
    serviceIds: uniqueStrings(value.serviceIds || [], 'eligibility.serviceIds', {
      maximum: 200,
      normalize: (entry) => requiredId(entry, 'eligibility.serviceId'),
    }),
    locationIds: uniqueStrings(value.locationIds || [], 'eligibility.locationIds', {
      maximum: 200,
      normalize: (entry) => requiredId(entry, 'eligibility.locationId'),
    }),
    positionValues: uniqueStrings(
      value.positionValues || [],
      'eligibility.positionValues',
      {
        maximum: 100,
        normalize: (entry) => requiredId(entry, 'eligibility.positionValue'),
      },
    ),
    excludedUserIds: uniqueStrings(
      value.excludedUserIds || [],
      'eligibility.excludedUserIds',
      {
        maximum: 500,
        normalize: (entry) => requiredId(entry, 'eligibility.excludedUserId'),
      },
    ),
  });
  if (!result.allEmployees && result.userIds.length === 0 &&
      result.departmentIds.length === 0 && result.serviceIds.length === 0 &&
      result.locationIds.length === 0 && result.positionValues.length === 0) {
    invalid(
      'Restricted eligibility requires a user, department, service, location, or organisation position.',
    );
  }
  return result;
}

function validateCatalogueServiceOwner(raw) {
  const value = object(raw, 'serviceOwner');
  exactKeys(value, ['displayName', 'userId', 'teamName'], 'serviceOwner');
  return freeze({
    displayName: requiredString(value.displayName, 'serviceOwner.displayName', 160),
    userId: optionalId(value.userId, 'serviceOwner.userId'),
    teamName: optionalString(value.teamName, 'serviceOwner.teamName', 160),
  });
}

function validateCatalogueConfigurationItems(raw) {
  return array(raw, 'underlyingCis', 30).map((entry, index) => {
    const value = object(entry, `underlyingCis[${index}]`);
    exactKeys(value, ['id', 'name'], `underlyingCis[${index}]`);
    return freeze({
      id: requiredId(value.id, `underlyingCis[${index}].id`),
      name: requiredString(value.name, `underlyingCis[${index}].name`, 160),
    });
  });
}

function configurationReference(raw, name) {
  const value = object(raw, name);
  exactKeys(value, ['definitionId', 'version', 'versionDocumentId'], name);
  return freeze({
    definitionId: requiredId(value.definitionId, `${name}.definitionId`),
    version: integer(value.version, `${name}.version`, 1),
    versionDocumentId: requiredId(
      value.versionDocumentId,
      `${name}.versionDocumentId`,
    ),
  });
}

function localizedRequired(raw, name) {
  const value = object(raw, name);
  exactKeys(value, ['en', 'fr'], name);
  return freeze({
    en: requiredString(value.en, `${name}.en`, 4000),
    fr: requiredString(value.fr, `${name}.fr`, 4000),
  });
}

function exactKeys(value, allowed, name) {
  const permitted = new Set(allowed);
  for (const key of Object.keys(value)) {
    if (!permitted.has(key)) invalid(`${name} contains unknown field ${key}.`);
  }
}

function object(value, name) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    invalid(`${name} must be an object.`);
  }
  return value;
}

function array(value, name, maximum) {
  if (!Array.isArray(value)) invalid(`${name} must be an array.`);
  if (value.length > maximum) invalid(`${name} exceeds ${maximum} entries.`);
  return value;
}

function requiredString(value, name, maximum = 500) {
  const normalized = normalizeString(value);
  if (!normalized) invalid(`${name} is required.`);
  if (normalized.length > maximum) invalid(`${name} exceeds ${maximum} characters.`);
  return normalized;
}

function optionalString(value, name, maximum = 500) {
  if (value === undefined || value === null || normalizeString(value) === '') return null;
  return requiredString(value, name, maximum);
}

function requiredId(value, name) {
  const normalized = requiredString(value, name, 180);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]*$/.test(normalized)) {
    invalid(`${name} contains unsupported characters.`);
  }
  return normalized;
}

function optionalId(value, name) {
  if (value === undefined || value === null || normalizeString(value) === '') return null;
  return requiredId(value, name);
}

function integer(value, name, minimum, maximum = Number.MAX_SAFE_INTEGER) {
  if (!Number.isInteger(value) || value < minimum || value > maximum) {
    invalid(`${name} must be an integer from ${minimum} to ${maximum}.`);
  }
  return value;
}

function number(value, name, minimum, maximum) {
  if (typeof value !== 'number' || !Number.isFinite(value) ||
      value < minimum || value > maximum) {
    invalid(`${name} must be a number from ${minimum} to ${maximum}.`);
  }
  return value;
}

function boolean(value, name, defaultValue) {
  if (value === undefined || value === null) return defaultValue;
  if (typeof value !== 'boolean') invalid(`${name} must be a boolean.`);
  return value;
}

function enumValue(value, name, allowed) {
  const normalized = requiredString(value, name, 100);
  const exact = allowed.includes(normalized)
    ? normalized
    : allowed.find((entry) => entry.toLowerCase() === normalized.toLowerCase());
  if (!exact) invalid(`${name} must be one of ${allowed.join(', ')}.`);
  return exact;
}

function requiredDate(value, name) {
  const date = optionalDate(value, name);
  if (!date) invalid(`${name} is required.`);
  return date;
}

function optionalDate(value, name) {
  if (value === undefined || value === null || value === '') return null;
  if (value instanceof Date && !Number.isNaN(value.getTime())) return value;
  if (typeof value !== 'string' ||
      !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(value)) {
    invalid(`${name} must be an ISO-8601 date-time.`);
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) invalid(`${name} is not a valid date-time.`);
  return date;
}

function validateDateKey(value) {
  const normalized = requiredString(value, 'holiday', 10);
  const date = new Date(`${normalized}T00:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(normalized) ||
      Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== normalized) {
    invalid('holiday must use YYYY-MM-DD.');
  }
  return normalized;
}

function timeOfDay(value, name) {
  const normalized = requiredString(value, name, 5);
  if (!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(normalized)) {
    invalid(`${name} must use 24-hour HH:mm format.`);
  }
  return normalized;
}

function minutesOfDay(value) {
  const [hour, minute] = value.split(':').map(Number);
  return hour * 60 + minute;
}

function eventName(value, name = 'eventName') {
  const normalized = requiredString(value, name, 120).toLowerCase();
  if (!/^[a-z][a-z0-9]*(?:[._-][a-z0-9]+)+$/.test(normalized)) {
    invalid(`${name} must be a namespaced event name.`);
  }
  return normalized;
}

function uniqueStrings(raw, name, options = {}) {
  const values = array(raw, name, options.maximum || 100).map((entry) =>
    options.normalize
      ? options.normalize(entry, name)
      : requiredString(entry, name, 180),
  );
  if (values.length < (options.minimum || 0)) {
    invalid(`${name} requires at least ${options.minimum} entries.`);
  }
  if (new Set(values).size !== values.length) invalid(`${name} contains duplicates.`);
  return freeze(values);
}

function duplicates(values) {
  const seen = new Set();
  return [...new Set(values.filter((value) => {
    if (seen.has(value)) return true;
    seen.add(value);
    return false;
  }))];
}

function issue(issues, code, subjectId) {
  issues.push(freeze({ code, subjectId }));
}

function assertTimeZone(timeZone) {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone }).format(new Date());
  } catch (_) {
    invalid('timeZone must be a valid IANA time zone.');
  }
}

function freeze(value) {
  if (Array.isArray(value)) {
    value.forEach((entry) => {
      if (entry && typeof entry === 'object' && !Object.isFrozen(entry)) freeze(entry);
    });
  } else if (value && typeof value === 'object' && !(value instanceof Date)) {
    Object.values(value).forEach((entry) => {
      if (entry && typeof entry === 'object' && !Object.isFrozen(entry)) freeze(entry);
    });
  }
  return Object.freeze(value);
}

function invalid(message, details) {
  throw new ItsmCommandError('invalid-argument', message, details);
}

module.exports = {
  AUDIT_EXPORT_MAX_DAYS,
  AUDIT_EXPORT_MAX_ROWS,
  REPORTING_ADMINISTRATION_ALLOWED_ROLES,
  REPORTING_ADMINISTRATION_COMMANDS,
  REFERENCE_DATA_TYPES,
  SOURCE_COLLECTIONS,
  WORK_ITEM_TYPES,
  validateAuditExportRequest,
  validateCatalogueDefinition,
  validateReportingAdministrationCommand,
  validateSlaPolicyDefinition,
  validateWorkflowDefinition,
  validateWeeklyWindows,
  workflowValidationIssues,
};
