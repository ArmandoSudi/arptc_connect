'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  REPORTING_ADMINISTRATION_ALLOWED_ROLES,
  REPORTING_ADMINISTRATION_COMMANDS: C,
  validateCatalogueDefinition,
  validateReportingAdministrationCommand,
  validateSlaPolicyDefinition,
  validateWorkflowDefinition,
  workflowValidationIssues,
} = require('../src/itsm_reporting_administration_validation');

test('every command has an explicit role policy and ADMIN has no mutation command', () => {
  assert.deepEqual(
    Object.keys(REPORTING_ADMINISTRATION_ALLOWED_ROLES).sort(),
    Object.values(C).sort(),
  );
  for (const [command, roles] of Object.entries(
    REPORTING_ADMINISTRATION_ALLOWED_ROLES,
  )) {
    if (command === C.requestAuditExport) {
      assert.deepEqual(roles, ['MANAGER', 'ADMIN']);
    } else {
      assert.deepEqual(roles, ['MANAGER']);
      assert.equal(roles.includes('ADMIN'), false);
    }
  }
});

test('SLA validation accepts business calendars and rejects unsafe targets', () => {
  const value = validateSlaPolicyDefinition(validSla());
  assert.equal(value.timeZone, 'Africa/Kinshasa');
  assert.equal(value.warningThreshold, 0.8);
  assert.equal(Object.isFrozen(value.weeklyWindows), true);
  assert.throws(
    () => validateSlaPolicyDefinition({
      ...validSla(),
      resolutionTargetMinutes: 30,
    }),
    /resolutionTargetMinutes/,
  );
  assert.throws(
    () => validateSlaPolicyDefinition({ ...validSla(), timeZone: 'Mars/Base' }),
    /IANA time zone/,
  );
  assert.throws(
    () => validateSlaPolicyDefinition({
      ...validSla(),
      weeklyWindows: {
        1: [{ start: '08:00', end: '12:00' }, { start: '11:00', end: '17:00' }],
      },
    }),
    /overlapping/,
  );
});

test('workflow publication validation finds start, reachability and approval issues', () => {
  const definition = validateWorkflowDefinition({
    ...validWorkflow(),
    startStateId: '',
    transitions: [{
      ...validWorkflow().transitions[0],
      permittedRoles: [],
      approvalPolicyId: null,
      isAuditable: false,
    }],
  });
  const codes = [
    ...workflowValidationIssues(definition),
    ...workflowValidationIssues(validateWorkflowDefinition({
      ...validWorkflow(),
      transitions: [],
    })),
  ].map((issue) => issue.code);
  assert(codes.includes('missing_start_state'));
  assert(codes.includes('transition_without_role'));
  assert(codes.includes('unaudited_transition'));
  assert(codes.includes('approval_bypass'));
  assert(codes.includes('unreachable_required_state'));
});

test('workflow roles are limited to USER, MANAGER and ADMIN', () => {
  assert.throws(
    () => validateWorkflowDefinition({
      ...validWorkflow(),
      transitions: [{
        ...validWorkflow().transitions[0],
        permittedRoles: ['REVIEWER'],
      }],
    }),
    /permitted role must be one of/,
  );
});

test('catalogue definitions require unique fields and immutable references', () => {
  const value = validateCatalogueDefinition(validCatalogue());
  assert.equal(value.workflow.versionDocumentId, 'v2');
  assert.deepEqual(value.visibleRoles, ['USER', 'MANAGER', 'ADMIN']);
  assert.throws(
    () => validateCatalogueDefinition({
      ...validCatalogue(),
      formFields: [{ key: 'title' }, { key: 'title' }],
    }),
    /duplicate key title/,
  );
  assert.throws(
    () => validateCatalogueDefinition({
      ...validCatalogue(),
      activeFrom: '2026-09-01T00:00:00Z',
      activeUntil: '2026-08-01T00:00:00Z',
    }),
    /activeFrom/,
  );
});

test('audit exports require bounded dates, row counts and strict fields', () => {
  const value = command(C.requestAuditExport, {
    startAt: '2026-08-01T00:00:00Z',
    endAt: '2026-08-10T00:00:00Z',
    module: 'Ticketing',
    maxRows: 250,
  });
  assert.equal(value.payload.module, 'ticketing');
  assert.equal(value.payload.maxRows, 250);
  assert.throws(() => command(C.requestAuditExport, {
    startAt: '2026-01-01T00:00:00Z',
    endAt: '2026-08-10T00:00:00Z',
  }), /31 days/);
  assert.throws(() => command(C.requestAuditExport, {
    startAt: '2026-08-01T00:00:00Z',
    endAt: '2026-08-02T00:00:00Z',
    includeSecrets: true,
  }), /unknown field includeSecrets/);
  const wrapped = command(C.requestAuditExport, {
    filters: {
      from: '2026-08-01T00:00:00Z',
      to: '2026-08-02T00:00:00Z',
      dimension: 'correlationId',
      value: 'command-123',
    },
    maxRows: 50,
  });
  assert.equal(wrapped.payload.correlationId, 'command-123');
});

test('envelopes reject forged identity, command mismatch and weak receipts', () => {
  assert.throws(() => validateReportingAdministrationCommand({
    command: C.createSlaPolicyDraft,
    idempotencyKey: 'valid-key-12345',
    payload: { draft: validSla() },
    role: 'MANAGER',
  }), /unknown field role/);
  assert.throws(() => validateReportingAdministrationCommand({
    command: C.createSlaPolicyDraft,
    idempotencyKey: 'short',
    payload: { draft: validSla() },
  }), /idempotencyKey/);
  assert.throws(() => validateReportingAdministrationCommand({
    command: C.createSlaPolicyDraft,
    idempotencyKey: 'valid-key-12345',
    payload: { draft: validSla() },
  }, C.createWorkflowDraft), /cannot execute/);
});

function command(name, payload) {
  return validateReportingAdministrationCommand({
    command: name,
    idempotencyKey: `test-${name}-12345678`,
    payload,
  }, name);
}

function validSla() {
  return {
    name: { en: 'Business support', fr: 'Support métier' },
    workItemType: 'incident',
    priority: 'P2',
    serviceId: 'network',
    responseTargetMinutes: 60,
    resolutionTargetMinutes: 240,
    fulfilmentTargetMinutes: null,
    timeZone: 'Africa/Kinshasa',
    weeklyWindows: {
      1: [{ start: '08:00', end: '17:00' }],
      2: [{ start: '08:00', end: '17:00' }],
      3: [{ start: '08:00', end: '17:00' }],
      4: [{ start: '08:00', end: '17:00' }],
      5: [{ start: '08:00', end: '17:00' }],
    },
    holidays: ['2026-08-15'],
    pauseStates: ['awaiting_user'],
    warningThreshold: 0.8,
    escalationTargets: [{
      eventName: 'sla.manager_escalation',
      assignmentGroupId: 'network-support',
      atPercent: 90,
    }],
  };
}

function validWorkflow() {
  return {
    key: 'incident-workflow',
    module: 'ticketing',
    workItemType: 'incident',
    name: { en: 'Incident workflow', fr: 'Flux des incidents' },
    startStateId: 'open',
    states: [
      { id: 'open', label: { en: 'Open', fr: 'Ouvert' } },
      {
        id: 'approved',
        label: { en: 'Approved', fr: 'Approuvé' },
        requiresApprovalBeforeEntry: true,
      },
    ],
    transitions: [{
      id: 'approve',
      fromStateId: 'open',
      toStateId: 'approved',
      permittedRoles: ['MANAGER'],
      approvalPolicyId: 'manager-approval',
      notificationEvents: ['incident.approved'],
      isAuditable: true,
    }],
  };
}

function validCatalogue() {
  return {
    code: 'NEW-LAPTOP',
    name: { en: 'New laptop', fr: 'Nouvel ordinateur' },
    description: { en: 'Request a laptop', fr: 'Demander un ordinateur' },
    categoryId: 'equipment',
    categoryName: { en: 'Equipment', fr: 'Équipement' },
    iconKey: 'laptop',
    eligibility: {
      allEmployees: true,
      userIds: [],
      departmentIds: [],
      serviceIds: [],
      excludedUserIds: [],
    },
    visibleRoles: ['USER', 'MANAGER', 'ADMIN'],
    formFields: [{ key: 'businessReason', type: 'long_text' }],
    requiredDocuments: [{ key: 'approval', required: true }],
    workflow: { definitionId: 'asset-request', version: 2, versionDocumentId: 'v2' },
    approvalPolicyId: 'manager-approval',
    fulfilmentGroupId: 'asset-team',
    slaPolicy: { definitionId: 'asset-sla', version: 1, versionDocumentId: 'v1' },
    activeFrom: '2026-08-01T00:00:00Z',
    activeUntil: '2027-08-01T00:00:00Z',
    allowManagerRequestOnBehalf: true,
    workflowAllowsCancellation: true,
    sortOrder: 10,
  };
}

module.exports = { validCatalogue, validSla, validWorkflow };
